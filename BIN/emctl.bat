@echo off
REM #
REM # Copyright (c) 2001, 2003 Oracle Corporation. All rights reserved.
REM #
REM # PRODUCT
REM #    EMDW - Enterprise Manager Control script   
REM #
REM # FILENAME
REM #    emctl.bat
REM #
REM # DESCRIPTION
REM #  emctl is used to start and stop the oc4j servlet container
REM #  with the SMP Webapplications that provide monitoring and admin-
REM #  istration capabilities.
REM #
REM #
REM MODIFIED   (MM/DD/YY)
REM    sxzhu    11/02/04 - Set full path for commonenv 
REM    smpbuild 09/21/04 - 
REM    njagathe 08/24/04 - Remove references to win arch 
REM    njagathe 08/23/04 - Fix 561 refs 
REM    aaitghez 04/06/04 - bug 3542881. cd to EMDROOT before calling emctl.pl 
REM    rzkrishn 03/18/04 - removing instant client 
REM    rzkrishn 03/04/04 - using instant client 
REM    jsutton  04/09/04 - Fix AS Control and Agent service name tokens 
REM    vnukal   03/02/04 - adding SystemRoot to PATH 
REM    vnukal   11/14/03 - structure instantiations to root var 
REM    njagathe 10/29/03 - Allowing for REMOTE_EMDROOT override 
REM    vnukal   10/10/03 - Deploy changes 
REM    dmshah   09/15/03 - Changes for multiple OH 
REM    mgoodric 07/24/03 - add oraInstaller.dll to PATH
REM    dmshah   07/08/03 - EMWD NT hookup
REM    vnukal   06/27/03 - jvm.dll under server
REM    szhu     06/18/03 - Set PERL_BIN
REM    vnukal   06/12/03 - updating for 401
REM    jsutton  06/03/03 - Fix path to perl.exe
REM    vnukal   04/28/02 - moving set EMDROOT to workaround installer bug
REM    vnukal   01/08/02 - Merged vnukal_rename-script_main
REM    vnukal   12/27/01 - Adding JAVA_HOME
REM

setlocal

REM No more overriding of EMDROOT through the environment - see bug 3217672
REM Instead, allow overriding through REMOTE_EMDROOT variable for state only
REM installs
if not defined REMOTE_EMDROOT (set ORACLE_HOME=D:\oracle\product\10.2.0\db_1)
if not defined REMOTE_EMDROOT (set EMDROOT=%ORACLE_HOME%)
if defined REMOTE_EMDROOT (set ORACLE_HOME=%REMOTE_EMDROOT%)
if defined REMOTE_EMDROOT (set EMDROOT=%ORACLE_HOME%)
if defined REMOTE_EMDROOT (set LOCAL_EMDROOT=D:\oracle\product\10.2.0\db_1)

REM # Set common environment settings
call %EMDROOT%/bin/commonenv

REM Make sure certain environment variables are set
set JAVA_HOME=%ORACLE_HOME%\jdk
set JRE_HOME=%ORACLE_HOME%\jdk\jre
set PERL_BIN=%ORACLE_HOME%\%EMPERLOHBIN%
set PERL_HOME=%ORACLE_HOME%\perl

set EM_OC4J_HOME=D:\oracle\product\10.2.0\db_1\oc4j\j2ee\OC4J_DBConsole

if not defined AGENT_SERVICE_NAME (set AGENT_SERVICE_NAME=)
set SAC_SERVICE_NAME=
if not defined DBCONSOLE_SERVICE_NAME (set DBCONSOLE_SERVICE_NAME=OracleDBConsole%ORACLE_SID%)

set CRS_HOME=

set CONSOLE_CFG=dbconsole
set HOST_SID_OFFSET_ENABLED=host_sid

set PERL5LIB=%ORACLE_HOME%\%EMPERLOHBIN%;%ORACLE_HOME%\perl\lib;%ORACLE_HOME%\perl\lib\site_perl;%ORACLE_HOME%\perl\site\lib;%EMDROOT%\sysman\admin\scripts;%ORACLE_HOME%\bin;%EMDROOT%\bin

set PATH=%ORACLE_HOME%\%EMPERLOHBIN%;%ORACLE_HOME%\bin;%EMDROOT%\bin;%JAVA_HOME%\jre\bin\server;%ORACLE_HOME%\oui\lib\win32;%PATH%;%SystemRoot%;%SystemRoot%\system32

cd %EMDROOT%

if "%1" == "istart" goto skipEmctl
goto execEmctl

:execEmctl
%PERL_BIN%\perl.exe %EMDROOT%\bin\emctl.pl %*
set RETVAL=%errorlevel%
if defined NEED_EXIT_CODE exit %RETVAL%
goto :EOF

:skipEmctl
%PERL_BIN%\perl.exe %EMDROOT%\bin\emwd.pl %2
set RETVAL=%errorlevel%
if defined NEED_EXIT_CODE exit %RETVAL%
goto :EOF

endlocal

