############################################################
Debian/Ubuntu : Supprimer les anciens noyaux linux installés
############################################################

:date: 2013-06-26 08:41
:tags: debian, ubuntu, apt-get
:category: Astuces
:author: Rémy Hubscher
:lang: fr

Au fur et à mesure des mises à jour, les noyaux linux s'accumulent et
la partition racine `/` se remplie sans vraiment qu'on y fasse
attention.

Voici une petite commande bien sympa qui permet de supprimer tous les
anciens noyaux (sauf l'actuel)

    Si on vient de mettre à jour son noyaux, il faut redemarrer
    l'ordinateur avant.

Voici la commande :

::

    dpkg -l 'linux-*' | \
      sed '/^ii/!d;/'"$(uname -r | sed "s/\(.*\)-\([^0-9]\+\)/\1/")"'/d;s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d' |  \
      xargs sudo apt-get purge

Dans l'ordre :

- On récupère tous les packets installés commençant par `linux-`
- On vérifie qu'il ne sont pas liés au noyaux linux sur lequel tourne
  actuellement le système.
- Ensuite on passe cette nouvelle liste à apt-get purge pour les supprimer complètements.

Vous pouvez vérifier puis valider.

Vous pouvez aussi ajouter -y avant purge pour valider automatiquement :

::

    dpkg -l 'linux-*' | sed '/^ii/!d;/'"$(uname -r | sed "s/\(.*\)-\([^0-9]\+\)/\1/")"'/d;s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d' |  xargs sudo apt-get -y purge

Enjoy !
