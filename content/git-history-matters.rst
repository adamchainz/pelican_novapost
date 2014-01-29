###################
Git history matters
###################

:date: 2014-01-30 09:00
:tags: git, merge, rebase
:category: Astuces
:author: Benoît Bryon
:lang: en
:slug: git-history-matters

In many projects, core-committers chose a `Git` workflow: branching policy,
best practices for commit messages, pull-request management... About the
latter, some people recommend rewriting `Git` history via rebases, squashes,
patches... As an example, let's quote `Django documentation about "Handling
pull-requests"`_:

    Use git rebase -i and git commit --amend to make sure the commits have the
    expected level of quality.

    [...]

    Practicality beats purity, so it is up to each committer to decide how much
    history mangling to do for a pull request. The main points are engaging the
    community, getting work done, and having a usable commit history.

At Novapost, `@Natim`_ also promoted a similar workflow in `Successful git
feature workflow in team`_.

But as you may have noticed, I am a "merge" supporter (see `Merging the right
way`_ and `Psycho-rebasing: merge-based`_ articles in this weblog). I tend to
be suspicious about ``rebase`` and things that rewrite `Git` history.

Recently, we debated this topic (again) with the Novapost team, and also with
`@bmispelon`_ (a `Django` core-committer). At last, I think I understood the
reasons why some people recommend rewriting commit history. That said, I keep
on thinking it is not the best practice. I mean, I share the motivations, but
I think we can (and should) do it better without rewriting history, i.e. using
``merge``.

Let's consider the two workflows. As a developer, in order to review the
changes in a project, I want a readable log...


************************************
Rebase, squash, amend: clean history
************************************

One solution to get a readable log is to make it readable, altering it when
necessary.

Let's quote `Django` documentation again:

    When rewriting the commit history of a pull request, the goal is to make
    `Django`'s commit history as usable as possible

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

.. note::

   `Git` has builtin rebase and squash features. It looks like they are made
   for that purpose. I think this is a big advantage versus merge-based
   workflows. Let's develop that point in `Rebase is a Git builtin`_ below.

Now, let's see if I can do similar things without squash and rebase...

.. note::

   Do we really mean "clean history"? IRL, it would sound scary! Hopefully,
   we are talking about `Git` workflows in software development ;)


*********************************
Merge: clean views of raw history
*********************************

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
It depends... What are you looking for in history?

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

  If  feature branch has not been merged or deleted yet:

  .. code:: sh

     git log master...feature-branch

  I currently do not know how to achieve this when branch has been merged in
  master, but I guess it is possible.

* You want to focus on detailed changes: do not filter log.

  .. code:: sh

     git log

The idea is that, once you know your workflow, you can setup views to get the
log you need. Once the views have been setup, you should be able to reuse them
for any project with a similar workflow.

What is important here is that, using ``merge``, you decrease daily efforts in
maintaining history, whereas you put one-time efforts into customizing smart
log views...


******************************************************
You control merges, do not bother with "micro" commits
******************************************************

As a matter of fact, lambda contributors (not core-committers) tend to submit
incomplete commits with low quality messages. But it is not a big problem and
it should not require core-contributors spend time to improve their messages
or squash their commits. Because core-contributors can merge with a
high-quality commit message.

    The main points are engaging the community, getting work done, and having a
    usable commit history.

* Merge commits make the history usable.

* Core-committer have better focus on the pull-request result (i.e. on the
  contents of merge commits) than on the way this result was produced.

* Discussions around pull-request result have higher value than discussions
  around commit units.

  Of course, if contributors submit commits with a smart scope and a nice
  message, then it is fine. But core-contributors should not bother too much
  about it. What matters is the quality of the result that is actually merged
  in main branch.

* Core-committers do not need to put efforts into rearranging contributors'
  commits. This is big responsibility with low value. Moreover, it could be
  cause of errors.


**********************
Recent history matters
**********************

Because recent commits may be used to revert changes, bisect, blame, discuss...

Of course, definition of "recent" depends on your workflow:

* commits in a topic branch may be useful until the branch is merged in main
  branch.

* commits in topic branch may be useful until the next release, because tickets
  can be reopened before release.

* after a release, granularity in feature branches usually has less value. But
  is it an issue?

Workflows that rewrite history obviously break this feature, whereas
``merge``-based workflows preserve it.


**********************************
Optionally clean long-term history
**********************************

.. warning:: This is potentially harmful, and unnecessary for most projects.

Some people think that, six month later, granularity is no longer valuable.

At first, I would say that, since it is trivial to focus on merge-commits,
granularity is not a problem.

But it could become a problem on some big projects, where history is huge and
consumes too much disk space. In such a case, you may setup a script that
automatically cleans "old" history. As an example, you could squash or delete
commits in topic branches that have been merged more than six months ago, and
keep only merge commits in master.

Just keep in mind this is potentially harmful, and unnecessary for most
projects. It is an edge case.


*******************************
About release notes (CHANGELOG)
*******************************

Some people like using ``git log`` to build CHANGELOG. As a matter of fact,
``git log`` is helpful to create CHANGELOG.

