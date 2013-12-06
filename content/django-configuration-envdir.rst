###############################################################
(Django) configuration with environment variables (and schemas)
###############################################################

:date: 2013-12-06 12:00
:tags: django, configuration, deployment
:category: Astuces
:author: Benoît Bryon
:lang: en
:slug: django-configuration-with-envdir

`"Two scoops of Django" book`_ recommends to manage Django configuration using
environment variables. My main complaint about this technique was environment
variables cannot be put under version control (see details below). But I was
told about `envdir`_, which loads environment variables from the filesystem...
So, I tried it, and here is some feedback.

As a summary:

* I like the ideas related to loading configuration from external resources.
* I feel using raw things like ``SECRET_KEY = os.environ['SECRET_KEY']`` is not
  enough.
* I did some workarounds by declaring some configuration specifications
  (schemas).
* Things are not perfect yet, but they are getting better!

.. note::

   In this article, I focus on Django configuration, because that's the start
   of the story. But most of the techniques are not specific to Django and
   could be adapted to Python projects, and perhaps to any configuration files.


*************************************
Environment variables have no history
*************************************

Environment variables are fine to store configuration values.
But, as explained in `a previous article about configuration`_, they do not
support history. And I do need to review configuration changes, rollback...

Whereas files, combined with distributed version control systems, support these
features.

.. note::

   Putting local configuration under version control does not imply to push it
   on remote places! **Local configuration should remain local!**

But, let's introduce `envdir`_...


********************
Envdir to the rescue
********************

`envdir`_ is a project that loads contents of files into environment variables.
It is dead-simple to use.

Using `envdir`, I could:

* in Django settings files (``settings.py``), use ``os.environ`` to get the
  value of local settings:

  .. code-block:: python

     SECRET_KEY = os.environ['SECRET_KEY']

* generate local configuration with templates.
* put local configuration under (local) version control.

.. note::

   There are other ways to setup environment variables via files. See
   `circus configuration files`_ as an example. Whatever the tool, the idea is
   to manage configuration files which can be used to populate environment
   variables.

It looks good... but I quickly had to find some workarounds about
deserialization.


****************************
Extract data from os.environ
****************************

Environment variables in ``os.environ`` are strings. But I need various types,
such as booleans or integers:

.. code-block:: python

   DEBUG = parse_boolean(os.environ['DEBUG'])

Where ``parse_boolean()`` looks like this:

.. code-block:: python

   def parse_boolean(value):
       """Return boolean version of ``value``."""
       true_values = ['true', 'yes', '1', 'on']
       false_values = ['false', 'no', '0', 'off']
       value = str(value).strip().lower()
       if value in true_values:
           return True
       elif value in false_values:
           return False
       raise ValueError(
           'Value "{value}" could not be converted to boolean. '
           'Supported values are "{true}", "{false}".'.format(
               value=value,
               true='", "'.join(true_values),
               false='", "'.join(false_values)))

I quickly found myself writing simple deserialization functions for every
common data type... including lists and dictionaries!

.. code-block:: python

   DATABASES = parse_yaml(os.environ['DATABASES'])

Fine, I can now get any configuration value from ``os.environ``.
Quickly, my ``settings.py`` file got made of ``os.environ['SOMETHING']``...


***********************************************
Maintain a registry of "overridable" directives
***********************************************

I was registering overridable configuration directives like this:

.. code-block:: python

   SOME_DIRECTIVE = parse_some_type(os.environ['SOME_DIRECTIVE'])

To make things more simple, I wrote something like this:

