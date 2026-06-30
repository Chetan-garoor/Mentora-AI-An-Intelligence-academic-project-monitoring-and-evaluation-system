@echo off
setlocal

Rem batch file for stopping GSD daemon

set JREDIR=D:\oracle\product\10.2.0\db_1\jdk\jre
set JRE="%JREDIR%\bin\java"
set JREJAR=%JREDIR%\lib\rt.jar;%JREDIR%\lib\i18n.jar

set PATH=D:\oracle\product\10.2.0\db_1\bin;%PATH%

set CLASSPATH="D:\oracle\product\10.2.0\db_1\jlib\srvm.jar;D:\oracle\product\10.2.0\db_1\jlib\srvmhas.jar;%JREJAR%"

set CMD=%JRE% -classpath %CLASSPATH% oracle.ops.mgmt.daemon.OPSMDaemonStopper

%CMD%
endlocal
