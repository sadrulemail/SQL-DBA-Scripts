SELECT  'bcp [az1pcdadw].'+s.name+'.['+t.name +'] OUT D:\WCGHD-112307\Data\'+s.name+'_'+t.name+'.bcp -n -U "dw_etl_user" -P "#2Crayon" -S "az1pcdasvr.database.windows.net"  >  D:\WCGHD-112307\Data\'+s.name+'_'+t.name+'.out' as data_out,
'bcp [az1tpcdadw].'+s.name+'.['+t.name +'] IN D:\WCGHD-112307\Data\'+s.name+'_'+t.name+'.bcp  -n -U "wcgcdatestsqladmin" -P "UJXb&&Sgqyvb" -S "az1tpcdasqlsvr01.database.windows.net" -E -b 100000 > D:\WCGHD-112307\Data\'+s.name+'_'+t.name+'.in' as data_in
FROM sys.tables t
    LEFT OUTER JOIN sys.schemas s
        ON t.schema_id = s.schema_id
order by s.name,t.name