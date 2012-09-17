######################################
PyconFR 2012 à la Villette : le résumé
######################################

:date: 2012-09-17 11:23
:tags: afpy, pycon, python
:category: Conférences
:author: Rémy Hubscher

************
Introduction
************

Et voilà, `PyCon Fr`_ c'est déjà terminé, il est temps de faire un retour de
tout ce que nous avons appris durant ces quatre jours.

.. _`PyCon Fr`: http://pycon.fr

*******
Sprints
*******

Nous avons donc participé aux sprints et principalement travaillé sur Circus_
pendant les deux premiers jours.

Circus_ est un gestionnaire de processus et de sockets écrit en python par
`Mozilla Services`_.

.. _Circus: http://circus.readthedocs.org/en/latest/
.. _`Mozilla Services`: https://github.com/mozilla-services

Au programme
============

* `Complétion automatique`_ des arguments de ``circusctl``
* Mise en place d'une `ligne de commande interactive`_ lors du lancement de
  ``circusctl`` sans arguments
* Brainstorming_ sur la gestion d'un cluster de ``circusd`` avec une interface commune
* Nombreux `fix et améliorations`_ (voir la journée du 13 Septembre)
* Review de "Pull Requests" en attente d'être fusionnées

.. _`Complétion automatique`: ../autocompletion-des-arguments-dans-vos-commandes.html
.. _`ligne de commande interactive`: https://github.com/mozilla-services/circus/pull/268
.. _Brainstorming: ../circus-clustering-management-en.html
.. _`fix et améliorations`: https://github.com/mozilla-services/circus/commits/master


***********
Conférences
***********

Nous avons ensuite assistés à de nombreuses conférences sur les deux jours
suivants, et voici un petit résumé de ce que nous avons appris :

* Python 3.3 c'est bon mangez-en.
* Si vous utilisez Django, utilisez `Django Debug Toolbar`_, South_ et Sentry_
* Django 1.5 est compatible avec Python 3, les tests passent et il est possible
  de commencer à porter ses applications dessus (release fin 2012).
* Django 1.6 supportera officiellement Python 3 à l'horizon Novembre 2013.
* fabric, les makefiles en Python pour exécuter des commandes sur des serveurs
  distants.
* fabtools, utilisez fabric pour faire également du provisionning sur vos VM
* Mercurial continue sa progression avec des améliorations sur les performances
  et le rebase.
* REST in SPORE_ : Utilisez SPORE pour décrire vos API REST et créer
  automatiquement un client REST pour votre API dans de nombreux langages de
  programmation dont Spyre_ en Python.
* PyBABE_ : Gérez vos gros fichiers de données (CSV, Exel, ODS) sans tout
  charger en mémoire et en les convertissant simplement d'un format à l'autre.
* Cornice_, Générez vos API et ayez automatiquement une documentation ainsi que
  votre fichier SPORE_. Vous pouvez ensuite brancher votre API sur le système
  d'URL de votre choix : Werkzeug, Django ou Pyramid.
* Programmation web asynchrone avec Tornado_. Si vous devez faire du long
  polling ou demander des informations à des API distantes telles que Facebook,
  Twitter, ... vous devez jeter un œil à Tornado qui vous permet de le faire de
  manière asynchrone sans remplir vos workers WSGI ou faire exploser votre
  serveur. Par contre le mode asynchrone n'est pas compatible avec WSGI.
* WeasyPrint, une lib à suivre si vous devez générer des PDF en Python.
* Architecture CQRS et performances avec Django : Command-Query Responsibility
  Segregation. C'est une méthodologie de dénormalisation dans le cas ou vous ne
  pouvez pas mettre vos requêtes lentes en cache. En résumé, utiliser l'ORM
  pour faire les requêtes d'écritures dans la base (Commands), et ajouter des
  signaux pour mettre à jour la représentation de ces données dans Redis,
  CouchDB, MongoDB, une vue postgresql... Du côté de vos vues, en lecture
  (Query), il vous suffira d'afficher la représentation des données, au lieu
  de la recalculer à chaque fois à partir des données brutes. Et lorsqu'une
  modification est faite, la représentation est mise à jour avec une tâche
  celery asynchrone.
* Porter ses applications vers Python3 en utilisant Six.
* La gestion des timezones avec Python, utiliser des datetimes et non des
  dates. Exemple avec Django.
* Metrology, mesurez tout, tous le temps (graphite, statsd, carbon).
* Unicode, tout ce qu'il faut savoir.

.. _`Django Debug Toolbar`: https://github.com/django-debug-toolbar/django-debug-toolbar
.. _South: http://south.readthedocs.org/en/latest/about.html
.. _Sentry: http://sentry.readthedocs.org/en/latest/index.html
.. _SPORE: https://github.com/SPORE/specifications
.. _Spyre: http://spyre.readthedocs.org/en/latest/index.html
.. _PyBABE: https://github.com/fdouetteau/PyBabe
.. _Tornado: http://www.tornadoweb.org/
.. _Cornice: http://cornice.readthedocs.org/en/latest/index.html

**********
Conclusion
**********

Cette conférence fût, comme à son habitude, une excellente opportunité pour en
apprendre davantage sur notre métier, renforcer notre expertise, et surtout,
rencontrer et faire connaissance avec nos pairs !
Pour rappel, à l'exception d'une personne recrutée à la suite d'un stage, la
totalité de l'équipe Django à Novapost se connaissait bien avant de travailler
ensemble.

Tout développeur passionné par son métier devrait participer à ce genre de
rencontres (il y en a aussi de plus `spécifiques à Django`_), afin de parfaire
ses connaissances, découvrir de nouvelles pistes d'amélioration, et se tenir à
jour sur l'état de l'art !

Un énorme merci à toute l'équipe d'organisation, et un grand bravo à Nelle
Varoquaux, la nouvelle présidente de l'association AFPY_ qui chapeaute cette
rencontre depuis maintenant plusieurs années.

Merci enfin à tous les participants que nous avons pu croiser, avec qui nous
avons pu échanger, et qui nous ont parfois donné d'excellentes idées pour
rendre notre produit encore meilleur.

À l'année prochaine !

.. _`spécifiques à Django`: http://rencontres.django-fr.org
.. _AFPY: http://afpy.org
