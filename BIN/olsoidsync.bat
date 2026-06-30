@ echo off
Rem Copyright (c) 2003, Oracle Corporation.  All rights reserved.  
Rem
Rem    NAME
Rem      olsoidsync - Shell script to run the OID/OLS bootstrap utility
Rem
Rem    DESCRIPTION
Rem      Runs the OID/OLS bootstrap utility.

Rem External Directory Variables set by the Installer
SET JRE_HOME=D:\oracle\product\10.2.0\db_1\jdk\jre\
SET JLIBDIR=D:\oracle\product\10.2.0\db_1\jlib
SET LIBDIR=D:\oracle\product\10.2.0\db_1\jdbc\lib

%JRE_HOME%\bin\java -classpath %JLIBDIR%\opm.jar;%LIBDIR%\classes12.zip oracle.security.ols.policy.Bootstrap %*
