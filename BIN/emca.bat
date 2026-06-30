@echo off

setlocal

set OH=D:\oracle\product\10.2.0\db_1

set JRE_JAVA=%OH%\jdk\jre\bin\java
set EMCA_JAR=%OH%\jlib\emca.jar
set LIB_DIR=%OH%\jlib

set CLASSPATH=%EMCA_JAR%;
set CLASSPATH=%CLASSPATH%%LIB_DIR%\srvm.jar;
set CLASSPATH=%CLASSPATH%%LIB_DIR%\srvmasm.jar;
set CLASSPATH=%CLASSPATH%%LIB_DIR%\emConfigInstall.jar;
set CLASSPATH=%CLASSPATH%%LIB_DIR%\ldapjclnt10.jar;
set CLASSPATH=%CLASSPATH%%LIB_DIR%\ldap.jar;
set CLASSPATH=%CLASSPATH%%LIB_DIR%\share.jar;
set CLASSPATH=%CLASSPATH%%LIB_DIR%\srvmhas.jar;
set CLASSPATH=%CLASSPATH%%LIB_DIR%\netcfg.jar;
set CLASSPATH=%CLASSPATH%%OH%\lib\xmlparserv2.jar;
set CLASSPATH=%CLASSPATH%%OH%\assistants\jlib\assistantsCommon.jar;
set CLASSPATH=%CLASSPATH%%OH%\sysman\jlib\emCORE.jar;
set CLASSPATH=%CLASSPATH%%OH%\oui\jlib\OraInstaller.jar;
set CLASSPATH=%CLASSPATH%%OH%\oui\jlib\OraPrereq.jar;
set CLASSPATH=%CLASSPATH%%OH%\inventory\prereqs\oui\OraPrereqChecks.jar;
set CLASSPATH=%CLASSPATH%%OH%\oui\jlib\OraPrereqChecks.jar;

%JRE_JAVA% -DDISPLAY=%DISPLAY% -DORACLE_HOME=%OH% -DTNS_ADMIN=%TNS_ADMIN% oracle.sysman.emcp.EMConfigAssistant %*
