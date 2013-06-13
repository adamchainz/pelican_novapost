#######################################
Managing (Django) configuration (files)
#######################################

:date: 2013-06-13 12:00
:tags: django, configuration, deployment, python
:category: Astuces
:author: Benoît Bryon
:lang: en
:slug: django-configuration-files-with-templates-and-dvcs

At `DjangoCon Europe 2013`_, we heard about techniques to manage Django
configuration using files or environment variables. Some are explained in the
`"Two scoops of Django" book`_. But we are not convinced by those techniques.
So let's talk about one we use here at Novapost.
Get ready: it is based on files, templates and DVCS.

.. note::

   In this article, I focus on Django configuration, because that's the start
   of the story. But most of the techniques are not specific to Django and
   could be adapted to Python projects, and even to any configuration files.


*********************************
Configuration management features
*********************************

Why do I need to manage configuration?

* **I want to share and reuse configuration patterns at every level**:
  
  * across distinct projects,
  * across distinct environments (PROD, STAGING, TEST, DEV...) in a project,
  * across distinct instances (your DEV, my DEV) in an environment,
  * across distinct machines (front1, front2) in an environment instance,
  * across distinct applications or services on a machine.

* **I want optional specific setup at every level**.

* **I want local configuration remain local**, i.e. I do not want to have
  secrets published on some remote places (including private repositories).

* **When I upgrade some component, I want to review the changes**:

  * which configuration directives have been added,
  * which directives have been deprecated,
  * which default values have changed.

* **I want to be able to undo (rollback) or redo**.

* And, of course, **I want all of this to be as automated as possible**.


*********************
Our deployment layout
*********************

I will talk about files we deploy, so here is a commented overview of our
application deployment layout. This layout is not mandatory for the purpose of
this article, but it will illustrate parts of it.

.. code-block:: sh

   .   # Somewhere in the filesystem, probably under
   │   # /home/ or /var/.
   │
   ├── bin/   # Scripts.
   │   └── postbox   # Uses ``postbox.manage.main``.
   │
   ├── etc/   # Contains all local configuration.
   │   ├── circus/
   │   └── django/   # This folder is in sys.path.
   │       └── settings_local.py   # Settings specific to this deployment:
   │                               # ``from postbox.settings_default import *``
   │
   ├── lib/   # Libraries, i.e. code we do not develop.
   │
   ├── src/   # Code we develop.
   │   ├── django-downloadview/   # An app we develop...
   │   │   └── setup.py
   │   │
   │   ├── django-mail-factory/   # Another app we develop...
   │   │   └── setup.py
   │   │
   │   ├── postbox-front/   # Our Django project.
   │   │   ├── postbox/   # This folder is in sys.path.
   │   │   │   ├── __init__.py
   │   │   │   ├── manage.py   # Uses ``postbox.settings``.
   │   │   │   ├── settings.py   # ``from settings_local import *``.
   │   │   │   ├── settings_default.py   # Project's common configuration.
   │   │   │   ├── urls.py
   │   │   │   └── wsgi.py
   │   │   └── setup.py   # Packaging for our project.
   │   │
   │   └── postbox-templates/   # Configuration and code templates.
   │       └── django/
   │           └── settings_local.py
   │
   └── var/   # Local data files: collected statics, media, cache...

Some highlights:

* ``bin/`` and ``lib/`` are automatically populated by deployment scripts, and
  they can be re-generated on demand, i.e. we do not change files manually.

* ``src/`` contains clones of repositories (mercurial, git, whatever...) we
  develop or contribute to. We use a script (`mr.developer`_) to easily
  perform clone, pull, status, ..., on all the repositories.

  Everything in ``src/`` can be put moved to ``lib/`` when it is stable, i.e.
  things are in ``src/`` in DEV environment, but they may be in ``lib/`` on
  PROD.

* ``etc/`` is both generated with templates and under local version control.
  I will explain this below. For now, remember it contains all
  application-level local configuration, just like ``/etc/`` contains all
  machine-level configuration.

* ``var/`` contains data. Some should be backuped, some can be re-generated
  such as collected static files.


************************************************
Put local configuration outside your application
************************************************

What is important here is that ``etc/`` folder is separated from source code.

Application-level Python's ``sys.path`` contains the following:

* Python dependencies in ``lib/`` (managed with virtualenv or buildout)
* Python projects in ``src/``, including our main "postbox" project
* and ``etc/django/``, which allows us to ``import settings_local``

We tune ``sys.path`` with buildout (`extra-paths option of
z3c.recipe.scripts`_), but I guess you can have something similar with
virtualenv.

Settings are loaded like this:

* ``bin/postbox`` uses ``postbox.manage``. Notice that ``bin/postbox``
  script has been generated as part of project's ``setup.py``.

* project's ``manage.py`` uses ``settings`` in the same package, i.e.
  ``postbox.settings``.

* ``postbox.settings`` tries ``from settings_local import *`` and displays
  a human-readable error message in case of ``ImportError``.

* ``settings_local`` does ``from postbox.settings_default import *``, then
  can alter default values or assign new ones.

.. note::

   Optionally, in DEV environment, we have a ``settings_test.py`` which loads
   ``settings_local`` than alters some additional settings for test purpose.


*********************************************
Do not share several settings-${ENV}.py files
*********************************************

With the layout shown above, we do share (i.e. put under version control and
push on remote repositories) ``settings_default.py`` and... that's all!

We do not have ``settings_dev.py``, ``settings_prod.py``,
``settings_staging.py``...

* when you work in an environment, you do not care about configuration of
  other environments. I mean, in DEV, you do not need PROD configuration.

* local configuration can contain sensible data, such as passwords. So,
  generally, you should not push such files on remote repositories.

