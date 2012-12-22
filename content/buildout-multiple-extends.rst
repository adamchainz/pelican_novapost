####################################################
Multiple inheritance in buildout configuration files
####################################################

:date: 2012-12-21 17:00
:tags: buildout, extends
:category: Python
:author: Benoît Bryon
:lang: en
:slug: buildout-multiple-extends

In `zc.buildout <http://pypi.python.org/pypi/zc.buildout/>`_'s configuration
files, you can `extend several files
<http://pypi.python.org/pypi/zc.buildout/1.6.3#multiple-configuration-files>`_.
Looks like a powerful feature, doesn't it?
I tried it and started wondering what it is designed for.
In fact, using this feature made me wonder what is buildout designed for...

In this article, I will try explain buildout's multiple inheritance, then point
out problems I encountered, and finally suggest solutions whenever I can.


********************
``extend`` use cases
********************

Configuration reuse
===================

#1 use case for "extend" is configuration reuse:

* write directives you always use in some "base.cfg" file.
* make your "buildout.cfg" extend "base.cfg".

If you do this, you are certainly going to copy-paste-adapt your favorite
base configuration file. So you'll appreciate:

* generating buildout configuration from templates (with Jinja, PasteScript,
  diecutter...).

* or `extending from URL
  <http://pypi.python.org/pypi/zc.buildout/1.6.3#loading-configuration-from-urls>`_.

Also consider the following advices:

* extend bases that have distinct roles, i.e. bases which don't overlap each
  other.

* use explicit overrides instead of ``+=`` operator (which performs implicit
  overrides).

The motivations for the two advices above are detailed in `buildout's
inheritance mechanism`_  below.

Components
==========

#2 use case for "extend" is management of multiple components:

* you have some "frontend.cfg" that contains buildout directives to install
  some frontend component.

* you have some "backend.cfg" that contains buildout directives to install
  some backend component.

* you make your "buildout.cfg" extend both "frontend.cfg" and "backend.cfg"
  to install both components in a row.

* but you could use "frontend.cfg" and "backend.cfg" separately.

Well, you can extend several components, but, as of december 2012, I feel
buildout is not designed for this purpose:

* buildout is made to deploy consistent environments. As an example, items in
  the environment share a set of dependencies, i.e. within the environment,
  there is one and only one version of each dependency.

* buildout is not made to deploy independant components in a same location.
  As an example, if a frontend depends on Django 1.4 and an backend requires
  version 1.3, then buildout can't deploy both within a single run. You will
  need to run two deployments.

Deeper explanations below...


********************************
Buildout's inheritance mechanism
********************************

Let's consider the following example, with 3 files: main "a.cfg" extends both
"b.cfg" and "c.cfg".

What will happen when you run ``buildout -c buildout.cfg``?

* parse "a.cfg", store the resulting configuration for later use.
* in configuration, found 2 bases: "b.cfg" and "c.cfg".
* parse bases:

  * parse "b.cfg". Store the result as "bases result".
  * parse "c.cfg". Merge the result with current "bases result", i.e. with
    "b.cfg".
    In case of clashes, **the latter (b.cfg) overrides the former (a.cfg).**
  * there is no more bases, get back.

* Merge results from bases and results from buildout.cfg. The latter overrides
  the former.

**With buildout implementation, "A extends B and C" is handled exactly the same
as "C extends B, then A extends C".**

It means that, in case of clashes, ``=`` in "c.cfg" overrides value from
"b.cfg". And ``+=`` in "c.cfg" concatenates value from "a.cfg" and "b.cfg".

Beware the += bug
=================

For buildout 1.6.3, I reported a `bug with multiple inheritance and +=
<https://bugs.launchpad.net/zc.buildout/+bug/1060236>`_.

As a summary, you may encounter issues if you extend multiple files and make
intensive use of ``+=`` operator in sections.

Several solutions:

* submit a patch for the `zc.buildout.buildout._update_section() function
  <https://github.com/buildout/buildout/blob/f45bcbf1ae9bae74954cc61ace7bbec8bbd51f00/src/zc/buildout/buildout.py#L1452>`_.

* `avoid += in bases`_, see other examples in this article.

* optionally use and promote `a revised implementation of the += feature
  <https://github.com/buildout/buildout/pull/22>`_, which introduces backward
  incompatibilities.

Avoid += in bases
=================

Yes, you can use ``+=`` in bases. But don't you feel it is a bit strange?
I mean, why would you use ``+=`` in a file that don't inherit from other files?

The only reason I know is that the buildout inheritance mechanism makes bases
extend each other. But I believe this is a bad reason.

So, as of version 1.6.3, my recommendation is to avoid ``+=`` operator in
bases, unless themselves have bases (multi-level inheritance).

Here are two designs I'd prefer, but they introduce backward
incompatibilities...

Given:

* A extends (B and C)
* A sets "ac=A"
* B sets "bc=B"
* C sets "bc=C" and "ac=C"

I would find it more comprehensive if:

* bases were parsed separately, then inherited values were computed at
  the end, i.e. if C doesn't inherit from B.
  Result would be (ac=A, bc=C).

* or multiple bases were be concatenated,
  i.e. result is (ac=A, bc=BC).

Beware implicit overrides
=========================

