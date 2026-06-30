@echo off

@set OH=D:\oracle\product\10.2.0\db_1

@set JREDIR=D:\oracle\product\10.2.0\db_1\jdk\jre
@set JLIBDIR=D:\oracle\product\10.2.0\db_1\jlib

@set SHAREJAR=%JLIBDIR%\share.jar
@set EWTJAR=%JLIBDIR%\ewt3.jar
@set EWTOTHER=%JLIBDIR%\ewtcompat-3_3_15.jar
@set HELPJAR=%JLIBDIR%\help4.jar;%JLIBDIR%\jewt4.jar;%JLIBDIR%\oracle_ice.jar
@set SRVM_CLASSPATH=%JLIBDIR%\srvm.jar;%JLIBDIR%\srvmhas.jar
@set INSTALLERJAR=%OH%\oui\jlib\OraInstaller.jar
@set XMLPARSERJAR=%OH%\lib\xmlparserv2.jar
@set EMCAJAR=%OH%\emdw\lib\emca.jar

@set NETCFGJAR=%JLIBDIR%\netcfg.jar
@set JNDIJAR=%JLIBDIR%\jndi.jar
@set LDAPCLNT=%JLIBDIR%\ldapjclnt9.jar;%JLIBDIR%\ldapjclnt10.jar
@set NETJLIBDIR=%OH%\network\jlib
@set NETTOOLSDIR=%OH%\network\tools
@set NETCAJAR=%NETJLIBDIR%\netcam.jar;%NETJLIBDIR%\netca.jar
@set JRE=%JREDIR%\bin\java    
@set JREJAR=%JREDIR%\lib\rt.jar;%JREDIR%\lib\i18n.jar

@set CLASSPATH=%NETCAJAR%;%JNDIJAR%;%NETCFGJAR%;%LDAPCLNT%;%EWTJAR%;%HELPJAR%;%SHAREJAR%;%JREJAR%;%EWTOTHER%;%NETTOOLSDIR%;%SRVM_CLASSPATH%;%INSTALLERJAR%;%XMLPARSERJAR%;%EMCAJAR%

@set PWD=%CD%
cd %OH%\bin
%JRE% -Dsun.java2d.noddraw=true -classpath "%CLASSPATH%" oracle.net.ca.NetCA %*
@set NETCA_EXIT_STATUS=%ERRORLEVEL%
cd %PWD%
exit /B %NETCA_EXIT_STATUS%

