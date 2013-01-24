########################################
Djangocong Tolosa - C'est déjà terminé !
########################################

:date: 2012-11-25 13:59
:tags: ionyweb, python, django
:category: Python
:author: Rémy Hubscher
:lang: fr
:slug: djangocon-toulouse-2012-review


Mise en bouche
==============

C'est une fin de mois de novembre sur les chapeaux de roues, la
semaine dernière j'étais à Rennes pour `Djangocong-Breizh`_ et ce
week-end Django s'était invité au Capitole du Libre pour une série de
conférences et d'ateliers.

Au programme des lightning talks, des conférences, des ateliers, du
partage, des rencontres, des rires des projets et quelques bières.

.. _`Djangocong-Breizh`: http://rencontres.django-fr.org/2012/breizh

`Nous voilà donc partis pour Toulouse
<http://natim.ionyse.com/djangocon-toulouse-2012-review.html>`_.


Novapost en force
=================

`Novapost`_ était largement représenté puisque les 2/3 de notre équipe
Python R&D se trouvait sur place : Lauréline, Benoit, Mathieu et moi.

C'était la première fois que je voyais Lauréline depuis mon arrivée
chez `Novapost`_ et c'était très sympa de se retrouver tous les 4 IRL.

En plus d'être sponsor `Novapost`_ était sur tous les fronts :

 - 4 lightning talks sur 9.
 - 1 conférence sur 8.
 - 1 atelier sur 4.

Lauréline faisait partie du staff, et Benoît et moi avons géré le
timing des différentes conférences.

C'était donc un moment très agréable et intense.

Je tenais à remercier chaleureusement Mathieu Leplatre. D'une part
pour nous avoir hébergé Mathieu et moi, d'autre part pour avoir
organisé et porté la `Djangocong Tolosa 2012`_.  Sans lui, cet
événement n'aurait pas eu lieu.

Il y a eu environ 70 personnes sur les deux jours et nous nous
accordons tous à dire que c'était une belle réussite.

.. _`Novapost`: http://tech.novapost.fr/
.. _`Djangocong Tolosa 2012`: http://rencontres.django-fr.org/2012/tolosa/


Djangocon Tolosa au sein de Capitole du Libre
=============================================

Au passage dans le vrai sud, le "g" de Djangocong est tombé.

Je ne sais pas si c'était intentionnel, mais cela a été remarqué et
que quelques "conservateurs" se sont empressés de le rajouter.


Une rencontre des communautés
+++++++++++++++++++++++++++++

La vraie nouveauté de Djangocong Tolosa est d'être intégrée au grand
événement du Capitole du Libre. L'organisation était à la hauteur de
ce grand événement Toulousain orchestré d'une main de maître par
Thomas Petazzoni.

J'ai trouvé que c'était une très bonne idée qui correspondait bien à
ma vision du libre : des communautés avec des objectifs similaires,
mais des moyens différents, se retrouvent en un même lieu pour faire
avancer les choses, partager et réfléchir.

Cela nous a également permis de participer à la conférence de Jérémie
Zimmermann (qui après avoir réceptionné son trophée de cassoulet) nous
a raconté l'épopée ACTA. Après 4 ans de combat et avec le soutien
international des internautes, `La Quadrature du Net`_ a permis une
victoire historique contre le traité ACTA.

.. _`La Quadrature du Net`: http://lqdn.fr/


Djangocong Tolosa
=================

Le vrai défi après avoir fait l'intégralité des conférences django
francophones est de continuer à apprendre des choses.

De plus, dans une assistance composée de plus de la moitié de
débutants, il faut également réussir à intégrer les nouveaux et ne pas
se contenter de points de détails pour les experts.

C'est sur cette réflexion (suite à la conférence de David Larlet) que
ce sont clôturées les conférences.

Plusieurs choses durant ce congrès :

Des outils
++++++++++

Lors de cette conférence j'ai encore découvert quelques outils
vraiment sympa :

 - ``LiveServerTestCase`` présenté par Julien Phalip un core dev Django
   qui m'a permis de découvrir ce nouveau moyen de tester son application
   Django avec Selenium/Requests sur un véritable serveur Http.
 - La présentation de Mathieu : ``Django pour les fainéants`` avec son
   lot d'outils vraiment utiles ``flake8``, ``gorun``, ``xfvb``...


