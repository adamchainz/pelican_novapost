####################################################
Transformer un OneToOneField en AutoField avec South
####################################################

:date: 2013-02-25 12:42
:tags: python, django, south, django-fr
:category: Python
:author: Lauréline Guérin
:lang: fr
:slug: transformer-un-onetoone-field-en-autofield-avec-south


`South`_, c'est cool. Mais des fois, il faut mettre les mains dedans, et ça devient vachement moins cool.
Mais bon, à force, ça finit par rentrer.

.. _`South`: http://south.aeracode.org/


Contexte
========

Dans notre projet, on a eu besoin de gérer des permissions sur des instances d'objet valables pour un rôle donné,
un rôle étant affecté à des utilisateurs.

Pour cela, on a utilisé `django-guardian`_, qui gère ces permissions soit pour un utilisateur, soit pour un groupe.

On a donc dû lier nos rôles à des groupes, avec un OneToOneField, pour gérer ces permissions.

Mais en plus, comme on fait du multi-site, et que les groupes django ont une contrainte d'unicité sur name,
on a dû redéfinir un model Group.

Au départ, le model ressemblait à ça:

.. code-block:: python

    from django.db import models
    from django.contrib.auth.models import Permission, Group
    from django.contrib.sites.models import Site


    class MyGroup(models.Model):
        name = models.CharField(max_length=80)
        site = models.ForeignKey(Site, default=Site.objects.get_current, editable=False)
        group = models.OneToOneField(Group, null=True, editable=False)

        class Meta:
            unique_together = ['name', 'site']


    class Role(MyGroup):
        ...


(Je passe les methodes save et delete pour gérer le groupe associé à MyGroup, ce n'est pas ce qui m'intéresse dans ce post)

Pour simplifier, on a eu envie de faire sauter le model MyGroup, pour avoir un model de ce genre:

.. code-block:: python

    from django.db import models
    from django.contrib.auth.models import Permission, Group
    from django.contrib.sites.models import Site


    class Role(models.Model):
        name = models.CharField(max_length=80)
        site = models.ForeignKey(Site, default=Site.objects.get_current, editable=False)
        group = models.OneToOneField(Group, null=True, editable=False)

        ...

        class Meta:
            unique_together = ['name', 'site']


.. _`django-guardian`: http://pythonhosted.org/django-guardian/


Sortons la boîte à outils
=========================

Allez, hop, on dégaine south. Je ne vais pas m'étendre sur les manips successives
(changement de model, schemamigration, datamigration, changement de code, etc)
nécessaires pour tout bien migrer comme il faut, je vais passer directement à THE problem.

Pour transformer le OneToOneField implicite qui remplace la PK du model Role en AutoField,
il a bien fallu que je tente un truc du genre:

.. code-block:: python

    class Migration(SchemaMigration):

        def forwards(self, orm):
            db.rename_column('app_role', 'mygroup_ptr_id', 'id')
            db.alter_column('app_role', 'id', self.gf('django.db.models.fields.AutoField')(primary_key=True))


Si seulement c'était si simple :)

Ca marche parfaitement avec sqlite, mais le ``alter_column`` pète avec postgresql ! (Pas testé avec les autres backends)

On sait parfaitement créer une primary key avec south pour postgresql lorsqu'on crée une table, mais un alter column échoue::

    django.db.utils.DatabaseError?: type "serial" does not exist

Une petite recherche google m'a permis de tomber sur le ticket south n° `407`_,
qui donne une piste pour transformer un IntegerField en AutoField pour postgresql.

Dans le cas de notre migration ça donnerait:

.. code-block:: python

    class Migration(SchemaMigration):

        def forwards(self, orm):
            db.rename_column('app_role', 'mygroup_ptr_id', 'id')
            # Petit cas particulier pour posgtresql
            if db.__module__ == 'south.db.postgresql_psycopg2':
                # Supression de la FK
                db.delete_foreign_key('app_role', 'id')
                # Création d'une séquence
                db.execute("CREATE SEQUENCE app_role_id_seq")
                # Avec set de la dernière valeur
                db.execute("SELECT setval('app_role_id_seq', (SELECT MAX(id) FROM app_role))")
                # Et ajout d'un default sur la nouvelle PK
                db.execute("ALTER TABLE app_role ALTER COLUMN id SET DEFAULT nextval('app_role_id_seq'::regclass)")
            else
                db.alter_column('app_role', 'id', self.gf('django.db.models.fields.AutoField')(primary_key=True))


Oui mais ça suffit pas ...
==========================

Il manque un truc, et on ne s'en rend compte que si on s'amuse à faire des loaddata.

Un loaddata prend des données sérialisées, et crée des objets avec une PK déjà définie:
on n'appelle pas le ``default``, qui fait un ``nextval`` et met à jour la dernière valeur de la séquence.

A la fin d'un loaddata, le code suivant est exécuté:


.. code-block:: python

        # If we found even one object in a fixture, we need to reset the
        # database sequences.
        if loaded_object_count > 0:
            sequence_sql = connection.ops.sequence_reset_sql(self.style, models)
            if sequence_sql:
                if verbosity >= 2:
                    self.stdout.write("Resetting sequences\n")
                for line in sequence_sql:
                    cursor.execute(line)


Ce bout de code appelle la fonction postgresql ``pg_get_serial_sequence``, avec en paramètre le nom de la table
et le nom de la colonne, pour déterminer le nom de la séquence liée à la colonne. Puis avec le nom de la séquence,
on fait un ``setval`` pour mettre à jour la dernière valeur.

Dans notre cas, la fonction ``pg_get_serial_sequence`` retournait ``NULL``. Il manquait juste un bout de code pour lier
la colonne à la séquence:

.. code-block:: python

    db.execute("ALTER SEQUENCE app_role_id_seq OWNED BY app_role.id")

Voici la migration complète:

.. code-block:: python

    class Migration(SchemaMigration):

        def forwards(self, orm):
            db.rename_column('app_role', 'mygroup_ptr_id', 'id')
            # Petit cas particulier pour posgtresql
            if db.__module__ == 'south.db.postgresql_psycopg2':
                # Supression de la FK
                db.delete_foreign_key('app_role', 'id')
                # Création d'une séquence
                db.execute("CREATE SEQUENCE app_role_id_seq")
                # Avec set de la dernière valeur
                db.execute("SELECT setval('app_role_id_seq', (SELECT MAX(id) FROM app_role))")
                # Et ajout d'un default sur la nouvelle PK
                db.execute("ALTER TABLE app_role ALTER COLUMN id SET DEFAULT nextval('app_role_id_seq'::regclass)")
                # Liaison colonne - séquence
                db.execute("ALTER SEQUENCE app_role_id_seq OWNED BY app_role.id")
            else
                db.alter_column('app_role', 'id', self.gf('django.db.models.fields.AutoField')(primary_key=True))

Et voila ! :)


.. _`407`: http://south.aeracode.org/ticket/407
