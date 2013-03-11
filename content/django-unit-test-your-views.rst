###########################
Unit test your Django views
###########################

:date: 2013-03-07 10:00
:tags: django, testing
:category: Python
:author: Benoît Bryon
:lang: en
:slug: django-unit-test-your-views

How to test views of a Django application?

Django's builtin test client is not suitable for unit testing! It performs
system tests: it handles your views as a black box in a project's environment.

This article provides a recipe for developers to replace Django's builtin test
client by smaller, fine-grained, view-centric tests.


***********************************************
self.client.get(): system tests for the unaware
***********************************************

Here are some reasons why Django's builtin client performs system tests:

* it resolves URLs,
* it traverses middlewares,
* it traverses decorators,
* it uses template context processors,
* it relies on settings,
* ... and perhaps more. Who knows? Do you really want to know?

All the stuff above is not the view, it is the environment surrounding the
view.

It means that, **by using the test client, you don't test the view itself, but
the system the view is part of**. And the environment is quite hard (and
boring) to control.

Here, we want to focus on the view, so let's emancipate from all those third
party mechanisms.


**********************
Testing view functions
**********************

Let's consider this simple view:

.. code-block:: python

   from django.http import Http404, HttpResponse

   def hello(request, name):
       if name == u'Waldo'
           raise Http404("Where's Waldo?")
       return HttpResponse(u'Hello {name}!'.format(name=name))

Then test it:

.. code-block:: python

   import unittest

   class HelloTestCase(unittest.TestCase):
       def test_get(self):
           """hello view actually tells 'Hello'."""
           # Setup.
           request = 'fake request'
           name = 'world'
           # Run.
           response = hello(request, name)
           # Check.
           self.assertEqual(response.status_code, 200)
           self.assertEqual(response.content, u'Hello world!')

       def test_waldo(self):
           """Cannot find Waldo to tell him 'Hello'."""
           # Setup.
           request = 'fake request'
           name = 'Waldo'
           # Run and check.
           self.assertRaises(Http404, hello, request, name)

Pretty simple isn't it?

Really, you don't need Django's builtin test client to write such tests!


***********************************************
Use unittest or SimpleTestCase wherever you can
***********************************************

In the `example above <./#testing-view-functions>`_, we didn't hit the database,
so there were no reasons to use `django.test.TransactionTestCase`_ or
derivatives.

With such a configuration, tests run really fast!

.. note::

   Performance is another reason you should avoid Django's builtin test client.
   But that's another story.

Wherever you can, use unittest, or `django.test.SimpleTestCase`_.


*****************************
Don't decorate views in place
*****************************

The `"hello" example above <#testing-view-functions>`_ would have been broken if
the view were decorated in place. As an example:

.. code-block:: python

   from django.http import Http404, HttpResponse
   from django.contrib.auth.decorators import login_required

   @login_required
   def hello(request, name):
       if name == u'Waldo'
           raise Http404("Where's Waldo?")
       return HttpResponse(u'Hello {name}!'.format(name=name))

How can we test ``hello()`` view now?

We would have to perform (mock) a login, and we would have to check the
response with or without authentication. As a consequence, our tests would
become longer, less readable, less efficient... Moreover, what if the ``login``
decorator has bugs or changes? It would break ``hello``'s tests even if
``hello`` itself doesn't change. How bad!

So, **don't decorate views in place**.

Instead:

* decorate views somewhere related to URLconfs (urls.py), not related to views.
* have specific tests for decorators, i.e. validate ``login_required`` works.
* have specific tests for URLconfs, i.e. validate ``login_required`` is applied
  to ``hello`` in project's configuration (this is a system test).


*********************
Use request factories
*********************

`Django's builtin test client is a special kind of request factory`_, which
uses URL resolution to trigger the views (deep inside the system).
Now we have isolated views from system. But a view still takes a request as
argument. How to get a request?

In the `function-based example above <#testing-view-functions>`_, we used a
completely fake request.
But sometimes you can't do that and need a ``HttpRequest``.

Django provides `django.test.RequestFactory`_ to mock requests.

With a request factory, you get a request instance you can pass as argument
to views' methods such as ``dispatch()``.

.. code-block:: python

   from django.test import RequestFactory

   request_factory = RequestFactory()
   request = request_factory.post('/fake-path', data={'name': u'Waldo'})

.. note::

   Some notes about request factories, which could make a full article...

   * Django's builtin RequestFactory requires one positional argument: path.
     But, in the scope of tests of this article, we really don't care about
     the path. The path is mandatory for the test client to resolve URLs...
     So, unless your view actually uses the ``path`` argument, you can safely
     use a fake value.

   * If your view uses the messages framework, you'll need to setup (or mock)
     ``request._messages``. Notice that's a feature, since messages should
     be tested too ;)

   * Idem about session: you may need to mock ``request.session`` if your
     view depends on the session.

   * Yes, you are now aware of your view's dependencies :)

*************************
Testing class-based views
*************************

Once we got rid of Django's builtin test client, we can consider views
themselves. How do they look like?

Function-based views look like black boxes: things that take a request and
return a response. No way to test internals.

With class-based views, we have various methods and attributes. So we can write
fine-grained tests!

The idea here is to **test every custom method or attribute of the class-based
views you write**.

Let's consider the following view:

.. code-block:: python

   class HelloView(TemplateView):
       def get_context_data(self, **kwargs):
           kwargs = super(HelloView, self).get_context_data(**kwargs)
           kwargs.update('name', self.kwargs.get('name'))
           return kwargs

