@echo off

:: localconfig.bat for local CSS
::
:: This script file should be run for following three cases:
::  1) When there are more than two single instance Oracle homes on a node and 
::     you are deleting/deinstalling the Oracle home that currently runs 
::     CSS daemon
::  2) When there is only one single instance Oracle home on a node and you are
::     deleting/deinstalling that Oracle home
::  3) When there is a Oracle home and you want to add CSS to it.
::
:: USAGE: localconfig.bat [add] | [delete] | [ reset [destination Oracle home] ]
:: delete: should be used when you are executing case 2.
:: reset : should be used when you are executing case 1. When you select this 
::         option to reset CSS configuration, this script can be run from 
::         source Oracle home or destination Oracle home.
::         When running in source Oracle home, you must enter the Oracle path
::         of destination Oracle home so CSS can be reset to that Oracle home 
:: add   : should be used when you are executing case 3. When you select this 
::         option to add CSS to the home, this script can be run from 
::         the destination Oracle home.

set ORACLE_HOME=D:\oracle\product\10.2.0\db_1

if (%1)==(delete) %ORACLE_HOME%\bin\crssetup.exe ldel %2 & goto done
if (%1)==(add)    %ORACLE_HOME%\bin\crssetup.exe ladd -oh "%s_OracleHome%" -l "%s_languageid%" & goto done
if (%1)==(reset)  %ORACLE_HOME%\bin\crssetup.exe lres -oh %2 -l "AMERICAN_AMERICA.WE8ISO8859P1" & goto done
                  D:\oracle\product\10.2.0\db_1\bin\crssetup.exe %1 %2  & goto done

:done

exit /b %ERRORLEVEL%
