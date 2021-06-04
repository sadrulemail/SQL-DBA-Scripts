SEAPWITSDB01.wcgclinical.com
--today's script
INSERT INTO DBACentral.dbo.WCG_Host (HostName, [IP], IsListener, IsActive, DataCenter_ID, CPU, MEMORY, Version, Edition, IsProduction, IsMSSQL,IsMySQL )
VALUES ('SCSTWSMRDB01.medavante.net','10.21.65.75',0,1,6,4,8,'15.0.4073.23', 'Developer Edition (64-bit)',0,1,0),
('SCSPWSMRDB01.medavante.net','10.21.65.26',0,1,6,4,8,'15.0.4073.23', 'Standard Edition (64-bit)',1,1,0)

--SELECT * FROM WCG_Host ORDER BY ID

INSERT INTO WCG_HostApplication (HostID, [Application])
VALUES (283, 'SMART'),
(284, 'SMART')


-------------
declare @id int=253
declare @update int=0
select HostName, [IP], IsListener, IsActive, DataCenter_ID, CPU, MEMORY,
Version, Edition, IsProduction, IsMSSQL,IsMySQL from WCG_Host where id=@id
select * from WCG_HostApplication where HostID=@id

if(@update=1)
begin
update WCG_Host set 
 IsListener=0, 
 CPU=8,
 MEMORY=117,
Version='14.0.3238.1', 
Edition='Enterprise Edition: Core-based Licensing (64-bit)', 
IsProduction=1, 
IsMSSQL=1,
IsMySQL=0
 where id=@id 
	print 'updated successfully'
end
else
	print 'Failed'


-----------------

use dbacentral
go

select * from wcg_host order by id 
select * from WCG_HostApplication
SELECT * FROM WCG_DataCenter

SELECT h.HostName, dc.Abbreviated, ha.[Application], ha.[Description]
FROM WCG_Host h 
INNER JOIN WCG_HostApplication ha
ON h.ID = ha.HostID
INNER JOIN WCG_DataCenter dc
ON h.DataCenter_ID = dc.ID 
WHERE h.IsActive = 1 `
ORDER BY h.ID ASC

--Sample script to decomm SQL instance
update WCG_Host
set IsActive = 0
where hostname = 'PHLSWWCGDB01.epsnet.wan'

--Sample script to enter new SQL instance
INSERT INTO DBACentral.dbo.WCG_Host (HostName, [IP], IsListener, IsActive, DataCenter_ID, isproduction,ismysql,ismssql)
VALUES ('PHLULWCGDB01.EPSNET.WAN','10.32.40.37',0,1,2,0,1,0),
('PHLULWCGDB02.EPSNET.WAN','10.32.40.38',0,1,2,0,1,0),
('PHLULWCGDB03.EPSNET.WAN','10.32.40.39',0,1,2,0,1,0)

select * from WCG_Host
where ismysql = 1

INSERT INTO WCG_HostApplication (HostID, [Application], [Description])
VALUES (276, 'iConnect', 'CenterWatch'),
(277, 'iConnect', 'CenterWatch'),
(278, 'iConnect', 'CenterWatch')
