##################################
Class-based decorators with Python
##################################

:date: 2013-03-15 12:00
:tags: python
:category: Python
:author: Benoît Bryon
:lang: en
:slug: python-class-based-decorators

A Python decorator is, basically, a function that take a function as argument
and return a function. This is a powerful feature. But it has some drawbacks:

* **decorators are quite tricky to develop**. Of course they are for Python
  newbies. But, as an experienced Python developer, I must admit I also have to
  think every time I code a decorator. I often feel the decorator pattern is a
  bit complex.

* **decorators that take arguments are even more tricky to develop**. They are
  decorator factories, aka "functions that return a function that take a
  function and return a function". Inception WTF?

* **decorators without arguments are used without parentheses, whereas
  decorators with arguments require parentheses**, even if you pass empty
  arguments. So when using a decorator, you have to wonder whether it takes
  arguments or not. A bit more to think about everytime you use a decorator.

* last but not least, **function-based decorators are hard to test**, because
  they return functions and you can't easily check internals. How can you
  check the state of the decorator after it decorated the function, but before
  you actually run it? Classes are really helpful for that.

This article is an **experiment** around class-based decorators for Python.
I made it with this question in mind: **would class-based decorators help
writing, using and testing decorators?**

The examples described below are available as a Python file at
https://gist.github.com/benoitbryon/5168914


****************************************
Decorators are tricky to develop and use
****************************************

As a reminder of drawbacks of decorators, here are some examples. If you are
aware of those facts, `jump to the next section <#hello-world-example>`_.

Here is a simple decorator which prints "moo" then executes decorated function:

.. code-block:: python

   def moo(func):
       def decorated(*args, **kwargs):
           print 'moo'
           return func(*args, **kwargs)  # Run decorated function.
       return decorated

You use it like this:

.. code-block:: python

   >>> @moo
   ... def i_am_a(kind):
   ...     print "I am a {kind}".format(kind=kind)
   >>> i_am_a("duck")
   moo
   I am a duck

Here is the same decorator, which allows you configure the value to print:

.. code-block:: python

   def speak(word='moo'):
       def decorator(func):
           def decorated(*args, **kwargs):
               print word
               return func(*args, **kwargs)
           return decorated
       return decorator

You use it like that:

.. code-block:: python

   >>> @speak('quack')
   ... def i_am_a(kind):
   ...     print "I am a {kind}".format(kind=kind)
   >>> i_am_a("duck")
   quack
   I am a duck

If you want to use default arguments for "speak", you have to use empty
parentheses, i.e. you can't write ``@speak`` like you used ``@moo``, you have
to write ``@speak()`` instead.

I won't tell more about decorators here, there are plenty of articles about
them on the web. I just wanted to highlight the fact that even simplest
decorators are not as simple as they pretend.

But they could be! Let's introduce class-based decorators...


*******************
Hello world example
*******************

Here is a sample usage of the `Decorator class <#the-decorator-class>`_:

.. code-block:: python

   class Greeter(Decorator):
       """Greet return value of decorated function."""
       def setup(self, greeting='hello'):
           super(Greeter, self).setup()
           self.greeting = greeting

       def run(self, *args, **kwargs):
           """Run decorated function and return modified result."""
           name = super(Greeter, self).run(*args, **kwargs)
           return '{greeting} {name}!'.format(greeting=self.greeting, name=name)

The implementation is pretty simple, isn't it? So is the usage!

As a Decorator, you can use it without options.

.. code-block:: pycon

    >>> @Greeter
    ... def world():
    ...     return 'world'
    >>> world()
    'hello world!'

The example above is the same as providing empty options.

.. code-block:: pycon

    >>> @Greeter()
    ... def world():
    ...     return 'world'
    >>> world()
    'hello world!'

It accepts one ``greeting`` option:

.. code-block:: pycon

    >>> @Greeter(greeting='goodbye')
    ... def world():
    ...     return 'world'
    >>> world()
    'goodbye world!'

``greeting`` option defaults to ``'hello'``:

.. code-block:: pycon

    >>> my_greeter = Greeter()
    >>> my_greeter.greeting
    'hello'

You can setup a Greeter instance for later use:

.. code-block:: pycon

    >>> my_greeter = Greeter(greeting='hi')
    >>> @my_greeter
    ... def world():
    ...     return 'world'
    >>> world()
    'hi world!'

Which gives you an opportunity to setup the greeter yourself:

.. code-block:: pycon

    >>> my_greeter = Greeter()
    >>> my_greeter.greeting = 'bonjour'
    >>> @my_greeter
    ... def world():
    ...     return 'world'
    >>> world()
    'bonjour world!'

All arguments are proxied to the decorated function:

.. code-block:: pycon

    >>> @Greeter
    ... def name(value):
    ...     return value
    >>> name('world')
    'hello world!'

    >>> @Greeter(greeting='goodbye')
    ... def names(*args):
    ...     return ' and '.join(args)
    >>> names('Laurel', 'Hardy')
    'goodbye Laurel and Hardy!'


*********************************
Wrapping functions with functools
*********************************

`functools`_ provides utilities to "wrap" a function, i.e. make the decorator
return value look like the original function.

Here is another class-based decorator sample. It adds
"functools.update_wrapper" features to `Decorator class <#the-decorator-class>`_:

.. code-block:: python

   import functools

   class Chameleon(Decorator):
       """A Decorator that looks like decorated function.

       It uses ``functools.update_wrapper``.

       This is a base class which acts as a transparent proxy for the
       decorated function. Consider overriding the ``run()`` method.

       .. warning::
       
          Take care of what you pass in ``assigned`` or ``updated``: you could
          break the Chameleon itself. As an example, you should not pass "assigned",
          "run" or "__call__" in ``assigned``, except you know what you are doing.

       """
       def setup(self,
                 assigned=functools.WRAPPER_ASSIGNMENTS,
                 updated=functools.WRAPPER_UPDATES):
           self.assigned = assigned
           self.updated = updated

       def decorate(self, func):
           """Make self wrap the decorated function."""
           super(Chameleon, self).decorate(func)
           functools.update_wrapper(self, func,
                                    assigned=self.assigned,
                                    updated=self.updated)

Again, the implementation is pretty simple.

Let's look at the result...

.. code-block:: pycon

   >>> @Chameleon
   ... def documented():
   ...     '''Fake function with a docstring.'''
   >>> documented.__doc__
   'Fake function with a docstring.'

It accepts options ``assigned`` and ``updated``, that are proxied to
``functools.update_wrapper``.

Default values are ``functools.WRAPPER_ASSIGNMENTS`` for ``assigned`` and
empty tuple for ``updated``.

.. code-block:: pycon

   >>> def hello():
   ...    '''Hello world!'''
   >>> wrapped = Chameleon(hello)
   >>> wrapped.assigned
   ('__module__', '__name__', '__doc__')
   >>> wrapped.updated
   ('__dict__',)
   >>> wrapped.__doc__ == hello.__doc__
   True
   >>> wrapped.__name__ == hello.__name__
   True

   >>> only_doc_wrapped = Chameleon(hello, assigned=['__doc__'])
   >>> only_doc_wrapped.__doc__ == hello.__doc__
   True
   >>> only_doc_wrapped.__name__ == hello.__name__  # Doctest: +ELLIPSIS
   Traceback (most recent call last):
       ...
   AttributeError: 'Chameleon' object has no attribute '__name__'

   >>> hello.__dict__ = {'some_attribute': 'some value'}  # Best on an object.
   >>> attr_wrapped = Chameleon(hello, updated=['__dict__'])
   >>> attr_wrapped.updated
   ['__dict__']
   >>> attr_wrapped.some_attribute
   'some value'

Here we have a good replacement for decorators using ``functools.wraps``.


************************
Handling setup arguments
************************

There is a trick with setup arguments, particularly with positional arguments.
This is because ``Decorator`` has an adaptive behaviour that allow you to pass
the function to decorate either in ``__init__()`` or in ``__call__``. How to
differenciate the function to decorate from setup arguments?

Let's consider the use cases...

Optional setup arguments
========================

* You can decorate with or without parentheses
* Use keyword arguments for setup, or you may get unexpected ``TypeError``,
  because ``Decorator.__init__()``'s first optional argument is the function
  to decorate.

This is the ``Greeter`` example shown above:

.. code-block:: pycon

   >>> @Greeter('what?')  # doctest: +ELLIPSIS
   ... def world():
   ...     return 'world'
   Traceback (most recent call last):
       ...
   TypeError: Cannot decorate non callable object "what?"
   >>> wrong_greeter = Greeter('what?')  # doctest: +ELLIPSIS
   Traceback (most recent call last):
       ...
   TypeError: Cannot decorate non callable object "what?"
   >>> ok_greeter = Greeter(lambda: 'world', 'right')
   >>> ok_greeter()
   'right world!'
   >>> another_wrong_greeter = Greeter()
   >>> another_wrong_greeter('what?')  # doctest: +ELLIPSIS
   Traceback (most recent call last):
       ...
   TypeError: Cannot decorate non callable object "what?"

