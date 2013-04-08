############################################
Configurer Emacs comme un développeur Python
############################################

:date: 2013-04-08 16:25
:tags: emacs, python, django, django-fr
:category: Astuces
:author: Rémy Hubscher

Introduction
************

Souvent on me demande qu'elle IDE j'utilise. Quand je réponds emacs,
ça ne semble pas convenir à mon interlocuteur.

Voici un petit article pour transformer son emacs en véritable IDE
python.

Quand je code en Python, j'ai envie de respecter la PEP-8, d'avoir
la complétion des noms de fonctions et variables et que mon IDE me
dise quand j'ai oublié d'importer une bibliothèque ou que j'en importe
qui ne sont pas utilisées.


En Python, les tabulations font 4 espaces
*****************************************

On modifie le fichier ``.emacs`` avec ces deux lignes::

    (setq-default indent-tabs-mode nil)  ; use only spaces and no tabs
    (setq default-tab-width 4)


Installation des outils de refactoring
**************************************

Pour cela il faut installer Ropemacs_ et Pymacs_.

Installer Ropemacs
------------------

.. code-block:: bash

    sudo pip install http://bitbucket.org/agr/ropemacs/get/tip.tar.gz 


Installer Pymacs
----------------

.. code-block:: bash

    curl -L https://github.com/pinard/Pymacs/tarball/v0.24-beta2 | tar zx
    cd pinard-Pymacs-016b0bc
    make 
    mkdir -p ~/.emacs.d/vendor/pymacs
    cp pymacs.el ~/.emacs.d/vendor/pymacs/pymacs.el 
    emacs -batch -eval '(byte-compile-file "~/.emacs.d/vendor/pymacs/pymacs.el")'
    python setup.py install


Configurer Emacs
----------------

.. code-block:: lisp

    (add-to-list 'load-path "~/.emacs.d/vendor/pymacs")
    (require 'pymacs)
    (pymacs-load "ropemacs" "rope-")
    (setq ropemacs-enable-autoimport t)


Ajouter les outils de complétion automatique
********************************************

Pour installer auto-complete_::

    cd ~/.emacs.d/vendor 
    curl http://cx4a.org/pub/auto-complete/auto-complete-1.2.tar.bz2 | tar jx 
    cd auto-complete-1.2 
    make byte-compile 


Ajouter la vérification de code
*******************************

La vérification du code se fait avec Flymake_

Téléchargez flymake-cursor.el
-----------------------------

Créez le fichier ``~/.emacs.d/vendor/flymake-cursor.el`` en
téléchargeant: http://www.emacswiki.org/emacs/flymake-cursor.el


Configurez ``.emacs``
---------------------

::

    (add-to-list 'load-path "~/.emacs.d/vendor")
    
    (add-hook 'find-file-hook 'flymake-find-file-hook)
    (when (load "flymake" t)
      (defun flymake-pyflakes-init ()
        (let* ((temp-file (flymake-init-create-temp-buffer-copy
                   'flymake-create-temp-inplace))
           (local-file (file-relative-name
                temp-file
                (file-name-directory buffer-file-name))))
          (list "pycheckers"  (list local-file))))
       (add-to-list 'flymake-allowed-file-name-masks
                 '("\\.py\\'" flymake-pyflakes-init)))
    (load-library "flymake-cursor")
    (global-set-key [f10] 'flymake-goto-prev-error)
    (global-set-key [f11] 'flymake-goto-next-error)


Créez /usr/local/bin/pycheckers
-------------------------------

::

    #!/bin/bash
    
    pyflakes "$1"
    pep8 --ignore=E221,E701,E202 --repeat "$1"
    true


Installer pep8 et pyflakes
--------------------------
::

    chmod +x /usr/local/bin/pycheckers
    sudo pip install pyflakes pep8


Coloration syntaxique Django
****************************

Télécharger et installer nxhtml
-------------------------------

::

    cd ~/.emacs.d/vendor/
    wget http://ourcomments.org/Emacs/DL/elisp/nxhtml/zip/nxhtml-2.08-100425.zip
    unzip nxhtml-2.08-100425.zip
    sed -i 's/font-lock-beginning-of-syntax-function/syntax-begin-function/g' nxhtml/util/mumamo.el


Configurer .emacs
-----------------

::

    (load "~/.emacs.d/vendor/nxhtml/autostart.el")
    (setq mumamo-background-colors nil) 
    (add-to-list 'auto-mode-alist '("\\.html$" . django-html-mumamo-mode))


Conclusion
**********

Vous voilà avec un emacs boosté en IDE Python. Vous n'aurez plus
aucune raison de ne pas respecter la PEP-8.

Merci à jojax pour les partages successifs de cet article qui m'ont
poussés à le traduire, le simplifier et le corriger sur ce blog.

 * Article original en Anglais : http://www.saltycrane.com/blog/2010/05/my-emacs-python-environment/

.. _Ropemacs: http://rope.sourceforge.net/ropemacs.html
.. _Pymacs: http://pymacs.progiciels-bpi.ca/
.. _auto-complete: http://cx4a.org/software/auto-complete/
.. _Flymake: http://flymake.sourceforge.net/
