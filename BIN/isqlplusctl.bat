@ECHO OFF
rem 
rem Copyright (c) 2004, 2005, Oracle. All rights reserved.  
rem
rem    NAME
rem      isqlplusctl.bat - Single controller script for start and shutdown
rem                        of iSQL*Plus
rem
rem    DESCRIPTION
rem      Starts up and shuts down iSQL*Plus instance.
rem
rem    NOTES
rem
rem    MODIFIED   (MM/DD/YY)
rem    asouleim    06/14/05 - Add IS_RAC sys var
rem    lnim        05/05/05 - Bump version to 10.2.0.1.0 
rem    lnim        03/08/05 - update copyright year 
rem    asouleim    07/07/04 - Get rmi port from rmi.xml during startup
rem    lnim        04/01/04 - Bump version to 10.2.0.0.0 
rem    asouleim    02/19/04 - Fix for bug# 3435850
rem    asouleim    12/18/03 - asouleim_iplusservice 
rem    asouleim    12/18/03 - modification for opmn
rem    iawu        11/27/03 - switch to service executable
rem    asouleim    08/31/03 - env vars fix 
rem    ahollowa    08/29/03 - Add environment variable set up. Remove sleep command.
rem                           Tidy up messages.
rem    asouleim    08/06/03 - asouleim_qafix 
rem    asouleim    08/07/03 - Creation

if !%1==!                      goto noarg

set ORACLE_HOME=D:\oracle\product\10.2.0\db_1

set IS_RAC=false

cd D:\oracle\product\10.2.0\db_1\bin

echo iSQL*Plus 10.2.0.1.0
echo Copyright (c) 2003, 2005, Oracle.  All rights reserved.

if "%1" == "start" goto startiplus
if "%1" == "stop"  goto stopiplus

goto badarg

rem 
rem Stop the iSQL*Plus Instance
rem

:stopiplus

echo Stopping iSQL*Plus ...

D:\oracle\product\10.2.0\db_1\bin\isqlplussvc.exe -stop

echo iSQL*Plus stopped.

goto exit

rem 
rem Start the iSQL*Plus Instance
rem

:startiplus

echo Starting iSQL*Plus ...

D:\oracle\product\10.2.0\db_1\bin\isqlplussvc.exe -start

echo iSQL*Plus started.

goto exit

:nohome
echo ORACLE_HOME is not set
goto exit

:noarg
echo No arguments
echo Usage:
echo        isqlplusctl start
echo        isqlplusctl stop
goto exit

:badarg
echo Invalid arguments
echo Unknown command option %1 
echo Usage:
echo        isqlplusctl start
echo        isqlplusctl stop
goto exit

:aborted
echo Starting iSQL*Plus aborted.

:exit
