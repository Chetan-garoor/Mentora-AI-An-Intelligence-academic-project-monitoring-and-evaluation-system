@echo off

REM #
REM # Copyright (c) 2001 Oracle Corporation.  All rights reserved.
REM #
REM # PRODUCT
REM #   OID Provisioning Tool
REM #
REM # FILENAME
REM #   oidprovtool.bat
REM #
REM # DESCRIPTION
REM #   This script is used to launch the provisioning tool
REM #
REM # NOTE:
REM #   This script is typically invoked as follows:
REM #
REM #

SETLOCAL

REM  Make sure that our JRE is used for this invocation.
IF Windows_NT == %OS% SET PATH=%s_JRE_LOCATION%\bin;D:\oracle\product\10.2.0\db_1\bin;%PATH%
IF not Windows_NT == %OS% SET PATH="%s_JRE_LOCATION%\bin;D:\oracle\product\10.2.0\db_1\bin;%PATH%"

REM Set class path
SET CLASSROOT=D:\oracle\product\10.2.0\db_1\classes
SET LDAPJCLNT10=D:\oracle\product\10.2.0\db_1\jlib\ldapjclnt10.jar
SET NETCFG=D:\oracle\product\10.2.0\db_1\jlib\netcfg.jar
SET JNDIJARS=D:\oracle\product\10.2.0\db_1\jlib\ldap.jar;D:\oracle\product\10.2.0\db_1\jlib\jndi.jar;D:\oracle\product\10.2.0\db_1\jlib\providerutil.jar

REM make sure ldapjclnt10.jar is present
IF NOT EXIST %LDAPJCLNT10% GOTO NO_LDAPJCLNT10JAR_FILE

SET CLASSPATHADD=%LDAPJCLNT10%;%JNDIJARS%;%CLASSROOT%;%NETCFG%;

SET JRE=jre -nojit
SET CLASSPATH_QUAL=cp

IF "%ORACLE_OEM_JAVARUNTIME%x" == "x" GOTO JRE_START
SET JRE=%ORACLE_OEM_JAVARUNTIME%\bin\java -nojit
SET CLASSPATH_QUAL=classpath
SET CLASSPATHADD=%CLASSPATHADD%;%ORACLE_OEM_JAVARUNTIME%\lib\classes.zip
SET CLASSPATHADD=%CLASSPATHADD%;D:\oracle\product\10.2.0\db_1\jlib\javax-ssl-1_2.jar
SET CLASSPATHADD=%CLASSPATHADD%;D:\oracle\product\10.2.0\db_1\jlib\jssl-1_2.jar

:JRE_START

D:\oracle\product\10.2.0\db_1\jdk\bin\java -ms4m -mx256m -%CLASSPATH_QUAL% %CLASSPATHADD% -DORACLE_HOME=D:\oracle\product\10.2.0\db_1  oracle.ldap.util.provisioning.ProvisioningProfile %*

GOTO THE_END

:NO_LDAPJCLNT10JAR_FILE
   ECHO Missing jar file
   ECHO %LDAPJCLNT10% not found
   GOTO THE_END

:THE_END
   ENDLOCAL
