http://www.sqlservercentral.com/articles/Replication/62625/

ћожно ставить метку в тран лог и отслеживать еЄ перемещение в репликации.

sp_posttracertoken Сpublication_nameТ

потом запросом

use distribution
GO
select publisher_commit,
       distributor_commit,
       datediff(ss, publisher_commit, distributor_commit) 'Latency bw Pub and Dis',
       subscriber_commit,
       datediff(ss, distributor_commit, subscriber_commit) 'Latency bw Dis and Sub'
from MSTracer_tokens join MSTracer_history 
    on tracer_id = parent_tracer_id
