
use master

DECLARE @login VARCHAR(2000) = $(login_PSv)
DECLARE @DBName varchar(100) = $(DBName_PSv)
DECLARE @showResltForUser varchar(1000) = NULL 
DECLARE @CreateUserScript bit = 1  
DECLARE @ShowServerAccess bit = 1 

Declare @SQL varchar(MAX) = ''
Declare @SQL_FINAL varchar(MAX) = ''

IF OBJECT_ID('tempdb.dbo.#accessT') is not null
	DROP TABLE #accessT

Create table  #accessT ([DATABASE_NAME] nvarchar(300),
[LoginName]			nvarchar(300),
[UserType]          nvarchar(300),
[DatabaseUserName]  nvarchar(300),
[Role]              nvarchar(300),
[PermissionType]    nvarchar(300),
[PermissionState]   nvarchar(300),
[ObjectType]        nvarchar(300),
[ObjectName]        nvarchar(300),
[ColumnName]        nvarchar(300))

SET @SQL ='
INSERT INTO #accessT
select DB_NAME() as [DATABASE_NAME],
[LoginName],
[UserType],
[DatabaseUserName],
[Role],
[PermissionType],
[PermissionState],
[ObjectType],
[ObjectName],
[ColumnName]
from (
SELECT  
    [LoginName] = ulogin.[name] COLLATE Latin1_General_CI_AI,
    [UserType] = CASE princ.[type]
                    WHEN ''S'' THEN ''SQL User''
                    WHEN ''U'' THEN ''Windows User''
					WHEN ''G'' THEN ''Windows Group''
					WHEN ''R'' THEN ''Database Role''
                 END,  
    [DatabaseUserName] = princ.[name],       
    [Role] = null,      
    [PermissionType] = perm.[permission_name],       
    [PermissionState] = perm.[state_desc],       
    [ObjectType] = isnull(obj.type_desc,perm.[class_desc]),       
    [ObjectName] = isnull(OBJECT_NAME(perm.major_id),SCHEMA_NAME(sch.[schema_id])),
    [ColumnName] = col.[name]
FROM    
    sys.database_principals princ  
LEFT JOIN
    sys.syslogins ulogin on princ.[sid] = ulogin.[sid]
LEFT JOIN        
    sys.database_permissions perm ON perm.[grantee_principal_id] = princ.[principal_id]
LEFT JOIN
    sys.columns col ON col.[object_id] = perm.major_id 
                    AND col.[column_id] = perm.[minor_id]
LEFT JOIN
    sys.objects obj ON perm.[major_id] = obj.[object_id]
LEFT JOIN
    sys.schemas sch ON perm.[major_id] = sch.[schema_id]
WHERE 
    princ.[type] in (''S'',''U'',''R'',''G'')
	and perm.[permission_name] is not NULL
UNION
select
    [LoginName] = sl.[name] COLLATE Latin1_General_CI_AI,
    [UserType] = CASE dp.[type]
                    WHEN ''S'' THEN ''SQL User''
                    WHEN ''U'' THEN ''Windows User''
					WHEN ''G'' THEN ''Windows Group''
					WHEN ''R'' THEN ''Database Role''
                 END,  
    [DatabaseUserName] = dp.[name],       
    [Role] = null,      
    [PermissionType] = ''CONNECT'',       
    [PermissionState] = CASE su.hasdbaccess when 1 then ''GRANT'' else ''REVOKE'' END,       
    [ObjectType] = ''DATABASE'',       
    [ObjectName] = NULL,
    [ColumnName] = NULL
from sys.sysusers su
join sys.database_principals dp 
	on dp.sid = su.sid
	and dp.[type] in (''S'',''U'',''R'',''G'')
LEFT JOIN
    sys.syslogins sl on dp.[sid] = sl.[sid]
where 
not exists (select 1 from sys.database_permissions perm where perm.[grantee_principal_id] = dp.[principal_id]  and perm.[permission_name] = ''CONNECT'')
UNION
SELECT  
    [LoginName] = ulogin.[name] COLLATE Latin1_General_CI_AI,
    [UserType] = CASE memberprinc.[type]
                    WHEN ''S'' THEN ''SQL User''
                    WHEN ''U'' THEN ''Windows User''
					WHEN ''G'' THEN ''Windows Group''
                 END,  
    [DatabaseUserName] = memberprinc.[name],   
    [Role] = roleprinc.[name],      
    [PermissionType] = perm.[permission_name],       
    [PermissionState] = perm.[state_desc],       
    [ObjectType] = obj.type_desc,  
    [ObjectName] = OBJECT_NAME(perm.major_id),
    [ColumnName] = col.[name]
FROM    
    sys.database_role_members members
	JOIN
    sys.database_principals roleprinc ON roleprinc.[principal_id] = members.[role_principal_id]
	JOIN
    sys.database_principals memberprinc ON memberprinc.[principal_id] = members.[member_principal_id]
LEFT JOIN
    sys.syslogins ulogin on memberprinc.[sid] = ulogin.[sid]
LEFT JOIN        
    sys.database_permissions perm ON perm.[grantee_principal_id] = roleprinc.[principal_id]
LEFT JOIN
    sys.columns col on col.[object_id] = perm.major_id 
                    AND col.[column_id] = perm.[minor_id]
LEFT JOIN
    sys.objects obj ON perm.[major_id] = obj.[object_id]
UNION
SELECT  
    [LoginName] = ''{All Users}'',
    [UserType] = ''{All Users}'', 
    [DatabaseUserName] = ''{All Users}'',       
    [Role] = roleprinc.[name],      
    [PermissionType] = perm.[permission_name],       
    [PermissionState] = perm.[state_desc],       
    [ObjectType] = obj.type_desc, 
    [ObjectName] = OBJECT_NAME(perm.major_id),
    [ColumnName] = col.[name]
FROM    
    sys.database_principals roleprinc
LEFT JOIN        
    sys.database_permissions perm ON perm.[grantee_principal_id] = roleprinc.[principal_id]
LEFT JOIN
    sys.columns col on col.[object_id] = perm.major_id 
                    AND col.[column_id] = perm.[minor_id]                   
JOIN  
    sys.objects obj ON obj.[object_id] = perm.[major_id]
WHERE
    roleprinc.[type] = ''R'' AND
    roleprinc.[name] = ''public'' AND
    obj.is_ms_shipped = 0
	) allAccess
	where [DatabaseUserName]='+isnull(''''+@login+'''','[DatabaseUserName]')+
	'OR [LoginName] = '+isnull(''''+@login+'''','[LoginName] ')+
	'ORDER BY
    [DatabaseUserName],
    [ObjectName],
    [ColumnName],
    [PermissionType],
    [PermissionState],
    [ObjectType]'

select @SQL_FINAL = @SQL_FINAL+' USE '+QUOTENAME(db.name)+';'+@sql++ char(13) 
from sys.databases db
where db.name = isnull(@DBName,db.name)
and db.is_read_only = 0
and db.state_desc = 'ONLINE'

exec (@SQL_FINAL)

select @@SERVERNAME as SERVERNAME,a.AccessLevel,a.[Login/DBUserName],a.[Role/Access],a.Command
from(
select 0 OrderBy1, case when sp.permission_name collate SQL_Latin1_General_CP1_CI_AS='CONNECT SQL' then 0 else 2 end Orderby2, 
'Server' AccessLevel, pr.name as "Login/DBUserName", sp.permission_name collate SQL_Latin1_General_CP1_CI_AS as [Role/Access]
, case when sp.permission_name collate SQL_Latin1_General_CP1_CI_AS = 'CONNECT SQL' 
		then 'CREATE LOGIN '+ QUOTENAME(pr.name) +' '+
		case when pr.type_desc like 'WINDOWS%' then ' FROM WINDOWS WITH ' 
			else ' WITH PASSWORD='''' HASHED'+',CHECK_EXPIRATION='+case when sl.is_expiration_checked=1 then 'ON' else 'OFF' end+', CHECK_POLICY='+case when sl.is_policy_checked=1 then 'ON' else 'OFF' end+',' 
		end 
		+' DEFAULT_DATABASE='+QUOTENAME(pr.default_database_name)+' , DEFAULT_LANGUAGE='+pr.default_language_name
		+'; '+sp.state_desc collate SQL_Latin1_General_CP1_CI_AS+' '+sp.permission_name collate SQL_Latin1_General_CP1_CI_AS+' TO '+QUOTENAME( pr.name collate SQL_Latin1_General_CP1_CI_AS) 
	else 
	sp.state_desc collate SQL_Latin1_General_CP1_CI_AS+' '+sp.permission_name collate SQL_Latin1_General_CP1_CI_AS+' TO '+QUOTENAME( pr.name collate SQL_Latin1_General_CP1_CI_AS) 
end as Command
from sys.server_permissions sp
left join sys.server_principals AS pr 
on pr.principal_id = sp.grantee_principal_id
left join sys.sql_logins sl on pr.sid = sl.sid
where pr.name not in ('public','sa','NT AUTHORITY\SYSTEM')
and pr.name not like '##%##'
and pr.name = @login
Union All
select 0 OrderBy1, 3 Orderby2, 'Server' AccessLevel, prm.name as "Login/DBUserName", prr.name as [Role/Access]
, 'exec sp_addsrvrolemember '''+prm.name+''','''+prr.name+'''' as GrantCMD
from sys.server_role_members srm
left join sys.server_principals AS prm on prm.principal_id = srm.member_principal_id
left join sys.server_principals AS prr on prr.principal_id = srm.role_principal_id
where prm.name = @login
union all
select 0 OrderBy1, 1 Orderby2,'Server' AccessLevel, sp.name as "LoginName", 'DISABLED' [ROle/Access], 'ALTER LOGIN '+QUOTENAME(sp.name)+' DISABLE;' command
from sys.server_principals sp
where sp.name = @login
and sp.is_disabled = 1
Union All
select distinct 2 OrderBy1, case when t.permissionType = 'CONNECT' then 0 when t.Role is null then 1 else 2 end Orderby2, DATABASE_NAME,DatabaseUserName,isnull(Role,PermissionType) [Role/Access],
'USE '+QUOTENAME(t.database_name) +'; '+
case when t.Role is null then 
	case when (@CreateUserScript=1 and t.permissionType = 'CONNECT') then 'CREATE USER '+QUOTENAME(ISNULL(t.DatabaseUserName,t.LoginName))+' FROM LOGIN '+QUOTENAME(isnull(@login,ISNULL(t.LoginName,t.DatabaseUserName)))+'; ' else '' end
	+ t.PermissionState+' '+t.permissionType+ ISNULL (' ON '+t.ObjectName,'') +' TO '+QUOTENAME(ISNULL(t.DatabaseUserName,t.LoginName))+'; '
when t.Role is not null then ' EXEC sp_addrolemember '''+t.role+''','+QUOTENAME(ISNULL(t.DatabaseUserName,t.LoginName))+';' else '' 
end "SQL_CMD"
from #accessT t
where ISNULL( @showResltForUser , t.DatabaseUserName) like '%'+t.DatabaseUserName +'%'
OR  ISNULL( @showResltForUser , t.LoginName)  like '%'+t.LoginName +'%'
) a
where a.AccessLevel not like case when @ShowServerAccess=0 then 'Server' else '' end
order by a.OrderBy1,a.AccessLevel,a.Orderby2,a.[Role/Access]
