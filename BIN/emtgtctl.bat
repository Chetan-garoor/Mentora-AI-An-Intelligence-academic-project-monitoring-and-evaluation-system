@echo off
setlocal
set NLS_LANG=
set ORA_NLS=
set ORA_NLS32=
set ORA_NLS33=
set CONSOLE_CFG=

if not defined REMOTE_EMDROOT (set ORACLE_HOME=D:\oracle\product\10.2.0\db_1)
if not defined REMOTE_EMDROOT (set EMDROOT=D:\oracle\product\10.2.0\db_1)
if defined REMOTE_EMDROOT (set ORACLE_HOME=%REMOTE_EMDROOT%)
if defined REMOTE_EMDROOT (set EMDROOT=%REMOTE_EMDROOT%)

REM # Set common environment settings
call commonenv

set PATH=%ORACLE_HOME%\%EMPERLOHBIN%;%ORACLE_HOME%\bin;%EMDROOT%\bin;%ORACLE_HOME%\jdk\jre\bin\server;%ORACLE_HOME%\oui\lib\win32;%PATH%;%SystemRoot%;%SystemRoot%\system32

%EMDROOT%\bin\emtgtctl.exe %*
endlocal