Required setup arguments
========================

* You cannot decorate without parentheses, you have to use parentheses in order
  to provide setup argument.
* For code readability, separate setup and decoration steps.

An example is the django-traditional-style decorator shown in
`Testing Django view decorators
<|filename|django-testing-view-decorators.rst>`_ article, which has a required
(i.e. postitional) argument: ``test_func``.

.. code-block:: python

   from functools import wraps
   from django.utils.decorators import available_attrs

   def authenticated_user_passes_test(test_func,
                                      unauthorized=UnauthorizedView.as_view(),
                                      forbidden=ForbiddenView.as_view()):
       """Make sure user is authenticated and passes test."""
       def decorator(view_func):
           @wraps(view_func, assigned=available_attrs(view_func))
           def _wrapped_view(request, *args, **kwargs):
               if not request.user.is_authenticated():
                   return unauthorized(request)
               if not test_func(request.user):
                   return forbidden(request)
               return view_func(request, *args, **kwargs)

... would be written like this with class-based-style:

.. code-block:: python

   class authenticated_user_passes_test(Chameleon):
       """Make sure user is authenticated and passes test."""
       def setup(self,
                 test_func,
                 unauthorized=UnauthorizedView.as_view(),
                 forbidden=ForbiddenView.as_view()):
           self.test_func = test_func
           self.unauthorized = unauthorized
           self.forbidden = forbidden
           super(authenticated_user_passes_test, self).setup()

       def run(self, request, *args, **kwargs):
           if not request.user.is_authenticated():
               return self.unauthorized(request)
           if not self.test_func(request.user):
               return self.forbidden(request)
           return super(authenticated_user_passes_test, self).run(request, *args, **kwargs)

So you have to provide one positional argument when decorating in place:

.. code-block:: python

   @authenticated_user_passes_test(lambda user: user.is_staff)
   def some_view(request):
       """Do something."""

When decorating afterwards, also separate setup and decoration:

.. code-block:: python

   test_func = lambda user: user.is_staff
   decorated_view = authenticated_user_passes_test(test_func)(some_view)

Which is an equivalent to:

.. code-block:: python

   decorated_view = authenticated_user_passes_test(test_func).decorate(some_view)


*******
Testing
*******

Class-based decorators are easier to test:

As a test writer, you can write tests for decorators internals:

* you can check decorator's state after setup, after decoration, after run;

* you can inspect a callable and see whether is has been decorated of not.

  As an example, using the ``Greeter`` example above:

  .. code-block:: python

     @Greeter
     def world():
         return 'world'

     assert(isinstance(world, Greeter))

How would you do that with function-based decorators?

* you have to test the result of the decorated function;
* or you have to mock the decorator in order to check whether the mock has been
  called or not. It works but it is not as simple as testing the class.


*******************
The Decorator class
*******************

At last, here is the base class. Little magic inside.

.. code-block:: python

   # Sentinel to detect undefined function argument.
   UNDEFINED_FUNCTION = object()


   class Decorator(object):
       """Base class to easily create convenient decorators.

       Override :py:meth:`setup`, :py:meth:`run` or :py:meth:`decorate` to create
       custom decorators:

       * :py:meth:`setup` is dedicated to setup, i.e. setting decorator's internal
         options.
         :py:meth:`__init__` calls :py:meth:`setup`.

       * :py:meth:`decorate` is dedicated to wrapping function, i.e. remember the
         function to decorate.
         :py:meth:`__init__` and :py:meth:`__call__` may call :py:meth:`decorate`,
         depending on the usage.

       * :py:meth:`run` is dedicated to execution, i.e. running the decorated
         function.
         :py:meth:`__call__` calls :py:meth:`run` if a function has already been
         decorated.

       Decorator instances are callables. The :py:meth:`__call__` method has a
       special implementation in Decorator. Generally, consider overriding
       :py:meth:`run` instead of :py:meth:`__call__`.

       """
       def __init__(self, func=UNDEFINED_FUNCTION, *args, **kwargs):
           """Constructor.

           Accepts one optional positional argument: the function to decorate.

           Other arguments **must** be keyword arguments.

           And beware passing ``func`` as keyword argument: it would be used as
           the function to decorate.

           """
           self.setup(*args, **kwargs)
           #: The decorated function.
           self.decorated = UNDEFINED_FUNCTION
           if func is not UNDEFINED_FUNCTION:
               self.decorate(func)

       def decorate(self, func):
           """Remember the function to decorate.

           Raises TypeError if ``func`` is not a callable.

           """
           if not callable(func):
               raise TypeError('Cannot decorate non callable object "{func}"'
                               .format(func=func))
           self.decorated = func
           return self

       def setup(self, *args, **kwargs):
           """Store decorator's options"""
           self.options = kwargs
           return self

       def __call__(self, *args, **kwargs):
           """Run decorated function if available, else decorate first arg."""
           if self.decorated is UNDEFINED_FUNCTION:
               func = args[0]
               if args[1:] or kwargs:
                   raise ValueError('Cannot decorate and setup simultaneously '
                                    'with __call__(). Use __init__() or '
                                    'setup() for setup. Use __call__() or '
                                    'decorate() to decorate.')
               self.decorate(func)
               return self
           else:
               return self.run(*args, **kwargs)

       def run(self, *args, **kwargs):
           """Actually run the decorator.

           This base implementation is a transparent proxy to the decorated
           function: it passes positional and keyword arguments as is, and returns
           result.

           """
           return self.decorated(*args, **kwargs)

