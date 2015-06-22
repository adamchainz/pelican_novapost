#####################################################
Utiliser l'application_name de PostgreSQL avec Django
#####################################################

:date: 2015-06-23 11:00
:tags: django, postgresql, settings, application_name, logging
:category: Astuces
:author: Rodolphe Quiédeville
:lang: fr
:slug: postgresql-application_name-django-settings


L'utilisation d'un ORM efficace comme celui de Django abstrait la base
de donnée au point de rendre parfois le debug peut aisé voir
difficile. Il n'est pas souvent évident de remonter à la vue qui a
générée une requête SQL consommatrice de ressource qui aurait été
détectée dans les logs d'un serveur de production. Nous avons déjà
pour cela mis en oeuvre chez PeopleDoc une app Django nommée
`django-sql-log <https://pypi.python.org/pypi/django-sql-log/>`_, dans la suite logique de cette démarche nous allons
voir dans ce billet comment enrichir la chaîne de connection pour
ajouter de l'information dans les log du serveur PostgreSQL.

La `libpq <http://www.postgresql.org/docs/9.4/static/libpq-connect.html#LIBPQ-CONNSTRING>`_ de PostgreSQL inclut un paramètre optionnel nommé
**application_name** constitué d'une chaine de caractère laissée à la
disposition des développeurs d'application. Il faut entendre ici le
mot application dans son sens générique et non pas dans un contexte
Django. Cette information, si présente, est consultable dans les logs
(au moyen du format %a du paramère de `log_line_prefix <http://www.postgresql.org/docs/9.4/static/runtime-config-logging.html#GUC-LOG-LINE-PREFIX>`_), mais également
dans des vues systèmes comme `pg_stat_activity <http://www.postgresql.org/docs/9.4/static/monitoring-stats.html#PG-STAT-ACTIVITY-VIEW>`_ ou encore dans la vue
`pg_stat_statements <http://www.postgresql.org/docs/9.4/static/pgstatstatements.html>`_ de l'extension éponyme.

L'utilisation de cette option depuis Django se fait au moyen de
l'entrée `OPTIONS` du dict `DATABASES` dans les settings comme suit. 


.. code-block:: python

    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.postgresql_psycopg2',
            'HOST': 'localhost',
            'PORT': 5432,
            'NAME': 'foo',
            'USER': 'rodo',
            'PASSWORD': 'neverusetoto',
            'OPTIONS': {'application_name': 'foo'}
        }
    },

Le dict `OPTIONS` est passé tel quel à la libraire `psycopg2`, mais
n'inclut pas malheureusement toutes les options possibles de la libpq.

Utilisé de cette manière tout le code utilisant ces settings signera
ces actions dans les logs avec le nom `foo`.

L'intérêt devient plus évident si vous utilisez un **application_name**
différent pour certaines tâches spécifiques au sein de votre code comme
dans une commandes de management, vous pouvez en effet surcharger
directement les settings dans une commande comme suit :

.. code-block:: python

    #!/usr/bin/env python

    from django.conf import settings
    from django.core.management.base import BaseCommand

    class Command(BaseCommand):
        help = 'A real big command'

        def handle(self, *args, **options):
            # toujours le faire au plus tôt avant d'utiliser une QuerySet
            settings.DATABASES['default']['OPTIONS'] = {'application_name': 'expire_all'}
            dothejob()

Ainsi si vous paramétrez vos logs postgreSQL avec un `log_line_prefix`
de ce type :

.. code-block:: text

    djangofoo=# select current_setting('log_line_prefix');
    -[ RECORD 1 ]---+----------------------------------------------
    current_setting | %t [%p]: [%l-1] user=%u,db=%d,host=%h,app=%a

vous obtiendrez dans les logs les lignes suivantes ; où il devient
de suite plus aisé de retrouver l'origine d'un **COUNT** désastreux.

.. code-block:: text
                
    2015-06-22 20:18:14 CEST [4761]: [14-1]
    user=rodo,db=djangofoo,host=::1,app=expire_all LOG:  duration: 7.471 ms
    statement: SELECT COUNT(*) FROM "hotel_hotel WHERE town_id=23"
    2015-06-22 20:18:21 CEST [4601]: [7-1] user=rodo,db=djangofoo,host=::1,app=[unknown] LOG:  duration: 377.968 ms
    statement: SELECT COUNT(*) FROM "hotel_hotel"
    2015-06-22 20:19:03 CEST [4809]: [1-1] user=rodo,db=djangofoo,host=[local],app=psql LOG:  duration: 9.583 ms
    statement: SELECT COUNT(*) FROM hotel_hotel WHERE closed=true;

Dans ce cas ici, la première commande a été éxécutée dans la commande
manage que l'on a nommée `expire_all`, la deuxième dans un `shell`
Django (oui il serait judicieux que cela soit plus explicite) et enfin
la dernière directement avec le client **psql**. Sans cette
information les 3 commandes ayant été exécutée depuis la même machine
avec le même user il aurait été impossible de retrouver nos petits.

Il ne faut pas que cette solution vous dévie toutefois de la meilleure
séparation possible en créant des utilisateurs spécifiques suivants
les contextes, qui permet non seulement d'identifier la source mais
aussi de borner le périmètre d'action afin de se protéger d'éventuels
erreurs applicatives.
