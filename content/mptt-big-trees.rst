###############################
MPTT, des arbres et des données
###############################

:date: 2012-11-26 12:42
:tags: python, django, mptt, django-fr
:category: Python
:author: Lauréline Guérin
:lang: fr
:slug: mptt-des-arbres-et-des-donnees


Rémy insiste souvent pour que j'écrive des articles sur tel ou tel truc,
je profite donc de toute l'énergie positive accumulée ce week-end lors du
`Djangocon-Toulouse`_ (sans G, n'en déplaise à Rémy :) ) pour prendre
ma plume^W^Wmon clavier.

.. _`Djangocon-Toulouse`: http://rencontres.django-fr.org/2012/tolosa


Contexte
========

Pour un projet, nous avons eu besoin de modéliser des organisations
sous forme arborescente, ce que nous avons fait avec `MPTT`_.

.. _`MPTT`: https://github.com/django-mptt/django-mptt

Voici notre modèle:

.. code-block:: python

    from django.db import models
    from mptt.managers import TreeManager
    from mptt.models import MPTTModel, TreeForeignKey


    class Organization(MPTTModel):
        parent = TreeForeignKey('self', null=True, blank=True)
        name = models.CharField(_("name"), max_length=255)
        code = models.CharField(_("code"), max_length=64, db_index=True)

        ...

        tree = TreeManager()
        objects = models.Manager()


Problème
========

Nous avons parfois besoin d'importer un gros tas d'organisations depuis un fichier CSV.
Dernièrement, nous avions un fichier de 8000 lignes, 8000 organisations donc.

En théorie, même pas peur. 8000 organisations, ce n'est pas vraiment un chiffre astronomique.

Pourtant, lorsqu'on essaie d'insérer 8000 éléments dans un arbre, ça peut faire mal;
il a fallu 5H et masse CPU pour importer cette poignée d'organisations. Et le serveur était à genoux.


Des pistes
==========

Voici un article sur un retour d'expérience avec MPTT:
`My experience with django-mptt`_.

.. _`My experience with django-mptt`: http://www.darkcoding.net/software/my-experience-with-django-mptt/

Il est notamment expliqué qu'à chaque fois qu'on sauvegarde un MPTTModel, l'ensemble de l'arbre est
reconstruit, afin de placer chaque élément à la bonne position (calcul des champs `lft`, `rght`, `tree_id`, `level`).
Plus on a d'éléments, plus la reconstruction est lente et consommatrice de ressources.

Il y a 4 mois, des `contextmanagers`_ ont été ajoutés à MPTT. Ils permettent de débrancher
la reconstruction de l'arbre à chaque mise à jour.

.. _`contextmanagers`: https://github.com/django-mptt/django-mptt/pull/201

Avec `disable_mptt_updates`, il suffit de rebuild après avoir bidouillé un tas de
MPTTModel:

.. code-block:: python

    with transaction.commit_on_success():
        with MyNode.objects.disable_mptt_updates():
            ## bulk updates.
        MyNode.objects.rebuild()

Avec `delay_mptt_updates`, le rebuild se fait automatiquement à la sortie du bloc:

.. code-block:: python

    with transaction.commit_on_success():
        with MyNode.objects.delay_mptt_updates():
            ## bulk updates.

Chouette, c'est exactement ce qu'il nous faut. Zut, c'est dans master, ce n'est pas encore released
(dernière version à ce jour: 0.5.4).

Une solution
============

Bon, y'a plus qu'à faire les choses à la main, en attendant la prochaine release.

J'ai ajouté une méthode save qui bypasse la reconstruction de l'arbre MPTT:

.. code-block:: python

    def save_without_mptt_updates(self):
        """
        Do not update mptt tree fields
        Organization.tree.rebuild() has to be performed later.
        """
        if self.pk is None:
            # init tree fields
            self.lft = self.rght = self.tree_id = self.level = 0
        models.Model.save(self)

(Je vous invite à jeter un oeil à la méthode `save` de MPTTModel)

A noter: l'initialisation des champs spécifiques à MPTT dans le cas d'un nouvel objet,
car ils sont définis comme non nulls.

L'utilisation est simple, ça donne à peu près:

.. code-block:: python

    with transaction.commit_on_success():
        for line in csv_reader:
            # create or update org
            org = ...
            ...
            org.save_without_mptt_updates()
        Organization.tree.rebuild()

Avec cette méthode, nous avons réussi à importer nos 8000 organisations en 3 minutes \\o/
