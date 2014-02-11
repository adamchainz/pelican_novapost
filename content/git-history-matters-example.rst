#################################
Git history matters (2) - example
#################################

:date: 2014-02-11 17:00
:tags: git, merge, rebase
:category: Astuces
:author: Benoît Bryon
:lang: en
:slug: git-history-matters-example

Here are additional notes around my previous post `Git history matters`_.

`dey` commented:

  Sounds ok since you have only one commiter.

  But the git history becomes unnecessarily complex since several features are
  coded at the same time or when features require a base branch **merge**.

So here is a little scenario, where several contributors perform concurrent
commits and use base branch merge...


******************
Initial repository
******************

First, D. Doctor initializes a repository:

.. code:: sh

   # Create repository.
   mkdir git-complex-example
   cd git-complex-example/
   git init

   # Author commits as D. Doctor by default.
   git config user.name "D. Doctor"
   git config user.email "d.doctor@example.com"

   # Add some commits, so that history is not empty.
   git commit --allow-empty -m "Initialized repository."
   git commit --allow-empty -m "Refs #1 - README introduces project."
   git commit --allow-empty -m "Release 1.0."


************************
Commits in travis branch
************************

Contributor A. Abracadabra starts working on TravisCI.org integration, in a
topic branch named `travis`:

.. code:: sh

   git checkout master  # Make sure we start from master.
   git checkout -b travis

   # Commit as A. Abracadabra.
   git commit --allow-empty -m "Added TravisCI.org configuration." --author="A. Abracadabra <a.abracadabra@example.com>"


************************
Commits in sphinx branch
************************

In the meantime, C. Cachemire adds Sphinx documentation, in a topic branch
named `sphinx`:

.. code:: sh

   git checkout master  # Make sure we start from master.
   git checkout -b sphinx

   # Commit as C. Cachemire.
   git commit --allow-empty -m "Introduced Sphinx documentation. Work in progress." --author="C. Cachemire <c.cachemire@example.com>"
   git commit --allow-empty -m "Added about/ section in documentation." --author="C. Cachemire <c.cachemire@example.com>"
   git commit --allow-empty -m "Typos." --author="C. Cachemire <c.cachemire@example.com>"


*****************************
More commits in travis branch
*****************************

Later, A. Abracadabra adds some commits in his `travis` branch.

.. code:: sh

   git checkout travis

   # Commit.
   git commit --allow-empty -m "Added link to continuous integration platform in README." --author="A. Abracadabra <a.abracadabra@example.com>"


**********
Checkpoint
**********

What's the situation?

* Master has only the initial commits.
* We have 2 topic branches.
* None of the topic branches has been merged in `master` yet.
* In topic branches, there are several commits.
* `travis` branch has one commit before `sphinx` ones, and one commit after.
  So a flat chronological view of commits will not suggests the branches.

What does history look like at this time?

.. code:: console

   # Let's configure an alias to improve log format.
   $> git config alias.logp 'log --pretty=format:"%s %Cgreenby %an <%ae> %Cred on %cd"'

   # Inspect "master" branch:
   $> git logp --graph master
   * Release 1.0. by D. Doctor <d.doctor@example.com>  on Wed Feb 5 14:07:45 2014 +0100
   * Refs #1 - README introduces project. by D. Doctor <d.doctor@example.com>  on Wed Feb 5 14:07:44 2014 +0100
   * Initialized repository. by D. Doctor <d.doctor@example.com>  on Wed Feb 5 14:04:17 2014 +0100

   # Inspect what is in "travis" branch and not in "master":
   $> git logp --graph travis...master
   * Added link to continuous integration platform in README. by A. Abracadabra <a.abracadabra@example.com>  on Wed Feb 5 14:16:09 2014 +0100
   * Added TravisCI.org configuration. by A. Abracadabra <a.abracadabra@example.com>  on Wed Feb 5 14:15:39 2014 +0100

   # Inspect what is in "sphinx" branch and not in "master":
   $> git logp --graph sphinx...master
   * Typos. by C. Cachemire <c.cachemire@example.com>  on Wed Feb 5 14:15:47 2014 +0100
   * Added about/ section in documentation. by C. Cachemire <c.cachemire@example.com>  on Wed Feb 5 14:15:47 2014 +0100
   * Introduced Sphinx documentation. Work in progress. by C. Cachemire <c.cachemire@example.com>  on Wed Feb 5 14:15:47 2014 +0100