And let's consider we'd like to reproduce this URLconf scenario:

* view: ``hello = HelloView.as_view(template_name='hello.html')``
* URL: ``url(r'(?P<name>\w+)', hello)``

``as_view()`` is not enough
===========================

Testing class-based views using ``as_view()`` and ``RequestFactory`` is now
described in Django's documentation along with `django.test.RequestFactory`_:

.. code-block:: python

   import unittest
   from django.test import RequestFactory

   class HelloViewTestCase(unittest.TestCase):
       def test_get(self):
           """HelloView.get() sets 'name' in response context."""
           # Setup name.
           name = 'peter'
           # Setup request and view.
           request = RequestFactory().get('/fake-path')
           view = HelloView.as_view(template_name='hello.html')
           # Run.
           response = view(request, name=name)
           # Check.
           self.assertEqual(response.status_code, 200)
           self.assertEqual(response.template_name[0], 'home.html')
           self.assertEqual(response.context_data['name'], name)

Ok, it works. But, in the ``HelloView`` above, I just overrid the
``get_context_data()`` method. So I'd like to test only that. I mean, status
code and template name are features inherited from TemplateView, and they are
covered by TemplateView's test suite.

We can't use ``as_view()`` to perform fine-grained testing.

One issue with ``as_view()`` is that it returns a function, not an instance
of the view class. And this callable is a proxy to view's ``dispatch()``, which
involves almost all view's methods, depending on the arguments.

Using ``as_view()`` in tests is the same as having a function-based view.
You don't really take advantage of the class-based view.

Alright, let's get rid of ``as_view()`` and focus on ``get_context_data()``...

Mimic ``as_view()``
===================

Here is a simple replacement for ``as_view()``:

.. code-block:: python

   def setup_view(view, request, *args, **kwargs):
       """Mimic as_view() returned callable, but returns view instance.

       args and kwargs are the same you would pass to ``reverse()``

       """
       view.request = request
       view.args = args
       view.kwargs = kwargs
       return view

Here is how to use it in a test:

.. code-block:: python

   import unittest
   from django.test import RequestFactory

   class HelloViewTestCase(unittest.TestCase):
       def test_context_data(self):
           """HelloView.get_context_data() sets 'name' in context."""
           # Setup name.
           name = 'django'
           # Setup request and view.
           request = RequestFactory().get('/fake-path')
           view = HelloView(template_name='hello.html')
           view = setup_view(view, request, name=name)
           # Run.
           context = view.get_context_data()
           # Check.
           self.assertEqual(context['name'], name)

That's all. What happened?

* Just tested the ``get_context_data`` method which we overrid. Other methods
  inherited from ``TemplateView`` are covered by ``TemplateView`` test suite.

* We used unittest since there is no transaction involved.

The fairy ``as_view()`` and the ugly ``dispatch()``
===================================================

Let's end with a story about ``as_view()`` magic.

Using as_view() is quite elegant:

.. code-block:: python

   request = RequestFactory().get('/fake-path')
   view = HelloView.as_view(template_name='hello.html')
   response = view(request, name='bob')

Using ``dispatch()`` is ugly:

.. code-block:: python

   request = RequestFactory().get('/fake-path')
   view = HelloView(template_name='hello.html')
   view = setup_view(view, request, name='bob')
   response = view.dispatch(view.request, *view.args, **view.kwargs)

Got it? ``dispatch()`` receives arguments the instance already knows...

Diving into fine-grained tests on Django-style class-based views may awake
trolls. Billy-Thread-Safe, Kate-Instance and Frank-Class-Attribute may join the
party soon ;)

In fact, it looks like Django's class-based views haven't been designed to be
fine-grained tested.

If your are curious, have a look on Django's tests...

* At
  https://github.com/django/django/blob/1.5/tests/regressiontests/generic_views/base.py#L278
  nothing proves we are testing a ``TemplateView``. It relies on the URLconf.
  Calling view's ``get_context_data()`` may have been more efficient and
  readable.

* At
  https://github.com/django/django/blob/1.5/tests/regressiontests/generic_views/base.py#L67
  are we really testing the queryset? It seems we are testing the queryset and
  the context data and the status code and the template name and the URL
  configuration and... all in a row.

  There could be one test around default ``get_queryset()`` to check that it
  returns ``Author.objects.all()``. Then another test around
  ``get_context_data()`` to check that the queryset (a fake queryset that
  doesn't hit the database) is registered in context.

* and soooooo many tests that handle views (or system) as black boxes...


***********
What's next
***********

Since you test your views as isolated items, you have to test everything else:
middlewares, decorators, context processors, models...

And you can fake/mock many things inside tests of views, so that you don't rely
on database, settings, ...


**********
References
**********

.. target-notes::

.. _`django.test.TransactionTestCase`:
    https://docs.djangoproject.com/en/1.5/topics/testing/overview/#transactiontestcase
.. _`django.test.SimpleTestCase`:
    https://docs.djangoproject.com/en/1.5/topics/testing/overview/#simpletestcase
.. _`Django's builtin test client is a special kind of request factory`:
   https://github.com/django/django/blob/56e54727661bc34bd2b6f9fa6a75f5370149256e/django/test/client.py#L345
.. _`django.test.RequestFactory`:
   https://docs.djangoproject.com/en/1.5/topics/testing/advanced/#django.test.client.RequestFactory