Some people argue that altering commit history makes it easier to generate, or
pre-generate CHANGELOG.

I would say that if you can automatically build CHANGELOG out of ``git log``,
then do not maintain CHANGELOG. If ``git log`` is enough, you do not need
another tool.

That said, I think  **Git log is not CHANGELOG** in most cases, i.e. ``git
log`` is not enough:

* Sometimes several commits relate to a single ticket (feature, bugfix).

* Sometimes a single commit relates to several tickets.

* Tickets may be more pertinent, and more "human readable".

* Release notes do not only list changes. They explain upgrade procedure. They
  are kind of editorial content.

In fact, I think release notes (or CHANGELOG file) are part of the
documentation. So they should be part of "definition of done", i.e. included
in commits as changes in code. It means that, in master branch, release notes
should always be up to date.


************************************
About list of contributors (AUTHORS)
************************************

As a developer, when I committed in project code, then I appreciate my name
is mentioned in `Git` log.

This can be done preferring squash (rebase) to merge: when you rebase, you
preserve authorship. Whereas when you merge as a core-committer, you author the
merge commit... so the authorship may be altered if you rewrite history later.

First of all, as explained above, rewriting history is usually unnecessary (and
potentially harmful). So in most cases, merge does not alter authorship.

Then **Git log is not AUTHORS.**. ``git log`` is not enough.

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

Of course `Git` log (or Github's contributors page) is helpful to build some
AUTHORS file. But, IMHO, it is not enough. I mean, if we do care about
contributors, let's maintain some AUTHORS file, or code something that
highlights contributions:

* "committers", see Github's contributors page
* active users in bug tracker
* special mentions and thanks from AUTHORS file
* ... and perhaps more, depending on your project.

As a matter of fact, maintaining AUTHORS file is a tedious task, and we would
appreciate tools that make it easier.

I think that `Git` log is not enough for that purpose. And I think that
building tools to highlight contributors would be easier (and safer) than
editing `Git` history. As a core-committer of some project, I do not want to
think about contributors every time I merge a pull-request. I would appreciate
some tool that does it automatically, or helps me do it in a snap. Moreover, I
guess such a tool could be reused for many projects.


***********************
Rebase is a Git builtin
***********************

As you noticed, I am trying to promote ``merge``. I think we can improve our
workflows using merge instead of rebase/squash.

That said, I think there is at least one BIG reason why rebase is sooo popular:
``rebase`` is a `Git` builtin.

Yes, ``merge`` is a `Git` builtin too. But ``rebase`` does more than ``merge``.
``rebase`` is a sequence, whereas ``merge`` is an unit. I mean, ``rebase``
automatically implements a workflow, whereas ``merge`` is part of a manual
workflow.

The merge-based solutions I explained in this article are not builtins. They
are solutions you must implement yourself. There may be some implementations on
the internet, but they are not the reference, they are not built in `Git`.
As a consequence, ``rebase`` looks smart and ``merge`` looks tedious.

In fact, I think ``merge``-based workflows lack a good (and famous) toolkit to
beat ``rebase``-based workflows...


******************************
Improve with merge-based tools
******************************

I used to think ``rebase`` was an anomaly, because it gives immediate capability
to alter the history. Many ``rebase`` users do not understand what they are
actually doing. Even if I understand why some people like rebase, I dislike
the fact that a workflow that implicitely alters history is the easiest to use
and the most widely promoted.

Now, I think the problem is I do not know a dead-simple alternative which is
based on ``merge``. I mean, I cannot argue in "rebase VS merge" discussions
while the only merge-based alternative I have is "do-it-yourself".

I wish we had:

* some merge-based tool that reproduces the rebase concept (merge commits on
  top of another branch). I started `psykorebase`_ for that purpose (it is
  just a proof of concept right now).

* some tools that provide nice history views, taking advantage of
  merge-commits. Both command-line and a web viewers would be welcome.
  As an example, Github's log view is not enough.

And that may be enough to promote ``merge``!


******************
Conclusion: merge!
******************

Did I miss some points?

Else, I keep on believing ``merge`` is the way to go. I cannot find an use case
where ``merge`` does not fit, whereas I know use cases where ``rebase`` and
``squash`` are harmful, because they alter history.

The counterpart is we need to setup some tools... But aren't we developers?
Or perhaps some tools already exists?


.. target-notes::

.. _`Django documentation about "handling pull-requests"`:
   https://docs.djangoproject.com/en/1.6/internals/contributing/committing-code/#handling-pull-requests
.. _`@Natim`: https://twitter.com/natim
.. _`Successful git feature workflow in team`:
   /successfull-git-feature-workflow-in-team.html
.. _`Merging the right way`: /merging-the-right-way-en.html
.. _`Psycho-rebasing: merge-based`: /psycho-rebasing-en.html
.. _`@bmispelon`: https://twitter.com/bmispelon
.. _`git-flow`: https://github.com/nvie/gitflow
.. _`psykorebase`: https://github.com/benoitbryon/psykorebase