Fine, let's continue...


*******************
Merge branch sphinx
*******************

Now, D. Doctor merges `sphinx` branch into master, with a merge commit.

.. code:: sh

   git checkout master
   git merge --no-ff -m "Refs #2 - Added Sphinx documentation." sphinx


******************************
Update and merge branch travis
******************************

Let's update the `travis` branch before we merge it.
We use `psykorebase <https://github.com/benoitbryon/psykorebase>`_ here, in
order to perform a rebase-like that preserves history. As a summary, it does
a "merge `travis` branch on top of `master`, still in a topic branch". We will
review the graph in the next section.

.. code:: sh

   # As A. Abracadabra
   git config user.name "A. Abracadabra"
   git config user.email a.abracadabra@example.com

   # Psyko-rebase "gitignore" branch on top of "master" branch.
   git checkout travis
   psykorebase master

Finally, D. Doctor merges `travis` branch.

.. code:: sh

   # As D. Doctor...
   git config user.name "D. Doctor"
   git config user.email "d.doctor@example.com"

   # Merge "travis" branch in "master", with an explicit merge commit.
   git checkout master
   git merge --no-ff -m "Refs #3 - Enabled continuous integration with TravisCI.org." travis


********************************
Raw Git history gets complicated
********************************

What's the situation?

* We have 3 commits explicitely performed on `master`: initial commit and 2
  merges.
* The 2 topic branches have been merged in `master`.
* In topic branches, there are several commits.
* `gitignore` branch has one commit before `links` ones, and one commit after.
  So a flat chronological view of commits do not suggests the branches.

As expected, the flat raw log is no longer easy to understand:

.. code:: console

   $> git logp
   Refs #3 - Enabled continuous integration with TravisCI.org. by D. Doctor <d.doctor@example.com>  on Wed Feb 5 14:30:10 2014 +0100
   Psycho-rebased branch travis on top of master by A. Abracadabra <a.abracadabra@example.com>  on Wed Feb 5 14:27:13 2014 +0100
   Refs #2 - Added Sphinx documentation. by D. Doctor <d.doctor@example.com>  on Wed Feb 5 14:23:10 2014 +0100
   Added link to continuous integration platform in README. by A. Abracadabra <a.abracadabra@example.com>  on Wed Feb 5 14:16:09 2014 +0100
   Typos. by C. Cachemire <c.cachemire@example.com>  on Wed Feb 5 14:15:47 2014 +0100
   Added about/ section in documentation. by C. Cachemire <c.cachemire@example.com>  on Wed Feb 5 14:15:47 2014 +0100
   Introduced Sphinx documentation. Work in progress. by C. Cachemire <c.cachemire@example.com>  on Wed Feb 5 14:15:47 2014 +0100
   Added TravisCI.org configuration. by A. Abracadabra <a.abracadabra@example.com>  on Wed Feb 5 14:15:39 2014 +0100
   Release 1.0. by D. Doctor <d.doctor@example.com>  on Wed Feb 5 14:07:45 2014 +0100
   Refs #1 - README introduces project. by D. Doctor <d.doctor@example.com>  on Wed Feb 5 14:07:44 2014 +0100
   Initialized repository. by D. Doctor <d.doctor@example.com>  on Wed Feb 5 14:04:17 2014 +0100

And the raw graph is getting weird (although it is explicit):

