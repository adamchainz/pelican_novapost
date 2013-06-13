Circus Sprint @ Novapost July 8th-9th, 2013
###########################################

:date: 2013-06-13 15:37
:tags: python, circus
:category: Python
:author: Rémy Hubscher
:lang: en

Introduction
============

Circus is a process & socket manager. It can be used to monitor and
control processes and sockets.

At Novapost, we usually launch processes on different (virtual) machines, 
so we wanted `Circus`_ to manage processes launched on different servers.

.. _`Circus`: http://docs.circus.io/

Today we are using circus in production and one nice feature is to be
able to monitor all processes and sockets dispatched around our
servers from one interface.


Mozilla is coming
=================

Circus is an Open Source project started by `Tarek Ziadé`_ and `Alexis
Metaireau`_ from the Mozilla Services team.

.. _`Tarek Ziadé`: http://ziade.org/
.. _`Alexis Metaireau`: http://blog.notmyidea.org/

It appears that after one year of development, Mozilla is now looking
forward to use Circus internally to manage their service
infrastructure.

As a matter of fact we, at Novapost, are also planning to replace our
supervisord based infrastructure with circus.


A Sprint to implement clustering
================================

Novapost is organizing a Sprint on Circus for two days in Paris.

From July the 8th to July the 9th 2013.

Pizza and Drinks will be provided.

You are welcome to help us, please register here :
http://www.doodle.com/s856fqh4mht32nw6
