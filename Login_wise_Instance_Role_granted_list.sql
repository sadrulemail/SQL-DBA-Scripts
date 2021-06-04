SELECT 

SL.name,
SR.name as Rolename
into #T
FROM master.sys.server_principals SR
left join master.sys.server_role_members SRM  ON SR.principal_id = SRM.role_principal_id
--INNER JOIN master.sys.server_principals SR ON SR.principal_id = SRM.role_principal_id
   left JOIN master.sys.server_principals SL ON SL.principal_id = SRM.member_principal_id
WHERE SL.type IN ('S','G','U')
        AND SL.name NOT LIKE '##%##'
        AND SL.name NOT LIKE 'NT AUTHORITY%'
        AND SL.name NOT LIKE 'NT SERVICE%'
        AND SL.name <> ('sa')
        AND SL.name <> 'distributor_admin';


		select SL.name, isnull(Rolename,'')Rolename 
		into #T2 from sys.server_principals SL left join #T as t on SL.name=t.name
		where SL.type IN ('S','G','U')
        AND SL.name NOT LIKE '##%##'
        AND SL.name NOT LIKE 'NT AUTHORITY%'
        AND SL.name NOT LIKE 'NT SERVICE%'
        AND SL.name <> ('sa')
        AND SL.name <> 'distributor_admin' 
		--group by SL.name
		--order by SL.name

		SELECT  name
       ,STUFF((SELECT ', ' + CAST(Rolename AS VARCHAR(50)) [text()]
         FROM #T2 
         WHERE name = t.name
         FOR XML PATH(''), TYPE)
        .value('.','NVARCHAR(MAX)'),1,2,' ') List_Output
FROM #T2 t
GROUP BY name
order by name

		drop table #T
		drop table #T2