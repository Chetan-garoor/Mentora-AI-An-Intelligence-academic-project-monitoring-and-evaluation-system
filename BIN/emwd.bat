@echo off
REM #
REM # Copyright (c) 2001, 2003 Oracle Corporation.  All rights reserved.
REM #
REM # PRODUCT
REM #	Enterprise Manager Agent, Version 4.0.1
REM #
REM # FILENAME
REM #	emwd.bat
REM #
REM # DESCRIPTION
REM #	This script is responsible for keeping the agent UP. It restarts the
REM #	the agent until it exits with a known set of error codes OR if the 
REM #   EM_RESTART is set to 0
REM #
REM # MODIFIED (MM/DD/YY)
REM #    kduvvu 04/09/03 - write nohup to emagent.nohup
REM #    vnukal 01/27/03 - vnukal_nt-service-1
REM #    vnukal 01/12/03 - Initial revision
REM #
setlocal

set debug=1
IF NOT DEFINED EMDROOT ( 
	echo EMDROOT env. var not set. Exiting.
	goto :EOF
	)

if not defined AGENTSTATE (set AGENTHOME=%EMDROOT%)
if defined AGENTSTATE (set AGENTHOME=%AGENTSTATE%)

set EM_WDLOGFILE=%AGENTHOME%\sysman\log\emagent.nohup
set PATH=%ADDL_PATH%;%PATH%

if "%1" == "start" goto startAgent
if "%1" == "status" goto statusAgent
if "%1" == "stop" goto stopAgent
echo Unknown command. Valid commands are start, status, stop.
goto :EOF


:statusAgent
%EMDROOT%\bin\emdctl status agent > NUL 2>&1
set RETVAL=%errorlevel%
call :printtimestamp timestamp
echo Status request sent on %timestamp% .Return value %RETVAL% >> %EM_WDLOGFILE%_stat
exit %RETVAL%

:stopAgent
%EMDROOT%\bin\emdctl stop agent > NUL 2>&1
set RETVAL=%errorlevel%
call :printtimestamp timestamp
echo Stop request sent on %timestamp% .Return value %RETVAL% >> %EM_WDLOGFILE%_stop
exit %RETVAL%


:startAgent

REM shift to lose the command argument i.e. 'start'
shift

REM IF NOT DEFINED ORACLE_HOME (
REM	echo ORACLE_HOME env. var not set. Exiting.
REM	goto :EOF
REM	)

IF NOT DEFINED JAVA_HOME ( 
	echo JAVA_HOME env. var not set. Exiting.
	goto :EOF
	)

IF NOT DEFINED EM_MAX_RETRIES set EM_MAX_RETRIES=3
IF NOT DEFINED EM_RETRY_WINDOW set EM_RETRY_WINDOW=600

if DEFINED debug echo EM_MAX_RETRIES is %EM_MAX_RETRIES% >> %EM_WDLOGFILE%
if DEFINED debug echo EM_RETRY_WINDOW is %EM_RETRY_WINDOW% >> %EM_WDLOGFILE%

set numTimes=0
set prevDate=1
set timeDiff=0
set debug=1

:restartAgent

if not exist %EMDROOT%\bin\emagent.exe (
	echo emagent executable not found in %EMDROOT%\bin. Exiting.
	goto :EOF
	)

REM TODO put blank line
call :printtimestamp timestamp
echo  ----------------------------------------------------------------- >> %EM_WDLOGFILE%
echo  --------------- Starting emagent at %timestamp% ----------------- >> %EM_WDLOGFILE%
echo  ----------------------------------------------------------------- >> %EM_WDLOGFILE%



%EMDROOT%\bin\emagent %1 %2 %3 %4 %5 %6 %7 >> %EM_WDLOGFILE% 2>&1
set RETVAL=%errorlevel%
call :printtimestamp timestamp
echo Agent exited on %timestamp% with return value %RETVAL% >> %EM_WDLOGFILE%

rem RETVAL=0 indicates normal exit
if "%RETVAL%" == "0" goto exitscript

rem RETVAL=3 indicates restart request
if "%RETVAL%" == "3" goto restartAgent

rem RETVAL=55 indicates initialization failure
if "%RETVAL%" == "55" goto exitscript

rem check if restart variable is explicitly overidden
if "%EM_RESTART%" == "0" goto exitscript

rem check if dbsnmp has been restarted more than EM_MAX_RETRIES times in less than EM_RETRY_WINDOW
REM get and store current time
call :gettimestamp currDate

if DEFINED debug echo numTimes is %numTimes% >> %EM_WDLOGFILE%
set /a modValue=numTimes %% EM_MAX_RETRIES
if DEFINED debug echo modValue is %modValue% >> %EM_WDLOGFILE%

if DEFINED debug echo currDate is %currDate% >> %EM_WDLOGFILE%
if DEFINED debug echo prevDate is %prevDate% >> %EM_WDLOGFILE%
set /a timeDiff=currDate - prevDate 
if DEFINED debug echo timeDiff is %timeDiff% >> %EM_WDLOGFILE%

REM For some reason the set does not seem effective inside a multi-statement if block
REM hence splitting the condition statement into two parts.
if %modValue% EQU 0 (set /a prevDate=currDate)

if %modValue% EQU 0 (
	if %timeDiff% LSS %EM_RETRY_WINDOW% (
			call :printtimestamp timestamp
			echo Agent thrashing. Exiting dbsnmpwd at %timestamp% >> %EM_WDLOGFILE%
			goto :EOF))
	

set /a numTimes=numTimes+1
if DEFINED debug echo numTimes after increment is %numTimes% >> %EM_WDLOGFILE%

call :printtimestamp timestamp
echo Restarting the agent at %timestamp% >> %EM_WDLOGFILE%

goto restartAgent

:printtimestamp
for /f "tokens=2" %%D in ('date /t') do (
     for /f %%T in ('time /t') do (set %1=%%D %%T))
goto :EOF

:gettimestamp 
for /f %%U in ('%EMDROOT%\bin\nmetm') do set %1=%%U
goto :EOF

:exitscript
if "%RETVAL%" == "0" ( echo Agent shutdown normally >> %EM_WDLOGFILE%
) ELSE if "%RETVAL%" == "55" (echo Could not start agent. Initialization failure >> %EM_WDLOGFILE% & echo Agent startup failed. Check %EM_WDLOGFILE% for details >> %EM_WDLOGFILE% 
) ELSE (echo DBSNMP: Abnormal exit. Not restarting. >> %EM_WDLOGFILE%)
endlocal
exit %RETVAL%


