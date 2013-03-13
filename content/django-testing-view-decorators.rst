#########################
Testing Django decorators
#########################

:date: 2013-03-14 10:00
:tags: django, testing
:category: Python
:author: Benoît Bryon
:lang: en
:slug: django-testing-view-decorators

How to test view decorators of Django applications? Here are some tips. 

In a post before, I recommended to avoid decorating views in place (i.e. not
in views.py). Once decorators and views are separated, we can `unit test the
views <|filename|django-testing-view-decorators.rst>`_. That was the topic of
the post before. This article focuses on testing decorators.

The examples described below are available as a Python file at
https://gist.github.com/benoitbryon/5156512


*****************
Use unittest.mock
*****************

Learn about `unittest.mock`_ (or backward-compatible `mock`_) library!
This article makes heavy use of those wonderful features.

In ``tests.py``:

.. code-block:: python

   try:
       from unittest import mock
   except ImportError:
       import mock

And in project's or app's ``setup.py``:

.. code-block:: python

   # ...
   requirements = []
   try:
       from unittest import mock
   except ImportError:
       requirements.append('mock')
   # ...
   setup(
       # ...
       install_requires(requirements),
       # ...
   )


****************
Fake the request
****************

We want to focus on the decorator. Does it rely on the request to perform
some actions? Fake/stub/mock all and only what you need.

`django.test.RequestFactory`_ can be useful.
But sometimes it is overkill and `django.http.HttpRequest`_ is enough.

In the `hello world example <#hello-world-decorator>`_ below, we'll use a
completely fake request:

.. code-block:: python

   request = 'fake request'

In the `authenticated_user_passes_test example
<#authenticated-user-passes-test-decorator>`_ below, we use mocks to support
``request.user.is_authenticated()``:

.. code-block:: python

   request = mock.MagicMock()
   request.user.is_authenticated = mock.MagicMock(return_value=True)


***********************
Stub the decorated view
***********************

We want to focus on the decorator. We don't care about decorated view
implementation. But we care about how the decorator handles the view.
Let's use `unittest.mock`_.

Decorated views are functions (or callables).
We can instantiate and check a mocked-view like this:

.. code-block:: python

   import unittest

   class MockViewTestCase(unittest.TestCase):
       def test_stub(self):
           # Setup.
           request = 'fake request'
           view = mock.MagicMock(return_value='fake response')
           # Run.
           response = view(request)
           # Check.
           view.assert_called_once_with(request)
           self.assertEqual(response, view.return_value)


*********************
hello_world decorator
*********************

Before we dive into a real-life example, let's consider a really simple one.

Here is the decorator:

.. code-block:: python

   from django.http import HttpResponse

   def hello_world(view_func):
       """Run the decorated view, but return "Hello world!"."""
       def decorated_view(request, *args, **kwargs):
           view_func(request, *args, **kwargs)
           return HttpResponse(u'Hello world!')
       return decorated_view

Here is the test case:

.. code-block:: python

   import unittest

   class HelloWorldTestCase(unittest.TestCase):
       def test_hello_decorator(self):
           """hello_world decorator runs view and returns greetings."""
           # Setup.
           request = 'fake request'
           request_args = ('foo', )
           request_kwargs = {'bar': 'baz'}
           view = mock.MagicMock(return_value='fake response')
           # Run.
           decorated = hello_world(view)
           response = decorated(request, *request_args, **request_kwargs)
           # Check.
           # View was called.
           view.assert_called_once_with(request, *request_args, **request_kwargs)
           # But response is "Hello world!".
           self.assertEqual(response.status_code, 200)
           self.assertEqual(response.content, u"Hello world!")

The test looks like a documentation for the decorator :)


****************************************
authenticated_user_passes_test decorator
****************************************

Now let's consider a real-life example, with a custom decorator:

.. code-block:: python

   from functools import wraps

   from django.utils.decorators import available_attrs

   def authenticated_user_passes_test(test_func,
                                      unauthorized=UnauthorizedView.as_view(),
                                      forbidden=ForbiddenView.as_view()):
       """Make sure user is authenticated and passes test.

       This is an adaptation of
       ``django.contrib.auth.decorators.user_passes_test`` where:

       * if user is anonymous, the request is routed to ``unauthorized`` view.
         No additional tests are performed in that case.

       * if user is authenticated and doesn't pass ``test_func ``test, the
         request is routed to ``forbidden`` view.

       * else, request and arguments are passed to decorated view.

       Typical ``unauthorized`` view returns HTTP 401 status code and gives the
       user an opportunity to log in: access may be granted after
       authentication.

       Typical ``forbidden`` view returns HTTP 403 status code: with active
       user account, access is refused. As explained in rfc2616, 401 and 403
       status codes could be suitable.

       .. seealso::

          * http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.4
          * https://en.wikipedia.org/wiki/List_of_HTTP_status_codes

       """
       def decorator(view_func):
           @wraps(view_func, assigned=available_attrs(view_func))
           def _wrapped_view(request, *args, **kwargs):
               if not request.user.is_authenticated():
                   return unauthorized(request)
               if not test_func(request.user):
                   return forbidden(request)
               return view_func(request, *args, **kwargs)
           return _wrapped_view
       return decorator

