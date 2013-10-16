########################################
Successfull git feature workflow in team
########################################

:date: 2013-10-16 15:41
:tags: git
:category: Astuces
:author: Rémy Hubscher


Introduction
============

I like to have a nice commit list mainly because I am using this
commit list to generate release CHANGELOG between two changelogs.

First of all configure your favorite editor::

    git config --global core.editor emacs

or you might want to use vim::

    git config --global core.editor vim


How does it works?
==================

Create a branch for the issue
-----------------------------

Well, first of all, create an issue with the description of the thing
to implements::

    #2145 - Implements ElasticSearch Integration for Articles

Then open a new branch with its named prefixed with the issue number::

    git checkout -b 2145_es_article_integration

Now you can implement the feature and create a pull request so that
other people can review your work.


Create a pull-request
---------------------

You can do it with the github interface or with hub_::

    hub pull-request -m "ES Integration for Articles\nRefs #2145"

Or even link the pull request to the existing issue::

    hub pull-request -i 2145

And if you have a fork, you must specify the branch from and to::

    hup pull-request -m "ES Integration for Articles\nRefs #2145" \
                     -b owner_org:master \
                     -h your_org:2145_es_article_integration


Squash your commit
------------------

Now that your PR has been reviewed, you must prepare it for merge.

Well, they might be some changes on master so you will need to rebase
your work before merge.

You may also want to squash your commit in one feature commit.

To do that first pull new changes on master::

    git checkout master
    git pull origin master

Then squash your commit::

    git checkout 2145_es_article_integration
    git rebase -i HEAD~15 # NB_COMMIT = 15

NB_COMMIT est le nombre de commit qui se trouve dans votre Pull Request.

You will have a list of commit like that::

    pick 1e1209b Cleanup _percolate index so it isn't left behind from tests.
    pick 4996a46 make py.test find test files
    pick 46c98ac Missed quote in example
    pick b234ce0 requests 2.0 is still compatible
    
    # Rebase 71a7f4d..b234ce0 onto 71a7f4d
    #
    # Commands:
    #  p, pick = use commit
    #  r, reword = use commit, but edit the commit message
    #  e, edit = use commit, but stop for amending
    #  s, squash = use commit, but meld into previous commit
    #  f, fixup = like "squash", but discard this commit's log message
    #  x, exec = run command (the rest of the line) using shell
    #
    # These lines can be re-ordered; they are executed from top to bottom.
    #
    # If you remove a line here THAT COMMIT WILL BE LOST.
    #
    # However, if you remove everything, the rebase will be aborted.
    #
    # Note that empty commits are commented out
    
You will let the first one to pick and change all the other with fixup or f::

    pick 1e1209b Cleanup _percolate index so it isn't left behind from tests.
    fixup 4996a46 make py.test find test files
    fixup 46c98ac Missed quote in example
    fixup b234ce0 requests 2.0 is still compatible
    
    # Rebase 71a7f4d..b234ce0 onto 71a7f4d
    #
    # Commands:
    #  p, pick = use commit
    #  r, reword = use commit, but edit the commit message
    #  e, edit = use commit, but stop for amending
    #  s, squash = use commit, but meld into previous commit
    #  f, fixup = like "squash", but discard this commit's log message
    #  x, exec = run command (the rest of the line) using shell
    #
    # These lines can be re-ordered; they are executed from top to bottom.
    #
    # If you remove a line here THAT COMMIT WILL BE LOST.
    #
    # However, if you remove everything, the rebase will be aborted.
    #
    # Note that empty commits are commented out

It will merge all the patches in the commit that you picked.

Then you may want to amend the commit message of your squashed commit::

    git commit --amend -m "Fix #2145 — Implements ElasticSearch Integration for Articles"

Once you've done that, you will override your remote branch with your squashed commit::

    git push origin 2145_es_article_integration --force

The force is important to override the remote branch.


Merge your pull-request
-----------------------

After all, your pull request is ready for merge you may rebase it
again if there were some changes on master during the process::

    git checkout master
    git pull
    git checkout 2145_es_article_integration
    git rebase master

You can click on the merge button or do it with git::

    git checkout master
    git merge 2145_es_article_integration
    git push origin master


Remove merge branches
---------------------

Once you have merge your work, you do not need that branch anymore.

You can use the Delete button or use git to delete the branch localy and remotely::

    git checkout master
    git branch -d 2145_es_article_integration
    git push origin :2145_es_article_integration  # Remove remote branch


Conclusion
==========

Well it is an interesting process, it will improve the readability of
your commit change list.

Hope this helps.


.. _hub: http://hub.github.com/
