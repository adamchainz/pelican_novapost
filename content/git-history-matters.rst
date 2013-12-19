###################
Git history matters
###################

:date: 2013-12-18 15:00
:tags: git, mercurial
:category: Astuces
:author: Benoît Bryon
:lang: en
:slug: git-history-matters

In many projects, core-committers chose a `Git` workflow: branching policy,
best practices for commit messages, pull-request management... About the
latter, some projects recommend rewriting `Git` history via rebases, squashes,
patches or whatever.

As an example, let's quote `Django documentation about "Handling
pull-requests"`_:

    Use git rebase -i and git commit --amend to make sure the commits have the
    expected level of quality.

    [...]

    Practicality beats purity, so it is up to each committer to decide how much
    history mangling to do for a pull request. The main points are engaging the
    community, getting work done, and having a usable commit history.

At Novapost, `@Natim`_ also promoted a similar workflow in `Successfull git
feature workflow in team`_.

But as you may have noticed, I am a "merge" supporter (see `Merging the right
way`_ and `Psycho-rebasing: merge-based`_ articles in this weblog). I tend to
be suspicious about ``rebase`` and things that rewrite `Git` history.

Recently, we debated this topic with the Novapost team, and also with
`@bmispelon`_ (a Django core-committer).

Today I feel I understood the reasons why some people recommend rewriting
commit history. But I keep on thinking it is not the best practice. I mean,
I share the motivations, but I feel we can do it better without rewriting
history, i.e. using ``merge``...

.. note::

   I am talking about `Git` here, but I guess this story could be adapted to any
   distributed version control system, such as Mercurial.


**********************
Use case: read history
**********************

As a developer, in order to review the changes in a project, I want a readable
log.

Rebase, squash: write a "clean" history
=======================================

One solution to get a readable log is to make it readable, altering it when
necessary.

Let's quote `Django` documentation again:

    When rewriting the commit history of a pull request, the goal is to make
    Django’s commit history as usable as possible

Here are main actions:

* **Improve commit messages**: make them meaningful, standardize them...

      Use [...] ``git commit --amend`` to make sure the commits have the
      expected level of quality

* **Reduce log granularity**: group (squash) related commits, remove "noisy"
  commits.

      If a patch contains back-and-forth commits, then rewrite those into one.
      [...]
      Trivial and small patches usually are best done in one commit.

* **Reduce log tree complexity**: avoid merge commits, avoid nested
  branching...

      Use ``git rebase``
      [...]
      Merge the work as "fast-forward" to master, to avoid a merge commit.

Once the rewrite has been performed, ``git log`` provides "usable" output.
Fine.

Notice that ``Git`` has builtin rebase and squash features. They seem made for
that purpose. Big temptation!

Let's see if I can do similar things without squash and rebase.

.. note::

   Do you really mean "clean history"? IRL, it would sound scary! Hopefully,
   we are talking about `Git` workflows in software development ;)

Merge: clean views of raw history
=================================

Another solution to get a readable log is to filter, order and format the log.
``git log`` accepts various options and arguments for that purpose. And, guess
what, merge-based workflows integrate very well with it.

The "pull-request handling" recommendations based on merge would look like
this:

    When a pull-request is ok, use ``git merge --edit`` to merge it with a nice
    commit message.

And that's all. There is no need to rewrite history. Contributors' commits are
not amended, squashed, rebased or whatever.

Now, how to read the history?
Hmm, it depends... What are you looking for in history?

* Releases: have a look at tags. Or, if you use `git-flow`_, have a look at
  commits in branch "master".

  .. code:: sh

     git tag --list

* Features: have a look at commits in main development branch. Usually it is
  "master", but if you use `git-flow` it is "develop".

  .. code:: sh

     git log --first-parent master

* You want to focus on changes related to one feature/bug/ticket: have a look
  at commits in some feature branch.

  Hmm, looks like "not so easy" with Git, particularly if the branch has been
  merged.

Depending on your workflow, there should be ways to get the views you need.
Once you setup the views, you should be able to reuse them for any project
using the same branching policy or commit workflow.

You control merges, do not bother with "micro" commits
======================================================

Lambda contributors (not core-committers) tend to perform incomplete commits
with "poor" messages. That is not a big problem. That does not require you
spend time to improve their messages or squash their commits. Because you can
make it clean by merging.

If you want a feature to be summarized in one "clean" commit, then the easiest
way is to have a clean merge commit: includes all changes, have a nice message.

I mean, as a core-committer of some project, you do not control contributors'
work, whereas you control the merges in "master" branch. Trying to control
contributors' commits, core-committers tend to alter history (rebase, squash).
First of all, it is unnecessary: setting a clean commit message yourself after
the review is easier and faster. Then it is not safe (see `Recent history
matters`_ above). Finally, IMHO, it involves more brain-efforts than a merge.

