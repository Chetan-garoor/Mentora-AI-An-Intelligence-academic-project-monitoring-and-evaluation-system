@echo off
if "%OS%"=="Windows_NT" setlocal

set jreclasspath="D:\oracle\product\10.2.0\db_1\jdk\jre\\lib\rt.jar;D:\oracle\product\10.2.0\db_1\jdk\jre\\lib\i18n.jar;D:\oracle\product\10.2.0\db_1\jdbc\lib\classes12.jar;D:\oracle\product\10.2.0\db_1\javavm\lib\aurora.zip"

set args=
:loop
  if (%1)==() goto :done
  set args=%args% %1
  shift
  goto :loop
:done

"D:\oracle\product\10.2.0\db_1\jdk\jre\\bin\java" -Xint -classpath %jreclasspath% oracle.aurora.server.tools.shell.ShellClient  %args%

if "%OS%" == "Windows_NT" endlocal
