#####################
Introducing diecutter
#####################

:date: 2012-12-18 16:00
:tags: templates, service
:category: Astuces
:author: Benoît Bryon
:lang: en
:slug: introducing-diecutter

Today, we initiated a proof-of-concept template generation service
called `diecutter <https://github.com/novagile/diecutter>`_:

* at a given URL, there is a "template" resource;
* post variables to resource's URL and receive the rendered string.

The resource is, basically, an engine (`Jinja <http://jinja.pocoo.org>`_) and a
template string.


*****
Usage
*****

The project is at a really early stage, but you can try it already.

Install ``diecutter`` from Github and run the server:

.. code-block:: sh

   git clone git@github.com:novagile/diecutter.git
   cd diecutter/
   make develop
   make serve &

Check it works::

    $ curl http://localhost:8106
    {"diecutter": "Hello", "version": "0.1dev"}

Put your template in the service templates directory or use the API::

    $ echo "Hello {{ who }}" | curl -X PUT http://localhost:8106/hello -F "file=@-"
    {"diecutter": "Ok"}

Then we can get the raw template we just created::

    $ curl http://localhost:8106/hello
    Hello {{ who }}

And we can render the template against some variables::

    $ curl -X POST http://localhost:8106/hello -d 'who=world'
    Hello world

Or the same with some JSON input::

    $ curl -X POST http://localhost:8106/hello -d '{"who": "world"}' -H "Content-Type: application/json"
    Hello world


***********
Motivations
***********

As developers, we want to generate configuration from templates.

Many template-related tools already exist. As examples, we can use `PasteScript
<http://pypi.python.org/pypi/PasteScript/>`_ or `Chef
<http://www.opscode.com/chef/>`_, depending on the use case. But those tools,
and the others we know, have drawbacks we'd like to get rid of:

* PasteScript has a shell interface (+ Python interface). There, we'd like
  some REST API.

* PasteScript requires templates to be installed as Python projects, via
  entry points. There we'd like something simpler, or more flexible.

* Chef is quite good for provisioning. But when we just want to generate a
  file from a template, it's overkill. We'd like something small we can install
  as saas or on our local workstation for one shot use.

Right now, features we'd like are:

* lightweight: deploy it easily on the web, on a saas platform, or on local
  workstation.

* configurable and extensible: easy tuning of routes, available template
  engines, authentication...

And here is a typical architecture we are thinking of:

* a diecutter server, exposes API(s).
* a diecutter client, i.e. an IHM such as a web interface, or some shell
  client.
* you and your favorite client, i.e. web browser or shell.

Then what about putting it together with `daybed <http://daybed.rtfd.org/>`_
for schema validation?
