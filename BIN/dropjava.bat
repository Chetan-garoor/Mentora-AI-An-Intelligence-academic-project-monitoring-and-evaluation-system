@echo off
if (%OS%) == (Windows_NT) setlocal
set JAVA_HOME=D:\oracle\product\10.2.0\db_1\jdk\jre\

set JRECLASSPATH="D:\oracle\product\10.2.0\db_1\javavm\lib\aurora.zip;D:\oracle\product\10.2.0\db_1\jdk\jre\\lib\rt.jar;D:\oracle\product\10.2.0\db_1\jdk\jre\\lib\i18n.jar;D:\oracle\product\10.2.0\db_1\jdbc\lib\classes12.jar"

"D:\oracle\product\10.2.0\db_1\jdk\jre\\bin\java" -Xint -classpath %JRECLASSPATH%  oracle.aurora.server.tools.loadjava.DropJavaMain %*

if (%OS%) == (Windows_NT) endlocal
