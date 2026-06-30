@echo off

REM #
REM # Copyright (c) 2001, 2003 Oracle Corporation.  All rights reserved.
REM #
REM # PRODUCT
REM #   OID LDIF Migration to OID
REM #
REM # FILENAME
REM #   LDIFMigrator.bat
REM #
REM # DESCRIPTION
REM #   This script is used to launch the LIDF Migration.
REM #
REM # NOTE:
REM #
REM #   ldifmigrator -help prints usage
REM #
REM #   Note that parameters containing an '=' sign must be 
REM #   double-quoted when invoking this script, else they will 
REM #   be broken up into separate parameters at the = sign
REM #   and errors will result.
REM #

SETLOCAL

REM # Check ORACLE_HOME is defined
IF "D:\oracle\product\10.2.0\db_1x" == "x" GOTO NO_ORACLE_HOME
SET JAVAEXE=D:\oracle\product\10.2.0\db_1\jdk\bin\java

REM Set class path
SET LDAPJCLNT10=D:\oracle\product\10.2.0\db_1\jlib\ldapjclnt10.jar
SET NETCFG=D:\oracle\product\10.2.0\db_1\jlib\netcfg.jar

REM make sure ldapjclnt10.jar is present
IF NOT EXIST %LDAPJCLNT10% GOTO NO_LDAPJCLNT10JAR_FILE

SET CLASSPATH=%LDAPJCLNT10%;%NETCFG%;

%JAVAEXE% -classpath %CLASSPATH% -DORACLE_HOME=D:\oracle\product\10.2.0\db_1 oracle.ldap.util.LDIFMigration %*

GOTO THE_END

:NO_LDAPJCLNT10JAR_FILE
   ECHO Missing jar file
   ECHO %LDAPJCLNT10% not found
   GOTO THE_END

:NO_ORACLE_HOME
  ECHO ORACLE_HOME is not defined

:THE_END
   ENDLOCAL