This decorator depends on some additional stuff:

.. code-block:: python

   from django.http import HttpResponse, HttpResponseForbidden
   from django.views.generic import TemplateView

   class HttpResponseUnauthorized(HttpResponse):
       status_code = 401

   class UnauthorizedView(TemplateView):
       response_class = HttpResponseUnauthorized
       template_name = '401.html'

   class ForbiddenView(TemplateView):
       response_class = HttpResponseForbidden
       template_name = '403.html'

Then, here is the test case!
It seems quite long, but isn't it readable?

* first we setup fakes or mocks for all dependencies: ``request.user``,
  ``test_func``, ``unauthorized`` view, ``forbidden`` view, and the view to be
  decorated.
* then we declare a ``run_decorated_view`` function to avoid repeating code.
* finally we test the 3 main situations: unauthorized, forbidden, authorized.

.. code-block:: python

   import unittest

   class AuthenticatedUserPassesTestTestCase(unittest.TestCase):
       def setUp(self):
           """Common setup: fake request, stub views, stub user test function."""
           super(AuthenticatedUserPassesTestTestCase, self).setUp()
           # Fake request and its positional and keywords arguments.
           self.request = mock.MagicMock()
           self.request.user.is_authenticated = mock.MagicMock()
           self.request_args = ['fake_arg']
           self.request_kwargs = {'fake': 'kwarg'}
           # Mock user test function.
           self.test_func = mock.MagicMock()
           # Mock unauthorized and forbidden views.
           self.unauthorized_view = mock.MagicMock(
               return_value=u"401 - You may log in.")
           self.forbidden_view = mock.MagicMock(
               return_value=u"403 - Insufficient privileges.")
           # Mock the view to decorate.
           self.authorized_view = mock.MagicMock(
               return_value=u"200 - Greetings, Professor Falken.")

       def run_decorated_view(self, is_authenticated=True, user_passes_test=True):
           """Setup, decorate and call view, then return response."""
           # Custom setup.
           self.request.user.is_authenticated.return_value = is_authenticated
           self.test_func.return_value = user_passes_test
           # Get decorator.
           decorator = authenticated_user_passes_test(
               self.test_func,
               unauthorized=self.unauthorized_view,
               forbidden=self.forbidden_view)
           # Decorate view.
           decorated_view = decorator(self.authorized_view)
           # Return response.
           return decorated_view(self.request,
                                 *self.request_args,
                                 **self.request_kwargs)

       def test_unauthorized(self):
           """authenticated_user_passes_test first tests user authentication."""
           response = self.run_decorated_view(is_authenticated=False)
           # Check: unauthorized view was called with request as unique positional
           # argument.
           self.unauthorized_view.assert_called_once_with(self.request)
           self.assertEqual(response, self.unauthorized_view.return_value)
           # Test func was not called.
           self.assertFalse(self.test_func.called)
           # Of course, authorized and forbidden views were not called.
           self.assertFalse(self.authorized_view.called)
           self.assertFalse(self.forbidden_view.called)

       def test_test_func_args(self):
           """authenticated_user_passes_test passes user instance to test func."""
           self.run_decorated_view(is_authenticated=True)
           # Check: test_func was called with one argument: user instance.
           self.test_func.assert_called_once_with(self.request.user)

       def test_forbidden(self):
           """authenticated_user_passes_test runs forbidden view if user fails."""
           response = self.run_decorated_view(is_authenticated=True,
                                              user_passes_test=False)
           # Check: forbidden view was called with request as unique positional
           # argument.
           self.forbidden_view.assert_called_once_with(self.request)
           self.assertEqual(response, self.forbidden_view.return_value)
           # Of course, authorized and unauthorized views were not triggered.
           self.assertFalse(self.authorized_view.called)
           self.assertFalse(self.unauthorized_view.called)

       def test_authorized(self):
           """authenticated_user_passes_test runs view if user passes test."""
           response = self.run_decorated_view(is_authenticated=True,
                                              user_passes_test=True)
           # Check: decorated view has been called, request and other arguments
           # were proxied as is, response was not altered.
           self.authorized_view.assert_called_once_with(self.request,
                                                        *self.request_args,
                                                        **self.request_kwargs)
           self.assertEqual(response, self.authorized_view.return_value)
           # Of course, forbidden and unauthorized views were not triggered.
           self.assertFalse(self.forbidden_view.called)
           self.assertFalse(self.unauthorized_view.called)

Would you trust the ``authenticated_user_passes_test`` decorator?


**********
References
**********

.. target-notes::

.. _`mock`: https://pypi.python.org/pypi/mock
.. _`unittest.mock`: http://docs.python.org/3/library/unittest.mock.html
.. _`django.test.RequestFactory`:
   https://docs.djangoproject.com/en/1.5/topics/testing/advanced/#django.test.client.RequestFactory
.. _`django.http.HttpRequest`:
   https://docs.djangoproject.com/en/1.5/ref/request-response/#django.http.HttpRequest
