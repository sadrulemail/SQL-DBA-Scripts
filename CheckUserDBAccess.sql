--sp_helplogins sfsasdbreader

use master

--DECLARE @login VARCHAR(2000) = NULL --'EPLNET\fmorari' NULL=ALL Users
DECLARE @login VARCHAR(2000) = NULL -- NULL=ALL Users
DECLARE @DBName varchar(100) = NULL -- 'dev_safetyRepositoryEps_01' -- NULL=ALL Database
DECLARE @showResltForUser varchar(1000) = NULL -- 'eplnet\ymurshed,eplnet\hrahman,eplnet\ianisimov,dev_spuma01' -- NULL = show result for all users
DECLARE @CreateUserScript bit = 1  -- 0 - GRANT CONNECT script;  1 - CREATE USER script

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
	/*CASE princ.[type] 
                    WHEN ''S'' THEN princ.[name]
                    WHEN ''U'' THEN ulogin.[name] COLLATE Latin1_General_CI_AI
                 END,*/
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
UNION
SELECT  
    [LoginName] = ulogin.[name] COLLATE Latin1_General_CI_AI,
	/*CASE princ.[type] 
                    WHEN ''S'' THEN princ.[name]
                    WHEN ''U'' THEN ulogin.[name] COLLATE Latin1_General_CI_AI
                 END,*/
    [UserType] = CASE memberprinc.[type]
                    WHEN ''S'' THEN ''SQL User''
                    WHEN ''U'' THEN ''Windows User''
					WHEN ''G'' THEN ''Windows Group''
					--WHEN ''R'' THEN ''Database Role''
                 END,  
    [DatabaseUserName] = memberprinc.[name],   
    [Role] = roleprinc.[name],      
    [PermissionType] = perm.[permission_name],       
    [PermissionState] = perm.[state_desc],       
    [ObjectType] = obj.type_desc,--perm.[class_desc],   
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
    [ObjectType] = obj.type_desc,--perm.[class_desc],  
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

select @SQL_FINAL = @SQL_FINAL+' USE ['+db.name+'];'+@sql++ char(13) 
from sys.databases db
where db.name = isnull(@DBName,db.name)
and db.is_read_only = 0
and db.state_desc = 'ONLINE'

--print cast(@SQL_FINAL as text)

exec (@SQL_FINAL)

--select * from #accessT

/*
select *,
'USE ['+t.database_name +']; '+
case when t.Role is null then 
	case when (@CreateUserScript=1 and t.permissionType = 'CONNECT') then 'CREATE USER ['+ISNULL(t.DatabaseUserName,t.LoginName)+'] FROM LOGIN ['+isnull(@login,ISNULL(t.LoginName,t.DatabaseUserName))+'];' else
	t.PermissionState+' '+t.permissionType+ ISNULL (' ON '+t.ObjectName,'') +' TO ['+ISNULL(t.DatabaseUserName,t.LoginName)+']; '
	END
when t.Role is not null then ' EXEC sp_addrolemember '''+t.role+''',['+ISNULL(t.DatabaseUserName,t.LoginName)+'];' else ''  
end "SQL_CMD"
from #accessT t
where ISNULL( @showResltForUser , t.DatabaseUserName) like '%'+t.DatabaseUserName +'%'
OR  ISNULL( @showResltForUser , t.LoginName)  like '%'+t.LoginName +'%'
*/


select distinct DATABASE_NAME,LoginName,UserType,DatabaseUserName,isnull(Role,PermissionType) [Role/Access],
'USE ['+t.database_name +']; '+
case when t.Role is null then 
	case when (@CreateUserScript=1 and t.permissionType = 'CONNECT') then 'CREATE USER ['+ISNULL(t.DatabaseUserName,t.LoginName)+'] FROM LOGIN ['+isnull(@login,ISNULL(t.LoginName,t.DatabaseUserName))+'];' else
	t.PermissionState+' '+t.permissionType+ ISNULL (' ON '+t.ObjectName,'') +' TO ['+ISNULL(t.DatabaseUserName,t.LoginName)+']; '
	END
when t.Role is not null then ' EXEC sp_addrolemember '''+t.role+''',['+ISNULL(t.DatabaseUserName,t.LoginName)+'];' else '' 
end "SQL_CMD"
from #accessT t
where ISNULL( @showResltForUser , t.DatabaseUserName) like '%'+t.DatabaseUserName +'%'
OR  ISNULL( @showResltForUser , t.LoginName)  like '%'+t.LoginName +'%'



