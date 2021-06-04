select SCHEMA_NAME(t.schema_id), t.name , i.name,i.*
from sys.indexes i 
inner join sys.tables t on i.object_id = t.object_id
where i.name is not null
and i.is_primary_key = 0
and i.is_unique_constraint = 0
order by t.name