Here is something that could happen if you use one of the popular version
manager in buildout (buildout.dumppickedversions or buildout-versions).

buildout.cfg:

.. code-block:: cfg

  [buildout]
  extends = frontend.cfg backend.cfg
  extensions = buildout-versions
  versions = versions
  parts = frontend backend

frontend.cfg:

.. code-block:: cfg

  [frontend]
  recipe = z3c.recipe.scripts
  eggs = Django frontend

  [versions]
  Django == 1.3

backend.cfg:

.. code-block:: cfg

  [backend]
  recipe = z3c.recipe.scripts
  eggs = Django backend

  [versions]
  Django == 1.2

Here, buildout performs implicit overrides, and you get Django==1.2 as a
result. It means that the "frontend" won't work as expected. You don't get
warnings or errors about it, so it's quite hard to debug if you aren't aware
that implicit overrides occur.

Explicit is better than implicit
================================

When extending multiple bases (and because the "strange" inheritance
implementation), you should use explicit overrides.

As an example, in some "a.cfg", you'd better write:

.. code-block:: cfg

   [buildout]
   extends = b.cfg c.cfg
   parts = b1 b2 c1 c2

... instead of using ``+=`` in c[parts] and ``+=`` again in a[parts].


**************************
Flat is better than nested
**************************

The easiest way to avoid inheritance problems is to maintain a single buildout
configuration file, i.e. don't use inheritance.

Try to keep your buildout.cfg small, simple and readable.

If you can't get a simple file, or want to reuse parts of your work, then what
about generating your buildout configuration from templates? Template engines
provide all you need to create buildout configuration: includes, inheritance,
variables, and even more helpers like loops, formatters...

Consider buildout's inheritance and variables features as simple
implementations. Use them for simple needs. If you need more, use powerful
template engines. Buildout is good at managing execution of recipes ; templates
engines are good at generating files.


*********************************
Multiple components in a buildout
*********************************

You can apply the pattern below to deploy multiples components in a row,
but keep in mind this has a major limitation: **all components share the
same versions for dependencies**. When you run buildout, you build an
environment with a consistent set of dependencies.

If you want components to use distinct versions for dependencies, you must
`run several buildouts <#multiple-buildouts>`_.

In the following example, we build an environment with a frontend and a
backend.

frontend.cfg:

.. code-block:: cfg

   [buildout]
   parts = ${frontend:parts}

   [frontend]
   parts =
       frontend-1
       frontend-2
       frontend-3
       ...
       frontend-42

You can run buildout with standalone frontend.cfg. It works and
installs ``frontend-a`` and ``frontend-b``.

backend.cfg:

.. code-block:: cfg

   [buildout]
   parts = ${backend:parts}

   [backend]
   parts =
       backend-1
       backend-2

You can run buildout with backend.cfg. It works and installs
``backend-a`` and ``backend-b``.

.. warning::

   If you run ``buildout -c frontend.cfg`` then ``buildout -c backend.cfg``,
   the second command will start with uninstall of frontend!

Now let's compose the main buildout.cfg file explicitely:

.. code-block:: cfg

   [buildout]
   extends =
       frontend.cfg
       backend.cfg
   parts =
       ${frontend:parts}
       ${backend:parts}

Executing buildout on buildout.cfg installs ``frontend-a``,
``frontend-b``, ``backend-a`` and ``backend-b``.

.. note::

   Using this pattern, we didn't had to rewrite the complete (potentially long)
   list of parts from frontend.cfg and backend.cfg.


******************
Multiple buildouts
******************

As told in previous sections, there are several reasons why you would want to
run several buildouts:

* components have separate set of dependencies (versions).
* since configuration files are independent, you want to be able to run each
  one independantly of the other.

There are several techniques. The ones I know customize directories.

Completely separated directories
================================

Use `directory options
<http://pypi.python.org/pypi/zc.buildout/1.6.3#alternate-directory-and-file-locations>`_
and ``-c`` argument to deploy each component in its own
directory, i.e. alter ``buildout:directory`` option.

.. note::

   By default, ``buildout:directory`` option is "the directory where lives
   configuration file".

As an example:

.. code-block:: sh

   bin/buildout -c frontend.cfg buildout:directory=frontend
   bin/buildout -c backend.cfg buildout:directory=backend

Some shared resources
=====================

But you can also share some resources, like the eggs cache or the "bin/"
folder.

The minimum thing you can do is to setup distinct ``buildout:installed``
option in configuration files, so that parts, eggs, ... are shared. It works
well if configuration files don't overlap.

As an example, frontend.cfg:

.. code-block:: cfg

   [buildout]
   extensions = buildout-versions
   installed = .frontend-installed.cfg
   parts = frontend-django
   
   [frontend-django]
   recipe = z3c.recipe.scripts
   eggs =
       Django
   interpreter = frontend
   
   [versions]
   Django = 1.3.4

And backend.cfg:

.. code-block:: cfg

   [buildout]
   extensions = buildout-versions
   installed = .backend-installed.cfg
   parts = backend-django
   
   [backend-django]
   recipe = z3c.recipe.scripts
   eggs = Django
   interpreter = backend
   
   [versions]
   Django = 1.4.2

With this example, components don't overlap, so ``buildout -c frontend.cfg &&
buildout -c backend.cfg`` works well.
