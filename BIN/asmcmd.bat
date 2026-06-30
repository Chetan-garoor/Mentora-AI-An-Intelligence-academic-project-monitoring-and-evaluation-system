@echo off
rem $Header: asmcmd.bat 27-dec-2004.12:36:11 hqian Exp $
rem
rem asmcmd.bat
rem
rem Copyright (c) 2004, Oracle. All rights reserved.  
rem
rem    NAME
rem      asmcmd.bat - ASM CoMmanD line interface (Wrapper)
rem
rem    DESCRIPTION
rem      This program is a wrapper for asmcmdcore.  It takes the same
rem      parameters as asmcmdcore.  It first checks to see if %ORACLE_HOME% 
rem      is set.  If not, it prints an error messages and exits. 
rem      It then invokes asmcmdcore at %ORACLE_HOME%/bin/asmcmdcore with 
rem      the Perl interpreter at %ORACLE_HOME%/perl/<version>/bin/perl.
rem
rem    NOTES
rem      usage: asmcmd [-p] [command]
rem
rem      This wrapper program now supports only Windows platforms.  Use 
rem      the asmcmd Bourne Shell script for UNIX platforms.
rem
rem    MODIFIED   (MM/DD/YY)
rem    hqian      12/27/04 - hqian_bug-4027167_nt
rem    hqian      12/10/04 - Creation: wrapper batch file for ASMCMD on NT.


rem %ORACLE_HOME% must be set; if not, print error and exit.
if "%ORACLE_HOME%"=="" (
  echo "asmcmd: the environment variable ORACLE_HOME is not set."
  goto end
)

rem Construct path to Perl.  Assume version 5.8.3 first.
set PERLBIN=%ORACLE_HOME%\perl\5.8.3\bin\MSWin32-x86-multi-thread\perl.exe

rem If version 5.8.3 is not there, assume version 5.6.1.
if not exist %PERLBIN% (
  set PERLBIN=%ORACLE_HOME%\perl\5.6.1\bin\MSWin32-x86\perl.exe
)

rem If version 5.6.1 is not there, then assume Perl is in %PATH%.
if not exist %PERLBIN% (
  set PERLBIN=perl.exe
)

rem Construct path to ASMCMDCORE.
set ASMCMDCORE=%ORACLE_HOME%\bin\asmcmdcore

rem Now run asmcmdcore with all arguments!
%PERLBIN% %ASMCMDCORE% %*

:end
