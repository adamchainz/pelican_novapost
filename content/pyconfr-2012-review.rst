##########################
PyconFR 2012 à la Villette
##########################

:date: 2012-09-17 11:23
:tags: afpy, pycon, python
:category: Conférences
:author: Rémy Hubscher
:status: draft

************
Introduction
************

Et voilà, PyCon Fr c'est déjà terminé, il est temps de faire un retour
de tout ce que nous avons appris durant ces quatre jours.

*******
Sprints
*******

Nous avons donc participés aux sprints et principalement travaillés sur Circus_.

Circus_ est un gestionnaire de processus et de sockets écrit en python par `Mozilla Services`_.

.. _Circus: http://circus.readthedocs.org/en/latest/
.. _`Mozilla Services`: https://github.com/mozilla-services

Au programme
============

* Complétion automatique des arguments de ``circusctl`` et rédaction
  d'un `article explicatif
  <http://tech.novapost.fr/autocomplete-de-vos-arguments-dans-vos-commandes-python.html>`_.
* Mise en place d'une ligne de commande intéractive lors du lancement
  de ``circusctl`` sans arguments.
* Braistorming sur la gestion d'un cluster de ``circusd`` avec une
  interface commune et rédaction d'un `article explicatif
  <http://tech.novapost.fr/circus-clustering-management.html>`_


***********
Conférences
***********

Nous avons donc assistés à de nombreuses conférences et voici ce que
nous avons appris :

* Python 3.3 c'est bon mangez-en
* Si vous utilisez Django, utilisez `Django Debug Toolbar`_, South_ et Sentry_
* Django 1.5 est compatible avec Python 3, les tests passent et il est
  possible de commencer à porter ses applications dessus (release
  fin 2012)
* Django 1.6 supportera officiellement Python 3 à l'horizon
  Novembre 2013.
* fabric, les makefiles en Python pour exécuter des commandes sur des
  serveurs distants
* fabtools, utilisez fabric pour faire également du provisionning sur
  vous VM.
* Mercurial continue sa progression avec des améliorations sur les
  performances et le rebase.
* REST in SPORE_ : Utilisez SPORE pour décrire vos API REST et créer
  automatiquement un client REST pour votre API dans de nombreux
  languages de programmation dont Spyre_ en Python
* PyBABE_ : Gérez vos gros fichiers de données (CSV, Exel, ODS) sans
  tout charger en mémoire et en les convertissant simplement d'un
  format à l'autre.
* Cornice_, Générez vos API et ayez automatiquement une documentation
  ainsi que votre fichier SPORE_. Vous pouvez ensuite brancher votre
  API sur le système d'URL de votre choix Werkzeug, Django ou Pyramid.
* Programmation web asynchrone avec Tornado_. Si vous devez faire du
  long polling ou demander des informations à des API distances telles
  que Facebook, Twitter, ... vous devez jeter un œil à Tornado qui
  vous permet de le faire de manière asynchrone sans remplir vos
  workers WSGI ou faisant exploser votre serveur. Par contre le mode
  asynchrone n'est pas compatible avec WSGI.
* WeasyPrint, une lib à suivre si vous devez générer des PDF en Python
* Architecture CQRS et performances avec Django : Command Query
  Responsibility Segregation. En gros, lorsque vous regardez vos
  requêtes avec DjDT si vous avez une requête qui prends plusieurs
  secondes et que vous pouvez pas la cacher, vous devez regarder cette
  solution : Utiliser l'ORM pour faire les requêtes d'écritures dans
  la BD (Commands) et ajouter des signaux pour mettre à jour une vue
  noSQL de ces données (Redis, CouchDB, MongoDB) du côté de vos views
  en lecture (Query) ainsi lorsqu'une modification est faites, votre
  base noSQL est mise à jour avec une tâche celery asynchrone et en
  lecture vous avez directement votre résultat.
* Porter ses applications vers Python3 en utilisant Six
* La gestion des timezones avec Python, utiliser des datetimes et non
  des dates. Exemple avec Django.
* Metrology, mesurez tout, tous le temps (graphite, statsd, carbon)
* Unicode, tout ce qu'il faut savoir

.. _`Django Debug Toolbar`: https://github.com/django-debug-toolbar/django-debug-toolbar
.. _South: http://south.readthedocs.org/en/latest/about.html
.. _Sentry: http://sentry.readthedocs.org/en/latest/index.html
.. _SPORE: https://github.com/SPORE/specifications
.. _Spyre: http://spyre.readthedocs.org/en/latest/index.html
.. _PyBABE: https://github.com/fdouetteau/PyBabe
.. _Tornado: http://www.tornadoweb.org/

**********
Conclusion
**********

Trop cool !
