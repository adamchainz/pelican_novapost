######################################
Python xworkflows et django-xworkflows
######################################

:date: 2012-09-01 15:28
:tags: python, django, django-fr
:category: Python
:author: Rémy Hubscher

************
Introduction
************

Cela fait aujourd'hui un mois que j'ai rejoint l'équipe de Novapost.

C'est donc l'occasion pour moi de faire un petit bilan de ce que j'ai
appris durant ce mois.

J'aimerais pour commencer vous parler de `django-xworkflows
<https://django-xworkflows.readthedocs.io/en/latest/>`_.

***************************************************
Gestion des états d'un objet avec django-xworkflows
***************************************************

J'en ai entendu parlé lors de la dernière DjangoCong lorsque
Polyconseil nous a présenté ce qu'ils avaient mis en place pour
`Autolib <http://www.autolib.eu/>`_.

L'objectif est de définir différents états d'un objet et des
transitions qui permettent de passer d'un état à l'autre.

Les transitions sont des méthodes ce qui permet de modifier des
valeurs de l'objet lors d'un changement d'état.

Concrétement dès lors que vous avez un processus en plus de 2 étapes
vous êtes succeptibles de vouloir utiliser des états à la place d'un
``BooleanField``.

Prenons un exemple simple. Lors de l'upload d'un document sur votre
coffre nous devons lancer la génération des miniatures de votre
document.

Il y a donc quatre états :

 * **init** : Un nouveau document a été créé.
 * **uploaded** : Le contenu du document a été uploadé le coffre sécurisé.
 * **queued** : Le document a été envoyé aux workers de génération des miniatures.
 * **ready** : Les miniatures ont bien été générées, le document est prêt.

Cela évite d'afficher un lien preview alors que les miniatures ne sont
pas prêtes notamment.

Dans notre cas nous utilisons un model Django pour stocker notre
document, nous allons donc utiliser ``django-xworkflows`` qui va
enregistrer notre nouvel état à chaque transition.

.. code-block:: python

    from django_xworkflows import models as xwf_models

    class DocumentWorkflow(xwf_models.Workflow):
        """States and transitions for :py:class:`Document` model."""
        #: Disable logging to database
        log_model = ''
        #: Available states.
        states = (
        ('init', _(u'Created')),
            ('uploaded', _(u'Uploaded')),
            ('queued', _(u'Queued for previews generation')),
            ('ready', _(u'Ready')),
        )
        #: Available transitions.
        transitions = (
        ('upload', 'init', 'uploaded'),
            ('queue', 'uploaded', 'queued'),
            ('activate', 'queued', 'ready'),
            # Administration command to restart preview generation
            ('reset', 'queued', 'uploaded'),
        )
        #: Default state on instance creation.
        initial_state = 'init'

Ensuite nous modifions notre models pour y ajouter la gestion des
workflows.

.. code-block:: python

    from django.db import models
    from django.core.files.storage import get_storage_class
    from django_xworkflows import models as xwf_models

    storage_import_string = getattr(settings, 'VAULT_STORAGE',
                                    'project.storage.DummyStorage')
    Storage = get_storage_class(storage_import_string)
    upload_to = Storage.upload_to()
    
    class Document(xwf_models.WorkflowEnabled, models.Model):
        file = models.FileField(verbose_name=_('file'), storage=Storage(), upload_to=upload_to)
        title = models.CharField(_('title'), max_length=100, blank=True)

        state = xwf_models.StateField(DocumentWorkflow)

        def __unicode__(self):
            return u'%s' % self.title

        def save(self, *args, **kwargs):
            flag = self.pk is None
            if not self.title:
                self.title = self.file.name
            super(Document, self).save(*args, **kwargs)
            if flag:
                self.upload() # On first save, the document is uploaded to the secure bucket

Maintenant nous avons un models django qui est capable de sauvegarder son état.
Il faut bien sur mettre à jour la base de données.

