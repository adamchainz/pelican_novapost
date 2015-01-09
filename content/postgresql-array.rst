##########################
Stockage Array avec Django
##########################

:date: 2014-12-23 11:00
:tags: django, postgresql, array, djorm-array
:category: Astuces
:author: Rodolphe Quiédeville
:lang: fr
:slug: postgresql-array


Actuellement dans un de nos projets nous stockons un ensemble d'id
provenant d'une table dans une autre base de données, ces valeurs étant
coûteuses à calculer et variant peu nous les stockons directement
au niveau du tuple dans une colonne de type *text* en séparant chaque valeur
par une virgule. La table étant amenée à dépasser le million de tuples
rapidement nous avons anticipé d'éventuels problèmes de performance en
recherchant une méthode de stockage plus efficace lors de la
lecture. Car si le stockage actuel est satisfaisant lors des écritures
et des manipulations des valeurs dans le code, la recherche sur ces
valeurs laisse à désirer.



Les mesures ont été effectuées sur une table principale de 10K
tuples, avec un nombre median de valeurs associées de 10, ce qui donne
à peu près 100k valeurs à stocker, le ratio de 10 est un peu
supérieur à ce que nous avons réellement mais on prend une marge de
sécurité.

Le temps de référence sera pris sur l'EXPLAIN suivant, à savoir
4.552ms, temps mesuré sur une nouvelle installation de PostgreSQL 9.4
qui sera notre prochaine version de production. On notera au passage
qu'aucun index n'est utilisé du fait de la structure de la recherche,
nous cherchons ici si la valeur *17439* est présente dans la chaine de
caractère *,345,17439,452,4569,*, ce qui génère au final un `Seq Scan`
que l'on cherche à éviter.

.. code-block:: sql

                                 QUERY PLAN
    -----------------------------------------------------------------------------------------------------------
     Seq Scan on public.grid_grid  (cost=0.00..348.09 rows=1 width=4) (actual time=0.021..4.531 rows=8 loops=1)
       Output: id
       Filter: (grid_grid.old ~~ '%,17439,%'::text)
       Rows Removed by Filter: 9992
     Planning time: 0.294 ms
     Execution time: 4.552 ms


Première piste étudiée, stocker les valeurs dans une colonne de type
`ARRAY <http://www.postgresql.org/docs/9.4/static/arrays.html>`_
en utilisant
l'extension `djorm-pgarray <https://github.com/niwibe/djorm-pgarray>`_.
Le stockage en ARRAY semble naturel au vu des données manipulées, mais
malheureusement il n'apporte pas de gain significatif lorsque l'on
effectue une recherche de présence de valeur dans la colonne, ce
qui est d'ailleurs noté dans la documentation. La recherche passant toujours
par un `Seq Scan` sur la table le temps de réponse ne peut chuter.


.. code-block:: sql

                                QUERY PLAN
    -----------------------------------------------------------------------------------------------------------
     Seq Scan on public.grid_grid  (cost=0.00..348.09 rows=5 width=4) (actual time=0.039..4.298 rows=8 loops=1)
       Output: id
       Filter: (grid_grid.tags @> '{17439}'::integer[])
       Rows Removed by Filter: 9992
     Planning time: 0.334 ms
     Execution time: 4.312 ms


Deuxième piste, cette fois on va stocker les valeurs dans
une table de jointure et revenir aux *bases* du modèle
relationnel, le fait de générer une table d'une taille équivalent à 10 fois le nombre de tuple
de la table initiale qui contient déjà plusieurs millions de lignes est
peut-être la raison du non choix de cette solution à l'origine, sans
que l'on puisse toutefois l'assurer par manque d'archive. Cette fois
pouvoir utiliser un index nous permet de **diviser par 40** le temps
de réponse, ce qui tend à nous satisfaire.


.. code-block:: sql

                                QUERY PLAN
    --------------------------------------------------------------------------------------------------------------------------------------
     Bitmap Heap Scan on public.grid_gridforeign  (cost=4.33..22.99 rows=5 width=4) (actual time=0.035..0.072 rows=8 loops=1)
       Output: grid_id
       Recheck Cond: (grid_gridforeign.tag = 17439)
       Heap Blocks: exact=8
       ->  Bitmap Index Scan on grid_gridforeign_tag_grid_id_idx (cost=0.00..4.33 rows=5 width=0) (actual time=0.018..0.018 rows=8 loops=1)
             Index Cond: (grid_gridforeign.tag = 17439)
     Planning time: 0.221 ms
     Execution time: 0.091 ms


Est-ce le moment de rappeler que c'est dans les vieux pots que l'on
fait les meilleurs soupes ? Je ne sais pas ... ? Mais tester, mesurer et
comparer reste la méthode qui vous garantit d'éviter les mauvaises
surprises.
