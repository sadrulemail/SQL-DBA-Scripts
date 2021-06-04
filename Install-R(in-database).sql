WCGHD-64670  - https://jira.wcgclinical.com/browse/WCGHD-64670 https://jira.wcgclinical.com/browse/WCGHD-71428

https://docs.microsoft.com/en-us/sql/advanced-analytics/install/sql-r-services-windows-install?view=sql-server-2016
https://docs.microsoft.com/en-us/sql/machine-learning/install/sql-machine-learning-services-windows-install?view=sql-server-ver15&viewFallbackFrom=sql-server-2016
https://docs.microsoft.com/en-us/archive/blogs/docast/setting-up-sql-server-r-service-in-database-and-r-serverstandalone
https://docs.microsoft.com/th-th/sql/machine-learning/install/sql-ml-cab-downloads?view=sql-server-2017
https://docs.microsoft.com/en-us/sql/machine-learning/security/sql-server-launchpad-service-account?view=sql-server-ver15

install patch as same as MSSQL server version and CU

Check MSSQL Data root directory -> sould be in local derive -> i.e. "C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL" -> HKLM\software\microsoft sql server\mssql14.mssqlserver\setup

EXEC sp_configure  'external scripts enabled', 1
RECONFIGURE WITH OVERRIDE
restert MSSQL service

Service Accoutn :: NT Service\MSSQLLaunchpad
	Make sure this user has "Log on as a Service" permission --> Click Start -> Run -> secpol.msc -> Local policy -> User Rights Assignment -> Log on as a Service
User Group: <SERVER_Name>\SQLRUserGroup - control panel-> administrative tools->Computer Management -> Local Users and Groups
	Grant MSSQL login to this group. https://docs.microsoft.com/en-us/sql/machine-learning/security/create-a-login-for-sqlrusergroup?view=sql-server-ver15
	Check "allow log on locally" in sequrity policy 

Create a new User or System variable.
Set variable name to MKL_CBWR
Set the variable value to AUTO

Access check
------------------
Group policy setting	Constant name
Adjust memory quotas for a process	SeIncreaseQuotaPrivilege
Bypass traverse checking	SeChangeNotifyPrivilege
Log on as a service	SeServiceLogonRight
Replace a process-level token	SeAssignPrimaryTokenPrivileg
-----------------

Permission MSSQL 
---------
USE <database_name>
GO
GRANT EXECUTE ANY EXTERNAL SCRIPT TO [UserName]

TEST
----
EXEC sp_execute_external_script  @language =N'R',
@script=N'
OutputDataSet <- InputDataSet;
',
@input_data_1 =N'SELECT ''R'' AS hello'
WITH RESULT SETS (([hello] varchar(10) not null));
GO

EXEC sp_execute_external_script  @language =N'Python',
@script=N'
OutputDataSet = InputDataSet;
',
@input_data_1 =N'SELECT ''Python'' AS hello'
WITH RESULT SETS (([hello] varchar(10) not null));
GO
-----

permission issues

The application-specific permission settings do not grant Local Activation permission for the COM Server application with CLSID 
{3185A766-B338-11E4-A71E-12E3F512A338}
 and APPID 
{7006698D-2974-4091-A424-85DD0B909E23}
 to the user WCGCLINICAL\acidevdbsvc SID (S-1-5-21-2822359809-1774866326-3366490116-13680) from address LocalHost (Using LRPC) running in the application container Unavailable SID (Unavailable). This security permission can be modified using the Component Services administrative tool.
 
 
 CLSID {3185A766-B338-11E4-A71E-12E3F512A338}
 Default = Flight Settings API Broker
 
 APPID {7006698D-2974-4091-A424-85DD0B909E23}
 
 
  CLSID {D63B10C5-BB46-4990-A94F-E40B9D520160}
APPID {9CA88EE3-ACB7-47C8-AFC4-AB702511C276} == RuntimeBroker
NT SERVICE\MSSQLLaunchpad


https://docs.microsoft.com/en-us/sql/advanced-analytics/common-issues-external-script-execution?view=sql-server-ver15#check-the-launchpad-service-account 
 
https://social.technet.microsoft.com/Forums/Lync/en-US/dfc465bc-7bbd-483e-b98b-2ba56fa98313/the-applicationspecific-permission-settings-do-not-grant-local-launch-permission-for-the-com-server?forum=configmgrgeneral
 
1. Click Start -> Run -> Type -> dcomcnfg, expand Component Services -> Computers -> My Computer -> DCOM Config.
2. Click View -> Detail -> Now you will get Application Name and Application ID in right side.
3. Scroll down and find the application ID {7006698D-2974-4091-A424-85DD0B909E23} -> Right Click -> Properties and select the Security tab.
3. Click Customize under "Launch & Activation Permission" -> click Edit -> Add in the account NT AUTHORITY\SYSTEM and set local launch and local activation.
4. Restart the application Service linked to this Application ID or restart the server

If the option is gray to edit above , follow below steps and repete above steps
1. Press Windows + R keys and type regedit and press Enter.
2. Go to HKEY_Classes_Root\CLSID\*CLSID*.
3. Right click on it then select permission.
4. Click Advance and change the owner to administrator. Also click the box that will appear below the owner line.
5. Apply full control.
6. Close the tab then go to HKEY_LocalMachine\Software\Classes\AppID\*APPID*.
7. Right click on it then select permission.
8. Click Advance and change the owner to administrators.
9. Click the box that will appear below the owner line.
10. Click Apply and grant full control to Administrators.


HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\wscsvc

Change the DWORD DelayedAutoStart from 1 to 0.


