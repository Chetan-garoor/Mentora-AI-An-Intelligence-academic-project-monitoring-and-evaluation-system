@echo off

REM #
REM # Copyright (c) 2001 Oracle Corporation.  All rights reserved.
REM #
REM # PRODUCT
REM #   DIP
REM #
REM # FILENAME
REM #   odisrvreg.bat
REM #
REM # DESCRIPTION
REM #   This script is used to register the DIP Server on NT
REM #
REM # NOTE:

set ORACLE_HOME=D:\oracle\product\10.2.0\db_1
set JAVA_HOME=D:\oracle\product\10.2.0\db_1\jdk

set PATH=D:\oracle\product\10.2.0\db_1\bin;%PATH%

set CLASSPATH="D:\oracle\product\10.2.0\db_1\ldap\odi\jlib\sync.jar;D:\oracle\product\10.2.0\db_1\jlib\ldapjclnt9.jar;D:\oracle\product\10.2.0\db_1\jlib\javax-ssl-1_2.jar;D:\oracle\product\10.2.0\db_1\jlib\jssl-1_2.jar;D:\oracle\product\10.2.0\db_1\jlib\ojmisc.jar"

%JAVA_HOME%\bin\java -ms4m -mx128m -classpath %CLASSPATH% oracle.ldap.odip.engine.OdiReg D:\oracle\product\10.2.0\db_1 %*