De bonnes idées
+++++++++++++++

Timothée Peignier nous a présenté une bonne idée pour séparer
correctement les différentes parties de son service en proposant avant
tout une API et en consommant ensuite cette API, je vous recommande
vivement sa conf là dessus.


Le retour d'expérience
++++++++++++++++++++++

Le retour d'expérience de Météo France sur Django, par Fabien Marty
était tout simplement un pur bonheur.

"Django nous a permis de passer pour des développeurs de génie en
gagnant plusieurs semaines sur le planning de développement."


La question
+++++++++++

La question de cette DjangoCong, c'est l'asynchrone avec Django,
quelles sont les solutions et la bonne solution ?

On a encore le temps d'y réfléchir un peu et quelque chose devrait
être proposé dans Django 1.6.

On entends également de plus en plus parler de Tornado.


Les projets
+++++++++++

À cette Djangocong, on a également découvert des beaux projets :


**MySmeuh**

Pour faire simple MySmeuh c'est l'outil libre qu'il manquait pour les
associations, les groupes de musiques, ...

C'est un réseau social qui permet de partager entre ses membres.

Je pense que si vous avez une association, ça peut vous intéresser. On
peut tester le service en s'inscrivant sur `le site de l'association
<https://my.smeuh.org/>`_.


**Ionyweb**

Vous n'en avez sûrement jamais entendu parlé car ce projet a choisi
Djangocong Tolosa pour faire son coming out.

Ionyweb est un CMS en Django qui a été développé en closed source
durant ces 3 dernières années par Ionyse.

Cependant, avec la fin de l'aventure Ionyse, ses fondateurs, dont je
fais partie, ont décidé de le rendre opensource et de mettre en place
les moyens nécessaires pour que les personnes ayant besoin d'un CMS en
Django puissent l'utiliser pour leur projet.

J'ai passé ces deux derniers jours à écrire la documentation technique
et à peaufiner l'installation par défaut mais les efforts en valaient
la peine.

Après `un petit Lighning Talk </static/images/slides/ionyweb-tolosa.html>`_
reprenant la genèse du projet et expliquant ses objectifs, j'ai
organisé ce dimanche matin un atelier pour le présenter.

L'effet était garanti, un thème par défaut basé sur le NotMyIdea de
Pelican permet de commencer tout en douceur.

Le CMS est facile à améliorer, pluggable et je vous assure d'être
disponible pour traiter vos Pull Requests rapidement.

On m'a reproché quelques petites choses :

 - le nom apparemment un peu difficile à prononcer, 
 - le fait que le gestionnaire de fichier ne sache pas interdire la
   suppression d'une image si elle est utilisée dans le site,
 - le fait que les liens vers les pages ne se modifient pas
   automatiquement lors de la modification du slug de la page.

Ce sont des features intéressantes mais qui n'empêchent cependant pas de
bien utiliser le CMS.

On m'a recommandé de faire un screencast, ce que je vais m'empresser
de faire.

De mon côté, je suis extrêmement content d'avoir pu présenter Ionyweb
et je pense qu'il apporte un bon lot d'innovations intéressantes :

 - La modification des pages basée sur une API.
 - Une interface javascript qui s'ajoute au site.
 - Des commandes guidant le développeur ``ionyweb-quickstart`` et ``ionyweb-manage``
 - Une gestion poussée du référencement
 - Une gestion des noms de domaines
 - Une gestion des utilisateurs
 - La simplicité d'ajouter des plugins et des apps sans modifier le cœur du CMS.

Il reste encore de la documentation à écrire mais ce qui est écrit
permet déjà de bien mettre le pied à l'étrier et de lancer son premier
ionyweb en 3 commandes : ::

    $ pip install ionyweb
    $ make syncdb
    $ make runserver

Si vous avez besoin d'un CMS en Django, franchement, ce serait dommage
de ne pas l'essayer : http://www.ionyweb.com/.


Conclusion
==========

Et bien, ça valait le coup de venir "au bout du monde" pour faire ces
rencontres et participer à ce bon moment de partage.

L'année prochaine, j'espère qu'il y aura du cassoulet en quantité.
