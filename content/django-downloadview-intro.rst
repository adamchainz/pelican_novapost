###############################
Introducing django-downloadview
###############################

:date: 2012-12-17 10:30
:tags: django, file, download, nginx, x-sendfile, x-accel
:category: Astuces
:author: Benoît Bryon
:lang: en
:slug: introducing-django-downloadview

At `Novapost <http://www.novapost.fr/>`_, we develop online document storage
services, where download is a standard feature. We use the `Django
<http://djangoproject.com>`_ framework, and we needed some advanced
file-download features.
However, as of version 1.4, Django doesn't provide such features, and `it
seems that download views are not in the roadmap
<https://code.djangoproject.com/ticket/2131>`_.

So, welcome `django-downloadview
<http://pypi.python.org/pypi/django-downloadview>`_.


********
Use case
********

As a developer, you are asked to add download features to websites:

* download PDF documents as attachment,
* export data as CSV files,
* generate archives (tar.gz)...

Sometimes you can simply make sure that those files are on server's disk, then
serve them as static files.

But sometimes you can't, because the files are generated dynamically, or
you have to perform some backend operations such as user authentication.

Using Django, you can write views that return files as attachment, with very
little code. But that's always the same "copy-paste-adapt" pattern. In order
to keep it DRY, you'd appreciate an API.

Last but not least, streaming files with Django (and with Python in general)
isn't the most efficient way to go. Http servers and reverse proxies (nginx,
lighttpd, ...) are far more efficient. Luckily, many servers allow proxied
services (i.e. Django) to delegate the actual streaming process. This feature
is generally known as "x-sendfile". As an example, see `Lighttpd's X-Sendfile
documentation
<http://redmine.lighttpd.net/projects/lighttpd/wiki/X-LIGHTTPD-send-file>`_.

Django-downloadview simplifies the implementation of download views with
Django, with pluggable x-sendfile support.


*******
Example
*******

Given some Django model with a FileField:

.. code-block:: python

   # In some models.py...
   from django.db import models

   class Document(models.Model):
       """A sample model with a FileField."""
       slug = models.SlugField(verbose_name='slug')
       file = models.FileField(verbose_name='file', upload_to='document')

You can easily create a view that returns the file contents as attachment:

.. code-block:: python

   # In some urls.py...
   from django.conf.urls import patterns, url
   from django_downloadview import ObjectDownloadView
   from document.models import Document  # The model we created upward.
   
   download_document = ObjectDownloadView.as_view(model=Document)

   urlpatterns = patterns('',
       url(r'^document/(?P<slug>[a-zA-Z0-9_-]+)/$', download_document),
   )

Pretty straightforward isn't it?

Of course, there are several ways to get download views.
ObjectDownloadView supports more options (basically, all options inherited from
DetailView, more some options related to the download).


*************
Optimizations
*************

You have the download view, let's optimize the streaming. Depending on your
use case, you can enable global optimization with a middleware, or setup
per-view optimizations via decorators.
`Read the documentation about optimizations
<https://django-downloadview.readthedocs.io/en/latest/optimizations/index.html>`_
for details.

As of version 1.0, django-downloadview has built-in support of `Nginx's
X-Accel <http://wiki.nginx.org/X-accel>`_ only.
But `contributions are welcome
<https://django-downloadview.readthedocs.io/en/latest/dev.html>`_ ;)


******************
Made for overrides
******************

We tried to make django-downloadview simple to use, and simple to adapt:

* for most cases, using the built-in views is quick and enough;

* for special cases, class-based views and utilities should be easy to extend
  and override.

Do you feel some use case cannot easily be implemented? `Let us know!
<https://github.com/benoitbryon/django-downloadview/issues/>`_.


******
Future
******

After the 1.0 release, two big user stories were identified, which could
require some API refactoring.

Get closer to django-sendfile
=============================

`django-sendfile <http://pypi.python.org/pypi/django-sendfile>`_ is another project
related to Django and downloads.

`Do the two projects share the same scope? Maybe not.
<https://github.com/johnsensible/django-sendfile/issues/9>`_

Nevertheless, there are features we like in django-sendfile:

* one active backend at a time. Given there are poor chances you want
  optimizations for several servers at once (i.e. return Nginx's X-Accel for
  some views and Lighttp's X-Sendfile for others), one "backend" should be
  enough. As an example, we should need only one "download middleware"
  instance, which gets a backend as argument.

* the API made of a single ``sendfile()`` function. Even if
  django-downloadview keeps on providing class-based views, it should be
  possible to use a multi-purpose ``sendfile()`` function within
  implementation of views. Then maybe use django-sendfile, or reconsider the
  pull-request(s) from django-downloadview to django-sendfile.

.. note::

   `Learn more about similarities and differences between django-sendfile and
   django-downloadview
   <https://django-downloadview.readthedocs.io/en/latest/about/alternatives.html#django-sendfile>`_
   in the latter's documentation.

`Follow "unique backend" story on the bugtracker
<https://github.com/benoitbryon/django-downloadview/issues/25>`_.

Use file wrappers
=================

As of version 1.0, django-downloadview computes file attributes within the
view. That's hard work because file attributes really depend on the file:
it could be a dynamically generated file to be streamed without being stored on
disk, it could be a file on the local filesystem, or a remote file in a Django
storage...

It seems much more suitable to use file wrappers within download views and
responses:

* the file wrapper exposes attributes such as file name, size, url, content...
  Some of the attributes may not be supported, depending of the file, the
  storage or whatever.

* views and response use file attributes, and that's enough. When some
  attribute isn't supported, fallback is supported.

Looks like Django's `FieldFile
<https://docs.djangoproject.com/en/1.4/ref/models/fields/#filefield-and-fieldfile>`_
and `File
<https://docs.djangoproject.com/en/1.4/ref/files/file/#django.core.files.File>`_
wrappers can be used out of the box!

`Follow "file wrappers" story on the bugtracker
<https://github.com/benoitbryon/django-downloadview/issues/23>`_.


**********
References
**********

* `Online documentation <https://django-downloadview.readthedocs.io>`_
* Have a look at `alternatives and related projects
  <https://django-downloadview.readthedocs.io/en/latest/about/alternatives.html>`_.
* `django-downloadview on PyPI
  <http://pypi.python.org/pypi/django-downloadview>`_
* `Issues and feature requests
  <https://github.com/benoitbryon/django-downloadview/issues>`_
* `Main code repository <https://github.com/benoitbryon/django-downloadview>`_
