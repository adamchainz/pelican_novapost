################################
Pytong 2013 à Toulon : le résumé
################################

:date: 2013-06-24 10:10
:tags: pytong, python, django-fr
:category: Conférences
:author: Rémy Hubscher

************
Introduction
************

Et voilà, `Pytong 2013`_ est déjà terminé, il est temps de faire un retour de
tout ce que nous avons appris durant ce week-end ensoleillé.

.. _`Pytong 2013`: http://www.pytong.org


*************
Récapitulatif
*************

Voici ce que j'ai retenu de ce week-end

Salt
++++

`Salt`_ est un outil pour faire du provisionning ça pouttre et pour
cause c'est en Python et basé sur ØMQ, le vocabulaire est un peu
tiré par les cheveux cependant mais l'essayer c'est l'adopter.


ØMQ
+++

`ØMQ`_ permet de faire de la communication inter-processus en IPC ou
over TCP. C'est vraiment génial et ça s'intègre parfaitement avec
Tornado_ pour exposer une api HTTP. Voici `les trucs et astuces`_ pour marrier
les deux.


WebTest
+++++++

`WebTest`_ permet de faire des tests fonctionnels d'applications
WSGI. Mais saviez-vous qu'il permet de carrément tester la prod ?
C'est génial !


Déprime ? Burnout ?
+++++++++++++++++++

Si vous êtes déprimés, prenez des vacances, allez à des conférences
mais si ça ne suffit pas voici trois autres solutions :


S'ennuyer
---------

Il faut également trouver 15 minutes par jour à ne rien faire d'autre
que de s'ennuyer, c'est à dire laisser vagabonder son esprit, ça
permet de réamorcer la créativité.


La règle des trois tâches
-------------------------

Au début de la journée tu choisis 4 tâches.

Quand tu en as fait trois la journée est "réussie".

Si tu fais les 4 la journée est "finie" tu arrêtes de travailler pour faire autre chose.


Le Shageek
----------

C'est comme le Shabat mais c'est pour les geeks :

Chaque samedi tu ne touches pas à un ordinateur/smartphone/tablette et
tu passes du temps avec tes amis/ta famille.


Migrations de BDD sans interruption de services
+++++++++++++++++++++++++++++++++++++++++++++++

C'est possible avec South en 3 étapes :

* Commencer par faire une migration qui permet de faire tourner les deux versions du code en parallèle
* Faire la migration des données
* Prendre son temps pour bien mettre à jour les machines avec le nouveau code
* Faire les migrations de nettoyage (suppression des champs/tables inutiles avec le nouveau code)

Il faut bien veiller à ce que la migration de données ne bloque pas la table trop longtemps.
À noter aussi la création d'index concurrents avec PostgreSQL : **CREATE INDEX CONCURRENTLY**


Reporting web et print en Python
++++++++++++++++++++++++++++++++

* `Pygal`_ pour les graphs HTML5/SVG interractifs
* `Weasyprint`_ pour générer un PDF de qualité à partir de la même page.


Daybed
++++++

Si vous n'avez pas entendu parler de Daybed c'est que vous ne venez
pas assez à des events Python francophones.

Daybed_ est un service de validation et stockage de models dynamiques
basé sur Cornice_, Collander_ et CouchDB_.

Avec Daybed vous pouvez donc avec une appli web entièrement Javascript
et faire le stockage de vos models directement avec Daybed. C'est une
API REST très simple.

Nous faisons un `sprint Daybed`_ à Rennes les 12/13/14 juillet 2013
pour implémenter ce qu'il manque à Daybed. L'authentification et les
ACL, les JSON Schema et une interface Javascript pour pouvoir utiliser
Daybed comme Google Forms.


Le web components
+++++++++++++++++

Les web components ou comment créer des functions ou des app avec HTML.

On définit un nouveau tag avec ses paramètres ainsi que le CSS et de
base et le javascript nécessaire à le rendre.

Google a déjà mis en place une bibliothèque permettant de l'émuler
avant que ce soit un standard dans les navigateurs. Il va falloir
surveiller cela de prêt mais on peut déjà jour avec avec `Polymer`_.


Brython
+++++++

On a eu une présentation codée en Brython. Brython permet de faire du
Python dans le navigateur.

Cependant c'est carrément indébuggable car ça gènère du Javascript et
donc les erreurs ne sont pas au bon endroit. En plus ce n'est pas
vraiment du Python.

Comme n1k0 nous l'a fait remarqué Python n'est pas un language prévu
pour l'asynchrone alors que Javascript oui.

Javascript a beaucoup évolué ces derniers temps et le développement
frontend c'est l'avenir alors `mettez-vous au Javascript
sérieusement`_ !


D'autres informations en vrac
+++++++++++++++++++++++++++++

* Besoin d'un CMS Django ? essayez `Mezzanine`_ !
* Achetez le livre de Yohan Gabory - `Django Avancé`_ aux éditions Eyrolles.
* Si vous ne voulez pas utiliser `Buildout`_, vous pouvez toujours mettre
  en place un pypi privé pour déployer vos forks d'applications python
  avec pip c'est pas si compliqué.


.. _`Salt`: https://salt.readthedocs.org/en/latest/
.. _WebTest: http://webtest.pythonpaste.org/en/latest/
.. _South: http://south.readthedocs.org/en/latest/
.. _Pygal: http://pygal.org/
.. _Weasyprint: http://weasyprint.org/
.. _Mezzanine: http://mezzanine.jupo.org/
.. _`Django Avancé`: http://www.eyrolles.com/Informatique/Livre/django-avance-9782212134155
.. _Brython: http://www.brython.info/
.. _Buildout: http://www.buildout.org/en/latest/
.. _Daybed: http://daybed.readthedocs.org/en/latest/
.. _Polymer: http://www.polymer-project.org/
.. _`ØMQ`: http://www.zeromq.org/
.. _Tornado: http://www.tornadoweb.org/
.. _`les trucs et astuces`: https://speakerdeck.com/lothiraldan/use-omq-and-tornado-for-fun-and-profits
.. _Cornice: http://cornice.readthedocs.org/en/latest/
.. _Collander: http://docs.pylonsproject.org/projects/colander/en/latest/
.. _CouchDB: http://couchdb.apache.org/
.. _`sprint Daybed`: http://wiki.python.org/moin/AfpyCamp2013
.. _`mettez-vous au Javascript sérieusement`: http://ejohn.org/apps/learn/

**********
Conclusion
**********

J'avoue que traverser la France en diagonale pour aller assister à une
journée de conférence et une journée de plage ne m'enchantait pas plus
que ça. Mais finalement ça vallait le coup et je suis bien content de
l'avoir fait.
