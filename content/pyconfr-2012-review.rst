######################################
PyconFR 2012 à la Villette : le résumé
######################################

:date: 2012-09-17 11:23
:tags: afpy, pycon, python, django-fr
:category: Conférences
:author: Rémy Hubscher

************
Introduction
************

Et voilà, `PyCon Fr`_ est déjà terminé, il est temps de faire un retour de
tout ce que nous avons appris durant ces quatre jours.

.. _`PyCon Fr`: http://pycon.fr

*******
Sprints
*******

Nous avons donc participé aux sprints et principalement travaillé sur Circus_
pendant les deux premiers jours.

Circus_ est un gestionnaire de processus et de sockets écrit en python par
`Mozilla Services`_.

.. _Circus: https://circus.readthedocs.io/en/latest/
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


Les infos en vrac
=================

* Python 3.3 c'est bon mangez-en
* Si vous utilisez Django, utilisez `Django Debug Toolbar`_, South_ et Sentry_
* Django 1.5 est compatible avec Python 3, les tests passent et il est possible
  de commencer à porter ses applications dessus (release fin 2012).
* Django 1.6 supportera officiellement Python 3 à l'horizon Novembre 2013.
* Mercurial continue sa progression avec des améliorations sur les
  performances et le rebase.


Déployer avec fabric
====================

Vous connaissez peut-être déjà ``fabric`` c'est un module Python qui
permet d'exécuter des règles écrites en python sur un serveur distant
en utilisant ``ssh``

En gros, le fabfile est **le makefile python** over ssh.

