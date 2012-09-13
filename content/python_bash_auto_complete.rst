###############################################################
Autocomplete de vos arguments dans vos commandes python ou ruby
###############################################################

:date: 2012-09-13 15:11
:tags: python, ruby, bash
:category: Python
:author: Rémy Hubscher


Introduction
============

Aujourd'hui nous sommes quelques-un à nous être réunis Porte de la
Villette à Paris pour des sprints Python.

Le premier sprint de ce matin a porté sur l'ajout de l'autocompletion
Bash des arguments de la commande ``circusctl``.

Pour le faire je me suis inspiré de l'autocompletion des commandes
``django-admin`` qui me semble être une bonne idée, voici comment vous
allez pouvoir, vous aussi, ajouter l'autocomplete bash à vos commandes.


Bash Autocomplete
=================

La fonctionnalité de completion automatique de bash fonctionne de la
manière suivante :

Une fonction bash est définie qui s'occupe de modifier la valeur de la
variable bash ``COMPREPLY``. Cette valeur contient la liste des
completions possibles séparées par des espaces.

.. code-block:: bash

    _my_script_completion()
    {
        COMPREPLY=("hello world")
    }


Pour associer une fonction à un nom de programme, on utilise ``complete``

.. code-block:: bash

    complete -F _my_script_completion -o default my_script_command.py

Une fois ceci fait, je peux taper :

.. code-block:: console

    $ my_script_command.py <tab>hello world

Pour compléter en utilisant les mots de la liste à partir de ce qui
est disponible dans la ligne de commande, on peut utiliser ``compgen`` :

.. code-block:: console

    $ cur="Hel"
    $ opts=("Hello world")
    $ compgen -W "$opts" -- $cur
    Hello

Il est important d'utiliser -- avant ``$cur`` pour éviter les injections
d'options à ``compgen`` dans le contenu de ``$cur``.

Dans les fait, il suffit de faire le fichier suivant :

.. code-block:: bash

    _my_script_completion()
    {
        local args cur opts
        
        # COMPREPLY désigne la réponse à renvoyer pour la complétion
        # actuelle
        COMPREPLY=()
        
        # argc : vaut le nombre d'argument actuel sur la ligne de
        # commande
        argc=${COMP_CWORD};
        
        # cur : désigne la chaine de caractère actuelle pour le
        # dernier mot de la ligne de commande
        cur="${COMP_WORDS[argc]}"
        
        # les options possibles pour notre auto-complétion
        opts="hello world"
        
        # on auto-complete la ligne de commande en recherchant cur
        # dans la liste opts.
        COMPREPLY=( $(compgen -W "$opts" -- $cur ) )
        # A noter que le -- est important ici pour éviter les
        # "injections d'options" depuis $cur.
    }
    complete -F _my_script_completion -o default my_script

Pour le tester dans un terminal :

.. code-block:: console

    $ ``source ~/path/to/my_script_bash_completion``
    $ my_script <tab><tab>
	Hello world
	$ my_script Hel<tab>lo

Nous avons donc la complétion pour notre script inexistant. Super !


Un fichier bash générique pour nos programmes
=============================================

En fait ce sont nos programmes qui connaissent la liste des
options/arguments valides, ce sont donc à eux de nous retourner la
liste des complétions possibles.

Nous pouvons donc passer les arguments ``$COMP_WORDS`` et
``$COMP_CWORD`` à notre programme et lui demander de retourner une
liste de complétion possible.

On va également ajouter une variable ``$AUTO_COMPLETE`` pour entrer
dans notre programme en mode autocomplete et éviter tout comportement
anormal de notre commande par la suite.

Voici le contenu générique de notre fichier d'autocompletion :

.. code-block:: bash

    # #########################################################################
    # This bash script adds tab-completion feature to my_script
    #
    # Testing it out without installing
    # =================================
    #
    # To test out the completion without "installing" this, just run this file
    # directly, like so:
    #
    #     source ~/path/to/my_script_bash_completion
    #
    # After you do that, tab completion will immediately be made available in your
    # current Bash shell. But it won't be available next time you log in.
    #
    # Installing
    # ==========
    #
    # To install this, point to this file from your .bash_profile, like so:
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
    
    _my_script_completion()
    {
        COMPREPLY=( $( COMP_WORDS="${COMP_WORDS[*]}" \
                       COMP_CWORD=$COMP_CWORD \
                       AUTO_COMPLETE=1 $1 ) )
    }
    complete -F _my_script_completion -o default my_script.py


Gérer la complétion du côté du programme
========================================

Du côté du programme, voici un exemple d'implémentation en python :

.. code-block:: python

    class ControllerApp(object):
        """Controller that manage the command dispatch"""
        def __init__(self):
            self.commands = ['hello', 'world']

        def autocomplete(self):
            """
            Output completion suggestions for BASH.
    
            The output of this function is passed to BASH's `COMREPLY` variable and
            treated as completion suggestions. `COMREPLY` expects a space
            separated string as the result.
    
            The `COMP_WORDS` and `COMP_CWORD` BASH environment variables are used
            to get information about the cli input. Please refer to the BASH
            man-page for more information about this variables.
    
            Subcommand options are saved as pairs. A pair consists of
            the long option string (e.g. '--exclude') and a boolean
            value indicating if the option requires arguments. When printing to
            stdout, a equal sign is appended to options which require arguments.
    
            Note: If debugging this function, it is recommended to write the debug
            output in a separate file. Otherwise the debug output will be treated
            and formatted as potential completion suggestions.
            """
            # Don't complete if user hasn't sourced bash_completion file.
            if 'AUTO_COMPLETE' not in os.environ:
                return

            cwords = os.environ['COMP_WORDS'].split()[1:]
            cword = int(os.environ['COMP_CWORD'])
    
            try:
                curr = cwords[cword-1]
            except IndexError:
                curr = ''
    
            subcommands = self.commands
    
            # subcommand
            if cword == 1:
                print(' '.join(sorted(filter(lambda x: x.startswith(curr), subcommands))))
            sys.exit(1)

        def run(self, args):
            self.autocomplete()
            print "Normal use of the command '%s'." % args

    def main():
        controller = ControllerApp()
        controller.run(sys.argv[1:])
        
    if __name__ == '__main__':
        main()

Conclusion
==========

En conclusion, ce sprint circus m'a permis de trouver un bon moyen de
gérer simplement et efficacement la complétion des arguments d'une
commande.

Le prochain sprint, lancer une CLI lorsque ``circusctl`` est lancé
sans arguments.
