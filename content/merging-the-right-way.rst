#####################
Merging the right way
#####################

:date: 2012-10-24 10:30
:tags: git, mercurial
:category: Astuces
:author: Benoît Bryon
:lang: en
:slug: merging-the-right-way

If, during a merge, you have to resolve conflicts on files you didn't change
in your branch, then you maybe merged the wrong way. Yes, during a merge,
direction matters. Here are some tips to figure it out and avoid some merge
nightmares.


*****************************************
Apply your changes on top of other's work
*****************************************

All you need to remember from this article is:

  **When you merge, you'd better replay your own work on top of other's**, i.e.
  ``git checkout other-branch && git merge my-branch`` instead of the opposite.

If you are not convinced yet, here are detailed explanations...


*****************************************
Not a bug, not related to a specific tool
*****************************************

This story affects both Git and Mercurial, and maybe some other DVCS. I am to
provide examples for Git, then explain how to reproduce with Mercurial.

The focus here is not about the tool. It's about usage.

As `DVCS`_ users, we often perform merges.
And we really appreciate the smart merging capabilities of `Git`_ or
`Mercurial`_: don't worry about merging except when the tool reports conflicts.
We do trust the tool. And sometimes we forget that we are responsible of the
usage.


*******************************
Given a classic merge situation
*******************************

Let's consider a repository:

.. code-block:: sh

   # Initialize a repository.
   mkdir merging-the-right-way
   cd merging-the-right-way/
   git init
   echo "Hello" > hello.txt
   echo "Goodbye" > goodbye.txt
   git add hello.txt goodbye.txt
   git commit -m "Initial commit"

I start working on some feature in a branch:

.. code-block:: sh

   git checkout -b my-branch  # Create a new branch.
   echo "world" >> hello.txt
   git commit -a -m "Said hello to the world." --author="Myself <myself@example.com>"

By that time, someone else also worked on the repository and put his changes
in another branch:

.. code-block:: sh

   git checkout master  # Started the new branch from master.
   git checkout -b other-branch
   echo "Triple axel with double backflip" >> goodbye.txt
   git commit -a -m "A complex but memorable goodbye." --author="Other <other@example.com>"

What if I want to have a branch where changes from Other and Myself are
applied?


*************************
Possible merge directions
*************************

I have two options:

1. Apply other's changes on top of my branch:

   .. code-block:: sh

      git checkout my-branch
      git checkout -b my-branch-updated
      git merge other-branch

   .. note::

      We use another branch so that we can easily compare things.

2. Or apply my changes on top of other's branch:

   .. code-block:: sh

      git checkout other-branch
      git checkout -b other-branch-updated
      git merge my-branch

Ok, let's compare the results with
``git diff my-branch-updated other-branch-updated``.

No difference: ``hello.txt`` and ``goodbye.txt`` get exactly the same with both
workflows. So, why bother about direction?

Because what matters is the diff I committed (a merge implies a commit).

``git diff my-branch-updated my-branch`` tells:

 .. code-block:: diff

    diff --git a/goodbye.txt b/goodbye.txt
    index 2b60207..ee3f527 100644
    --- a/goodbye.txt
    +++ b/goodbye.txt
    @@ -1 +1,2 @@
     Goodbye
    +Triple axel with double backflip

And ``git diff other-branch-updated other-branch`` tells:

   .. code-block:: diff

      diff --git a/hello.txt b/hello.txt
      index e965047..65a56c3 100644
      --- a/hello.txt
      +++ b/hello.txt
      @@ -1 +1,2 @@
       Hello
      +world

During the first workflow I committed changes others introduced, whereas
during the second workflow I committed changes I introduced.


**************************
A matter of responsibility
**************************

In case of regressions or conflicts introduced by the merge, it'll be easier
for you to fix things caused by changes you know, i.e. your own changes.

::

    master:        C0[pass]
                           \
    my-branch:              \----C1[pass]
                             \           \
    other-branch:             --C2[pass]--C3[fail]

At ``C0``, the repository is clean.

At ``C1``, you prepared your changes and asserted the tests pass. It belongs
to your responsibility.

At ``C2`` (``git checkout other-branch``) the repository is in a state made by
others. You can check that tests pass. If tests don't pass, you may renunce to
merge. If tests pass, you can continue safely. Your responsibility isn't
involved at this point.

At ``C3`` (``git merge my-branch``), if tests fail, you will have to review and
adapt changes you introduced. Since you commit the merge, it belongs to you to
resolve conflicts, so it'd be better off if the diff reflects your own work.


***********
Keep humble
***********

It's you VS the world:

* the more the project you work on have contributors,
* the more commits have been done in "other-branch",
* the bigger the diff (files and lines changed)  introduced in "other-branch",
* ... the more you should apply your own (little) changes on top of others.

