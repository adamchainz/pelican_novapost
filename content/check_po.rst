############################
Introducing gettext check_po
############################

:date: 2012-12-13 17:16
:tags: python, django, django-fr
:category: Astuces
:author: Rémy Hubscher


Introduction
************

Au début de notre dernier projet django nous avons décidé de le
séparer en app d'un même namespace. (project.core, project.user,
project.share, ...)

Cela permet de séparer les composants sur différentes VM en installant
les dépendances nécessaires.

Notre projet est donc séparé en une dizaine de composants qui ont
chacun leur github, setup.py, licence, numéro de version, changelog,
readme, etc bien propre.

L'avantage c'est que c'est bien modulaire et prévu pour monter en
charge.

Le désavantage c'est qu'il faut être rigoureux pour les releases en
mettant bien à jour le changelog et la version du projet, en taggant
chaque dépôt et mettant à jour les numéros de version des dépendances.

Nous avons donc un script interne qui nous permet de faire la release
des composants d'un même projet.


Le problème
***********

Comme chaque composant est séparé, la traduction est également séparée.

ça pose différents problèmes notamment différents doublons de
traductions entre les composants.

Normalement si on oublie la traduction d'un composant, il s'affiche
dans l'application en anglais et on fini par le corriger, mais dans ce
projet nous avons également mis en place la traduction des urls et si
une url est mal traduite avec un fuzzy, retiré un peu trop vite,
l'application peut ne plus être fonctionnelle dans une des langues.

De plus dans un soucis de qualité, nous souhaitions être sur qu'à
chaque release, tous les fichiers de langues seraient bien à jour.


La solution
***********

Après `une question sur serverfault`_ restée quelques jours sans
réponse, j'ai finalement découvert polib_.

L'avantage de polib_ c'est qu'il permet de lire le fichier PO est de
nous donner les chaînes non traduites et les fuzzy (chaînes
pré-traduites en attente de validation).

J'ai donc réalisé un tout petit script qui ouvre un fichier po et
vérifie qu'il n'y a pas de FUZZY ou de UNTRANSLATED messages dedans.

Si tel est le cas, il les affiche::

    Processing locale/de/LC_MESSAGES/django.po
    UNTRANSLATED	User has been deleted.
    UNTRANSLATED	^activate/(?P<activation_key>\w+)/$
    UNTRANSLATED	^register/complete/$
    UNTRANSLATED	^register/closed/$
    UNTRANSLATED	^reset/done/$
    UNTRANSLATED	^email/change/$
    UNTRANSLATED	^email/verify/(?P<verification_key>\w+)/$
    UNTRANSLATED	Email modification.
    UNTRANSLATED	Password reset mail has been sent to %(email)s.
    UNTRANSLATED	Email change
    UNTRANSLATED	Your email address has been changed successfully.
    UNTRANSLATED	Your new email address is:
    UNTRANSLATED	Back to your profile
    UNTRANSLATED	An email containing a verification link has been sent to your new email address.
    UNTRANSLATED	Follow the instructions in this email in order to successfully change your current email address.
    UNTRANSLATED	Email confirmation
    UNTRANSLATED	This confirmation code has either expired or is invalid.
    ...
    FUZZY	title titel
    FUZZY	^activate/complete/$ Aktivierung abgeschlossen
    FUZZY	^register/$ Registrieren
    FUZZY	^logout/$ ^login/$
    FUZZY	^password_change/$ Passwort-Änderung
    FUZZY	^password_change/done/$ Passwort-Änderung
    FUZZY	^email/verification/sent/$ Benachrichtigung gesendet
    FUZZY	^email/change/complete/$ Aktivierung abgeschlossen
    FUZZY	^password_reset/$ Passwort-Reset
    FUZZY	^password_reset/done/$ Passwort-Reset
    ...
    
    ----------
    16 FUZZY string found.
    33 UNTRANSLATED string found.
    ----------
    Edit: /home/.../user/locale/de/LC_MESSAGES/django.po

Si tout va bien::

    locale/fr/LC_MESSAGES/django.po: PO File OK

Conclusion
**********

Installez et testez **check_po** :

::

    $ pip install check_po
    $ check_po locale/fr/LC_MESSAGES/django.po

N'hésitez pas à le forker pour l'améliorer : https://github.com/novagile/check_po

Vous pouvez ajouter ce script en pre-commit de votre dépôt git ou
mercurial ou encore en script de pre-release ce qui vous permettra de
garantir une bonne qualité de traduction à vos programmes, services et
applications.

.. _`une question sur serverfault`: http://superuser.com/questions/517276/after-a-gettext-update-be-able-to-check-if-a-translation-file-has-been-translate
.. _polib: https://polib.readthedocs.io/en/latest/quickstart.html#more-examples