.. code-block:: python

   globals().update(parse_directives(os.environ, environment_directives)

Where ``environment_directives`` looked like that:

.. code-block:: python

   environ_directives = {
       'DATABASES': parse_yaml,
       'DEBUG': parse_boolean,
       'SECRET_KEY': parse_string,
   }

... and ``parse_directives()`` looked like this:

.. code-block:: python

   def parse_directives(input_data, mapping):
       output_data = {}
       for key, parse in mapping.iteritems():
           output_data[key] = parse(input_data[key])

But I quickly found myself registering overridable configuration directives,
again and again...


**************************************
Register every configuration directive
**************************************

I first tried to limit the number of overridable configuration directives,
because I believe that environments (typically PROD and DEV) should look like
each other, i.e. there should be only small changes between environments of a
given project.

As an example, if database is PostgreSQL in PROD environment, then DEV
environments should use PostgreSQL too. Database type does not change, whereas
database password varies.

With such an idea in mind, I identified two scenarios:

* the setting is really local, such as database password: register it in
  overridable local settings.

* the setting should be shared by other environments, such as database type:
  alter default settings, commit and push in code.

But, even if local changes are small, they are so many... I was committing
"Registered SOME_SETTING as local configuration" six times a day.

In fact, everytime we needed a new overridable setting, we had to change the
code, pass the tests, ... before we could actually change the setting in some
environment. It was too long. Ops/Devops do not want to wait just to override a
configuration directive. When they need to change configuration, they want it
now, they do not want to wait for a new release.

One could argue this workflow is a feature, because it makes sure the code is
up to date. That's acceptable when the configuration directive should be shared
across environments... But when it is a setting that is local, people cannot
wait!

So I started to wonder: what about allowing local configuration to override all
directives? Let's try something and see if it fits our use case...


**************************************
Deserialize any external configuration
**************************************

What matters is to be able to get a mapping from external configuration,
whatever its format.

Here is an example dedicated to ``os.environ``:

.. code-block:: python

   import json
   import yaml

   def parse_string_mapping(input):
       """Convert mapping of {key: string} to {key: complex type}.

       Simple key-value stores (flat mappings) are supported:

       >>> flat_mapping = {'DEBUG': 'True', 'SECRET_KEY': 'not a secret'}
       >>> output = convert_string_mapping(flat_mapping)
       >>> output == flat_mapping
       True

       Values can be complex types (sequences, mappings) using JSON or YAML.
       Keys using ".json" or ".yaml" suffix are automatically decoded:

       >>> nested_mapping = {
       ...     'DATABASES.yaml': 'ENGINE: sqlite3\nNAME: var/db.sqlite',
       ... }
       >>> output = convert_string_mapping(nested_mapping)
       >>> output['DATABASES'] == {'ENGINE': 'sqlite3', 'NAME': 'var/db.sqlite'}
       True

       """
       output = {}
       for key, value in input.iteritems():
           if key.endswith('.json'):
               output[key[:-5]] = json.loads(value)
           elif key.endswith('.yaml'):
               output[key[:-5]] = yaml.load(value)
           else:
               output[key] = value
       return output

I would use it like this:

.. code-block:: python

   import os

   raw_settings = parse_string_mapping(os.environ)

Then I can use the same pattern to load configuration from some YAML file:

.. code-block:: python

   import yaml

   raw_settings = yaml.load(open('etc/local_settings.yaml'))

Or any JSON/YAML file, depending on the filename's extension:

.. code-block:: python

   import json
   import yaml

   def parse_file(filename):
       if filename.endswith('.yaml'):
           return yaml.load(open(filename))
       elif filename.endswith('.json'):
           return json.load(open(filename))
       else:
           raise ValueError('Cannot guess format of configuration file.')

Or from some python module (this looks like ``django.conf.Settings``
behaviour):

.. code-block:: python

   def parse_module(module_name):
       """Import settings from module's globals and return them as a dict.

       >>> settings = settings_from_module('django.conf.global_settings')
       >>> settings['DATABASES']
       {}
       >>> '__name__' in settings
       False

       """
       module = __import__(module_path, fromlist='*', level=0)
       is_uppercase = lambda x: x.upper() == x
       is_special = lambda x: x.startswith('_')
       return dict([(key, value) for key, value in module.__dict__.items()
                    if is_uppercase(key) and not is_special(key)])

   raw_settings = parse_module('myproject.local_settings')

Ok, now I can read enough configuration input formats. So I am not tied
to one format, and I can even combine several ones. As an example, I could
read defaults from a module, then update defaults with local settings from
environment variables.

I could also have several "combine/merge" techniques, but "dict.update()" will
be enough to start.

As an example, I could write the following:

.. code-block:: python

   raw_settings = {}
   raw_settings.update(parse_module('django.conf.global_settings'))
   raw_settings.update(parse_module('myproject.settings_default'))
   raw_settings.update(parse_string_mapping(os.environ))

Well, I have a dictionary of settings. Do I still need a specification for
settings? Yes!

First of all, because I still have strings, where I sometimes need booleans,
strings, and other basic scalar types.

Then because as soon as I added many settings, I was facing optional and
required settings, a.k.a. validation...


**********************
Validate configuration
**********************

Some settings are mandatory in local configuration. An example is
``SECRET_KEY``: it must be customized in each environment, or it is not a
secret! ``SECRET_KEY`` **MUST** be in local settings.

Other settings have a sane default but can optionally be overriden locally. An
example is ``DEBUG``. The sane default value is ``False``, but many developers
will appreciate to turn it ``True`` in their development environment. ``DEBUG``
**CAN** be in local settings.

So I added a specification for required/optional values:

.. code-block:: python

   environ_directives = {
       'DEBUG': {
           'parser': parse_boolean,
           'required': False,
           'default': False,
       },
       'SECRET_KEY': {
           'parser': parse_string,
           'required': True,
       }
   }

... and updated ``parse_directives()`` accordingly:

.. code-block:: python

   def parse_directives(input_data, spec):
       output_data = {}
       for key, options in spec.iteritems():
           parse = options['parser']
           try:
               output_data[key] = parse(input_data[key])
           except KeyError:
               if options['required']:
                   raise ImproperlyConfigured(
                       'You must set {name} configuration directive in local '
                       'settings.'.format(name=key))
               else:
                   output_data[key] = options['default']
        return output_data

This optional VS required is a basic validation. With little imagination (or
experience), one can find use cases for more advanced validation:

* some settings are required depending on other settings. As an example, if
  I enable ``USE_I18N``, then ``LANGUAGES`` is mandatory.

* some settings must be in a specific format. As an example, I implicitely
  did this in the ``parse_boolean()`` above: if the value is not a known
  "boolean string", an exception is raised. More advanced examples would be
  ``DEFAULT_FROM_EMAIL``: not only it is a string, but it should be a valid
  email address!

So, validation would be definitely useful. But implementing a full-featured
validation tool is hard work. Let's see if some third-party tool already
exists...


*************************
Use configuration schemas
*************************

I will not cover this topic in depth in this article, but here is the idea:
I want to register every configuration directive and setup some validation.
I need a configuration schema.

* I first thought about Django forms. But they are not made to deserialize
  complex datatypes such as dictionaries. They are made for "flat" input data.

* I discovered `django-configglue`_, based on `configglue`_. It provides a
  schema for Django's builtin settings. The concept looks great, but it is
  limited to configuration files in INI configuration format. And I feel INI
  configuration files are definitely not suitable to store nested
  configuration, whereas JSON, YAML (or XML) are. I'd like to be able to load
  configuration from various formats, including Python modules.

* I finally tried `colander`_. Once the schema has been setup, it is really
  easy to use:

  .. code-block:: python

     import colander
     import yaml

     class DjangoConfigurationSchema(colander.Mapping):
         DEBUG = colander.SchemaNode(
             colander.Boolean(),
             missing=False,
             default=False
         )
         # ... and many others.
         # Have a look at https://gist.github.com/benoitbryon/7827678

     raw_settings = parse_file(os.environ['DJANGO_SETTINGS_FILE'])
     schema = DjangoConfigurationSchema()
     cleaned_settings = schema.deserialize(raw_settings)

     # Finally update globals because that's what Django uses.
     globals().update(cleaned_settings)


***********************************
Healthchecks validate configuration
***********************************

One may feel configuration schemas are over-engineering.
Well, they require more efforts than just declaring and using a bunch of
module-level variables with uppercase names. But there are valuable benefits:

* as explained above, schemas make it easy to load configuration from various
  locations.

* schemas make it easier to validate configuration. Such a validation should
  be part of healthchecks (did I mentioned `python-hospital`_?). Once you
  deployed your project, you run healthchecks and get feedback if something is
  going wrong. As an example, you should get alerts if
  ``settings.DEFAULT_FROM_EMAIL`` is not a valid email address, but also if
  ``settings.EMAIL_HOST`` cannot be reached.


****
Pros
****

* configuration is not code: code in PROD is the same as code in DEV.

* configuration is separated from code: no mix, configuration does not live
  in code's repository. That's clean.

* environment variables are loaded one layer "above" Python process. It means
  that configuration files (envdir) are read once, not on every HTTP request
  that hits the server, not on every worker process that is spawned by
  process manager (`circus`_).

* environment variables can be defined with many tools: `envdir`_, `circus
  configuration files`_, virtual machines managers...

* since we can define environment variables from files, we can take advantage
  of tools that manage files:
  
  * generate local configuration from templates (`diecutter`_, `salt`_, ...)
  * put local configuration under (local) version control then diff, undo...
    (`git`, `mercurial`, ...).

* schemas make it possible to both deserialize and validate configuration
  (`colander`_).


****
Cons
****

* have to declare every configuration directive in code, in order to perform
  validation and cleaning. Yes, this is a tedious task.

* envdir is one value in one file. We often need dictionaries (DATABASES), so
  I had JSON/YAML in environment variables. I feel it is quite ugly.


************
What's next?
************

* optionally replace envdir by loading one or several files (YAML, JSON, ...)

* generate envdir, circus, or whatever dedicated configuration files with
  templates. Perhaps have a look at `diecutter`_.

* register all configuration directives, load the specification from a
  third-party

* use schemas for deserialization and validation. By the way, did you know
  `daybed`_ uses `colander`_?

* create healthchecks that validate configuration

* use forms for UI! An UI to configure your projects! Yeah!

* put all of this in third-party libraries (`Django`, `django-configglue`_,
  ...)


.. target-notes::

.. _`"Two scoops of Django" book`: http://django.2scoops.org/
.. _`a previous article about configuration`:
   /django-configuration-files-with-templates-and-dvcs-en.html
.. _`envdir`: https://pypi.python.org/pypi/envdir
.. _`django-configglue`: https://pypi.python.org/pypi/django-configglue
.. _`configglue`: https://pypi.python.org/pypi/configglue
.. _`colander`: https://pypi.python.org/pypi/colander
.. _`python-hospital`: https://github.com/python-hospital
.. _`circus`: http://circus.readthedocs.org
.. _`circus configuration files`:
   http://circus.readthedocs.org/en/latest/for-ops/configuration/#env-or-env-watchers-as-many-sections-as-you-want
.. _`rebase local configuration on top of default configuration`:
   /django-configuration-files-with-templates-and-dvcs-en.html
.. _`diecutter`: http://diecutter.io/
.. _`daybed`: https://pypi.python.org/pypi/daybed
.. _`salt`: http://saltstack.org
