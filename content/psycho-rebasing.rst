############################
Psycho-rebasing: merge-based
############################

:date: 2012-10-24 11:59
:tags: git, mercurial
:category: Astuces
:author: Benoît Bryon
:lang: en
:slug: psycho-rebasing

This article tries to point out a potential problem with rebasing, and how
to solve it with merges. Examples use `Git`_, but the story could be adapted
to other `DVCS`_, like `Mercurial`_ with `rebase extension`_.


******
Rebase
******

Given:

::

    master: C0---C1---C2
              \ 
    topic:     C3

Basic rebasing ``git checkout topic && git rebase master``:

::

    master: C0---C1---C2
                        \
    topic:               C3'

C3 changes have been replayed on the top of master, as C3'.
Cool feature isn't it? Let's combine it with tests.


*************
Rebase + test
*************

As a developer, I care about tests.
Here is the base changelog annotated with test status, which could
have been checked by some continuous integration service (i.e. Jenkins).

::

    master: C0[pass]---C1[pass]---C2[pass]
                    \
    topic:           C3[pass]

Let's ``git checkout topic && git rebase master``:

::

    master: C0[pass]--C1[pass]--C2[pass]
                                        \
    topic:                               C3'[?]

If there is no conflict, ``git rebase`` commits.
But **"no merge conflict" doesn't imply "no regression"**.

Tests would often pass on C3'. But they could fail too. **Rebase preserves
changesets, but not test status.**


**********************************
When rebase introduces regressions
**********************************

Let's consider a fail:

::

    master: C0[pass]--C1[pass]--C2[pass]
                                        \
    topic:                               C3'[fail]

One solution is to:

* run an interactive rebase (no automatic commit) with
  ``git checkout topic && git rebase --interactive master``

* run the test suite. It fails (that's our scenario).

* fix the regression.

* commit (rebase --continue).

It means we produced a brand new commit:

::

    master: C0[pass]--C1[pass]--C2[pass]
                                        \
    topic:                               C4[pass]

Notice we didn't commit C3', but C4, i.e. a different diff.
It works. Great!

So, would you bet a billion dollar C4 is safe? Of cour... oh! wait.

Where is all the valid work I did on C3? In C4? Are you sure? C3 has
been altered, and so maybe compromised my (potentially hard and
complex) work. I mean, tests are great, but in real-life, tests could
also be wrong or incomplete. I did my best on C3, and C4 is the result
of another effort, involving changes introduced by someone else. I can't
consider C4 as an equivalent of C3.


***************
Safe "rebasing"
***************

It is possible to preserve C3:

::

    git checkout master
    git checkout -b topic-merge
    git merge C3

Gives:

::

    master: C0[pass]--C1[pass]--C2[pass]
                    \                   \
    topic:           C3[pass]            \
                             \            \
    topic-merge:              -------------C4[?]

Now, if C4 breaks tests, it's easy to rollback or see differences with
C3.

If we want to run tests before C4 is committed:

::

    git checkout master
    git checkout -b topic-merge
    git merge --no-commit C3
    # Fix the tests.
    git commit

Would result to:

::

    master: C0[pass]--C1[pass]--C2[pass]
                    \                   \
    topic:           C3[pass]            \
                             \            \
    topic-merge:              -------------C4[pass]

The more commits you want to rebase, the more helpful is this workflow.
Given:

::

    master: C0[pass]--C1[pass]--C2[pass]--C3[pass]---C4[pass]
                    \
    topic:           C5[pass]---C6[pass]---C7[pass]

Then I dislike this "what happened? Did you test before commit?" situation:

::

    master: C0[pass]--C1[pass]--C2[pass]--C3[pass]---C4[pass]
                                                             \
    topic-merge:                                              C5'[pass]---C6'[fail]---C7'[fail]

Whereas I know I can fix this one, where it is clear that the regression
was introduced by the merge:

::

    master:      C0[pass]---C1[pass]--C2[pass]--C3[pass]---C4[pass]
                         \                                         \
    topic-merge:          \                                         C8[pass]---C9[fail]---C10[fail]
                           \                                       /          /          /
    topic:                  -------------------------------C5[pass]---C6[pass]---C7[pass]


***********************
Rename "merge-branches"
***********************

The more you "psycho-rebase", the more branches you create.
I mean we want "topic-merge" to be called "topic"!

If "topic" is local (not pushed on remote), then I can do it:

::

    git checkout master
    git branch -m topic topic-deprecated
    git branch -m topic-merge topic
    git branch -d topic-deprecated

Since "topic commits" has been merged to "topic-merge" branch, removing
the "topic-deprecated" branch doesn't remove the commit objects (i.e.C5,
C6 and C7).

.. note::

   It seems that we can rename even if the "topic" branch has been pushed on a
   remote... but, as I am writing this article, I'm not sure about the result.

******************
Don't merge master
******************

One would say I could have merged "master" instead of "topic":

::

    git checkout topic  # HEAD is now C7.
    git merge C1
    git merge C2
    git merge C3
    git merge C4
    # Or directly git merge C4...

That's true. But `I don't want to commit other's work. I want to commit
changes I can review, i.e. my own changes`_. That's partly a matter of
responsibility.
If I am contributing to a project where 42 contributors performed 1234
commits while I was on holidays, I don't want to merge the whole master
changeset, I just want to replay my changes on top of the master... That's
the basics of a rebase, isn't it?


**************************************
Feature request: safe rebasing command
**************************************

Using the "safe" workflow is a pain!

::

    git checkout master  # HEAD is now C4.
    git checkout -b topic-merge
    git merge C5
    git merge C6
    git merge C7

And that's only the version where I don't run tests before commit.

So, I am dreaming of something like:

::

  git checkout topic
  git safe-rebase master

... which would:

* cherrypick changesets of "topic" and replay them on top of "master",
  as part of the "topic" branch.
* don't remove former "topic" changesets (i.e. kind of "copy" changesets
  rather than "move" them).

It's a kind of transplantation, rather than a rebase.


********
See also
********

* http://alblue.bandlem.com/2011/06/git-tip-of-week-rebasing-revisited.html
* http://randyfay.com/content/rebase-workflow-git

.. _`Git`: http://git-scm.com/
.. _`DVCS`: https://en.wikipedia.org/wiki/Distributed_revision_control
.. _`Mercurial`: http://mercurial.selenic.com/
.. _`rebase extension`: 
   http://mercurial.selenic.com/wiki/RebaseExtension
.. _`I don't want to commit other's work. I want to commit changes I can
   review, i.e. my own changes`: ../merging-the-right-way-en.html