.. code-block:: pycon

    >>> from models import Document
    >>> from django.core.files.base import ContentFile
    >>> myfile = ContentFile("Foo bar", "foobar.txt")
    >>> d = Document.objects.create(file=myfile)
    >>> d.title
    'foobar.txt'
    >>> d.state
    <StateWrapper: <State: 'uploaded'>>
    >>> d.activate()
    InvalidTransitionError: Transition 'activate' isn't available from state 'uploaded'.
    >>> d.queue()
    >>> print d.state
    <State: 'queued'>
    >>> print u'%s' % d.state
    Queued for previews generation
    >>> d.state.is_queued
    True

Nous avons donc des transitions de bases qui nous permette de valider
les changements d'états.

Ensuite nous pouvons définir des actions lors des transitions :

.. code-block:: python

    from django.core.urlresolvers import reverse_lazy as reverse
    from django.db import models
    from django_xworkflows import models as xwf_models
    import xworkflows
    import requests

    THUMBNAILER_API = 'http://example.com/async/document/'
    
    class Document(xwf_models.WorkflowEnabled, models.Model):
        file = models.FileField(verbose_name=_('file'))
        title = models.CharField(_('title'), max_length=100, blank=True)
        num_pages = models.PositiveIntegerField(editable=False, default=0)

        state = xwf_models.StateField(DocumentWorkflow)

        def __unicode__(self):
            return u'%s' % self.title

        def save(self, *args, **kwargs):
            flag = self.pk is None
            if not self.title:
                self.title = self.file.name
            super(Document, self).save(*args, **kwargs)
            if flag:
                self.upload() # On first save, the document is uploaded to the secure bucket
        
        def _queue(self):
            """Send job for async preview generation request."""
            # Add job to redis queue
            requests.get(THUMBNAILER_API, params = {
                    'url': self.file.url,
                    'width': [1000, 750, 150],
                    'max_pages': 20,
                    'callback': reverse('vault:thumbnail_callback', self.pk)})
        
        @xworkflows.transition()
        def upload(self):
            """Change the state when the file has been uploaded to the secure bucket."""
        
        @xworkflows.transition()
        def queue(self):
            self._queue()
        
        @xworkflows.transition()
        def activate(self, num_pages):
            self.num_pages = num_pages
        
        @xworkflows.transition()
        def reset(self):
            self._queue()

Il nous reste simplement à réaliser une view qui va nous permettre de
mettre à jour le nombre de pages lors du callback.

.. code-block:: python

    from django.shortcuts import get_object_or_404
    from django.http import HttpResponse
    from decorators import api_key_validation, post_only
    from models import Document
    from xworkflows import InvalidTransitionError

    @api_key_validation
    @post_only
    def thumbnailer_callback(request, pk):
        document = get_object_or_404(Document, pk=pk)
        num_pages = request.POST.get('num_pages', 1)
        try:
            document.activate(num_pages)
        except InvalidTransitionError, e:
            return HttpResponse(e.message(), status_code=400)
        return HttpResponse('Document activated')

Dans nos templates, si nous souhaitons tester si nous devons afficher la preview :

.. code-block:: django

    {% load thumbnailer_tags %}

    {% if object.state.is_activated %}
    <img src="{% version object.file '150' %}" alt="{{ object.title }}" />
    {% else %}
    <img src="{% static 'img/loading.gif' %} alt="{{ object.title }}" />
    {% endif %}

Comme vous le voyez, il est très simple de tester l'état d'un objet à l'aide d'un boolean.

**********
Conclusion
**********

En conclusion : **les workflows c'est bon, mangez-en !**

Ça simplifie grandement la gestion de l'état d'un objet, les
transitions garantissent que l'objet est toujours dans un état
stable et correct.

Si vous souhaitez en savoir plus sur notre service de génération des
miniatures, allez voir `la documentation de Thumbnailer
<https://thumbnailer.readthedocs.io/>`_.
