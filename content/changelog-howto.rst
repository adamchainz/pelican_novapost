#####################
Maintaining CHANGELOG
#####################

:date: 2014-08-29 14:30
:tags: git, changelog, history
:category: Astuces
:author: Benoît Bryon
:lang: en
:slug: changelog-howto

At PeopleDoc, in our development workflow, many questions came about CHANGELOG:
what to put in CHANGELOG? How to maintain CHANGELOG and make sure it stays up
to date? How do releases affect CHANGELOG? ...

In this article, I'll try to share my experience on the topic, as a base for
discussions, and perhaps as a reference for implementations.


*******************************************
CHANGELOG is human-readable project history
*******************************************

I expect CHANGELOG to explain a project's history to users (humans! not bots).

As I said in a previous `post about git history`_, I think that:

* CHANGELOG is part of the documentation. It is some editorial content.
  Tip: I usually `include CHANGELOG into Sphinx documentation`_.

* ``git log`` is not the appropriate tool to generate CHANGELOG. It can be
  used as a start, but needs review.

Here is a sample CHANGELOG content (from `piecutter`_ project), written in
reStructuredText for `Sphinx`_:

.. code-block:: rst

   Changelog
   =========

   This document describes changes between each past release. For information
   about future releases, check `milestones`_ and :doc:`/about/vision`.


   0.2 (unreleased)
   ----------------

   - Nothing changed yet.


   0.1.1 (2014-04-09)
   ------------------

   Fixes around distribution of release 0.1.

   - Bug #12 - piecutter archive on PyPI was missing many files.


   0.1 (2014-04-08)
   ----------------

   Initial release.

   - Feature #6 - Imported stuff from diecutter: loaders, writers, resources and
     engines.


   .. rubric:: Notes & references

   .. target-notes::

   .. _`milestones`: https://github.com/diecutter/piecutter/issues/milestones

Of course, this CHANGELOG could be improved. As an example with some links
to the bugtracker for each feature/bugfix. Or with additional information about
how to upgrade from one version to another. But you get the idea: the content
is quite simple, explains briefly the changes, and is human-readable. It is
**not** a commit history.

How to maintain such a CHANGELOG?


*********************************************
Maintain CHANGELOG as you merge pull-requests
*********************************************

**At first, I tried to update the CHANGELOG inside the topic branches, before
they are merged**, so that I was able to merge the topic branch using Github's
"merge pull-request" button. This is easy and cool... when you are the only
contributor!

When you work in a team, or receive pull-requests from community, maintaining
CHANGELOG in topic branches becomes harder:

* contributors rarely care about CHANGELOG. Often, this is because they
  do not know well your workflow, even if you documented it in a
  contributor guide.

* as a core-committer, you care about CHANGELOG, but usually you do not edit
  the pull-request's contents: you ask the contributor to update the code...

* ... partly because with Github it is not so easy to pull-request a topic
  branch that lives in a fork. But that's another story.

As a consequence, pull-requests take longer to be merged because of some weird
issues such as CHANGELOG, typos or wording.

Of course it is nice if the pull-request meets your quality requirements and
you do not need to edit the code. But communication with the contributor takes
time and sometimes it introduces excessive latency compared to the value of the
changes. What a waste of energy!

**Now, I merge pull-requests manually, and maintain CHANGELOG in the merge
commit**:

* I no longer use Github's "merge pull-request" button!

* I enter my development environment for the project, on my computer

* I ``git remote add {FORK} {FORK_URL}`` then ``git fetch {FORK}`` to download
  the topic branch

* I ``git checkout -b {TOPIC}`` and do a full review, such as run the tests.

* I ``git checkout master && git merge --no-ff --no-commit {TOPIC}``,
  i.e. merge but do not commit yet.

* I edit the CHANGELOG, then ``git commit -am "{CHANGE_SUMMARY}"``,

* and finally ``git push origin master`` to close the pull-request.

That way, the **CHANGELOG in master is always up to date**. It is quick and
really clean.

As a bonus, having a merge commit with a smart message makes the
``git log --first-parent`` really useful: it is the fastest, easiest and
safest recipe I know (at the moment) to keep the Git history readable. But
that's another story I already mentioned in `git history matters`_.


***********************************************
Automatically update the dates when you release
***********************************************

So, CHANGELOG in master is always up to date. Now let's do a release!

In the example above, the latest "in-development" release has "unreleased"
instead of a date. In Python projects, I use `zest.releaser`_ to update the
date, upgrade version numbers and push the code on both PyPI and Github.

Since the CHANGELOG is ok, this is just one command:

.. code-block:: sh

   fullrelease

In most cases, ``fullrelease --no-input`` is fine too! It is faster :)


*******************************************
Automatically release when you merge master
*******************************************

I haven't tried this recipe yet, but I think this is the next step...

Since the release is just one command, what about automating the release
process? This could be a great step on the road to continuous deployment!

I think I will try the following scenario:

* for each merge in master, continuous build platform (aka Travis-ci.org)
  performs a release, either a "patch" (1.0.1, 1.0.2, 1.0.3...) or a minor
  (1.1, 1.2, 1.3...) release.

* I still can perform major (1.0, 2.0...) or minor releases manually, when
  changes are significant enough.

.. note::

   Releases are not automatically published for each commit! Releases are
   (automatically) triggered after a (manual) merge/push in master branch. As a
   human, you keep control on the merge operation. The idea is that the value
   lives in the merge which involves human review, then other tasks can be
   performed by bots.

Of course, this release policy has to be explained in documentation (in
CHANGELOG itself?).

And it requires to care about what is merged into master branch... Because a
broken master would mean a broken release. But I believe this is a good
philosophy: make sure the master branch is stable!

See you when I try it ;)


.. target-notes::

.. _`post about git history`:
   http://tech.novapost.fr/git-history-matters-en.html#about-release-notes-changelog
.. _`include CHANGELOG into Sphinx documentation`:
   https://github.com/diecutter/sphinx-quickstart/blob/master/template/docs/about/changelog.txt
.. _`piecutter`: https://piecutter.readthedocs.org/
.. _`Sphinx`: http://sphinx-doc.org/
.. _`git history matters`:
   http://tech.novapost.fr/git-history-matters-en.html
.. _`zest.releaser`: http://zestreleaser.readthedocs.org/
