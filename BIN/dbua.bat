@echo off

@set OH=D:\oracle\product\10.2.0\db_1
@set JRE_CLASSPATH=D:\oracle\product\10.2.0\db_1\jdk\jre\lib\rt.jar
@set I18N_CLASSPATH=D:\oracle\product\10.2.0\db_1\jdk\jre\lib\i18n.jar
@set EWT_CLASSPATH=%OH%\jlib\ewt3.jar;%OH%\jlib\ewtcompat-3_3_15.jar
@set BALISHARE_CLASSPATH=%OH%\jlib\share.jar
@set SWING_CLASSPATH=%OH%\jlib\swingall-1_1_1.jar
@set ICE_BROWSER_CLASSPATH=%OH%\jlib\oracle_ice5.jar
@set HELP_CLASSPATH=%OH%\jlib\help4.jar;%OH%\jlib\jewt4.jar
@set XMLPARSER_CLASSPATH=%OH%\lib\xmlparserv2.jar
@set GDK_CLASSPATH=%OH%\jlib\orai18n.jar;%OH%\jlib\orai18n-mapping.jar;%OH%\jlib\orai18n-utility.jar;%OH%\jlib\orai18n-collation.jar
@set NETCFG_CLASSPATH=%OH%\jlib\netcfg.jar;%OH%\jlib\oraclepki103.jar;%OH%\jlib\ldapjclnt10.jar
@set EM_CLASSPATH=%OH%\classes;%OH%\jlib\oemlt-10_1_0.jar;%OH%\jlib\emca.jar;%OH%\sysman\jlib\emCORE.jar;%OH%\oc4j\j2ee\home\oc4j.jar;%OH%\oc4j\j2ee\home\db_oc4j_deploy.jar;%OH%\jlib\emConfigInstall.jar
@set SRVM_CLASSPATH=%OH%\jlib\srvm.jar;%OH%\jlib\srvmhas.jar;%OH%\jlib\srvmasm.jar
@set ASSISTANTS_COMMON_CLASSPATH=%OH%\assistants\jlib\assistantsCommon.jar
@set DBMA_CLASSPATH=%OH%\assistants\dbua\jlib\dbma.jar
@set INSTALLER_CLASSPATH=%OH%\oui\jlib\OraInstaller.jar

@set CLASSPATH=%JRE_CLASSPATH%;%I18N_CLASSPATH%;%DBMA_CLASSPATH%;%ASSISTANTS_COMMON_CLASSPATH%;%EWT_CLASSPATH%;%BALISHARE_CLASSPATH%;%SWING_CLASSPATH%;%ICE_BROWSER_CLASSPATH%;%HELP_CLASSPATH%;%XMLPARSER_CLASSPATH%;%GDK_CLASSPATH%;%EM_CLASSPATH%;%SRVM_CLASSPATH%;%NETCFG_CLASSPATH%;%ORACLE_OEM_CLASSPATH%;%INSTALLER_CLASSPATH%

"D:\oracle\product\10.2.0\db_1\jdk\jre\BIN\JAVA" -Dsun.java2d.noddraw=true -DORACLE_HOME="%OH%" -mx128m oracle.sysman.assistants.dbma.Dbma  %*

exit /B %ERRORLEVEL%
