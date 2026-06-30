@ECHO OFF
SETLOCAL

REM Check if ORACLE_HOME has been set
if (D:\oracle\product\10.2.0\db_1) == () goto :nohome

REM Get the command line arguments
set args=
:loop
  if !%1==! goto :done
  set args=%args% %1
  shift
  goto :loop
:done

D:\oracle\product\10.2.0\db_1\jdk\jre\\bin\java -classpath D:\oracle\product\10.2.0\db_1\jlib\oraclepki.jar oracle.security.pki.OracleSecretStoreTextUI %args%

goto :exit

:nohome
echo ORACLE_HOME environment variable is not set

:exit
endlocal
