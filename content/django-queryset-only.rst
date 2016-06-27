######################################
Aller à l'essentiel avec only et defer
######################################

:date: 2014-10-06 11:00
:tags: django, sql, defer, only
:category: Astuces
:author: Rodolphe Quiédeville
:lang: fr
:slug: django-queryset-only-defer

Après avoir étudié l'intérêt de la pagination par clé dans un récent
article nous allons nous pencher cette fois sur les queryset et en
particulier sur la méthode `only()
<https://docs.djangoproject.com/en/dev/ref/models/querysets/#only>`_

Le bench est réalisé sur une table de 10 000 lignes, ce qui est peu
mais déjà suffisant pour mettre en avant l'intérêt de **only()**. Le
modèle utilisé **BigBook** possède des caractéristiques assez
classiques que l'on retrouve dans de nombreuses applications Django,
regroupant des informations stockées dans des colonnes de petite taille
(Integer, CharField(30)), mais aussi des types TextField plus gourmands
en volume.

.. code-block:: python

    class BigBook(models.Model):
        """The big books
        """
        keyid = models.IntegerField(unique=True)
        author = models.ForeignKey(Author)
        title = models.CharField(max_length=30)
        serie = models.IntegerField(default=0)
        nbpages = models.IntegerField(default=0)
        editors = models.ManyToManyField(Editor, blank=True)
        translators = models.ManyToManyField(Translator, blank=True)
        synopsis = models.TextField(blank=True)
        intro = models.TextField(blank=True)


Le premier test consiste en une lecture classique de la table avec
uniquement la méthode **filter()**, ici **serie=3** va renvoyer 10%
des objets ce qui suffit à notre démonstration. Une fois les
informations lues depuis la base on effectue un traitement dans la
méthode **action()** du modèle.

.. code-block:: python

    books = BigBook.objects.filter(serie=3).order_by('keyid')
    for book in books:
        keyid = book.keyid
        # do want you want here
        if book.nbpages > 500:
            book.action()


Si on analyse cette requête avec la commande debugsqlshell de la
`debugtoolbar <https://django-debug-toolbar.readthedocs.io/>`_ de
Django on obtient :


    >>> BigBook.objects.filter(serie=3).order_by('keyid')
    SELECT "july_bigbook"."id",
           "july_bigbook"."keyid",
           "july_bigbook"."author_id",
           "july_bigbook"."title",
           "july_bigbook"."serie",
           "july_bigbook"."nbpages",
           "july_bigbook"."synopsis",
           "july_bigbook"."intro"
    FROM "july_bigbook"
    WHERE "july_bigbook"."serie" = 3
    ORDER BY "july_bigbook"."keyid" LIMIT 21 [127.64ms]

Il faut ici **127.64 ms** pour lire les données depuis la base.


Dans le deuxième test, même prédicat de filtre sur **serie**  mais cette
fois nous utilisons la méthode **only()** pour se limiter aux
propriétés **keyid** et **nbpages** du modèle.

.. code-block:: python

    books = BigBook.objects.only('keyid','nbpages').filter(serie=3).order_by('keyid')
    for book in books:
        keyid = book['keyid']
        # do want you want here
        if book['nbpages'] > 500:
            book.action()

Le résultat toujours avec debugsqlshell :

    >>> BigBook.objects.only('keyid','nbpages').filter(serie=3).order_by('keyid')
    SELECT "july_bigbook"."id",
           "july_bigbook"."keyid",
           "july_bigbook"."nbpages"
    FROM "july_bigbook"
    WHERE "july_bigbook"."serie" = 3
    ORDER BY "july_bigbook"."keyid" LIMIT 21 [1.53ms]

Première chose sur le résultat, bien que l'on ait indiqué uniquement
les propriétés **keyid** et **nbpages** la requête contient également
la colonne **id** de la table car celle-ci est la clé primaire que
Django ajoute par défaut.

Enfin et c'est le plus important de temps de réponse de **1.53ms**
est bien inférieur au 127.64 du premier test. Cette différence tient
essentiellement au fait que l'on a pas lu les colonnes **intro** et
**synopsis**.

Une mise en garde sur l'utilisation de cette méthode, bien que très
efficace il faut en effet s'assurer que dans le traitement qui est
fait a posteriori (ici dans **action()**) vous n'ayez pas besoin des
autres propriétés, car bien que celles-ci restent disponibles Django
effectuera une requête SQL supplémentaire pour aller chercher les
informations qu'il n'a pas lu la première fois, et dans ce cas vous
pourriez à contratio dégrader vos performances.

Enfin dernier point, la méthode **defer()** est le pendant de
**only()** dans le sens où elle permet d'exclure des colonnes du
queryset, le fonctionnement est le même mais reste plus pratique à
utiliser si vous voulez exclure un petit nombre de colonne.
