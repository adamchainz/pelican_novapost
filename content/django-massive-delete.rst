################################################
Supprimer un grand nombre d'objets dans une base
################################################

:date: 2014-11-14 17:00
:tags: django, sql, raw, delete, massive
:category: Astuces
:author: Rodolphe Quiédeville
:lang: fr
:slug: django-massive-delete

Dans ce billet nous allons nous intéresser aux différentes méthodes
utilisables pour supprimer un grand nombre d'objets dans une base de
données PostgreSQL.

Le test est réalisé sur des tables contenant 100 000 lignes et la
suppression représente environ 16% des lignes. Les différentes mesures
sont réalisées sur une base strictement identique, un dump est
réalisé avant le test et un restore avant chaque mesure.

On tient compte des 2 typologies de modèle que l'on retrouve
régulièrement dans Django, un modèle simple sans relation qui est
nommé **Company** ici, et un modèle avec une foreignkey et qui est
également en relation avec un autre modèle au travers d'une relation
*ManyToMany*, nommé cette fois **Book**

Lors de la génération des données **code** (que l'on va retrouver dans
*Book* et *Company*) est initialisé avec une valeur entre 0 et 5 de
façon aléatoir de sorte que les lignes ne soient pas succinctes sur le
disque. Le test va supprimer toutes les lignes dont code=1 soit 16592
lignes exactement.

.. code-block:: sql

    perf=> select code,count(*) from tuna_company group by code order by
    code;
     code | count
    ------+-------
        0 | 16802
        1 | 16592
        2 | 16638
        3 | 16623
        4 | 16647
        5 | 16698
    (6 rows)


Intéressons-nous en premier à **Company**, dont le modèle n'a rien de
particulier, la colonne **code** est indexée car c'est elle qui sera
la clé de sélection pour la suppression.

.. code-block:: python

    class Company(models.Model):
        """A Company with

        No relation to any other model
        """
        name = models.CharField(max_length=300)
        code = models.IntegerField(db_index=True)
        epsilon = models.CharField(max_length=33)

Permière méthode de suppression, la liste des objets à supprimer est
passée à la suppression par une QuerySet évaluée.

.. code-block:: python

    def regular_delete(code, model):
        """Delete books with an evaluated QuerySet
        """
        start = time.time()

        books = model.objects.filter(code=code)
        count = books.count()

        to_be_deleted_ref_list = [doc.id for doc in books]

        model.objects.filter(pk__in=to_be_deleted_ref_list).delete()

        delta = time.time() - start
        return (count, delta)


Deuxième méthode de suppression, la liste des objets à supprimer est
passée à la suppression par une QuerySet qui cette fois n'est pas
évaluée, comme la première QS *books* a été évaluée par le count on en
initialise une nouvelle identique dans *book_list*

.. code-block:: python

    def list_delete(code, model):
        """Delete books with a non evaluated QuerySet
        """
        start = time.time()

        books = model.objects.filter(code=code)
        count = books.count()

        book_list = model.objects.filter(code=code)

        model.objects.filter(pk__in=book_list).delete()

        delta = time.time() - start

        return (count, delta)

Troisième méthode, cette fois on utilise directement la méthode
**delete()** sur notre QuerySet, ce qui semble le plus logique du
point de vue du développeur.

.. code-block:: python

    def direct_delete(code, model):
        """Delete books directly
        """
        start = time.time()

        books = model.objects.filter(code=code)
        count = books.count()

        books.delete()

        delta = time.time() - start
        return (count, delta)


Quatrième et dernière méthode cette fois nous allons exécuter des `raw
queries <https://docs.djangoproject.com/en/dev/topics/db/sql/#performing-raw-queries>_`

.. code-block:: python

    def raw_delete_company(code, model):
        """Delete companies with raw commands
        """
        start = time.time()

        books = model.objects.filter(code=code)
        count = books.count()

        cursor = connection.cursor()
        cursor.execute("DELETE FROM tuna_company WHERE code=%s", [code])

        delta = time.time() - start

        return (count, delta)

On doit faire un pause ici avant de continuer, comme vous avez du le
remarquer dans les 3 première méthodes, les fonctions de suppressions
sont génériques et utilisables aussi bien sur **Company** que
**Book**, ce qui n'est pas le cas de la méthode utilisant le raw
sql. Avant de regarder comment supprimer les Book on va analyser son
schéma, le modèle **Book** est lié par une *ForeignKey* à *Synopsis*
et à **Editor** par une *ManyToMany*.

.. code-block:: python

    class Book(models.Model):
        """A book
        """
        name = models.CharField(max_length=300)
        title = models.CharField(max_length=300)
        code = models.IntegerField(default=4, db_index=True)

    class Editor(models.Model):
        """An editor
        """
        name = models.CharField(max_length=300)
        country = models.CharField(max_length=150)
        books = models.ManyToManyField(Book)

    class Synopsis(models.Model):
        """A synposis with a foreign key on book
        """
        text = models.TextField()
        book = models.ForeignKey(Book)

La suppression se fera donc au moyen de 3 commandes SQL ordonnées afin
de supprimer tous les objets et les liens

.. code-block:: python

    cursor.execute("DELETE FROM tuna_editor_books WHERE book_id IN (SELECT id FROM tuna_book WHERE code=%s)", [code])
    cursor.execute("DELETE FROM tuna_sinopsis WHERE book_id IN (SELECT id FROM tuna_book WHERE code=%s)", [code])
    cursor.execute("DELETE FROM tuna_book WHERE code=%s", [code])

Maintenant il est temps de se pencher sur les résultats. Tout d'abord
les résultats de suppression pour **Company**

============== =======================
méthode        temps d'éxecution
============== =======================
regular_delete  0.734172105789 seconds
list_delete     0.293972969055 seconds
del_delete      0.122102022171 seconds
raw_delete      0.12776017189 seconds
============== =======================

Première différence nette entre **regular** et **list** qui s'explique
par la structure de la requette SQL exécutée sur le serveur, dans le
premier cas on passe une liste de plus de 16000 values (nb d'objet à supprimer)

.. code-block:: sql

    DELETE FROM "tuna_company" WHERE "tuna_company"."id" IN (
      1, 2, 3, 4, .....)

quand dans le deuxième cas s'exécute directement une requête avec une
sous requête.

.. code-block:: sql

    DELETE FROM "tuna_company" WHERE "tuna_company"."id" IN (
      SELECT U0."id" FROM "tuna_company" U0
      WHERE U0."code" = 1 )

On note encore un effet de seuil entre la deuxième méthode et les deux
suivantes, avec peu de différence entre **raw** et **del** tout
simplement car ces deux dernières exécutent au final la même requête
SQL.

..  code-block:: sql

    DELETE FROM "tuna_company" WHERE "tuna_company"."code" = 6

En résumé on note une requête **six fois plus rapide** entre la
première méthode et la dernière. Reste à voir maintenant si les
résultats sont les même avec **Book**.

============== =======================
méthode        temps d'éxecution
============== =======================
regular_delete 4.14703702927 seconds
del_delete     3.54608106613 seconds
list_delete    3.39584183693 seconds
raw_delete     1.97530889511 seconds
============== =======================


book : 10000
regular_delete  1688 time 0.447408914566 seconds
raw_delete      1688 time 0.109646081924 seconds
book : 8312
company : 10000

company : 8334




Book : 10000

Book : 8312
Company : 10000
regular_delete  1666 time 0.0755910873413 seconds
raw_delete      1666 time 0.0107550621033 seconds
Company : 8334
