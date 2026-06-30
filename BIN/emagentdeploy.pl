#!/usr/local/bin/perl
# 
# $Header: emagentdeploy.pl.template 23-oct-2003.17:18:13 vnukal Exp $
#
# emagentdeploy.pl
# 
# Copyright (c) 2002, 2003, Oracle Corporation.  All rights reserved.  
#
#    NAME
#      emagentdeploy.pl - deploys emagent with seperate state directories
#
#    DESCRIPTION
#     This script operates in two modes. RAC mode and the agent-only mode.
#     The latter is the default. In the RAC mode directories and files 
#     relevant to the OMS, in addition to files relevant to the agent are 
#     created. In agent-only mode files relevant to only the agent are created 
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    vnukal      10/23/03 - .bat extension needed for Windows 
#    vnukal      10/21/03 - single-quoting substituted strings 
#    vnukal      10/17/03 - unobselting on PJs request 
#    vnukal      10/14/03 - obsoleting. 
#    rpinnama    10/06/03 - Copy the b64InternetCertificate 
#    dmshah      08/26/03 - Adding isqlplus text as part of replace strings 
#                           [on isqlplus request] 
#    dmshah      07/03/03 - Fixing syntax error
#    vnukal      06/23/03 - making script mode-aware
#    dmshah      06/19/03 - Replacing sid per instance during cfs deploy
#    dmshah      05/16/03 - grabtrans 'dmshah_fix_emagentdeploy_beta1'
#    dmshah      05/14/03 - Fixes for CFS-Install
#    dmshah      05/05/03 - optionally modify the targets.xml and copy
#    dmshah      03/26/03 - Review comments
#    dmshah      03/25/03 - Adding code to deploy DBConsole for CFS
#    vnukal      12/18/02 - vnukal_agentstate
#    vnukal      12/17/02 - code review comments
#    vnukal      12/16/02 - adding agentStateDir property
#    vnukal      12/16/02 - Creation
#

use File::Copy;
use Getopt::Std;
use English;

# enclosing in single quotes to prevent \ being interpreted as escape sequence.
$EMDROOT='D:\oracle\product\10.2.0\db_1';

die "EMDROOT var not set.\n" if( $EMDROOT eq "") ;

if (scalar(@ARGV) < 1) {
    print STDERR <<USAGE;
  Usage: $0 [-m rac] [-p <password>] <deploy-dir> <hostname:port> <localhost> <sid> [ <emdroot referenced remotely> ]

      -m rac       : For RAC state-only installs.
      -p <password>: Install password for securing agent.
      <deploy-dir> : Directory to create a state-only agent installation
      <hostname:port> : Hostname and port. Used in the EMD_URL property.
      <localhost> : The local host from which this command is executed. 
                    This is searched and replaced in targets.xml by the 
                    hostname provided in argument <hostname:port>.
      <sid> : The instance id of the remote database.

USAGE
    exit;
}

getopts('p:m:') or die "Aborted\n";

$EMHOME=$ARGV[0];
$HOSTPORT=$ARGV[1];
$LOCALHOST=$ARGV[2];
$SID=$ARGV[3];

my $racMode = $opt_m eq "rac";

# Optional command-line argument for EMDROOT location as referenced from a 
# a remote machine
if (scalar(@ARGV) == 5) 
{
  $REMOTE_EMDROOT = $ARGV[4];
  $replaceEMDROOT=1;
} 
else 
{
  $REMOTE_EMDROOT = $EMDROOT;
}

#######################################################################
#calling new interface
my @emctlargs;
if( ($OSNAME eq "MSWin32") or ($OSNAME eq "Windows_NT") )
{
 push(@emctlargs,$EMDROOT."/bin/emctl.bat","deploy");
}
else
{
 push(@emctlargs,$EMDROOT."/bin/emctl","deploy");
}

if ($racMode)
{
    push(@emctlargs,"dbconsole");
}
else
{
    push(@emctlargs,"agent");
}
push(@emctlargs,"-s ".$opt_p) if($opt_p ne "");
push(@emctlargs,$EMHOME,$HOSTPORT,$LOCALHOST);
push(@emctlargs,$SID) if ($racMode);
push(@emctlargs,$REMOTE_EMDROOT) if ($replaceEMDROOT);
my ($rc) = 0xffff & system @emctlargs ;
$rc >>= 8 ;

exit $rc;

####################################################################

