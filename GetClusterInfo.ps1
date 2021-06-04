Get-ClusterNode -Name DCE-U-SFTDB01

Get-ClusterNode -Cluster JSNSQLSPPRODCL

Add-WindowsFeature RSAT-Clustering-PowerShell

Get-Cluster -Domain epsnet | ForEach-Object { "Cluster: $_ Nodes: " + (Get-ClusterNode -Cluster $_) }

Get-Cluster -Domain wcgclinical | ForEach-Object { "Cluster: $_ Nodes: " + (Get-ClusterNode -Cluster $_) }
Get-Cluster -Domain epsnet | ForEach-Object { "Cluster: $_ Nodes: " + (Get-ClusterNode -Cluster $_) }



Get-ClusterResource -Cluster JSNSQLSPPRODCL

Cluster: dce-p-rochecl01  Nodes: dce-p-rochedb01 dce-p-rochedb02
Cluster: DCE-P-ROCHECL02  Nodes: dce-p-rochedb04 dce-p-rochedb05
Cluster: dce-u-rochecl01  Nodes: dce-u-rochedb01 dce-u-rochedb02
Cluster: DCE-U-ROCHECL02  Nodes: dce-u-rochedb04 dce-u-rochedb05
Cluster: PHLPWAIMCL01  Nodes: PHLPWAIMDB01 PHLPWAIMDB02
Cluster: PHLPWSFPCL01CV  Nodes: PHLPWSFPDB01CV PHLPWSFPDB02CV
Cluster: PHLPWSFPCL01JN  Nodes: PHLPWSFPDB01JN PHLPWSFPDB02JN
Cluster: PHLPWSFPCL02CV  Nodes: PHLPWSFPDB04CV PHLPWSFPDB05CV
Cluster: PHLPWSFPCL02JN  Nodes: PHLPWSFPDB04JN PHLPWSFPDB05JN
Cluster: PHLPWWCGCL01  Nodes: PHLPWWCGDB02 PHLPWWCGDB03
Cluster: PHLPWWCGCL02  Nodes: PHLPWWCGDB05 PHLPWWCGDB06
Cluster: PHLUWSFPCL01CV  Nodes: PHLUWSFPDB01CV PHLUWSFPDB02CV
Cluster: phluwsfpcl01jn  Nodes: PHLUWSFPDB01JN PHLUWSFPDB02JN
Cluster: PHLUWSFPCL02CV  Nodes: PHLUWSFPDB04CV PHLUWSFPDB05CV
Cluster: phluwsfpcl02jn  Nodes: PHLUWSFPDB04JN PHLUWSFPDB05JN
Cluster: PHLUWWCGCL  Nodes: PHLUWWCGDB01 PHLUWWCGDB02
Cluster: PRODCLU10  Nodes: prodnode01 prodnode02 PRODSQL12
Cluster: PRODCLU17  Nodes: prodsql15
Cluster: prodsftclu01  Nodes: dce-p-sftdb01 dce-p-sftdb02
Cluster: prodsftclu02  Nodes: dce-p-sftdb04 dce-p-sftdb05
Cluster: ROCHECLUSTER01  Nodes: prodrochenode01 prodrochenode02
Cluster: uatsftclu01  Nodes: dce-u-sftdb01 dce-u-sftdb02
Cluster: uatsftclu02  Nodes: dce-u-sftdb04 dce-u-sftdb05