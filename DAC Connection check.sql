select 
CASE
WHEN es.session_id= @@SPID THEN 'you are :)'
ELSE es.host_name
END AS Who_is_running_DAC,
es.original_login_name,
es.session_id,
es.login_time,
es.status
from sys.endpoints as ep
join sys.dm_exec_sessions es on
ep.endpoint_id=es.endpoint_id
where ep.name='Dedicated Admin Connection'