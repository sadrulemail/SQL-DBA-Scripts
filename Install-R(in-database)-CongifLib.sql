
EXECUTE sp_execute_external_script 
  @language = N'R',
  @script = N'OutputDataSet <- data.frame(.libPaths());'
WITH RESULT SETS (([DefaultLibraryName] VARCHAR(MAX) NOT NULL));
GO

C:/Program Files/Microsoft SQL Server/MSSQL14.MSSQLSERVER/R_SERVICES/library

C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\R_SERVICES\bin
C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\R_SERVICES\library

Launch R.exe from C:\Program Files\Microsoft SQL Server\MSSQLXX.MSSQLSERVER\R_SERVICES\bin with runas administrator and execute below r code:
#--------------------------------
ipak <- function(pkg,libpath){
  new.pkg <- pkg[!(pkg %in% installed.packages(lib=libpath)[, "Package"])]
  if (length(new.pkg))
      install.packages(new.pkg, lib=libpath,dependencies = TRUE)
  sapply(pkg, require, character.only = TRUE)
}

#usage

packages <- c("SASxport","Formula","ggplot2","gtable","scales","Rcpp","munsell","colorspace","lazyeval","plyr","rlang","tibble","pillar","crayon","pkgconfig","acepack","base64enc","latticeExtra","RColorBrewer","gridExtra","htmlTable","checkmate","backports","htmlwidgets","htmltools","digest","magrittr","knitr","xfun","rstudioapi","stringr","stringi","data.table","RODBC","tidyverse")

#lib.SQL is R library path noted on step 5

lib.SQL <- "C:/Program Files/Microsoft SQL Server/MSSQL14.MSSQLSERVER/R_SERVICES/library"

ipak(packages,lib.SQL)
library(tidyverse)
#--------------------------------

With that said , to install those packages from r project CRAN reporsitory run the below code in R

lib.SQL <- "C:/Program Files/Microsoft SQL Server/MSSQL14.MSSQLSERVER/R_SERVICES/library"
install.packages("https://cran.r-project.org/bin/windows/contrib/3.3/rlang_0.2.0.zip",lib=lib.SQL,repos=NULL,type="source")
install.packages("https://cran.r-project.org/bin/windows/contrib/3.3/xfun_0.1.zip",lib=lib.SQL,repos=NULL,type="source")
install.packages("https://cran.r-project.org/bin/windows/contrib/3.3/pillar_1.2.1.zip",lib=lib.SQL,repos=NULL,type="source")

