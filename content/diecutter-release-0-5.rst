#######################################
diecutter.io reads templates on Github!
#######################################

:date: 2013-07-19 14:00
:tags: templates, service, diecutter
:category: Astuces
:author: Benoît Bryon
:lang: en
:slug: diecutter-0-5-released

We have just released `diecutter <https://diecutter.readthedocs.org/>`_ 0.5,
which introduces support of remote templates. Let's explain why it does
matter...


****************
Remote templates
****************

Support of remote templates is the major feature of the 0.5 release.

.. note::

   Keep in mind that the current "remote templates" implementation is
   experimental. It is quite slow and greedy. The scope of this 0.5 release was
   to publish a proof of concept. We are planning some improvements related to
   performance and scalability in next releases.

   That said, let's give it a try!

Given:

* a public online diecutter server at http://diecutter.io/github/
* a template hosted in a public repository on github.com:
  https://github.com/novagile/diecutter/blob/0.5/demo/templates/greetings.txt

We can use diecutter.io to render the template:

.. code:: sh

   $ curl -X POST --data name=Novapost http://diecutter.io/github/novagile/diecutter/0.5/demo/templates/greetings.txt
   Hello Novapost!

Of course, you can also render directories as archives:

.. code:: sh

   $ curl -X POST -d django_project=wonderful http://diecutter.io/github/novagile/diecutter/0.5/demo/templates/+django_project+/ | tar -zt
   manage.py
   wonderful/__init__.py
   wonderful/settings.py
   wonderful/urls.py
   wonderful/wsgi.py

Supported URLs are ``http://diecutter.io/github/<owner>/<project>/<revision>/<path/to/file/or/directory>``,
where:

* ``<owner>`` is the repository owner, "novagile" in the examples above.
* ``<project>`` is the repository name, "diecutter" in the examples above.
* ``<revision>`` is the commit, tag or branch, "0.5" in the examples above.
* ``<path/to/file/or/directory>`` is the path to the file or directory template
  in the repository, "demo/templates/greetings.txt" in the first example above.

Yes, that's all.


*******************
Why does it matter?
*******************

Remote templates feature makes diecutter.io a SAAS: you can use diecutter.io
service to render templates that are managed in online public repositories.
The templates does not belong to diecutter. You, or third-party authors, own
them.

Now, **let's share templates online!**


************
What's next?
************

We are planning various improvements:

* performance and scalability related to loading templates on Github
* support of multiple templates engines depending on the template to render.
  Jinja2 and Django to begin
* SSL on diecutter.io
* improved documentation
* more shared templates!

And more...
Check `milestones <https://github.com/novagile/diecutter/issues/milestones>`_
for details about the roadmap.
