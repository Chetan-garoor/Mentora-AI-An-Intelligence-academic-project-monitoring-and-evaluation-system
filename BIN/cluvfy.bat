@echo off
REM
REM WINDOWS file
REM
REM $Header: cluvfyrac.sbs 28-sep-2004.17:28:27 smishra Exp $
REM
REM cluvfyrac.sbs
REM
REM Copyright (c) 2004, Oracle. All rights reserved.  
REM
REM    NAME
REM      cluvfyrac.sbs 
REM
REM    DESCRIPTION
REM      This file gets copied into OH/bin as cluvfy.sh 
REM
REM    NOTES
REM      This is a WINDOWS file
REM
REM

Rem Gather command-line arguments.
:arg
@set USER_ARGS=
:loop
if (%1)==() goto parsed
 @set USER_ARGS=%USER_ARGS% %1
 shift
goto loop
:parsed

@set ORA_CRS_HOME= 
CALL \bin\cluvfy %USER_ARGS%

