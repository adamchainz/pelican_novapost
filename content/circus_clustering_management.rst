Circus clustering management
############################

:date: 2012-09-16 15:28
:tags: python, circus
:category: Python
:author: Rémy Hubscher
:lang: en

Introduction
============

During PyConFr 2012, `Jonathan Dorival`_, `Mathieu
Agopian`_ and `me`_, spent two days sprinting on `Circus`_.

Circus is a process & socket manager. It can be used to monitor and
control processes and sockets.

At Novapost, we usually launch processes on different (virtual) machines, 
so we wanted `Circus`_ to manage processes launched on different servers.

.. _`Circus`: http://docs.circus.io/
.. _`Jonathan Dorival`: http://github.com/jojax/
.. _`Mathieu Agopian`: http://github.com/magopian/
.. _`me`: http://github.com/natim/


Brainstorming
=============

We had the chance to discuss this with `Tarek Ziadé`_ and `Alexis
Metaireau`_ at PyconFr 2012. They have the same needs at Mozilla so 
we seized the opportunity and brainstormed about our needs, and finally 
ended up with this conclusion:

.. _`Tarek Ziadé`: http://ziade.org/
.. _`Alexis Metaireau`: http://blog.notmyidea.org/


We want
*******

* An unique interface to manage processes on different circus nodes
  (eventually called ``circusmeta``)
* To manage an unique circus instance or pool of nodes the same way.
* To start new circus nodes and automatically be able to manage them
* To start new workers on specific nodes (by explicitely giving the name of the
  node)
* To add a new worker on the cluster and let ``circusmeta`` chose
  which node it will be started on.
* To aggregate statistics about the cluster
* To run commands on a specific node or every nodes


We don't want
*************

* To manage the virtual machines flow
* To register some watchers on an empty ``circusd``


Implementation
==============

After this brainstorming we ended up with this implementation roadmap:

* Have a default name for the ``circusd`` server but also be able to
  rename (via a config file or a circus command)
* Modify the stats management to prefix stats with the unique name of the node
* Create a socket on ``circusmeta`` that will agregate every ``circusd
  stats_endpoint`` on a unique socket base of the pool configuration.
* Adapt existing circus tools (circus-top, circushttpd, circusctl, ...) to handle
  nodes.


A word about circusmeta
=======================

With that in mind, ``circusmeta`` don't need to be a ``server``. It is
just a tool which will manage a pool of nodes by connecting node's
sockets (stats, endpoint and pubsub).

So ``circusmeta`` just need to be running when
accessing the pool. (When we use a circustool on the pool)

``circusmeta`` will be configured with the list of servers and some
information about the strategy it will use when adding watchers on the
pool.


Conclusion
==========

This proposal doesn't change the
core of ``circus``, there is no master/slave thing or complex architecture
to configure or understand.

The only changing point is that each stat message need to be identified with
the node name, in order to use the same command for a
unique server or for a pool behind ``circusmeta``.

The codebase is also already there, we still need some code to take one
step back and manage a list of node in ``circus`` tools.
