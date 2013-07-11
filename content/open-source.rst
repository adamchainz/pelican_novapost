##################################
Open-source : pourquoi et comment?
##################################

:date: 2013-07-12 12:00
:tags: 
:category: Astuces
:author: Benoît Bryon
:lang: fr
:slug: novapost-open-source

Si vous suivez ce blog, vous l'aurez sans doute déjà remarqué, chez
`Novapost`_ nous "faisons de l'open-source" :

* nous publions sur `notre compte Github`_ ;
* nous participons à des événements ;
* nous en parlons sur ce blog...

Or "faire de l'open-source" n'est pas la vocation de Novapost. Du point de vue
de l'entreprise, l'open-source n'est pas une fin en soi. Pourquoi-donc faisons-
nous de l'open-source ? Qualité, cercle vertueux, réutilisation, etc... les
raisons sont plutôt classiques et ont certainement été expliquées en détail
ailleurs. Et puis, nombreux sont ceux qui partagent ces idées mais ne font pas
d'open-source pour autant. C'est pourquoi cet article tâchera d'éclairer un
aspect tout aussi important : comment nous organisons-nous pour faire de
l'open-source chez Novapost ?


****************************
Des motivations personnelles
****************************

Au départ, l'open-source est une motivation portée individuellement, par des
développeurs :

  En tant que développeur, l'open-source me plaît.

Nous sommes plusieurs, nous nous parlons, nous collaborons sur les projets...
La motivation d'abord individuelle est peu à peu partagée par l'équipe.

Mais ça ne suffit pas. Contribuer à des projets existants ou libérer une partie
du code produit, cela demande du temps et des efforts. Pouvons-nous nous
permettre de faire ça sur notre temps de travail ? La question est légitime,
et elle mérite d'être clarifiée avec notre employeur...


**************************************
Une vision partagée avec le management
**************************************

Comment convaincre le management de l'intérêt de l'open-source ? Pour
commencer, se rappeler que l'open-source n'est pas une fin en soi, mais un
moyen de développer des logiciels. Pour schématiser, ce n'est pas l'open-source
qui fait entrer de l'argent dans l'entreprise, mais des produits ou services.
L'open-source est un moyen parmi d'autres pour développer ces produits et
rendre ces services. L'open-source présente les avantages suivants :

* publier du code favorise sa qualité. D'une part parce qu'on a tendance à
  s'appliquer davantage quand on montre son travail, et d'autre part parce
  qu'on s'expose aux critiques (constructives).

* publier du code favorise sa pérennité. On attache davantage d'importance à la
  lisibilité, à la documentation, à la facilité d'installation d'un
  environnement de développement, aux tests... Tout cela tend à rendre le
  projet plus accessible à de nouveaux venus. Par ailleurs, cela augmente la
  probabilité que l'auteur du projet continue à l'utiliser et à le maintenir
  même après avoir quitté l'entreprise.

* communiquer sur les projets open-source donne de la visibilité à
  l'entreprise.

* la culture open-source est un critère fort pour les recrutements. Les
  employeurs apprécient les candidats qui peuvent montrer des réalisations
  personnelles. La réciproque est vraie : l'open-source est une source de
  motivation pour un certain nombre de candidats... et en particulier ceux qui
  sont actifs dans le domaine.

Si le management est convaincu de la valeur ajoutée de l'open-source, alors
il est possible de reconsidérer un certains nombre d'idées reçues sous un
nouvel angle.


******************************************
L'open-source fait partie de notre travail
******************************************

Beaucoup considèrent que l'open-source est un bonus, quelque chose qu'on peut
pratiquer, mais seulement avec parcimonie ou sur le temps libre. "Je n'ai pas
le temps" est une raison souvent invoquée.

Chez Novapost, au sein de l'équipe de développpement, nous pensons que
l'open-source a une véritable valeur ajoutée. Dès lors, nous affirmons que
l'open-source est une partie intégrante de notre travail :

  L'open-source est un moyen de bien faire notre travail.