This base class transparently proxies to decorated function:

.. code-block:: pycon

   >>> @Decorator
   ... def return_args(*args, **kwargs):
   ...    return (args, kwargs)
   >>> return_args()
   ((), {})
   >>> return_args(1, 2, three=3)
   ((1, 2), {'three': 3})

This base class stores decorator's options in ``options`` dictionary. But
it doesn't use it... it's just a proof of concept.

.. code-block:: pycon

   >>> @Decorator
   ... def nothing():
   ...    pass
   >>> nothing.options
   {}

   >>> @Decorator()
   ... def nothing():
   ...    pass
   >>> nothing.options
   {}

   >>> @Decorator(one=1)
   ... def nothing():
   ...    pass
   >>> nothing.options
   {'one': 1}


***********
Limitations
***********

This `Decorator implementation <#the-decorator-class>`_ has some
limitations related to the adaptive behaviour of ``__init__()`` and
``__call__()`` methods: their behaviour change depending on the decorator's
state. This can be puzzling, and perhaps some people will tell it is a bad
pattern.

That said, I feel things are easier when you remember the decorator process as:

* optionally setup decorator
* decorate function
* run decorated function.

Also, when you write decorators, you have to remember the ``Decorator`` API,
i.e. ``setup()``, ``decorate()`` and ``run()`` methods. This is because
standard methods like ``__init__()`` and ``__call__()`` do some sorcery.
Perhaps it would be great to override ``__init__()`` instead of ``setup()`` and
override ``__call__()`` instead of ``run()``, but I have not figured out how to
make it...

This implementation does not deal with class and method decorators.

Are there other limitations?


********
Benefits
********

* As a decorator author, you focus on ``setup()``, ``decorate()`` and
  ``run()``. It is easy to remember. It produces readable code.

* As a decorator user, you don't bother with parentheses. You just use the
  decorator depending on your needs, and it works.

* As a decorator author, `testing is easier <testing>`_.

Would you use it?


************
What's next?
************

As said in the introduction, this is an experiment. I made it to explore other
ways to write decorators. My personal conclusion is that I like the concept of
class-based decorators.

So, next steps would be:

* try some packages on PyPI, such as:

  * `decorator`_
  * `DecoratorTools`_
  * `Decorum`_
  * `dectools`_
  * `pyxdeco`_

* contribute to one of the projects above?


********
See also
********

* `"Python et les décorateurs", by Gilles Fabio
  <http://gillesfabio.com/blog/2010/12/16/python-et-les-decorateurs/>`_
  is a good article (in french). It ends with an list of useful links
  (most in english). It also provides a function-based implementation of
  decorators that work with or without arguments.

* `Testing Django view decorators
  <|filename|django-testing-view-decorators.rst>`_

.. target-notes::

.. _`functools`: http://docs.python.org/2.7/library/functools.html
.. _`decorator`: https://pypi.python.org/pypi/decorator
.. _`DecoratorTools`: https://pypi.python.org/pypi/DecoratorTools
.. _`Decorum`: https://pypi.python.org/pypi/Decorum
.. _`dectools`: https://pypi.python.org/pypi/dectools
.. _`pyxdeco`: https://pypi.python.org/pypi/pyxdeco