Here is a very bad situation, where I applied ``other-branch``'s changes on top
of ``my-branch``:

::

    master:        C0
                     \
    my-branch:        \----C1..C4[4 commits, 10 files, 123 lines]------C495[508 files, 2430 lines]
                       \                                              /
    other-branch:       --C5..C494[489 commits, 508 files, 2430 lines]

If there is a merge conflict, I would have to review a giant sum of changes I
didn't develop myself. I don't want this to happen.

Here is a safer situation, where I applied ``my-branch`` changes on top of
``other-branch``:

::

    master:        C0
                     \
    my-branch:        \----C1..C4[4 commits, 10 files, 123 lines]------
                       \                                               \
    other-branch:       --C5..C494[489 commits, 508 files, 2430 lines]--C495[10 files, 123 lines]

If there is any merge conflict, I'd be glad to have to review only the 10 files
in which I introduced changes.


***************************************************************
Updating from remote: beware of ``git pull`` and ``hg pull -u``
***************************************************************

A common merge situation is when you work on the default branch and want to
synchronize your local repository with a remote one. Here, beware of the
default behaviour of your DVCS. By default, it's easier to do it the wrong way
with both Git and Mercurial.

.. note::

   Only ``git pull`` is unsafe, and many developers prefer the builtin
   `rebasing`_ feature.

   Mercurial won't merge and will inform you then let you take the lead.
   Nevertheless, the straightest workflow is the wrong one.

Before we consider `rebasing`_, we will see how to perform the merges in the
adequate direction.

``git pull``
============

From ``git help pull``:

  [...] "git pull" will fetch and replay the changes from the remote master
  branch since it diverged from the local master [...]

It means that, by default, ``git pull origin master`` does a
``git fetch origin master && git merge FETCH_HEAD``.

Here is a recipe to replace some
``git checkout master && git pull origin master`` with merges in the right
direction:

.. code-block:: sh

   # We are working on master branch...
   git checkout master
   # Fetch changes from the remote.
   git fetch origin master
   # Place yourself on top of the fetched commits (special "FETCH_HEAD"
   # reference), in a new branch ("origin-head").
   git checkout --track -b origin-head FETCH_HEAD
   # Apply your changes on top of remote's... and resolve conflicts if any.
   git merge master
   # Now, let's come back to master. The merge should be fast-forward now.
   git checkout master
   git merge origin-head
   # And cleanup temporary merge branch.
   git branch -d origin-head

A sequence of 6 commands to replace 1 ``git pull``... seems a bit boring, isn't
it? In fact, it looks like `rebasing`_.

``hg pull -u``
==============

From ``hg pull``:

  -u --update    update to new branch head if changesets were pulled

It means that, by default, ``hg pull -u`` does a ``hg pull`` then tries a
``hg update``.

If the remote contains changes, you'll get a notice like this...

  not updating, since new heads added

... and then it's up to you to perform the merge.

Here is a recipe to make the merge in the right direction:

.. code-block:: sh

   # We are working on the "default" branch.
   hg update -C default
   # Remember the current tip reference.
   hg tag my-tip
   # Fetch the changes from "default" remote.
   hg pull default
   # Place yourself on the latest commit from remote branch. Let's suppose it
   # is the "tip" if changes were applied on remote.
   hg update -C tip
   # Apply your changes on top of remote's.
   hg merge my-tip
   # Some cleanup.
   hg tag --remove my-tip

A sequence of 5 commands to replace ``hg pull && hg merge default``... seems a
bit boring, isn't it? In fact, it looks like `rebasing`_.


********
Rebasing
********

Another common merge situation is when you are working in a topic branch, and
want to refresh this topic branch against the main development branch (i.e.
"master" or "default", from the remote repository).

The common mistake here is to merge the main branch, i.e.
``git checkout topic-branch && git merge master``.

And we don't want to apply the topic changeset into master yet, i.e. we are not
ready for a ``git checkout master && git merge topic-merge``.

That's where rebase may be useful. You'll find many resources about
`Git's builtin rebase`_ or `Mercurial's rebase extension`_ over the internet.

Typical usages are ``git checkout topic-branch && git rebase master`` and
``git checkout master && git pull --rebase``.

Rebase is really useful.

But keep in mind that standard rebase alters history. In some situations, it
could be harmful. A solution is to replace the rebase feature with merges.
But that's another story I call `psycho-rebasing`_.


.. _`DVCS`: https://en.wikipedia.org/wiki/Distributed_revision_control
.. _`Git`: http://git-scm.com/
.. _`Mercurial`: http://mercurial.selenic.com/
.. _`Git's builtin rebase`: http://git-scm.com/book/en/Git-Branching-Rebasing
.. _`Mercurial's rebase extension`: 
   http://mercurial.selenic.com/wiki/RebaseExtension
.. _`psycho-rebasing`: ../psycho-rebasing-en.html