* you do not maintain all ``settings-${ENV}.py`` files simultaneously. Often
  you forget to backport a configuration change in one file or another... With
  time, comparing all those files becomes really difficult, and you do not
  even know which one is the reference.

We hold all common (and not so secret) configuration in
``settings_default.py``. This file is pushed and shared on remote repositories.

Then we generate ``settings_local.py`` with templates, i.e. we maintain only
one master file to generate settings in various environments. In the template,
we use variables to allow per-environment customization.


*************************************
Generate configuration with templates
*************************************

Using templates is an easy way to solve the "share & reuse" features:

* manage and share templates in repositories, just as you would do with code.
  That is the ``postbox-templates`` repository mentioned in `our deployment
  layout`_.

* generate configuration files with templates.
  We use `diecutter`_ as template rendering service.

* if you need to reuse some template context at some level (as an example,
  want DEBUG=True for every DEV environment) then manage presets in
  configuration files (json, ini...), share them in some remote repository,
  and pass them as input to your template renderer.

With diecutter, the command looks like this:

.. code-block:: sh

   curl -X POST \
        --data-binary '@etc/presets.ini' \
        -H "Content-Type: text/plain" \
        http://diecutter.local/django/settings_local.py \
        > etc/django/settings_local.py

... where we POST data from INI file to "settings_local.py" template and save
the rendered file locally.

Of course we have something like this in "presets.ini":

.. code-block:: text

   [django]
   debug = true

And something like that in "settings_local.py" template:

.. code-block:: jinja

   DEBUG = {% if django.debug %}True{% else %}False{% endif %}

.. note::

   Of course this "debug" example would be simple to manage manually. But think
   of more complex cases where one switch ("with_sentry" as an example) affects
   various portions of the configuration file.

   That is, with a template, you can focus on a few variables that really
   matter, whereas manually, you have to dive into the configuration details.

When we deploy, we first manage the "presets.ini" file.

This works very well to generate basic setup. It is easy to automate.


****************
Use DVCS locally
****************

So, with templates, we can automate all basic setup. Then we need to apply
specific configuration on a machine or application.

As an example, you want custom logging configuration on your development
environment (and it is so specific to your development environment that is is
useless to share).

Remember that when you upgrade your application, deployment scripts regenerate
configuration files from templates. But you do not want your local and specific
configuration to be lost!

You want to replay your specific changes on top of the generated configuration.

  Oh wait! I know this pattern: it is called "rebase"!

Let's use a DVCS. I will use git below, but you could achieve the same thing
with other tools.

Let's create a repository in ``etc/`` folder:

.. code-block:: sh

   cd etc/
   git init
   generate_default_configuration   # Run some provisioning script that
                                    # generate configuration files with default
                                    # values.
   git add .
   git commit -am "Generated default configuration from my-project version N"

Now, let's setup specific things, in a "local" branch:

.. code-block:: sh

   git checkout -b local
   vim django/settings_local.py   # Customize the configuration.
   git commit -am "Specific database setup."

And that's all for now. We can run our project...

Later, we need to upgrade.
First upgrade default configuration in master branch:

.. code-block:: sh

   git checkout master
   generate_default_configuration   # Upgrade default configuration.
   git add .
   git commit -am "Upgraded default configuration to my-project version N+1"

Then apply local changes on top of defaults:

.. code-block:: sh

   git checkout local
   git rebase master

Yes, that's enough.

Sometimes you will have to resolve some conflicts, but **detection and
management of conflicts is a feature!** What would happen if you do not get
warned and configuration is merged automatically? Bad things could happen, your
application could be broken, you could lose data... DVCS tools are really
helpful to manage those conflicts:

* review which configuration directives have been added
* review which directives have been deprecated
* review which default values have changed
* undo (rollback) or redo if something goes wrong.

Also, have a look at `merge-based rebasing`_ if you need a safe history.

.. note::

   Do you remember the data presets we used to render templates? In fact, we
   do manage these local presets in a local DVCS repository too. So that we are
   aware of new configuration directives, obsolete ones, conflicts...


Do not push local configuration!
================================

Notice I didn't pushed local configuration. That is an important point: local
configuration have to remain local!

As an example, local configuration could contain sensible data, such as
passwords. And, generally, it is a bad idea to share passwords.

Do you really need to push something? I would say you are dealing with some
non-local configuration :D
So have a break, and perhaps reconsider generation of defaults.

Need to backup configuration? This point depends on your backup/restore policy.
Discuss this topic with your ops and security teammates.


**********************
Environment variables?
**********************

The techniques mentioned in DjangoCon.eu use environment variables. But how do
you review the changes or rollback environment variables?

As of today, I do not know how to do that easily... so I do not want to manage
environment variables.

But I know how to do it on files with distributed version control systems such
as git or mercurial...


************
What's next?
************

We like the process described in this article, but:

* we'd like to automate things a little bit more. It looks like configuration
  review (diff validation, conflicts resolution) is the only thing that cannot
  be automated.

* is there a tool which provides a user-friendly interface for this
  configuration workflow?

* else, what about releasing one?

And keep in mind that this configuration management technique is not limited to
Django.


.. target-notes::

.. _`DjangoCon Europe 2013`: http://2013.djangocon.eu/
.. _`"Two scoops of Django" book`: http://django.2scoops.org/
.. _`mr.developer`: https://pypi.python.org/pypi/mr.developer
.. _`extra-paths option of z3c.recipe.scripts`:
   https://pypi.python.org/pypi/zc.recipe.egg/2.0.0#specifying-extra-script-paths
.. _`diecutter`: https://diecutter.readthedocs.org
.. _`merge-based rebasing`: http://tech.novapost.fr/psycho-rebasing-en.html
