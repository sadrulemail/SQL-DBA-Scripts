use master
go
declare @dbanme varchar(500)='staging_UmaCoreUserRepository_01'
declare @script_set_DB_Online varchar(3000)=''
declare @script_set_drop_DBs varchar(3000)=''
--select * from sys.databases where name =@dbanme and state_desc='offline'

if exists(select * from sys.databases where name =@dbanme and state_desc='offline')
begin
	set @script_set_DB_Online='alter database '+@dbanme+' set online'
	print @script_set_DB_Online
	exec(@script_set_DB_Online)

	set @script_set_drop_DBs='drop database '+@dbanme
	print @script_set_drop_DBs
	exec(@script_set_drop_DBs)
end