###############################################
Autocompletion des arguments dans vos commandes
###############################################

:date: 2012-09-13 15:11
:tags: python, bash, django-fr
:category: Python
:author: Rémy Hubscher


Introduction
============

Aujourd'hui nous sommes quelques-uns à nous être réunis Porte de la Villette à
Paris pour des sprints Python.

Le premier sprint de ce matin a porté sur l'ajout de l'autocompletion Bash des
arguments de la commande ``circusctl``.

Pour ce faire, nous nous sommes inspirés de l'autocompletion des commandes
``django-admin`` qui est bien réalisée, et voici comment vous allez pouvoir,
vous aussi, ajouter l'autocompletion bash à vos commandes.


Bash Autocomplete
=================

La fonctionnalité de completion automatique de bash fonctionne de la manière
suivante :

Une fonction bash est définie qui s'occupe de modifier la valeur de la variable
bash ``COMPREPLY``. Cette valeur contient la liste des completions possibles
séparées par des espaces.

.. code-block:: bash

    _my_script_completion() {
        COMPREPLY=("hello world")
    }


Il faut ensuite utiliser ``complete`` pour associer une fonction à un nom de
programme :

.. code-block:: bash

    complete -F _my_script_completion -o default my_script.py

Une fois ceci fait, on peut taper :

.. code-block:: console

    $ ./my_script.py <tab><tab>hello world

Pour compléter le mot courant, c'est ``compgen`` qu'il faut utiliser :

.. code-block:: console

    $ cur="hel"
    $ opts=("hello world")
    $ compgen -W "$opts" -- $cur
    hello

Il est important d'utiliser ``--`` avant ``$cur`` pour éviter les injections
d'options à ``compgen`` dans le contenu de ``$cur``.

Et voici un exemple de script complet :

.. code-block:: bash

    _my_script_completion() {
        local args cur opts

        # COMPREPLY désigne la réponse à renvoyer pour la complétion
        # actuelle
        COMPREPLY=()

        # argc : index du mot courant (sous le curseur)
        argc=${COMP_CWORD};

        # cur : mot courant (sous le curseur)
        cur="${COMP_WORDS[argc]}"

        # les options possibles pour notre auto-complétion
        opts="hello world"

        # on auto-complete la ligne de commande en recherchant cur
        # dans la liste opts.
        COMPREPLY=( $(compgen -W "$opts" -- $cur ) )
        # A noter que le -- est important ici pour éviter les
        # "injections d'options" depuis $cur.
    }
    complete -F _my_script_completion -o default my_script.py

Pour le tester dans un terminal :

.. code-block:: console

    $ source ~/path/to/my_bash_script_completion
    $ ./my_script.py <tab><tab>
    hello world
    $ ./my_script.py hel<tab>lo

Nous avons donc la complétion pour notre script inexistant. Super !


Un fichier bash générique pour nos programmes
=============================================

En fait ce sont nos programmes qui connaissent la liste des options/arguments
valides, ce sont donc à eux de nous retourner la liste des complétions
possibles.

Nous pouvons donc passer les arguments ``$COMP_WORDS`` et ``$COMP_CWORD`` à
notre programme et lui demander de retourner une liste de complétion possible.

On va également ajouter une variable ``$AUTO_COMPLETE`` pour signaler à notre
programme qu'on est en mode autocomplete et éviter tout comportement anormal de
notre commande par la suite.

Voici le contenu générique de notre fichier d'autocompletion :

.. code-block:: bash

    # #########################################################################
    # This bash script adds tab-completion feature to my_script.py
    #
    # Testing it out without installing
    # =================================
    #
    # To test out the completion without "installing" this, just run this file
    # directly, like so:
    #
    #     source ~/path/to/my_script_bash_completion
    #
    # After you do that, tab completion will immediately be made available in
    # your current Bash shell. But it won't be available next time you log in.
    #
    # Installing
    # ==========
    #
    # To install this, source this file from your .bash_profile, like so:
    #
    #     source ~/path/to/my_script_bash_completion
    #
    # Do the same in your .bashrc if .bashrc doesn't invoke .bash_profile.
    #
    # Settings will take effect the next time you log in.
    #
    # Uninstalling
    # ============
    #
    # To uninstall, just remove the line from your .bash_profile and .bashrc.

    _my_script_completion() {
        COMPREPLY=( $( COMP_WORDS="${COMP_WORDS[*]}" \
                       COMP_CWORD=$COMP_CWORD \
                       AUTO_COMPLETE=1 $1 ) )
    }
    complete -F _my_script_completion -o default my_script.py


Gérer la complétion du côté du programme
========================================

Du côté du programme, voici un exemple d'implémentation en python
(``my_script.py``) :

.. code-block:: python

    #!/usr/bin/env python
    # -*- coding: utf-8 -*-

    import os
    import sys


    class ControllerApp(object):
        """Controller that manages the command dispatch."""

        def __init__(self):
            self.options = ['hello', 'world']

        def autocomplete(self):
            """Output completion suggestions for BASH.

            The output of this function is passed to BASH's `COMREPLY` variable
            and treated as completion suggestions. `COMREPLY` expects a space
            separated string as the result.

            The `COMP_WORDS` and `COMP_CWORD` BASH environment variables are
            used to get information about the input. Please refer to the
            BASH man-page for more information about these variables.

            Note: If debugging this function, it is recommended to write the
            debug output in a separate file. Otherwise the debug output will be
            treated and formatted as potential completion suggestions.

            """
            # Don't complete if user hasn't sourced the bash_completion file.
            if 'AUTO_COMPLETE' not in os.environ:
                return

            # list of individual words on the command line
            words = os.environ['COMP_WORDS'].split()[1:]
            # index (in the words list) of the word under the cursor
            cword = int(os.environ['COMP_CWORD'])

            try:
                # curr is the current word, with cword being a 1-based index
                curr = words[cword - 1]
            except IndexError:
                curr = ''

            print(' '.join(sorted(filter(lambda x: x.startswith(curr),
                                         self.options))))
            sys.exit(1)


    def main():
        controller = ControllerApp()
        controller.autocomplete()

    if __name__ == '__main__':
        main()


Encore une fois, pour le tester :

.. code-block:: bash

    $ chmod +x my_script.py
    $ ./my_script.py<tab><tab>
    hello world
    $ ./my_script.py he<tab>llo w<tab>orld


Conclusion
==========

En conclusion, ce sprint sur circus m'a permis de trouver un bon moyen de gérer
simplement et efficacement la complétion des arguments d'une commande.

Pour la suite du sprint, il faudra lancer une CLI lorsque ``circusctl`` est
lancé sans arguments.
