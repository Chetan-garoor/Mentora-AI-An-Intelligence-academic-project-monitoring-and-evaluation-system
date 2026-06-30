@echo off
setlocal

Rem Utility for starting the GSDCTL application

Rem No argsuments are paased then goto FAILED
if !%1==! goto NOARG

Rem Gather command-line arguments.
set USER_ARGS=%1

Rem SRVM TRACING
if not (%SRVM_TRACE%)==() (
 set SRVM_PROPERTY_DEFS=%SRVM_PROPERTY_DEFS% -DTRACING.ENABLED=true -DTRACING.LEVEL=2
)

set JREDIR=D:\oracle\product\10.2.0\db_1\jdk\jre
set JRE="%JREDIR%\bin\java"
set JREJAR=%JREDIR%\lib\rt.jar
set JLIB=D:\oracle\product\10.2.0\db_1\jlib

set PATH=D:\oracle\product\10.2.0\db_1\bin;%PATH%

set CLASSPATH="%JLIB%\srvm.jar;%JLIB%\srvmhas.jar;%JLIB%\netcfg.jar;%JREJAR%"

set LSNODESEXE=D:\oracle\product\10.2.0\db_1\bin\lsnodes.exe

%LSNODESEXE% > NUL
if errorlevel 1 goto NOCM

Rem Set commands this batch will run
set STATCMD=%JRE% -classpath %CLASSPATH% %SRVM_PROPERTY_DEFS% oracle.ops.mgmt.daemon.GSDCTLDriver %USER_ARGS% D:\oracle\product\10.2.0\db_1
set STARTCMD=D:\oracle\product\10.2.0\db_1\bin\gsd.exe
set STOPCMD=D:\oracle\product\10.2.0\db_1\bin\gsdstop.bat
set RMSERVICE=D:\oracle\product\10.2.0\db_1\bin\gsdservice -remove

if (%USER_ARGS%)==(start) (
  goto STARTGSD
)

if (%USER_ARGS%)==("start") (
  goto STARTGSD
)

if (%USER_ARGS%)==(stat) (
  goto STATGSD
)

if (%USER_ARGS%)==("stat") (
  goto STATGSD
)

if (%USER_ARGS%)==(stop) (
  goto STOPGSD
)

if (%USER_ARGS%)==("stop") (
  goto STOPGSD
)

Rem you are here means gsdctl got a bogus argument
goto FAILED

:STARTGSD
 %RMSERVICE% > NUL
 %STARTCMD%
 set STATUS=%errorlevel%
 goto STATUSCHK

:STATGSD
 %STATCMD%
 set STATUS=%errorlevel%
 goto STATUSCHK

:STOPGSD
 %STOPCMD%
 set STATUS=%errorlevel%
 goto STATUSCHK

:NOCM
exit /B 0

:STATUSCHK
if (%STATUS%)==(1) (
goto FAILED
)
exit /B 0

:NOARG
:FAILED
exit /B 1

:ENDSCRIPT

endlocal