.. code:: console

   $> git logp --graph
   *   Refs #3 - Enabled continuous integration with TravisCI.org. by D. Doctor <d.doctor@example.com>  on Wed Feb 5 14:30:10 2014 +0100
   |\
   | *   Psycho-rebased branch travis on top of master by A. Abracadabra <a.abracadabra@example.com>  on Wed Feb 5 14:27:13 2014 +0100
   | |\
   |/ /
   | * Added link to continuous integration platform in README. by A. Abracadabra <a.abracadabra@example.com>  on Wed Feb 5 14:16:09 2014 +0100
   | * Added TravisCI.org configuration. by A. Abracadabra <a.abracadabra@example.com>  on Wed Feb 5 14:15:39 2014 +0100
   * |   Refs #2 - Added Sphinx documentation. by D. Doctor <d.doctor@example.com>  on Wed Feb 5 14:23:10 2014 +0100
   |\ \
   | |/
   |/|
   | * Typos. by C. Cachemire <c.cachemire@example.com>  on Wed Feb 5 14:15:47 2014 +0100
   | * Added about/ section in documentation. by C. Cachemire <c.cachemire@example.com>  on Wed Feb 5 14:15:47 2014 +0100
   | * Introduced Sphinx documentation. Work in progress. by C. Cachemire <c.cachemire@example.com>  on Wed Feb 5 14:15:47 2014 +0100
   |/
   * Release 1.0. by D. Doctor <d.doctor@example.com>  on Wed Feb 5 14:07:45 2014 +0100
   * Refs #1 - README introduces project. by D. Doctor <d.doctor@example.com>  on Wed Feb 5 14:07:44 2014 +0100
   * Initialized repository. by D. Doctor <d.doctor@example.com>  on Wed Feb 5 14:04:17 2014 +0100


******************************************
Solution 1: adopt "rebase+squash" workflow
******************************************

Many users stop at this point and complain:

  What a mess! Let's alter history!

Once history has been modified, ``git log`` gives a nice readable output:

.. code:: console

   $> git logp --graph master
   * Refs #3 - Enabled continuous integration with TravisCI.org. by A. Abracadabra <a.abracadabra@example.com>  on Wed Feb 5 14:30:10 2014 +0100
   * Refs #2 - Added Sphinx documentation. by C. Cachemire <c.cachemire@example.com>  on Wed Feb 5 14:23:10 2014 +0100
   * Release 1.0. by D. Doctor <d.doctor@example.com>  on Wed Feb 5 14:07:45 2014 +0100
   * Refs #1 - README introduces project. by D. Doctor <d.doctor@example.com>  on Wed Feb 5 14:07:44 2014 +0100
   * Initialized repository. by D. Doctor <d.doctor@example.com>  on Wed Feb 5 14:04:17 2014 +0100


***********************************
Solution 2: custom views of history
***********************************

Come on! The raw history was not a mess at all: it tells what happened, and
that's its primary purpose. Let's use custom views to display what we want
to...

Use ``--first-parent`` option to check "features", i.e. commits explicitely
performed on master:

.. code:: console

   $> git logp --first-parent --graph master
   * Refs #3 - Enabled continuous integration with TravisCI.org. by D. Doctor <d.doctor@example.com>  on Wed Feb 5 14:30:10 2014 +0100
   * Refs #2 - Added Sphinx documentation. by D. Doctor <d.doctor@example.com>  on Wed Feb 5 14:23:10 2014 +0100
   * Release 1.0. by D. Doctor <d.doctor@example.com>  on Wed Feb 5 14:07:45 2014 +0100
   * Refs #1 - README introduces project. by D. Doctor <d.doctor@example.com>  on Wed Feb 5 14:07:44 2014 +0100
   * Initialized repository. by D. Doctor <d.doctor@example.com>  on Wed Feb 5 14:04:17 2014 +0100

The filtered log above is what you make via "rebase+squash" workflows, isn't
it?

There is a small difference in the authorship:

* in the first case, rebase+squash action was performed by D. Doctor, but he
  preserved authorship of commits in topic branches. We do not have the
  information "who merged".

