@echo off

set ORACLE_HOME=D:\oracle\product\10.2.0\db_1
set JLIB_HOME=D:\oracle\product\10.2.0\db_1\jlib
set PATH=D:\oracle\product\10.2.0\db_1\ldap\bin;D:\oracle\product\10.2.0\db_1\bin;D:\oracle\product\10.2.0\db_1\opmn\bin;%PATH%

set HELPJAR=help4.jar
set ICEJAR=oracle_ice.jar
set SHAREJAR=share.jar
set EWTJAR=ewt3.jar
set EWTCOMPAT=ewtcompat-3_3_15.jar
set NETCFGJAR=netcfg.jar
set DBUIJAR=dbui2.jar



set CLASSPATH="D:\oracle\product\10.2.0\db_1\ldap\postcfg\oidca.jar;%JLIB_HOME%\javax-ssl-1_1.jar;%JLIB_HOME%\jssl-1_1.jar;%JLIB_HOME%\ldapjclnt10.jar;%JLIB_HOME%\%NETCFGJAR%;%JLIB_HOME%\%HELPJAR%;%JLIB_HOME%\%ICEJAR%%JLIB_HOME%\%SHAREJAR%;%JLIB_HOME%\%EWTJAR%;%JLIB_HOME%\%EWTCOMPAT%;%JLIB_HOME%\swingall-1_1_1.jar;%JLIB_HOME%\%DBUIJAR%;D:\oracle\product\10.2.0\db_1\ldap\odi\jlib\sync.jar;D:\oracle\product\10.2.0\db_1\ldap\oidadmin\dasnls.jar;%JLIB_HOME%\ojmisc.jar;D:\oracle\product\10.2.0\db_1\jdbc\lib\classes12.jar;D:\oracle\product\10.2.0\db_1\assistants\jlib\assistantsCommon.jar;D:\oracle\product\10.2.0\db_1\jlib\srvm.jar;D:\oracle\product\10.2.0\db_1\opmn\lib\optic.jar;D:\oracle\product\10.2.0\db_1\jlib\oraclepki103.jar"
D:\oracle\product\10.2.0\db_1\jdk\bin\java -ms4m -mx128m -Djava.security.policy=%s_java2policyFile% -DORACLE_HOME=D:\oracle\product\10.2.0\db_1 -DLDAP_ADMIN=%LDAP_ADMIN% -classpath %CLASSPATH% oracle.ldap.oidinstall.OIDClientCA orahome=D:\oracle\product\10.2.0\db_1 %*

