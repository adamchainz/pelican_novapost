##############################################
Django : Comment booster ses tests en 1 minute
##############################################

:date: 2013-03-20 10:16
:tags: python, django, django-fr, testing
:category: Python
:author: Rémy Hubscher

************
Introduction
************

Hier, Boris, en stage ici pour 6 mois, me parle d'une astuce pour
Django ultra simple, mais qui a tout bonnement divisé par deux notre
temps de tests :O


*************************
Connexion, views et tests
*************************

Lors des tests, on doit souvent se connecter pour tester les droits de
l'utilisateur ou encore accéder à des certaines pages de l'application
Django décorée par un ``user_passes_test`` ou un ``login_required``.

Si vous n'utilisez pas encore les techniques de tests unitaires des
views proposée la semaine dernière par Benoît Bryon, cette solution
simple va déjà vous faire gagner un temps fou.


***************************
À un problème, une solution
***************************

Grâce à `l'article de Igor Sobreira`_, on s'est rendu compte que le
temps passé dans le hachage des mots de passe était significatif sur
la durée totale des tests.

Nous avons donc essayé la solution proposée par l'article (utiliser un
`UnsaltedMD5PasswordHasher` pour les tests) et avons effectivement
constaté une amélioration du temps total des tests.

En regardant le code de `UnsaltedMD5PasswordHasher` on s'est dit qu'on
pouvait gagner encore plus de temps à la fois sur le hachage du mot de
passe et sur la vérification de celui-ci.

En effet, tous les hasher Django utilisent une méthode de comparaison
des mots de passe en temps constant afin d'éviter `les problèmes de
timing attaques`_.

****************
Et en pratique ?
****************

Il suffit de définir un ``PASSWORD_HASHER`` simplifié pour les tests
pour gagner un temps fou lors de l'exécution des tests.

C'est aussi simple que ça.

La première étape consiste à définir un PASSWORD_HASHER minimaliste

.. code-block:: python

    # -*- coding: utf-8 -*-
    from django.contrib.auth.hashers import BasePasswordHasher, mask_hash
    from django.utils.datastructures import SortedDict
    
    
    class PlainPasswordHasher(BasePasswordHasher):
        """
        The plain password hashing algorithm for test (DO NOT USE in production)
        """
        algorithm = "plain"
    
        def salt(self):
            return ''
    
        def encode(self, password, salt):
            return '%s$$%s' % (self.algorithm, password)
    
        def verify(self, password, encoded):
            algorithm, hash = encoded.split('$$', 1)
            assert algorithm == self.algorithm
            return password == hash
    
        def safe_summary(self, encoded):
            return SortedDict([
                ('algorithm', self.algorithm),
                ('hash', mask_hash(encoded, show=3)),
            ])

Ensuite dans le fichier de settings propre aux tests, on modifie la liste des PASSWORD_HASHERS.

**settings_test.py**

.. code-block:: python

    from myapp.settings import *
    PASSWORD_HASHERS = (
        'myapp.hashers.PlainPasswordHasher',   
    ),

Attention à ne pas utiliser cela en production, car tous les mots de
passes seraient stockés en clair dans la base de données.

Je vous invite à tester cette astuce sur votre base de tests pour voir
vous-même la différence de temps et nous faire un retour en
commentaire du post.

Si vous utilisez des fixtures de user, vous pouvez également utiliser
la solution ci-dessous dans votre settings de test afin que les tests
puissent décoder les mots de passe déjà stockés dans la base avec un
autre algorithme de mot de passe.

**settings_test.py**

.. code-block:: python

    from myapp.settings import *
    PASSWORD_HASHERS = ['myapp.hashers.PlainPasswordHasher'] + list(PASSWORD_HASHERS)


**********
Conclusion
**********

Cette astuce commence à être connue dans le monde Django, il y a même
`un ticket de Django qui en parle`_ et elle est maintenant décrite `dans la documentation officielle de Django`_.

Notre hasher personnalisé permet juste de gagner encore un peu plus de
temps. Sur notre base de tests nous avons gagné 10 minutes sur 50
minutes soit 20% de temps de tests en passant du
``UnsaltedMD5PasswordHasher`` à notre ``PlainTextPasswordHasher``

Nous avions initialement divisé par deux notre temps de tests en
passant à ``UnsaltedMD5PasswordHasher``


**********
Références
**********

.. target-notes::

.. _`l'article de Igor Sobreira`: http://igorsobreira.com/2012/09/19/improving-performance-of-django-test-suite.html
.. _`les problèmes de timing attaques`: http://codahale.com/a-lesson-in-timing-attacks/
.. _`un ticket de Django qui en parle`: https://code.djangoproject.com/ticket/18157
.. _`dans la documentation officielle de Django`: https://docs.djangoproject.com/en/1.4/topics/testing/#speeding-up-the-tests
