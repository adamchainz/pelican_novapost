###################
Novapost's paradize
###################

This repository contains content of Novapost's technical blog.


*********
Resources
*********

* Novapost's technical blog: http://tech.novapost.fr
* Novapost's main site: http://www.novapost.fr
* Pelican's documentation: http://docs.getpelican.com


*****
Usage
*****

Pelican is a static site generator:

* clone this repository on your computer (or edit content via Github UI)
* edit content as text files locally (reStructuredText, Markdown, AsciiDoc)
* generate HTML and push to server.


Install
=======

::

    $ git clone git@github.com:novagile/pelican_novapost.git
    $ cd pelican_novapost/
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

More at Pelican's documentation: http://docs.getpelican.com

More about reStructuredText: http://docutils.sourceforge.net/rst.html

Preview your article
====================

Compile your server on the flow::

    $ make devserver

Then connect on http://localhost:8000/ to see the blog running locally.

Release your new blog post online
=================================

When you are happy with what you've done, release it on the web with::

    $ make rsync_upload
