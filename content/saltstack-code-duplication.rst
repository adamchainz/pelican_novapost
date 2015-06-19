##############################
SaltStack and duplicate code
##############################

:date: 2015-06-19 12:00
:tags: saltstack, devop, best-practice
:category: SaltStack
:author: James Pic
:lang: en
:slug: saltstack-code-duplication

SaltStack_ enables DevOps_ to orchestrate and automate server administration
tasks. And that's a really broad topic.

When I started using such a tool, my repo just growed in an empiric manner and
ended up with duplicated, non-tested, spaggetti code - like when I started
hacking with PHP_ more than a decade ago. I've read in several blog articles
that it's normal to make such mistakes in the beginning, that's how we learn to
use this kind of tool.

While this article's purpose is not to demonstrate how bad `duplicate code`_
is - that's been proven thousands of times already - it covers some basic
examples of duplicate code in SaltStack and how to avoid them.

Code duplication in variables
=============================

SaltStack_ established the convention that a formula_ should **not** depend on
any pillar_ being set. That said, here's a typical legacy code example which
you can find in an example project::

    file.directory:
      - name: {{ pillar['sources_dir'] }}/foo
      - mode: 0750

Suppose that later on, you'd like to add a file in this directory, you'd be
tempted to just go for another state like this::

    file.directory:
      - name: {{ pillar['sources_dir'] }}/foo
      - mode: 0750

    file.managed:
      - name: {{ pillar['sources_dir'] }}/foo/bar
      - template: bar.j2

Good for you if you spotted my mistake. If you didn't, here's how we were
supposed to refactor the code to have the variable defined OOAO_::

    {% set foo_dir = pillar['sources_dir'] + '/foo' %}
    
    file.directory:
      - name: {{ foo_dir }}
      - mode: 0750
    
    file.managed:
      - name: {{ foo_dir }}/bar
      - template: bar.j2

As mentioned earlier, we'd rather use the ``pillar.get`` method with a default
value in case the pillar is not set if we wanted to follow SaltStack's
conventions.

Code duplication in states
==========================

Take the example where we're installing the hstore extension for PostgreSQL::

    posgtresql_hstore_{{ db.name }}:
      postgres_extension.present:
        - name: hstore
        - if_not_exists: True
        - maintenance_db: {{ db.name }}
        - user: postgres
        - require:
          - postgres_database: postgresql_db_{{ db.name }}

If we wanted to use another extension later, we'd be tempted to copy the above
as such::

    posgtresql_unaccent_{{ db.name }}:
      postgres_extension.present:
        - name: unaccent
        - if_not_exists: True
        - maintenance_db: {{ db.name }}
        - user: postgres
        - require:
          - postgres_database: postgresql_db_{{ db.name }}

    posgtresql_hstore_{{ db.name }}:
      postgres_extension.present:
        - name: hstore
        - if_not_exists: True
        - maintenance_db: {{ db.name }}
        - user: postgres
        - require:
          - postgres_database: postgresql_db_{{ db.name }}

Good for you if you've spotted the mistake here ! Avoiding duplicated code here
is easy by just adding a new dictionary key ``extensions`` to the ``db`` pillar
variable as such::

    db:
      name: foo
      extensions:
        - hstore
        - unaccent

We can then safely loop over ``db.extensions``, or almost::

    {%- for extension in db.get('extensions', ['hstore']) %}
    posgtresql_{{ extension }}_{{ db.name }}:
      postgres_extension.present:
        - name: {{ extension }}
        - if_not_exists: True
        - maintenance_db: {{ db.name }}
        - user: postgres
        - require:
          - postgres_database: postgresql_db_{{ db.name }}
    {% endfor %}

Note how the for-loop would be backward compatible with the previous
``postgresql_hstore_{{ db.name }}`` state by iterating over
``db.get('extensions', ['hstore'])``.

Avoid duplicate code in the beginning
=====================================

Of course, we avoid over-engineering code in the beginning and try to keep it
as simple as possible. Duplicate code increases technical debt, and when we
find or need duplicate code then it's the moment to refactor.

.. _SaltStack: http://saltstack.com
.. _formula: https://github.com/saltstack-formulas/salt-formula
.. _devops: https://en.wikipedia.org/wiki/DevOps
.. _php: http://php.net
.. _duplicate code: https://en.wikipedia.org/wiki/Duplicate_code
.. _pillar: http://docs.saltstack.com/en/latest/topics/pillar/
.. _OOAO: http://c2.com/cgi/wiki?OnceAndOnlyOnce
