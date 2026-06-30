@echo off
setlocal

Rem Utility for starting the GSD daemon

Rem SRVM TRACING
if not (%SRVM_TRACE%)==() (
 set SRVM_PROPERTY_DEFS=%SRVM_PROPERTY_DEFS% -DTRACING.ENABLED=true -DTRACING.LEVEL=2
)

set JREDIR=D:\oracle\product\10.2.0\db_1\jdk\jre
set JRE="%JREDIR%\bin\java"
set JREJAR=%JREDIR%\lib\rt.jar

set CLASSPATH="D:\oracle\product\10.2.0\db_1\jlib\srvm.jar;D:\oracle\product\10.2.0\db_1\jlib\srvmhas.jar;D:\oracle\product\10.2.0\db_1\jlib\netcfg.jar;D:\oracle\product\10.2.0\db_1\jlib\ldapjclnt10.jar;%JREJAR%"

set PATH=D:\oracle\product\10.2.0\db_1\bin;%PATH%

set CMD=%JRE% -DTRACING.ENABLED=false -DTRACING.LEVEL=2 -classpath %CLASSPATH% -Dsrvm.daemon.systemroot=%SystemRoot% %SRVM_PROPERTY_DEFS% oracle.ops.mgmt.daemon.OPSMDaemon "D:\oracle\product\10.2.0\db_1"

echo %CMD%

%CMD%
endlocal