Recent history matters
======================

Because recent commits may be used to revert changes, bisect, blame, discuss...

Of course, definition of "recent" depends on your workflow:

* commits in a "feature" branch may be useful until the branch is merged in
  "master" branch.

* commits in "feature" branch may be useful until the next release, because
  tickets can be reopened before release.

* after a release, granularity in feature branches usually have less value.

With this idea in mind, I would be suspicious about ``rebase`` and ``squash``,
because they rewrite history. But let's consider more points...

Optionally clean long-term history
==================================

Some people feel that, six month later, granularity is no longer valuable.
You may setup a script that automatically cleans "old" history. As an example,
you could squash or delete commits in feature branches and keep only commits in
master (usually merge commits).

But keep in mind this is potentially harmful, and usually unnecessary. Except
perhaps for very big projects where history consumes disk space.


***********************************
Use case: release notes (CHANGELOG)
***********************************

Some people like using ``git log`` to build CHANGELOG. As a matter of fact,
``git log`` is helpful to create CHANGELOG.

But **`Git` log is not CHANGELOG.**

If you can automatically build CHANGELOG out of ``git log``, do not maintain
CHANGELOG. Just tell "see git log".

But I feel ``git log`` is not not enough in most cases:

* Sometimes several commits relate to a single ticket (feature, bugfix).

* Sometimes a single commit relates to several tickets.

* Tickets may be more pertinent, and more "human readable".

* Release notes do not only list changes. They explain upgrade procedure. They
  are kind of editorial content.

In fact, I feel release notes (or CHANGELOG file) are part of the
documentation. So they should be part of "definition of done", i.e. included
in commits as changes in code. It means that, in master branch, release notes
should always be up to date.


****************************************
Use case: list of contributors (AUTHORS)
****************************************

As a developer, when I committed in project code, then I appreciate my name
is mentioned in `Git` log.

This can be done preferring squash (rebase) to merge: when you rebase, you
preserve authorship. Whereas when you merge as a core-committer, you author the
merge commit... so the authorship may be altered if you rewrite history later.

First of all, as explained above, rewriting history is usually unnecessary (and
potentially harmful).

But **`Git` log is not AUTHORS.**. ``git log`` is not enough.

There are situations where contributors cannot be mentionned as commit authors:

* pair-programming: only one developer appears as commit author. Pair can be
  mentioned in commit message, but not as commit author.

* merging a third-party: there are many situations where you include code from
  a snippet, stackoverflow.com, or from a third-party project. In such cases,
  you author the commit and do not import history from third-party. Of course,
  you can mention contributors in commit message.

* actions outside codebase: ticket submission, ticket review, triage, support
  on mailing lists... You could be a famous contributor without having
  committed code.

Of course `Git` log (or `Git`hub's contributors page) is helpful to build some
AUTHORS file. But, IMHO, it is not enough. I mean, if we do care about
contributors, let's maintain some AUTHORS file, or code something that
highlights contributions:

* "committers", see `Git`hub's contributors page
* bug reporters
* active users in bug tracker
* special mentions and thanks from AUTHORS file
* ... and perhaps more, depending on your project.

As a matter of fact, maintaining AUTHORS file is a tedious task, and we would
appreciate tools that make it easier.

I feel that `Git` log is not enough for that purpose. And I feel that building
tools to highlight contributors would be easier (and safer) than editing `Git`
history. As a core-committer of some project, I do not want to think about
contributors every time I merge a pull-request. I would appreciate some
tool that does it automatically, or helps me do it in a snap. Moreover, I guess
such a tool could be reused for many projects.


***********************************************
Conclusion: merge, do not rebase, do not squash
***********************************************

Did I missed some points?

Else, I keep on believing ``merge`` is the way to go. I cannot find an use case
where ``merge`` does not fit, whereas I know use cases where ``rebase`` and
``squash`` are harmful, because they alter history.

The counterpart is we need to setup some tools:

* smart views to review history;
* nice views to highlight contributors;
* merge-based rebase: check the `psykorebase prototype`_.

.. target-notes::

.. _`Django documentation about "handling pull-requests"`:
   https://docs.djangoproject.com/en/1.6/internals/contributing/committing-code/#handling-pull-requests
.. _`@Natim`: https://twitter.com/natim
.. _`Successfull git feature workflow in team`: /git-workflow-en.html
.. _`Merging the right way`: /merging-the-right-way-en.html
.. _`Psycho-rebasing: merge-based`: /psycho-rebasing-en.html
.. _`@bmispelon`: https://twitter.com/bmispelon
