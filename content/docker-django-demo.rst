####################
Let's do some docker
####################

:date: 2014-05-29 09:00
:tags: docker django demo
:category: Astuces
:author: Florent Pigout
:lang: en
:slug: docker-django-demo


*****
Intro
*****

From DjangoCon
==============

`Nice talk <https://speakerdeck.com/amjith/introduction-to-docker>`_ from
DjangoCon.

Docker doc
==========

In case you are lost, or you are tuning your Dockerfile, take a lot
`here <http://docs.docker.io/>`_, you should find the answer.

Docker index
============

Here is where we can find most of the 'officials' images:
`docker index <http://index.docker.io/>`_


A django app
============

This demo aims to embedded the following `django celery demo
<https://github.com/celery/celery/tree/v3.1.11/examples/django>`_ in an hand
made container.


*******
Install
*******

It's simple
===========

Very easy to install:

.. code:: sh

    ~$ apt-get install docker

It's light
==========

Few dependencies:

.. code:: sh

    ~$ apt-cache depends docker
    docker
    Depends: libc6
    Depends: libglib2.0-0
    Depends: libx11-6


***********
First Image
***********

List
====

List available images:

.. code:: sh

    ~$ docker images

Search
======

List available debian images:

.. code:: sh
        
    ~$ docker search debian
    NAME                        DESCRIPTION                                     STARS     OFFICIAL   TRUSTED
    debian                      (Semi) Official Debian base image.              41                   
    tianon/debian               use "debian" instead - https://index.docke...   14                   
    stackbrew/debian            Base debian images                              10                   
    ...

Retrieve
========

Get the lastest of the most popular:

.. code:: sh

    ~$ docker pull debian
    Pulling repository debian
    e565fbbc6033: Download complete 
    511136ea3c5a: Download complete 
    405cce5cd17d: Download complete 

Should have something now:

.. code:: sh

    ~$ docker images
    REPOSITORY   TAG       IMAGE ID        CREATED         VIRTUAL SIZE
    debian       latest    e565fbbc6033    4 weeks ago     115 MB
    ...


*************
Run a command
*************

Echo hi
=======

Let's echo something:

.. code:: sh

    ~$ docker run debian echo "hi"

Do it again
===========

Even simple as it is, it's already reproducible:

.. code:: sh

    ~$ docker ps -a
    CONTAINER ID   IMAGE          COMMAND   CREATED         STATUS                    PORTS    NAMES
    8ec4815f3ccd   debian:latest  echo hi   51 seconds ago  Exited (0) 49 seconds ago          silly_hypatia

    ~$ docker start -i 8ec4815f3ccd
    8ec4815f3ccd
    hi

Clean
=====

Remove that junk container:

.. code:: sh

    ~$ docker rm 8ec4815f3ccd


***************************
Start interactive container
***************************

Enter in the container
======================

Run a debian container:

.. code:: sh

    ~$ docker run --name deby -it debian /bin/bash

Do your stuff:

.. code:: sh

    root@deby:/# echo 'hi'
    hi


************
Get postgres
************

Pull:

.. code:: sh

    ~$ docker pull paintedfox/postgresql:latest

Run:

.. code:: sh

    ~$ docker run -d \
    --name="postgresql" \
    -h "db.local" \
    -e USER="docker" \
    -e DB="docker" \
    -e PASS="docker" \
    paintedfox/postgresql


************
Get rabbitmq
************

Pull:

.. code:: sh

    ~$ docker pull tutum/rabbitmq:latest

Run:

.. code:: sh

    ~$ docker run -d \
    --name="rabbitmq" \
    -e RABBITMQ_PASS="pass" \
    -h "amqp.local" \
    tutum/rabbitmq

********************
Make my django image
********************

The Dockerfile
==============

.. code:: sh

    ~$ echo "
    FROM debian:latest
    MAINTAINER Florent Pigout "florent@toopy.org"

    RUN apt-get update
    RUN apt-get upgrade -y
    RUN apt-get install -y git python2.7 python-pip python-psycopg2
    RUN pip install django django-celery

    RUN git clone https://github.com/celery/celery.git /root/celery
    RUN cp -rf /root/celery/examples/django /root/celery-example-django

    ADD settings_local.py /root/celery-example-django

    ADD run.sh /root
    RUN chmod +x /root/run.sh
    
    CMD /root/run.sh
    " > Dockerfile

A run.sh script
===============

.. code:: sh

    ~$ vim run.sh
    #!/bin/bash
    export DJANGO_SETTINGS_MODULE=settings_local

    echo "[run] go to example folder"
    cd /root/celery-example-django

    echo "[run] syncdb"
    python manage.py syncdb --noinput

    echo "[run] create superuser"
    echo "from django.contrib.auth.models import User
    if not User.objects.filter(username='admin').count():
        User.objects.create_superuser('admin', 'admin@example.com', 'pass')
    " | python manage.py shell

    echo "[run] runserver"
    python manage.py runserver 0.0.0.0:8000


Some settings
=============

.. code:: sh

    ~$ vim settings_local.py
    import os
    from proj.settings import *

    BROKER_URL = 'amqp://admin:pass@{0}//'.format(os.environ['RABBITMQ_PORT_5672_TCP_ADDR'])

    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.postgresql_psycopg2',
            'NAME': 'docker',  
            'USER': 'docker',
            'PASSWORD': 'docker',
            'HOST': os.environ['POSTGRESQL_PORT_5432_TCP_ADDR'],
            'PORT': '',
        }
    }


**************
Image Building
**************

Build my image
==============

.. code:: sh

    ~$ docker build -t django .

It's ready
==========

.. code:: sh

    ~$ docker images
    REPOSITORY                 TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
    django                     latest              1549cbf94b6e        26 minutes ago      463.6 MB
    ...


******
Run it
******

.. code:: sh

    ~$ docker run -it \
    --name "django" \
    --link postgresql:postgresql \
    --link rabbitmq:rabbitmq \
    -h "django.local" \
    django


*******
Push it
*******

Next time ;)
