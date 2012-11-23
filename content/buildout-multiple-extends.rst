##################################
Multiple inheritance with buildout
##################################


************
Beware: bugs
************


*************
Best practice
*************

:file:`frontend.cfg`:

.. code-block:: cfg

   [buildout]
   parts = ${frontend:parts}

   [frontend]
   parts =
       frontend-a
       frontend-b

You can run buildout with standalone :file:`frontend.cfg`. It works and
installs ``frontend-a`` and ``frontend-b``.

:file:`backend.cfg`

.. code-block:: cfg

   [buildout]
   parts = ${backend:parts}

   [backend]
   parts =
       backend-a
       backend-b

You can run buildout with  :file:`backend.cfg`. It works and installs
``backend-a`` and ``backend-b``.

Default inheritance
===================

:file:`buildout.cfg`:

.. code-block:: cfg

   [buildout]
   extends =
       frontend.cfg
       backend.cfg

**By default, the latter (backend) overrides the former (frontend).**

Executing buildout on :file:`buildout.cfg` installs ``backend-a`` and
``backend-b``.

Explicit inheritance composition
================================

:file:`buildout.cfg`:

.. code-block:: cfg

   [buildout]
   extends =
       ${frontend:parts}
       ${backend:parts}

Executing buildout on :file:`buildout.cfg` installs ``frontend-a``,
``frontend-b``, ``backend-a`` and ``backend-b``.

.. note::

   Using this pattern, we didn't had to rewrite the complete (potentially long)
   list of parts from :file:`frontend.cfg` and :file:`backend.cfg`.
