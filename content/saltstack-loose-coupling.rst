########################################################
SaltStack state orchestration and formula loose coupling
########################################################

:date: 2015-15-19 12:00
:tags: saltstack, devop, best-practice
:category: SaltStack
:author: James Pic
:lang: en
:slug: saltstack-loose-coupling-and-orchestration

SaltStack_ enables DevOps_ to orchestrate and automate server administration
tasks. We'll explore the implications of using orchestration in terms of code
quality in this article.

Our initial CI uses the all-in-one configuration for each service to deploy it
with its dependencies (ie. postgresql, redis, rabbitmq, etc, etc ...).
Migrating the database looked like this::

    yourproject_migrate:
      cmd.wait:
        - name: {{ pillar.yourproject_path }}/bin/migrate

This state failed in CI because the highstate executed the service setup
command before the database was ready. So I provided a patch the state into
this::

    yourproject_migrate:
      cmd.wait:
        - name: {{ pillar.yourproject_path }}/bin/migrate
        - require:
          - service.running: database

That breaks `loose coupling
<https://en.wikipedia.org/wiki/Loose_coupling>`_ as it ties yourproject_migrate
state to state database service. Also, that looks like an attempt to do
orchestration with highstate, which it wasn't designed for. Now that worked in
our CI environment where we're testing the allinone minion configurations which
install a database and the service in the same minion. However, when running in
a minion which hadn't the database state, it would fail to execute as such::

     Comment: The following requisites were not found:
                                 require:
                                     service: database

Such a quick and dirty fix would do the trick for now::

    yourproject_migrate:
      cmd.wait:
        - name: {{ pillar.yourproject_path }}/bin/migrate
        {% if allinone %}
        - require:
          - service.running: database
        {% endif %}

However, what we really want to do is first run a highstate on the database
servers, and then a highstate on yourproject's servers. That's orchestration
and that's what `state.orchestrate
<http://docs.saltstack.com/en/latest/topics/tutorials/states_pt5.html#orchestrate-runner>`_
is for.

Instead, we should remove the ``require`` statement and run ``state.orchestrate
orchestration.yourproject.install`` instead with such an
``orchestration/yourproject/install.sls``::

    database_setup:
      salt.state:
        - tgt: roles:database
        - tgt_type: grain
        - highstate: True

    yourproject_install:
      salt.state:
        - tgt: roles:yourproject
        - tgt_type: grain
        - highstate: True

And that'll set up the database server before yourproject ensuring that we're
not trying to upgrade a database which isn't ready.
