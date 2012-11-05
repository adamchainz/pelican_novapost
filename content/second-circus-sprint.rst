####################
Second Circus sprint
####################

:date: 2012-11-05 10:36
:tags: python, circus
:category: Python
:author: Mathieu Agopian
:lang: en
:slug: second-circus-sprint


Last Wednesday, the 31st of October, we (with Rémy Hubscher, from Novapost,
Alexis Métaireau and Tarek Ziade from Mozilla) sprinted for the second time on
Circus_.

.. _Circus: http://docs.circus.io/


*************
Circusctl CLI
*************

The feature_ developed by Rémy and Jonathan Dorival (from Novapost also) during
the first sprint has now been completed and merged.

.. _feature: https://github.com/mozilla-services/circus/pull/268

Try it out!

.. code-block:: shell

    $ circusctl

It displays a "supervisorctl-like" CLI when no commands or options are
provided, and is based on the CmdModule_.

.. _CmdModule: http://wiki.python.org/moin/CmdModule


*****
Hooks
*****

Tarek did a nice work on adding hooks_ to watchers, which are now available!
Check the docs_ for more information.

.. _hooks: https://github.com/mozilla-services/circus/pull/299
.. _docs: http://circus.readthedocs.org/en/latest/hooks/#hooks

What this allows is to plug callback functions at various places during the
watcher startup and shutdown process:

* before_start
* after_start
* before_stop
* after_stop

As explained in the docs, this could help you make sure that one watcher is
started (eg Redis in the example given) before starting another one.


***************
Respawn = False
***************

Alexis and I worked on a `first version`_ of an `initial idea`_ by Paul_: being
able to "fire and forget" commands in Circus.

.. _first version: https://github.com/mozilla-services/circus/pull/301
.. _initial idea: https://github.com/mozilla-services/circus/pull/162
.. _Paul: https://github.com/themgt

The idea we came up with is that you could have a ``respawn = False`` option
for a watcher. When a process is started on a watcher with ``respawn = False``,
it'll behave in the same way as usual, but for one detail: a process won't be
restarted automatically if it dies.

Everything else remains the same, but that allows you to configure watchers
with processes that are "one shot", for example cron commands or simple
scripts, without having them to be daemons.

There's still some discussion going on for this feature:

* should the watcher be a different class, ie a *OneShotWatcher*?
* is it possible to "re-fire" processes on such a watcher? If so, how? Using
  the *reload* command?
* if one-shot processes can be "re-fired", should *numprocesses* processes be
  fired, or only ``numprocesses - current number of running processes``?


**********
Bug fixing
**********

Bug fixed:

* `#173`_: Make utils.resolve_name more verbose about errors
* `#297`_: fix logger message formating on socket error
* `#302`_: Fix plugin test timeout too short by... removing timeout

.. _#173: https://github.com/mozilla-services/circus/issues/173
.. _#297: https://github.com/mozilla-services/circus/pull/297
.. _#302: https://github.com/mozilla-services/circus/pull/302


**********
Conclusion
**********

As for the first sprint, this was a real pleasure, and we're all looking
forward to the next sprint! By then, if you feel like playing with Circus,
giving it a try, or even contributing, feel free to come and say hi on irc, in
#mozilla-circus at freenode!
