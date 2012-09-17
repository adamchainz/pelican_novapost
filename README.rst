##################################
Novapost's Paradize Technical Blog
##################################


Install Pelican
===============

::

    $ make virtualenv update


Write an article
================

Create a file in the ``content`` folder : ``my-article-slug.rst``

::

    ##########################
    PyconFR 2012 à la Villette
    ##########################

    :date: 2012-08-31 13:55
    :tags: afpy, pycon, python
    :category: Conférences
    :author: Rémy Hubscher

    ************
    Introduction
    ************

    Content of your blog post

Preview your article
====================

Compile your server on the flow::

    $ make devserver

Then connect on http://localhost:8000/ to see the blog running locally.

Release your new blog post online
=================================

When you are happy with what you've done, release it on the web with::

    $ make rsync_upload
