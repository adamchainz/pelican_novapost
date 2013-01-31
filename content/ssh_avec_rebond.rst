#########################
SSH connexion avec rebond
#########################

:date: 2013-01-31 16:19
:tags: ssh, vm, netcat
:category: Astuces
:author: Sébastien Costes


Introduction
============

Lorsqu'on a une infrastructure réseau complexe, il se peut qu'on ai
une architecture composée de plusieurs serveur/VM.

Une bonne pratique est d'avoir une IP externe et de ne pas pouvoir
accéder à ses VM depuis l'Internet. Avec la pénurie d'IPv4 ça devient
même nécessaire.

Il faut donc d'abord se connecter sur la passerelle SSH pour ensuite
pouvoir accéder à ses VM.

On a donc une **connexion ssh avec rebond** ou **connexion ssh avec
passerelle**.


Le problème
===========

On souhaite donc faire ceci : ``vous >> server1 >> server2``

Beaucoup de gens configurent ``ssh`` dans le fichier ``.ssh/config``
comme ceci::

    host server2
       Hostname server2.my.cloud.com
       ProxyCommand ssh server1.my.cloud.com "nc %h %p" 2> /dev/null

Cette solution fonctionne mais laisse des petits process ``nc``
inutile sur la passerelle, ce qui pour un admin système est
inacceptable.


La solution
===========

En fait vous y êtes presque, mais il faut simplement que lorsque la
connexion est coupée, le process ``nc`` s'arrête::

    host server2
       Hostname server2.my.cloud.com
       ProxyCommand ssh server1.my.cloud.com "nc -q0 %h %p" 2> /dev/null

L'option ``-q0`` va demander à ``nc`` d'attendre ``0 secondes`` après
avoir reçu ``EOF`` avant de s'arrêter.


Conclusion
==========

Les rebonds SSL oui, mais pas n'importe comment ! 

Faites plaisir à votre ``adminsys`` utilisez ``nc -q0``
