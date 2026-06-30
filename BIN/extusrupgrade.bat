@echo off

SET JRE_HOME=D:\oracle\product\10.2.0\db_1\jdk\jre\
SET JLIBDIR=D:\oracle\product\10.2.0\db_1\rdbms\jlib
SET LIBDIR=D:\oracle\product\10.2.0\db_1\jdbc\lib

%JRE_HOME%\bin\java -classpath %JLIBDIR%\extusrupgrade.jar;%LIBDIR%\classes12.zip oracle.security.rdbms.server.ExtUsrUpgrade.upgrade.ExtUsrUpgrade %*
