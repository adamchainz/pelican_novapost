######################################
Paginator c'est bien, ... pour paginer
######################################

:date: 2014-09-18 14:00
:tags: django, paginator, offset, sql
:category: Astuces
:author: Rodolphe Quiédeville
:lang: fr
:slug: django-paginator-offset-keyset-pagination


Mesure avec un index simple

.. code-block:: rst

rodo@localhost:5432 perf=>  select name,
avg(stop-start),count(stop),sum(stop-start),max(stop-start),min(stop-start)
from offset_log group by name order by avg(stop-start) desc ;
          name          |       avg       | count |       sum       |
	  max       |       min       
------------------------+-----------------+-------+-----------------+-----------------+-----------------
 offset                 | 00:00:05.896866 |   200 | 00:19:39.373291 |
 00:00:12.183956 | 00:00:02.00522
 keypage                | 00:00:02.621238 |   200 | 00:08:44.247604 |
 00:00:04.251439 | 00:00:01.327866
 keypage_prepare        | 00:00:02.390769 |   200 | 00:07:58.153764 |
 00:00:04.490603 | 00:00:01.473376
 keypage_fields         | 00:00:00.428909 |   200 | 00:01:25.781895 |
 00:00:00.844589 | 00:00:00.1596
 keypage_prepare_fields | 00:00:00.297687 |   200 | 00:00:59.537499 |
 00:00:00.795728 | 00:00:00.110682
