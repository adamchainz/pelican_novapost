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
données PostgreSQL avec Django.

Le test est réalisé sur des tables contenant 100 000 lignes et la
suppression représente environ 16% des lignes. Les différentes mesures
sont réalisées sur une base strictement identique, un dump est
réalisé avant le test et un restore avant chaque mesure.

On tient compte des 2 typologies de modèles que l'on retrouve
régulièrement dans Django, un modèle simple sans relation qui est
nommé **Company** ici, et un modèle nommé **Book** avec une *ForeignKey* et qui est
également en relation avec un autre modèle au travers d'une relation
*ManyToMany*.

Lors de la génération des données, la colonne **code** (qui se trouve
dans *Book* et *Company*) est initialisée avec une valeur entre 0 et 5
de façon aléatoire de sorte que les lignes ne soient pas succinctes
sur le disque. Le test va consister à supprimer toutes les lignes dont
code=1.

Vérifions tout d'abord la distribution de nos données :

.. code-block:: sql

    perf=> SELECT code,count(*) FROM tuna_company GROUP BY code ORDER BY
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

Première méthode de suppression, la liste des objets à supprimer est
passée à la suppression sous forme de liste, on peut évidemment dire
ici que le code manque de pertinence, mais imaginez que la liste ait
été fournit autrement que par le QuerySet *books*.

.. code-block:: python

    def regular_delete(code, model):
        """Delete books with an evaluated QuerySet
        """
        books = model.objects.filter(code=code)
        count = books.count()

        to_be_deleted_ref_list = [doc.id for doc in books]

        model.objects.filter(pk__in=to_be_deleted_ref_list).delete()


Deuxième méthode de suppression, la liste des objets à supprimer est
passée cette fois sous la forme d'une QuerySet qui n'est pas évaluée,
comme le premier QuerySet *books* a été évaluée par le count on en
initialise une nouvelle identique dans *book_list*

.. code-block:: python

    def list_delete(code, model):
        """Delete books with a non evaluated QuerySet
        """
        books = model.objects.filter(code=code)
        count = books.count()

        book_list = model.objects.filter(code=code)

        model.objects.filter(pk__in=book_list).delete()


Troisième méthode, cette fois on utilise directement la méthode
**delete()** sur notre QuerySet *books*, ce qui semble le plus logique d'un
point de vue développeur Django. A chaque fois on a compté le nombre
d'objets à supprimer (classique d'un information loggée).

.. code-block:: python

    def direct_delete(code, model):
        """Delete books directly
        """
        books = model.objects.filter(code=code)
        count = books.count()

        books.delete()


Quatrième et dernière méthode cette fois nous allons exécuter des `raw
queries <https://docs.djangoproject.com/en/dev/topics/db/sql/#performing-raw-queries>_`

.. code-block:: python

    def raw_delete_company(code, model):
        """Delete companies with raw commands
        """
        books = model.objects.filter(code=code)
        count = books.count()

        cursor = connection.cursor()
        cursor.execute("DELETE FROM tuna_company WHERE code=%s", [code])


On doit faire un pause ici avant de continuer, comme vous avez dû le
remarquer dans les 3 première méthodes, les fonctions de suppressions
sont génériques et utilisables aussi bien sur **Company** que
**Book**, ce qui n'est pas le cas de la méthode utilisant le raw
sql. Avant de regarder comment supprimer les **Book** on va analyser son
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
de supprimer tous les objets et les liens sur ceux-ci.

.. code-block:: python

    cursor.execute("DELETE FROM tuna_editor_books WHERE book_id IN (SELECT id FROM tuna_book WHERE code=%s)", [code])
    cursor.execute("DELETE FROM tuna_synopsis WHERE book_id IN (SELECT id FROM tuna_book WHERE code=%s)", [code])
    cursor.execute("DELETE FROM tuna_book WHERE code=%s", [code])

Maintenant il est temps de se pencher sur les résultats. Tout d'abord
les résultats de suppression pour **Company**

============== =======================
méthode        temps d'éxecution
============== =======================
regular_delete  0.734172105789 seconds
list_delete     0.293972969055 seconds
direct_delete   0.122102022171 seconds
raw_delete      0.12776017189 seconds
============== =======================

Première différence nette entre **regular** et **list** qui s'explique
par la structure de la requette SQL exécutée sur le serveur, dans le
premier cas on passe une liste de plus de 16000 values (nb d'objets à
supprimer)

.. code-block:: sql

    DELETE FROM "tuna_company" WHERE "tuna_company"."id" IN (
      1, 2, 3, 4, .....)

quand dans le deuxième cas on exécute directement une requête avec une
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
list_delete    3.39584183693 seconds
direct_delete  3.54608106613 seconds
raw_delete     1.97530889511 seconds
============== =======================

On obtient toujours une amélioration notable en utilisant les *raw
queries*, ce qui est logique.  Cette fois par contre on ne note plus
de différence entre le QuerySet non évaluée (*direct_delete*) et la
liste d'id (*list_delete*) passée dans le filtre, pour la raison
simple que bien que l'on ait pas évalué le QuerySet l'ORM l'évalue tout de
même, car pour supprimer les objets liés il va utiliser les pk de
*Book* pour supprimer les Synopsis et les liens avec *Editor*

On va exécuter pour la démonstration de code suivant ; dans les deux
cas **qs** n'est pas évalué, pourtant le résultat SQL ne sera pas identique.

Sur **Company** le QuerySet n'étant pas évalué et n'ayant besoin pas de l'être on
a bien une sous requête d'employées

.. code-block:: python

    BEGIN
    DELETE FROM "tuna_company" WHERE "tuna_company"."id" IN (SELECT
    U0."id" FROM "tuna_company" U0 WHERE U0."code" = 2 )
    COMMIT

Par contre sur **Book** on a un premier *SELECT* sur la table **Book**
qui peut être très coûteux, rappel un `SELECT *` sur une table
contenant un grand nombre de colonne est toujours coûteux en IO si
votre base ne tient pas en RAM.

.. code-block:: sql
    qs = Book.objects.filter(code=2)
    Book.objects.filter(pk__in=qs).delete()

    SELECT
    "tuna_book"."id", "tuna_book"."name", "tuna_book"."title",
    "tuna_book"."code", "tuna_book"."author_id", "tuna_book"."deci",
    "tuna_book"."centi", "tuna_book"."milli" FROM "tuna_book" WHERE
    "tuna_book"."id" IN (SELECT U0."id" FROM "tuna_book" U0 WHERE
    U0."code" = 2 )
    BEGIN
    DELETE FROM "tuna_editor_books" WHERE
    "tuna_editor_books"."book_id" IN (7744, 7747, 7750)
    DELETE FROM "tuna_sinopsis" WHERE "tuna_sinopsis"."book_id" IN
    (7744, 7747, 7750)
    DELETE FROM "tuna_book" WHERE "id" IN (7750, 7747, 7744)
    COMMIT


Un méthode d'optimisation d'ici serait d'utiliser **only()** dans le delete
afin de limiter la largeur de la première requête, pour être moins pénalisant.

.. code-block:: sql

    qs = Book.objects.filter(code=2)
    Book.objects.filter(pk__in=qs).only('pk').delete()

Toutes les méthodes se valent sur des petites volumétrie où le gain ne
sera pas significatif, mais sur les grands volumes il est toujours
intéressant de penser global et de remettre en cause ses habitudes.