* in the second case, merge commits in `master` are authored by D. Doctor, who
  performed the merge. Contributors (A. Abracadabra and C. Cachemire) are
  mentioned in history of topic branches.

Notice the filtered log above is the only thing you can get once you have
rebased+squashed. You altered history, you did not keep the original commits.

Using merge commits, you can see the "nice log", but you also get granted
additional features related to original commits. Here are a few:

* you can inspect commits in a topic branch (see notes below);
* in discussions, references to commits and code are not broken;
* you can revert a subset of a feature. Useful in case of a mistake.


*************************************
Key differences: time, responsibility
*************************************

As we saw above, the "nice log" can be displayed whatever the workflow. So
this result is not the main difference between the workflows. Where is the
value?

I think the value of merge-based workflows is the time you spend performing
actions:

* executing a custom log (i.e. ``git customlog``) is as fast as executing
  ``git log``. Some people will tell ``git log`` is the default, so you do not
  need to learn or setup it. That's true. But I think raw ``git log`` is
  definitely more readable with some styling of your own... so I would
  recommend having a custom ``git log`` output anyway. Just make it fit your
  needs ;)

* editing history is longer than merging. When merging, you focus on the
  merge commit: diff and message.

* in case of mistake, merge-based workflow can save you time. You can revert a
  merge and rewind in original history. Whereas with a rebase+squash you only
  have the squashed result, no way to rewind. You certainly are smart enough
  to fix the mistake manually, but in some cases it is easier (and safer) with
  ``git revert`` or ``git reset``. The use case may be rare, but the time you
  spend on it may be big, and the stakes can be big too.

* in some cases, original history saves you time. Sometimes you need to check
  details of a topic branch, or some code design has been tried then reverted
  in topic branch, or some discussion references a commit in topic branch...
  Again, the use case may be rare, but when it occurs, you appreciate having
  the full topic branch history. Else you have to remember, guess or whatever.
  Nothing blocker, but time you could save.

It is also a matter of responsibility: I'd prefer make a mistake in a merge
commit than mess up a rebase+squash. Because I know I can revert a merge, and
I know I preserved other's hard-work. Whereas doing a rebase+squash, I
potentially alter one's contribution.

That's what I called "do not bother with micro commits" in the previous post
`Git history matters`_.


********************************
Merge-based workflows lack tools
********************************

I think merge-based workflows are the way to go... **but** I must admit I do
not know how to implement some features they have.

I mean, **I understand why people complain about merge and promote
"rebase+squash"**: ``rebase -i`` is a powerful `Git` builtin. It looks quite
simple. It produces simple output. And many people use it. Those are good
enough reasons to use rebase+squash workflows.

My point is **we should try, develop and promote merge-based workflows**. It
means collecting or making tools that implement the workflow.

`git-flow`_ is one solution. There could be others with one `master` and N
topic branches.

And, about reading `Git` history, there could be tools that produce nice views
out of any complex raw history.

To display commits in main branch (i.e. `master`), the ``--first-parent``
option is fine.

But while googling on "git log branch", I found:

* `git history visualizations`_, where the README explains the issue...
  and there is no implementation as of 2014-02-11.

* http://stackoverflow.com/questions/1527234/finding-a-branch-point-with-git
  and
  http://stackoverflow.com/questions/14848274/git-log-to-get-commits-only-for-a-specific-branch
  where simple questions get complex answers.

Back to our sample scenario above, as of 2014-02-11, I do not know a simple way
to get the list of commits in `travis` branch after it has been merged. I guess
it could be displayed, but the only way I know is reading the full and raw log
(easier with `gitk` or `gitg`).

Let's stop here today... I presume "git tools for merge-based workflows" is a
quite long story. Perhaps another post...


.. rubric:: Notes & references

.. target-notes::

.. _`Git history matters`: /git-history-matters-en.html
.. _`git-flow`: https://github.com/nvie/gitflow
.. _`git history visualizations`:
   https://github.com/datagrok/git-history-visualizations