Ce postulat change l'état d'esprit dans lequel nous travaillons, et c'est
beaucoup. En quelque sorte, nous ne faisons pas de l'open-source seulement pour
le plaisir, nous y avons des intérêts. Cela nous donne une réelle légitimité.

Les contributions open-source sont certes légitimes, mais elles ne doivent pas
compromettre la production privée, ce pour quoi nous sommes salariés...


***************************************
Open-source dans la roadmap des projets
***************************************

Pour cadrer les contributions open-source, rien de tel que de les intégrer dans
le cycle de développement des projets :

* les contributions open-source sont des tâches comme les autres.
* on se fixe des objectifs : une release pour telle date, l'ajout d'une
  fonctionnalité...
* on peut prioriser les contributions.

Reste maintenant à passer à la pratique...


*******************************
Séparer générique et spécifique
*******************************

Dans la pratique, il n'est pas toujours évident de contribuer ou de libérer du
code. Voici une petite astuce :

* tout ce qui n'est pas spécifique à un projet en particulier, je le déplace
  dans un package "utils" du projet.

  Voici ce que dit notre fichier "utils/__init__.py" :

  .. code:: python

     """Utilities that may be distributed in separate projects."""

  Pour savoir si un outil est spécifique, rien de tel que de regarder ce dont
  il dépend (arguments en entrée, ``import``) et ce qu'il produit.

* "utils" est un fourre-tout. C'est pratique pour coder rapidement, mais ce
  n'est pas satisfaisant. Dès que j'en ai l'occasion, par exemple dès que je
  souhaite réutiliser un outil dans un autre projet, je sors le contenu d'utils
  vers un projet externe.

  Faire grossir le code d'un utilitaire, et typiquement souhaiter transformer
  un module Python en package, c'est aussi une bonne occasion de démarrer un
  nouveau projet.

* quand je démarre un nouveau projet, je commence par chercher des
  alternatives. Certes cela demande un peu de temps, mais c'est bien moins
  cher que de réinventer la roue : tant que mon utilitaire ne représentait que
  peu de code, il n'était pas très coûteux de l'implémenter et de le maintenir.

  Si je trouve au moins une alternative, il est de bon ton d'utiliser les
  projets existants, quitte à y proposer des contributions quand c'est
  nécessaire.

.. note::

   Au départ, on a tendance à présumer du caractère générique des outils. C'est
   problématique si on y passe beaucoup de temps. Souvent, il est préférable
   d'attendre d'avoir besoin de l'outil dans un autre projet avant de le
   considérer générique.


**********
Un exemple
**********

Au départ, `django-downloadview`_ était un bout de code intégré dans l'un de
nos projets. C'était "juste" deux ou trois fonctions, dans un module.

J'ai eu besoin de cette fonctionnalité dans un autre projet, j'ai donc
packagé les fonctionnalités dans un projet externe. Comme rien n'était
spécifique à nos projets privés, un projet public convenait bien.

Plus tard, `en cherchant les alternatives pour rédiger la documentation`_, j'ai
découvert `django-sendfile`_. J'ai proposé à son auteur d'importer les
fonctionnalités de downloadview dans sendfile. Cette proposition a été
refusée et la fusion n'a pas eu lieu.

Aujourd'hui sur nos projets, nous utilisons django-downloadview. Ça
fonctionne, ça suffit. On a plus besoin d'y toucher, sauf bugs et mises à
jour liées aux évolutions de Django. Éventuellement, le projet sera
amélioré via des propositions de la communauté.

Mission accomplie ? J'ai bien l'impression que oui ;)


.. target-notes::

.. _`Novapost`: http://www.novapost.fr
.. _`notre compte Github`: https://github.com/novagile/
.. _`PyPI`: https://pypi.python.org/
.. _`django-downloadview`: https://pypi.python.org/pypi/django-downloadview
.. _`en cherchant les alternatives pour rédiger la documentation`:
   https://github.com/writethedocs/docs/issues/25
.. _`django-sendfile`: https://pypi.python.org/pypi/django-sendfile