`Ronan Amicel <http://twitter.com/amicel>`_ à eu la bonne idée de
rajouter là dessus des recettes de provisioning (c'est à dire des
règles permettant d'installer et de configurer la machine distante).

Cela permet notamment d'installer son appli sur une VM vierge.

Ce n'est pas réellement un concurrent à Chef_, Puppet_ ou Salt_ mais
plutôt une couche intermédiaire permettant d'aller un peu plus loin
avec un fabfile de manière propre et sans overhead.

Voilà à quoi ça ressemble :

.. code-block:: python

    from fabric.api import *
    from fabtools import require
    import fabtools
    
    @task
    def setup():
    
        # Require some Debian/Ubuntu packages
        require.deb.packages([
            'imagemagick',
            'libxml2-dev',
        ])
    
        # Require a Python package
        with fabtools.python.virtualenv('/home/myuser/env'):
            require.python.package('pyramid')
    
        # Require an email server
        require.postfix.server('example.com')
    
        # Require a PostgreSQL server
        require.postgres.server()
        require.postgres.user('myuser', 's3cr3tp4ssw0rd')
        require.postgres.database('myappsdb', 'myuser')
    
        # Require a supervisor process for our app
        require.supervisor.process('myapp',
            command='/home/myuser/env/bin/gunicorn_paster /home/myuser/env/myapp/production.ini',
            directory='/home/myuser/env/myapp',
            user='myuser'
            )
    
        # Require an nginx server proxying to our app
        require.nginx.proxied_site('example.com',
            docroot='/home/myuser/env/myapp/myapp/public',
            proxy_url='http://127.0.0.1:8888'
            )
    
        # Setup a daily cron task
        fabtools.cron.add_daily('maintenance', 'myuser', 'my_script.py')

* `En savoir plus sur Fabric <http://docs.fabfile.org/en/1.4.3/index.html>`_
* `En savoir plus sur fabtools <https://github.com/ronnix/fabtools>`_

.. _Chef: http://www.opscode.com/chef/
.. _Puppet: http://puppetlabs.com/
.. _Salt: http://docs.saltstack.org/en/latest/ref/modules/index.html

REST in SPORE
=============

SPORE_ est une spécification de description complète, au format JSON,
d'un service REST.

Ce fichier peut-être consommé pour générer automatiquement un client
REST pour cette API. 

Il existe des générateur de client SPORE dans de nombreux languages.

En Python, l'Université de Strasbourg développe actuellement Spyre_

Voici un exemple de fichier SPORE :

.. code-block:: javascript

    {
        "name": "Middle Earth Web API",
        "authority": "MORDOR:Sauron",
        "version": "1.0",
        "formats": [
            "json"
        ],
        "methods": {
            "get_ring": {
                "path": "/rings/:id.:format",
                "required_params": [
                    "id",
                    "format"
                ],
                "method": "GET",
                "authentication": true,
                "expected_status": [200, 403]
    
            },
            "get_precious": {
                "path": "/rings/9.:format",
                "required_params": [
                    "format"
                ],
                "authentication": true,
                "method": "GET",
                "expected_status": [200, 403]
            }
        }
    }

Pour voir un exemple de server et de client implémentant cette
spécification en Python : https://github.com/agrausem/mordor

Suite à cette présentation, `Alexis Metaireau`_ à commencer une feature
pour cornice permettant de générer automatiquement le fichier SPORE_ à
partir du service développé avec Cornice.

.. _`Alexis Metaireau`: http://blog.notmyidea.org/

PyBABE et les flux de données
=============================

PyBabe est conçu pour gérer de gros fichiers de données (CSV, Exel,
ODS) et de pouvoir les manipuler sans tout charger en mémoire pour
faire des requêtes dessus (extraire des colonnes) ou pour les convertir
simplement d'un format à l'autre.

PyBabe est capable de récupérer les fichiers over DB, FTP, Http, Email, S3, ...
Des fichiers zippés, Gzippé, CSV, Exel, ...

Voici un exemple simple d'utilisation :

.. code-block:: python

    # Recupére un fichier CSV de S3, le décompresse, cache en local 
    babe = babe.pull(url="s3://myapp/mydir 2012-07-07_*.csv.gz",cache=True)
    
    # Recupère l’IP dans le champs IP, trouve pas geoip le pays
    babe = babe.geoip_country_code(field="ip", country_code="country", ignore_error_True)
    
    # Récupère le user agent, et stocke le nom du navigateur
    babe = babe.user_agent(field="user_agent", browser="browser")
    
    # Ne garde que les champs pertinents
    babe = babe.filterFields(fields=["user_id", "date", "country", "user_agent"])
    
    # Stocke le résultat dans une base de donnée
    babe.push_sql(database="mydb", table="mytable", username="…");

Voici un autre exemple ou PyBabe gére un important flux de données :

.. code-block:: python

    babe = Babe()
    
    # Recupére un gros fichier csv 
    babe = babe.pull(filename="mybigfile.csv")
    
    # Effecture un tri "disk-based", par paquet de 100.000 lignes
    babe = babe.sortDiskBased(field="uid", nsize=100000)
    
    # Calcule un regroupement par uid 
    # Calcule la somme des revenues par utilisateurs. 
    babe = babe.groupBy(field="uid", reducer=lambda x, y: (x.uid, x.amount + y.amount))
    
    # Join avec le résultat d’une requete sql pour recupérer des meta information sur les utilisateurs
    babe = babe.join(Babe().pull_sql(database="mydb", table="user_info", "uid", "uid")
    
    # Stocke le résultat du rapport dans un fichier Excel !!
    babe.push (filename="reports.xlxs");
    
Le projet a l'air très intéressant, mais en rédigeant cette article,
je n'ai trouvé aucune documentation.

Plus d'informations : https://github.com/fdouetteau/PyBabe


Cornice : Vos webservices simplifiés
====================================

Générez vos API et ayez automatiquement une documentation ainsi que
votre fichier SPORE_. Vous pouvez ensuite brancher votre API sur le
système d'URL de votre choix Werkzeug, Django ou Pyramid.

Pour faire simple ::

    $ pip install cornice
    $ paster create -t cornice project

Ensuite il suffit de modifier le fichier ``views.py`` :

.. code-block:: python

    import json
    from cornice import Service
    
    values = Service(name='foo', path='/values/{value}',
                     description="Cornice Demo")
    
    _VALUES = {}
    
    
    @values.get()
    def get_value(request):
        """Returns the value.
        """
        key = request.matchdict['value']
        return _VALUES.get(key)
    
    
    @values.post()
    def set_value(request):
        """Set the value.
    
        Returns *True* or *False*.
        """
        key = request.matchdict['value']
        try:
            _VALUES.set(key, json.loads(request.body))
        except ValueError:
            return False
        return True

Pour plus d'informations : http://packages.python.org/cornice


Tornado : Et le web asynchrone devient possible
===============================================

Si vous devez faire du long polling ou demander des informations à des
API distances telles que Facebook, Twitter, ... vous devez jeter un
œil à Tornado.

Tornado vous permet de mettre en place vos applis de web asynchrone
sans remplir vos workers WSGI et sans faire exploser votre serveur en
le remplissant de requêtes bloquantes. 

Par contre le mode asynchrone n'est pas compatible avec WSGI.

Voici un exemple de requête asynchrone :

.. code-block:: python

    class MainHandler(tornado.web.RequestHandler):
        @tornado.web.asynchronous
        def get(self):
            http = tornado.httpclient.AsyncHTTPClient()
            http.fetch("http://friendfeed-api.com/v2/feed/bret",
                       callback=self.on_response)
    
        def on_response(self, response):
            if response.error: raise tornado.web.HTTPError(500)
            json = tornado.escape.json_decode(response.body)
            self.write("Fetched " + str(len(json["entries"])) + " entries "
                       "from the FriendFeed API")
            self.finish()

Tant que self.finish() n'est pas appelé la connexion HTTP ne se
termine pas, on peut donc utiliser un système de callback assez
sympathique.

Plus d'informations ici : http://www.tornadoweb.org/documentation/


WeasyPrint ou comment générer des PDF sans souffrir
===================================================

WeasyPrint, une lib à suivre si vous devez générer des PDF en Python

Par exemple :

.. code-block:: python

    import weasyprint
    weasyprint.HTML('http://weasyprint.org/').write_pdf('/tmp/weasyprint-website.pdf')

Plus d'informations ici : http://weasyprint.org/


Architecture CQRS et les performances avec Django
=================================================

CQRS veut dire : Command Query Responsibility Segregation.

C'est une méthodologie de dénormalisation dans le cas ou vous ne
pouvez pas mettre vos requêtes lentes en cache. 

En résumé, utiliser l'ORM pour faire les requêtes d'écritures dans la
base (Commands), et ajouter des signaux pour mettre à jour la
représentation de ces données dans Redis, CouchDB, MongoDB, une vue
postgresql... 

Du côté de vos vues, en lecture (Query), il vous suffira d'afficher la
représentation des données, au lieu de la recalculer à chaque fois à
partir des données brutes. Et lorsqu'une modification est faite, la
représentation est mise à jour avec une tâche celery asynchrone.


Comment porter ses applis sous Python3 avec six
===============================================

Une conférence très intéressante sur comment porter ses applications
vers Python3 en utilisant Six.

Le problème majeur concerne les chaines de caractères.  

Il est recommandé de programmer ses applications pour Python3 et
ensuite d'ajouter un support Python2 avec six.


La gestion des timezones en Python
==================================

La gestion des timezones est quelque chose d'assez compliqué.

Avec Python puisque cette notion évolue, la définition des timezones
est définie dans le package pytz qui est mis à jour à chaque
modification.

Il est conseillé de traiter tous les temps en UTC et de faire la modification lors de l'affichage.

Attention, une date seule ou une heure seule n'a pas de sens dans un environnement timezone aware.


Metrology, mesurez tout, tout le temps
======================================

Metrology, mesurez tout, tout le temps (graphite, statsd, carbon)

Très intéressant, plus d'info : https://github.com/cyberdelia/metrology#metrology


Marteau, faites vos tests de montée en charge et de performances
================================================================

Marteau est une web interface permettant de gérer un pool de serveur
et de lancer des tests de performances funkload.

Plus d'infos et des screeshots ici :
http://ziade.org/2012/08/22/marteau-distributed-load-tests/

.. _`Django Debug Toolbar`: https://github.com/django-debug-toolbar/django-debug-toolbar
.. _South: https://south.readthedocs.io/en/latest/about.html
.. _Sentry: https://sentry.readthedocs.io/en/latest/index.html
.. _SPORE: https://github.com/SPORE/specifications
.. _Spyre: https://spyre.readthedocs.io/en/latest/index.html
.. _PyBABE: https://github.com/fdouetteau/PyBabe
.. _Tornado: http://www.tornadoweb.org/
.. _Cornice: https://cornice.readthedocs.io/en/latest/index.html


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
