##########################
A Django testing challenge
##########################

:date: 2013-03-12 12:00
:tags: django, testing
:category: Python
:author: Benoît Bryon
:lang: en
:slug: django-testing-challenge

Here at Novapost, we have quite large Django projects. Big projects mean big
maintenance. Hopefully, those projects are covered by tests. Thousands of
tests. We are quite proud of this fact. Tests save our lives. But we also have
some worries and need to improve... Here is our testing challenge!


**************
Some issues...
**************

Here are some problems we encounter...

Performance
===========

In the biggest project, our continuous integration service can't run a full
test suite in less than one hour. That's embarrassing, because we can't wait
for global test results before we commit.

We'd like a collection of tests that run fast and give us the status of most of
the project. So that we can run it before we commit. Then the continuous
integration service would cover the rest.

Maintenance
===========

When we change a feature, it sometimes has side effects on some tests which
seem unrelated. It looks like our tests involve much more than necessary.
Not only it affects performance, but it also affects maintenance: sometimes
we know something is wrong because tests fail, but we cannot tell exactly
what's wrong. And finally, we have to adapt several tests for only one feature.

We'd like tests to focus on small units, so that, when something goes wrong,
tests help us figure out what's exactly wrong. And we'd like to change only
what's really related.

Tests pass, deployment fail
===========================

Sometimes tests are not enough: we fix things, but we can't tell if the fix
works after an upgrade. As an example, changes that involve settings are hard
to cover with tests: once the fix is committed and pushed, the story cannot be
closed before we make sure the configuration has been updated and everything is
ok on servers. We are doing some manual checks...

We'd like to involve more into deployment, supervision and monitoring, so that
we can automate some checks related to the issues or features we develop.


*************
Some clues...
*************

We already have some ideas about what's wrong with our testing strategy. Here
are some hypotheses:

* one cause of those long test suites is the heavy use of ``self.client.get()``
  aka functional/system test for the unaware ;

* we could mock/fake more things ;

* we could separate tests that run fast from tests that run slow ;

* we could split our big all-in-one test suite into smaller parts: unit tests,
  functional tests, integration tests, health checks...


***********
A challenge
***********

We are aware of some issues with our testing strategy and have some ideas...
**Let's improve!**

We started teamwork as a challenge:

* try various improvements when we implement features or fix bugs ;
* adopt improvements that work, measure how it improves things ;
* give feedback on the blog!

We are to share experience on this blog, through several articles with the
`testing tag </tag/testing.html>`_.

Here are articles we already posted:

* `unit test your Django views <|filename|django-unit-test-your-views.rst>`_
* `testing Django view decorators <|filename|django-testing-view-decorators.rst>`_
* ... to be continued...


********
See also
********

* The `"Fast test, slow test" presentation by Gary Bernhardt
  <https://www.youtube.com/watch?v=RAxiiRPHS9k>`_ is a must see!
