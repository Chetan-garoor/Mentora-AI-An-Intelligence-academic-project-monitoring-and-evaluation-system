@ echo off
Rem Copyright (c) 2003, Oracle Corporation.  All rights reserved.  
Rem
Rem    NAME
Rem    olsadmintool - Shell script to run the OID enabled OLS Administration
Rem                     Tool
Rem
Rem    DESCRIPTION
Rem      Runs the OID enabled OLS Administration Tool.

Rem External Directory Variables set by the Installer
SET JRE_HOME=D:\oracle\product\10.2.0\db_1\jdk\jre\
SET JLIBDIR=D:\oracle\product\10.2.0\db_1\jlib

%JRE_HOME%\bin\java -classpath %JLIBDIR%\opm.jar oracle.security.ols.policy.policyLDAP %*
