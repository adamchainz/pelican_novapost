#####################
Introducing diecutter
#####################

:date: 2013-01-29 17:34
:tags: templates, service, python
:category: Python
:author: Rémy HUBSCHER
:lang: en
:slug: diecutter-0.1


Introduction
============

Some days ago we started a proof of concept about a template
generation service called `diecutter <https://github.com/novagile/diecutter>`_.

Today we are proud to present your the first release.

A lot of people didn't understand why we were so exited about this
project.

Let me explain what is my feeling about it.

When you want to deploy a system or a project, you need to configure
it for your environment it can be quite simple, just modify the
``settings.py`` of your django project for instance.

But if you want to keep it configured in you dev environment where you
might be using **sqlite3** as well as in production where you might want
to use **postgres** then you will like ``diecutter``.


Simple example of how we handle this
====================================

We create a ``config.ini`` file that will keep all our variables::

   [admin]
   name = Webmaster
   email = webmaster@localhost

   [database]
   type = sqlite3
   name = db.sqlite3

When you POST this ``config.ini`` file diecutter convert it to a
context for your template::

    {{ admin.name }}
    {{ admin.email }}
    {{ database.type }}
    {{ database.name }}

Diecutter also add some information::

   {{ diecutter.api_url }}
   {{ diecutter.version }}
   {{ diecutter.now }}

We create our template ``settings.py``::

    # Generated with diecutter-{{ diecutter.version }} at {{ diecutter.now }}
    ADMINS = (
        {% if admin %}('{{ admin.name }}', '{{ admin.email }}'),{% endif %}
    )
    
    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.{% if database and database.type %}{{ database.type }}{% else %}sqlite3{% endif %}',
            'NAME': '{% if database and database.type %}{{ database.name }}{% else %}db.sqlite{% endif %}',
            'USER': '{% if database and database.user %}{{ database.user }}{% endif %}',
            'PASSWORD': '{% if database and database.passwd %}{{ database.passwd }}{% endif %}',
            'HOST': '{% if database and database.host %}{{ database.host }}{% endif %}',
            'PORT': '{% if database and database.port %}{{ database.port }}{% endif %}',
        }
    }

We store our new template in diecutter::

    $ curl -XPUT http://localhost:8106/settings.py -F "file=settings.py"

And we can query our template::

    $ curl -X POST --data-binary '@config.ini' -H "Content-Type: text/plain" http://localhost:8106/settings.py
    # Generated with diecutter-0.1 at 2013-01-29 18:49:42.543776
    ADMINS = (    
        ('Webmaster', 'webmaster@localhost'),
    )
    
    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.sqlite3',
            'NAME': 'db.sqlite3',
            'USER': '',
            'PASSWORD': '',
            'HOST': '',
            'PORT': '',
        }
    }

Going futher
============

The magic comes with the directory feature since you can configure all
your app in one request with one config.ini file. All you components
are then linked together with one file that is related to your environment.

More over you don't need to install anything in your host to configure
it. So you can even configure the provisionning using **diecutter**.

