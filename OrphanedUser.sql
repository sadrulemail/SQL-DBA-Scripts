-- orphaned users with status and command

USE [perf_surveysAuditLog_01]
EXEC sp_change_users_login 'Report';

-- USE <DatabaseName>
select * from (
select dp.type_desc, dp.name AS DB_user_name, dp.SID DB_SID, sp.name svr_login_name, sp.sid svr_SID,
case when dp.sid <> isnull(sp.sid , 0x0) then 'ORPHANED USER' else 'OK' end User_Status,
case when dp.sid <> isnull(sp.sid , 0x0)  then
	CASE when sp.sid is null then 'DENY CONNECT TO ['+dp.name+']' else 'EXEC sp_change_users_login ''update_one'', '''+dp.name+''', '''+sp.name+'''' END
END Action_CMD
from sys.database_principals AS dp
left outer join sys.server_principals AS sp  on  dp.name = sp.name OR dp.sid = sp.sid
where dp.type <> 'R' and dp.authentication_type <> 0
) a
where User_Status = 'ORPHANED USER'
order by  DB_user_name


--EXEC sp_change_users_login 'update_one', 'irissysadmin', 'IrisSysAdmin'