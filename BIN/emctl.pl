#!/usr/local/bin/perl
# 
# $Header: emctl.pl.template 18-jul-2005.17:53:39 balnaff Exp $
#
# emctl.pl
# 
# Copyright (c) 2002, 2005, Oracle. All rights reserved.  
#
#    NAME
#      emctl.pl - Single controller script for various consoles and agent
#
#    DESCRIPTION
#      Single entry point script for controlling various consoles and agent
#
#    NOTES
#
#    MODIFIED   (MM/DD/YY)
#    balnaff     07/18/05 - quitting with correct exit code with "emctl stop 
#                           dbconsole" 
#    blivshit    06/02/05 - check if PID is correct process 
#    vkapur      04/08/05 - fix bug 4279661 
#    rzazueta    03/10/05 - Update Copyright 
#    vnukal      02/23/05 - checkTZSynch
#    kduvvuri    01/25/05 - correct the name of the repository side script. 
#    asawant     01/17/05 - Do not execute perl when setting SSO 
#    vkapur      12/17/04 - bug 4073957 
#    kduvvuri    12/03/04 - RFI 3991544. 
#    rzkrishn    12/03/04 - starting subagent in windows 
#    rzazueta    12/01/04 - Hit /em/genwallet in statusOMS
#    kduvvuri    11/30/04 - RFI 3998189. 
#    asawant     11/23/04 - Adding secure password reading on Windows 
#    asawant     11/17/04 - Remove call to getLocalHost 
#    asawant     11/09/04 - Add ORACLE_HOSTNAME 
#    blivshit    10/14/04 - pass in EM product version number, either 10.2 or 
#                           10.1.0.4 
#    vkapur      10/14/04 - retrieve OMS_RECV_DIR_SET after deploy branch 
#    vkapur      10/13/04 - mod statusSAConsole() 
#    vkapur      10/12/04 - ER 3406918: do not check status of dbconsole if 
#                           oms configured remotely 
#    gan         05/06/04 - target direct load 
#    gan         04/13/04 - check repository mode 
#    vnukal      01/22/04 - fix started reporting behaviour 
#    gachen      01/09/04 - access permission 
#    jsutton     05/18/04 - Handle slower systems; e.g. regressions 
#    kduvvuri    05/14/04 - backport of bug 2997703. 
#    asawant     05/07/04 - add setpasswd verb to dbconsole and oms
#    gachen      05/04/04 - bump version to 10.1.0.3
#    gan         04/13/04 - check repository mode
#    vnukal      01/22/04 - fix started reporting behaviour
#    gachen      01/09/04 - access permission
#    kduvvuri    01/08/04 - unset PATH in reloadEMD only on non windows 
#    njagathe    12/31/03 - bug-3343940. perl taint 
#    aaitghez    12/29/03 - bug 3339329. add sysman/admin/scripts and bin to 
#    ancheng     01/02/04 - change copyright text 
#    aaitghez    12/23/03 - use delete not undef to unset env var 
#    rzazueta    12/16/03 - Remove space in ps command arguments 
#    vnukal      12/01/03 - creating service for DBConsole 
#    rzazueta    12/01/03 - Deprecate password to shutdown DBConsole 
#    vnukal      11/20/03 - error on agent down 
#    vnukal      11/17/03 - cr comments 
#    vnukal      11/14/03 - NFS install changes 
#    jabramso    11/12/03 - EXE extension on nmei 
#    jabramso    11/11/03 - copy ilint not error 
#    jabramso    11/10/03 - move temp files back to cwd 
#    rzazueta    11/05/03 - Fix bug 3164505: Deprecate password to shutdown 
#    jabramso    11/05/03 - add check for missing ilint executable 
#    rzazueta    11/04/03 - Fix bug 3174706: change status return codes 
#    jabramso    11/04/03 - chdir ilint 
#    jabramso    11/03/03 - NT Bug requires chdir for ilint 
#    rzazueta    10/31/03 - Fix bug 3127435: net command path 
#    njagathe    10/30/03 - Also unset REMOTE_EMDROOT 
#    njagathe    10/29/03 - Allow AGENT_STATE to be computed instead of being 
#    vnukal      10/22/03 - servicename not mandatory for dbconsole deploy 
#    vnukal      10/20/03 - deploy actions moved to top 
#    aaitghez    10/19/03 - bug 3201173 
#    vnukal      10/10/03 - deploy functionality 
#    rzazueta    10/14/03 - Fix bug 3146570 
#    jsutton     10/15/03 - Fix iAS console control 
#    rzazueta    10/06/03 - Fix bug 3119098: change banners and versions 
#    jsutton     10/01/03 - Fix substitutions 
#    aaitghez    09/30/03 - onde argument to getemhome 
#    aaitghez    09/30/03 - change usage message 
#    aaitghez    09/29/03 - review comments 
#    aaitghez    09/26/03 - bug 3095057 
#    rzazueta    09/30/03 - Add startifdown, remove restart iasconsole 
#    dmshah      09/17/03 - Code review changes 
#    dmshah      09/15/03 - Integration testing changes 
#    dmshah      09/03/03 - Moving checkAboutPage to the DBConsole.pm module 
#    jtrichar    09/02/03 - porting from 401: jsutton's startup backoff 
#    echolank    08/22/03 - merge from 401 to main 
#    kduvvuri    08/20/03 - fix config agent 
#    rzazueta    08/11/03 - Better error message for bug 3044441
#    rzazueta    08/06/03 - Fix bug 3044441
#    rpinnama    08/06/03 - Support secure dbconsole 
#    rzazueta    08/04/03 - Fix bug 3070285 
#    kduvvuri    07/28/03 - move supportedTZ to emwd.pl.template.
#    dkapoor     07/07/03 - use admin instead of ias_admin
#    dmshah      07/21/03 - internal command syntax to start agent is "agent"
#    dmshah      07/21/03 - Bug fix 3054810
#    dmshah      07/18/03 - Fixing EMDROOT var
#    jabramso    07/21/03 - ilint args
#    dmshah      07/10/03 - 
#    dmshah      07/09/03 - Testing changes
#    dmshah      07/08/03 - Adding NT svc hookup for emctl/emwd
#    dmshah      07/08/03 - Bug fixes from 401 branch
#    kduvvuri    07/08/03 - merge fix for 2949193
#    kduvvuri    06/19/03  - fix updateTZ getTZ options
#    kduvvuri    06/18/03 -  code review comments.
#    kduvvuri    06/17/03 - get rid of code that reads supportedtzs.lst
#    kduvvuri    06/17/03 - add emctl config agent updateTZ and  getTZ
#    dmshah      06/26/03 - opmnctl fixes
#    dmshah      06/23/03 - fix bug 3015053
#    szhu        06/23/03 - Do not use fork() on NT
#    jpyang      06/20/03 - 9.0.4 update
#    dmshah      06/14/03 - 
#    dmshah      06/09/03 - Reworking emctl code
#    dmshah      05/19/03 - Increasing the started wait time from 60 secs to 180 secs
#    dmshah      05/27/03 - Explicitly close stdin for rsh execution
#    dmshah      05/05/03 - Updating banner for CFS-RAC
#    njagathe    05/14/03 - Add reload dynamicproperties usage
#    njagathe    05/13/03 - Fix passing of args
#    njagathe    05/12/03 - Pass subcmds for reload
#    rzkrishn    04/30/03 - review comments
#    rzkrishn    04/29/03 - adding clearstate
#    njagathe    04/22/03 - Allow subrequests of status agent
#    dmshah      04/09/03 - Removing hardcoded pid 1 from dbaconsole stop
#    dmshah      04/06/03 - Fixing implicit shell launch
#    dmshah      04/02/03 - Adding func for monitoring dbConsole
#    dmshah      04/02/03 - grabtrans 'dmshah_fix_2849086_2'
#    dmshah      04/08/03 - Removing hardcoded pid from stopSAC
#    dmshah      04/07/03 - Review comments
#    dmshah      04/07/03 - Checking for exact return code during start agent/em
#    rpinnama    03/31/03 - Check if TZ is a supported TZ
#    dkapoor     03/26/03 - use 512M for MstartEM_SA
#    dmshah      03/26/03 - Review comments
#    dmshah      03/25/03 - Adding code to deploy DBConsole for CFS
#    vnukal      02/26/03 - Override for starting w/o NT service
#    hakali      02/20/03 - use oc4j j2ee
#    itarashc    02/25/03 - comment for runILINT
#    itarashc    02/17/03 - add ilint
#    kduvvuri    02/13/03 - use system instead of exec when doing emdctl reload
#    kduvvuri    01/28/03 - changes to start and stop of NT service
#    kduvvuri    01/27/03 - add NT Specific Macros
#    dkapoor     02/05/03 - use variable is condition
#    dkapoor     01/31/03 - use sa_setup variable
#    hakali      01/22/03 - use config instead of policy
#    aaitghez    01/13/03 - change EM version string
#    rzkrishn    01/14/03 - calling nohup on emsubagent
#    rzkrishn    01/14/03 - review changes : emsubagent redirecting to nohup
#    rzkrishn    01/13/03 - adding start, status, stop functionality for EM subagent
#    hakali      01/16/03 - mainsa setup
#    rzkrishn    01/10/03 - review changes
#    rzkrishn    01/10/03 - copying the comments
#    rzkrishn    01/09/03 - bug 2742104
#    rzkrishn    01/09/03 - including nodelevel
#    djoly       01/06/03 - Add a couple of properties for ias
#    skini       12/30/02 - Pass standalone mode to ias console
#    njagathe    01/09/03 - Set JAVA_HOME to JRE_HOME for agent environment
#    dmshah      01/02/03 - fix bug 2732042
#    vnukal      12/16/02 - separate out agent state directory
#    skini       12/30/02 - Pass standalone mode to ias console
#    njagathe    12/19/02 - Add JRE_HOME variable and use in LD_LIBRARY_PATH etc
#    dmshah      12/16/02 - Fixing status agent
#    dmshah      12/18/02 - Fixing bug 2719514.secure oms falls through the loop
#    dmshah      12/15/02 - 
#    dmshah      12/13/02 - fixing start em hang
#    dmshah      12/13/02 - Only status blackout can have 2 args
#    itarashc    12/13/02 - 
#    dmshah      12/12/02 - dmshah_common_emctl_main
#    dmshah      12/12/02 - Fixing command set message
#    dmshah      12/12/02 - fixing displayHelp
#    dmshah      12/11/02 - Renamed from emctl.pl to emctl.pl.template
#    dmshah      12/09/02 - start em is supported
#    dmshah      12/05/02 - Creation
# 

use lib qw(sysman/admin/scripts bin);

use LWP::Simple;
use POSIX ":sys_wait_h";
# use Term::ReadKey; # We need to comment this out until PDC picks up Term 
use LWP::UserAgent;
use HTTP::Response;
use HTML::TokeParser;
use URI;
use English;
use File::stat;
use File::Copy;
use Getopt::Std;

use Secure;

use EmctlCommon;
use IASConsole;
use DBConsole;
use EMAgent;
use EMDeploy;
use POSIX;
use File::Temp qw/ tempfile /;

# setup the environment ...
umask 037;

$|=1; # Set AUTOFLUSH on

# bug fix 2603257
# Check for the euid with the uid obtained from stating this ...
# On Win NT, both $EUID and stat($0) should return 0 and hence this is a noop.
# REMOTE_EMDROOT is populated for NFS installs which usually has the owner of
# state directory different from the owner of the OUI installed EM home dir. 

die "Cannot execute $0 since its userid does not match yours. \n" if (($ENV{REMOTE_EMDROOT} eq "") && ( (stat($0))->uid ne $EUID ));


# get the action, component and argument count ...

$action = $ARGV[0];

$component = $ARGV[1];
if (lc($component) eq "em")
{
  $component = "iasconsole";
}

$argCount = scalar(@ARGV);

if ($ENV{EMSTATE} eq "")
{
    delete($ENV{EMSTATE});
}

# The following deploy block needs to be at the top to avoid a circular
# dependency between deploy actions AND directory presence validation.
if($action eq "deploy")
{
    if (($component eq "agent") or
	($component eq "dbconsole"))
    {
       my $rc = deploy( \@ARGV );
       exit $rc;
    }
    else
    {
	printDeployUsage();
	exit 1;
    }
}

$EM_OC4J_HOME=getOC4JHome($component);
$EMHOME=getEMHome($component);

# Check if omsRecvDir property is set in emd.properties
# used by start/stop/status dbconsole
#
if ($component eq "dbconsole") {
  $OMS_RECV_DIR_SET = isOmsRecvDirSet();
}
else {
  $OMS_RECV_DIR_SET=1; 
}

if ($DEBUG_ENABLED) {
    print ("OMS_RECV_DIR_SET = $OMS_RECV_DIR_SET\n");
}

print "OC4J home for $component is : $EM_OC4J_HOME.\n" if $DEBUG_ENABLED;
print "EM home for $component is : $EMHOME.\n" if $DEBUG_ENABLED;

if (lc($component) eq "iasconsole")
{
  $IAS_URL=getWebUrl($EM_OC4J_HOME, $EMHOME, $component);
}
elsif(lc($component) eq "dbconsole")
{
  $DB_URL=getWebUrl($EM_OC4J_HOME, $EMHOME, $component);
}

print "URL for $component is : $DB_URL |  $IAS_URL \n" if $DEBUG_ENABLED;

# On WinNT, this file records the exitStatus [pseudo] of the child process.
$EXITFILE=$EMHOME."/sysman/log/exitStatus_".lc($component);

banner();                                        # print the banner.

makeBackups();

if ($argCount >= 2 && lc($component) eq "agent") #emctl start/stop/status agent
{
    testCEMDAvail();

    $action = lc($action);
    $component = lc($component);

    if ($action eq "start")
    {
      startCEMD();
    }
    elsif ($action eq "stop")
    {
      stopCEMD();
    }
    elsif ($action eq "status")
    {
      statusCEMD( \@ARGV );
    }
    elsif ($action eq "upload" or $action eq "reload") 
    {
      reloadCEMD( \@ARGV );
    }
    elsif ($action eq "clearstate")
    {
      clearCEMDstate( $action);
    }
    elsif ($action eq "resettz")
    {
      resetTZ();
    }
    elsif ($action eq "secure")
    {
        setupSecure( \@ARGV );
    }
    elsif ($action eq "istatus")
    {
        # This is for internal status that immediately returns a status
        # code for NT SRVC

        exit istatusCEMD();
    }
    elsif ($action eq "istop")
    {
       istopCEMD();
    }
    elsif ($action eq "config")
    {
       configAgent( \@ARGV );
    }
    else 
    {
        displayHelp();
    }
}
elsif ($argCount == 2 && $component eq "subagent" )
{
  if ($action eq "start")
  {
    $found = statusSubAgent();
    if ( $found == 1) {
       print "Sub agent is already running..\n";
       exit 1;
    }
    startSubAgent();
  }
  elsif ($action eq "stop")
  {
    $found = statusSubAgent();
    if ( $found == 0) {
       print "Sub agent is not running..\n";
       exit 1;
    }
    stopSubAgent();
  }
  elsif ($action eq "status" )
  {
    $found = statusSubAgent();
    if ( $found == 0) {
       print "Sub agent is not running..\n";
    }
    else {
       print "Sub agent is running..\n";
    }
  }
}
elsif ($action eq "getemhome")
{
    print "EMHOME=$EMHOME\n";
}
elsif ($action eq "clearstate")
{
  clearCEMDstate( $action);
}
elsif ($action eq "upload" or $action eq "reload") #emctl upload|reload [agent]
{
  reloadCEMD( \@ARGV );
}   #emctl start/stop/status em == StandAlone iASConsole                    
elsif ($argCount >= 2 and (lc($component) eq "em" or lc($component) eq "iasconsole")) 
{
    testSAConsoleAvail();

    $action = lc($action);
    $component = lc($component);

    if($action eq "start")
    {
        startSAConsole();
    }
    elsif(lc($action) eq "startifdown")
    {
        startSAConsole();
    }
    elsif($action eq "stop")
    {
        exit stopSAConsole( \@ARGV );
    }
    elsif($action eq "status")
    {
        statusSAConsole( $component );
    }
    elsif($action eq "secure")
    {
        setupSecure( \@ARGV );
    }
    elsif($action eq "istop")
    {
        istopSAConsole($component);
    }
    elsif($action eq "istatus")
    {
     # Agent returns 3 or 4 for either running or running but not ready
     # While console returns 0 for UP and rest for DOWN.

     # We convert the PROCESS_OK status to return code 3
     my($pstatus) = statusSAConsole_Internal($component, "true");
     if($pstatus == $STATUS_PROCESS_OK or
        $pstatus == $STATUS_PROCESS_PARTIAL)
     {
        exit 3;
     }
     else
     {
        exit 1;
     }
    }
    elsif ($action eq "config")
    {
       configIASConsole( \@ARGV );
    }
    else 
    {
        displayHelp();
    }
}
elsif ($argCount >= 2 and $component eq "dbconsole")
{
  #emctl start/stop/status em == EM with standalone OC4J 
  testSAConsoleAvail();

  $action = lc($action);
  $component = lc($component);

  if($action eq "start")
  {
      startEM_SAConsole();
  }
  elsif($action eq "stop")
  {
      $rc = stopEM_SAConsole( \@ARGV );
      exit $rc;
  }
  elsif($action eq "status")
  {
      statusSAConsole("dbconsole");
  }
  elsif($action eq "secure")
  {
      setupSecure( \@ARGV );
  }
  elsif($action eq "istop")
  {
      istopEM_SAConsole($component);
  }
  elsif($action eq "istatus")
  {
     # Agent returns 3 or 4 for either running or running but not ready
     # While console returns 0 for UP and rest for DOWN.

     # We convert the PROCESS_OK status to return code 3
     my($pstatus) = statusSAConsole_Internal($component, "true");
     if($pstatus == $STATUS_PROCESS_OK or
        $pstatus == $STATUS_PROCESS_PARTIAL)
     {
        exit 3;
     }
     else
     {
        exit 1;
     }
  }
  elsif($action eq "setpasswd")
  {
      setReposPasswd();
  }
  else 
  {
      displayHelp();
  }
}
elsif ($argCount >= 2 and $component eq "oms")
{
    if(0)
    {
      print "emctl start/stop/status/setpasswd oms for database control is obsoleted. \n";
      print "Use emctl start/stop/status/setpasswd dbconsole. \n";
    }
    #emctl start/stop oms == Central Console

    testOMSAvail();

    if($action eq "start")
    {
        startOMS();
    }
    elsif($action eq "stop")
    {
        stopOMS();
    }
    elsif($action eq "status")
    {
        statusOMS();
    }
    elsif($action eq "secure")
    {
        setupSecure( \@ARGV );
    }
    elsif($action eq "config")
    {
        configOMS( \@ARGV );
    }
    elsif($action eq "setpasswd")
    {
        setReposPasswd();
    }
    else 
    {
        displayHelp();
    }
}                                     #emctl stop/start/status blackout
elsif ($argCount >= 2 and $component eq "blackout") 
{
    if ($action eq "start" or $action eq "stop")
    {
          if ( $argCount == 2)
          {  
             displayHelp();
          }
          else
          {
             blackoutCEMD( \@ARGV );
          }
    }
    elsif ($action eq "status")
    {
          blackoutCEMD( \@ARGV );
    }
    else
    {
        displayHelpBlackout();
    }
}
elsif ($argCount > 0 and $action eq "secure")     #emctl secure [args]
{
  setupSecure( \@ARGV );
}
elsif ($argCount > 0 and $action eq "config")   #emctl config console | agent
{
  configAgent( \@ARGV );
}
elsif ($argCount > 0 and $action eq "set" and $component eq "credentials")
{
  shift (@ARGV);
  $action = "config";
  $component = "agent";
  @args = ($action, $component, @ARGV);
  configAgent( \@args );
}
elsif ($argCount > 0 and $action eq "config")   #emctl config console | agent
{
  configAgent( \@ARGV );
}
elsif ($argCount > 0 and $action eq "ilint")   #emctl ilint
{
  runILINT( \@ARGV );
}                                            #emctl set password [ias903 cmd set]
elsif ($argCount == 4 and $action eq "set" and $component eq "password") 
{
    setPassword( \@ARGV );   
}                                      #emctl authenticate [ias903 cmd set]
elsif ($argCount == 2 and $action eq "authenticate") 
{
   authenticate( \@ARGV );
}                                        #emctl set ssl action comp [ias903]
elsif ($argCount == 4 and $action eq "set" and $component eq "ssl")
{
    setSASSL( \@ARGV );
}                                        #emctl set ssl action [ias903 cmd set]
elsif ($argCount == 3 and $action eq "set" and $component eq "ssl") 
{ 
    @args = ($action, $component, $ARGV[2], "both");
    setSASSL( \@args );
}
elsif ($argCount == 1 and $action eq "blackout")
{
    displayHelpBlackout();
}
else 
{
    displayHelp();
}


# subroutine to display banner
sub banner
{
  my( $banner_add ) = "";
  if( $CFS_RAC )
  {
    $banner_add = "CFS-RAC Configuration.";
  }
  
  if($IN_VOB eq "TRUE")
  {
     print "Oracle Enterprise Manager 10g Release ".$ENV{EMPRODVER}." ".$banner_add." \n";
  }
  elsif( $INSTALL_TYPE_IAS )
  {
     print "Oracle 10g Application Server Control 10.1.2.0.0 ".$banner_add." \n";
  }
  elsif( $INSTALL_TYPE_AGENT or $INSTALL_TYPE_CENTRAL )
  {
     print "Oracle Enterprise Manager 10g Release ".$ENV{EMPRODVER}." ".$banner_add." \n";
  }
  elsif( $INSTALL_TYPE_DB )
  {
     print "Oracle Enterprise Manager 10g Database Control Release ".$ENV{EMPRODVER}." ".$banner_add." \n";
  }
  print "Copyright (c) 1996, 2005 Oracle Corporation.  All rights reserved.\n";
  print "$DB_URL\n" if ($INSTALL_TYPE_DB and defined($DB_URL));
  print "$IAS_URL \n" if ($INSTALL_TYPE_IAS and defined($IAS_URL));

  if($DEBUG_ENABLED)
  {
    print "NOHUP Files are $AGENT_NOHUPFILE | $DB_NOHUPFILE | $IAS_NOHUPFILE \n";
    print "PID File is $PID_FILE \n";
  }
}

# subroutine to display footer
sub footer
{
  print "------------------------------------------------------------------\n";
  print "Logs are generated in directory $EMHOME/sysman/log \n";
}

sub printOMSCmd
{
  if($INSTALL_TYPE_CENTRAL)
  {
    print "   Oracle Enterprise Manager 10g Grid Control commands:\n";
    print "       emctl start| stop| status| setpasswd oms\n";
    print "       emctl secure <options>\n";
    print "       emctl config oms sso -host ssoHost -port ssoPort -sid ssoSid -pass ssoPassword -das dasURL\n";
    print "\n";
  }
}

sub printAgentCmd
{
  if( $INSTALL_TYPE_AGENT or $INSTALL_TYPE_CENTRAL )
  {
    print "   Oracle Enterprise Manager 10g Agent commands:\n";
    print "       emctl start| stop| status agent\n";
    print "       emctl start| stop| status subagent\n";
    print "\n";
    print "       emctl reload | upload | clearstate\n"; 
    print "       emctl reload agent dynamicproperties [<Target_name>:<Target_Type>]....\n"; 
    print "       emctl config agent <options>\n";
    print "       emctl config agent updateTZ\n";
    print "       emctl config agent getTZ\n";
    print "       emctl resetTZ agent\n";
    print "       emctl config agent credentials [<Target_name>[:<Target_Type>]]\n";
    print "       emctl config agent port [portNumber]\n";
    print "       emctl secure <options>\n";
    print "       emctl start| stop| status blackout <options>\n";
    print "       emctl getemhome\n";
    print "\n";
  }
}

sub printIASCmd
{
  if($INSTALL_TYPE_CENTRAL or $INSTALL_TYPE_IAS)
  {
    print "   Oracle 10g Application Server Control commands:\n";
    print "       emctl start| stop| status iasconsole \n";
    print "       emctl set password <old ias_admin password> <new ias_admin password>\n";
    print "       emctl secure em\n";
    print "       emctl config agent credentials [<Target_name>[:<Target_Type>]]\n";
    print "       emctl config iasconsole port [portNumber]\n";
    print "       emctl config iasconsole rmiport [portNumber]\n";
    print "\n";
  }
}

sub printDBCmd
{
  if($INSTALL_TYPE_CENTRAL or $INSTALL_TYPE_DB)
  {
    print "   Oracle Enterprise Manager 10g Database Control commands:\n";
    print "       emctl start| stop| status| setpasswd dbconsole\n";
    print "       emctl secure <options>\n";
    print "\n";
  }
}

sub printDeployUsage
{
  if($IS_WINDOWS eq "TRUE")
  {
    print <<DEPLOYUSAGE
     
    Deploy has two options :

	emctl deploy agent [-n <NTServiceName>] [-u <NTServiceUsername>] [-p <NTServicePassword>] [-s <install-password>] <deploy-dir> <deploy-hostname>:<port> <source-hostname>
	
	emctl deploy dbconsole [-n <NTServiceName>] [-u <NTServiceUsername>] [-p <NTServicePassword>] [-s <install-password>] <deploy-dir> <deploy-hostname>:<port> <source-hostname> <sid>

      [agent|dbconsole] : 
	  'agent' creates and deploys only the agent.
	  'dbconsole' creates and deploys both the agent and the dbconsole.
      [-s <password>]:
	  Install password for securing agent.
      [-n <NTServiceName>]:
	  The name of the Windows Service to create for the deployment. If
	  not specified no service is created.
      [-u <NTServiceUsername>]:
      [-p <NTServicePassword>]:
	  Credentials of the Windows Service. The deployed agent/dbconsole 
	  will run with these credentials.
      <deploy-dir> : 
	  Directory to create the shared(state-only) installation
      <deploy-hostname:port> : 
	  Hostname and port of the shared(state-only) installation. 
	  Choose unused port.
      <source-hostname> : 
	  The hostname of the source install. 
	  Typically the machine where EM is installed. This is searched and 
	  replaced in targets.xml by the hostname provided in 
	  argument <deploy-hostname:port>.
      <sid> : 
	  The instance of the remote database. Only specified when
	  deploying "dbconsole".

DEPLOYUSAGE
}
else
{
    print <<DEPLOYUSAGE

    Deploy has two options:

	emctl deploy agent [-s <install-password>] <deploy-dir> <deploy-hostname>:<port> <source-hostname>

	emctl deploy dbconsole [-s <install-password>] <deploy-dir> <deploy-hostname>:<port> <source-hostname> <sid>

      [agent|dbconsole] : 
	  'agent' creates and deploys only the agent.
	  'dbconsole' creates and deploys both the agent and the dbconsole.
      [-s <password>]:
	  Install password for securing agent.
      <deploy-dir> : 
	  Directory to create the shared(state-only) installation
      <deploy-hostname:port> : 
	  Hostname and port of the shared(state-only) installation. 
	  Choose unused port.
      <source-hostname> : 
	  The hostname of the source install. 
	  Typically the machine where EM is installed. This is searched and 
	  replaced in targets.xml by the hostname provided in 
	  argument <deploy-hostname:port>.
      <sid> : 
	  The instance of the remote database. Only specified when
	  deploying "dbconsole".

DEPLOYUSAGE
}
    
}


# subroutine to display help

sub displayHelp
{ 
    print "Invalid arguments\n";
    print "\nUnknown command option $action\n"; 
    print "Usage:: \n";
    printIASCmd() unless (0) ;
    printDBCmd();
    printOMSCmd();
    printAgentCmd();

  if( $INSTALL_TYPE_AGENT or $INSTALL_TYPE_CENTRAL or $INSTALL_TYPE_DB)
  {
    print "       emctl set ssl test|off|on em\n"; 
    print "       emctl set ldap <host> <port> <user dn> <user pwd> <context dn>\n"; 
    print "emctl blackout options can be listed by typing \"emctl blackout\"\n";
    print "emctl config options can be listed by typing \"emctl config\"\n";
    print "emctl secure options can be listed by typing \"emctl secure\"\n";
    print "emctl ilint  options can be listed by typing \"emctl ilint\"\n";
    print "emctl deploy  options can be listed by typing \"emctl deploy\"\n";
  }
}

# subrouting to display blackout help ...
sub displayHelpBlackout
{
    print " Usage : \n";
    print "       emctl start blackout <Blackoutname> [-nodeLevel] [<Target_name>[:<Target_Type>]].... [-d <Duration>]\n";
    print "       emctl stop blackout <Blackoutname>\n";
    print "       emctl status blackout [<Target_name>[:<Target_Type>]]....\n\n"; 
    print "The following are valid options for blackouts\n"; 
    print "<Target_name:Target_type> defaults to local node target if not specified.\n";
    print "If -nodeLevel is specified after <Blackoutname>,the blackout will be applied to all targets";
   print " and any target list that follows will be ignored.\n ";
    print "Duration is specified in [days] hh:mm\n"; 
    print "\n";
}

#
# Sub routine to test the availibility of CEMD
#
sub testCEMDAvail
{
    if (not (-e "$EMDROOT/bin/emdctl"."$binExt" || -e "$EMDROOT/bin/emagent"."$binExt"))
    {
        die "Missing either emdctl or emagent from $EMDROOT/bin.\n";
    }
}


# 
# Sub routine to start the CEMD
#
sub startCEMD
{
    my ($returnCode) = 1;

    if( $IS_WINDOWS eq "TRUE" ) 
    {
       $returnCode =  system("$ENV{WINDIR}\\system32\\net.exe start $ENV{AGENT_SERVICE_NAME}");
       $returnCode >>= 8;
       exit $returnCode ;
    }

    if( $OSNAME eq "linux") {

      ($rc,$emdPropFile,$agentTZRegion,$envTZRegion) = checkAgentTZSync();

      if($rc == 1) {

       print("\nTimezone mismatch: The agentTZRegion value ($agentTZRegion) in\n $emdPropFile\ndoes not match the current environment TZ setting($ENV{TZ}).\nThe agent cannot run with this mismatch.\n\nIf $agentTZRegion is the correct timezone, set your timezone environment variable to $agentTZRegion and repeat the 'emctl start agent' operation.\n\nIf $agentTZRegion is not the correct timezone, make sure that the timezone in your environment is correct, and then run the following command in your local Oracle Home: 'emctl resetTZ agent'\n\nThe output of this command will include detailed instructions to follow, to correct the mismatch.\n\n");

	exit 1;
      }
    }


    $returnCode = 0;

    local $curdir=`pwd`;      # get the current directory
    chomp($curdir);           # remove trailing spaces

    chdir("$EMHOME/sysman/emd");

    my($rc) = 0xffff & system("$EMDROOT/bin/emdctl status agent >$devNull 2>&1");
    $rc >>= 8;

    if ( $rc < 2 )
    {
      # Start the agent and wait for 30 secs
      print "Starting agent ...";
      
      $CHILD_PROCESS = fork();

      #
      # If IS_WINDOWS then we need to use win32 perl libraries to fork/exec
      #
      if( $CHILD_PROCESS == 0 )
      {
          # Need to close the STD handles
          close(STDIN);
          close(STDOUT);
          close(STDERR);

          # Assume the process group leadership...
          setpgrp(0, 0);

          # Exec the emwd process ...
          exec("$PERL_BIN/perl $EMDROOT/bin/emwd.pl agent " .
               " $AGENT_NOHUPFILE ");
          exit 0;
      }
      else 
      {
        local $tries=30;
      
        while( $tries > 0 )
        {
            sleep 1;

            $rc = 0xffff & system("$EMDROOT/bin/emdctl status agent >$devNull 2>&1");
            $rc >>= 8;

            if ($rc == 3)
            {
                last; 
            }
            $tries = $tries-1;
            print ".";
        }

        # print appropriate started or failed error message.
        if( $rc == 3 ) 
        { 
            print " started.\n"; 
            $returnCode = 0;
        }
        elsif ( $rc == 4 ) 
        { 
            print " started but not ready. \n"; 
            $returnCode = 0;
        } 
        else 
        { 
            print " failed.\n"; 
            $returnCode = 1;
        }
      }
    }
    else
    {
        print "Agent is already running\n";
        $returnCode = 0;
    }

    chdir("$curdir");

    exit $returnCode;
}


# 
# Sub routine to stop the CEMD
#
sub stopCEMD
{
    #If the install type is *not* AGENT
    unless($INSTALL_TYPE_AGENT)
    {
      # Check to see if iasconsole is up...
      # Call getEMHome to set the right value for PID_FILE which is used
      # in statusSAConsole_Internal method
      $EMHOME = getEMHome($CONSOLE_CFG); 
      my($consoleStatus) = statusSAConsole_Internal($CONSOLE_CFG, "false");
      if($consoleStatus == $STATUS_PROCESS_OK or
         $consoleStatus == $STATUS_PROCESS_PARTIAL)
      {
         my ($consoleBanner) = "Oracle 10g Application Server Control";
         if( $CONSOLE_CFG eq "dbconsole") 
         {
           $consoleBanner = "Oracle Enterprise Manager 10g Database Control";
         }

         print "This will stop the $consoleBanner process. Continue [y/n] :";
         $continue=<STDIN>;
         chomp ($continue);

         if($continue eq "n" or $continue eq "N")
         {
           exit 1;
         }

         my ($returnValue) = -1;
         if( $CONSOLE_CFG eq "dbconsole") 
         {
           $returnValue = stopEM_SAConsole();
         }
         else
         {
           $returnValue = stopSAConsole();
         }

         if ($returnValue ne 0)
         {
           # This may be due to invalid password...
           print "unable to stop $consoleBanner.\n";
           exit 1;
         }
      }

      # Reset values for agent
      $EMHOME = getEMHome("agent");
    }

    if( $IS_WINDOWS eq "TRUE" )
    {
       $returnCode =  system("$ENV{WINDIR}\\system32\\net.exe stop $ENV{AGENT_SERVICE_NAME}");
       $returnCode >>= 8;
       exit $returnCode;
    }

    # Now call the code to stop the agent ...
    return istopCEMD();
}

#
# Issues the stop for CEMD and active waits 30 secs
# to check wether the agent was stopped or not.
#
sub istopCEMD
{
    my($rc) = istatusCEMD();
    if ( $rc != 3 and $rc != 4 )
    {
        print "Agent is not running.\n";
    }
    else
    {
        print "Stopping agent ...";

        if($IS_WINDOWS eq "TRUE")
        {
          open(EXITSTATUS, ">$EXITFILE");
          print {EXITSTATUS} "0";
          close(EXITSTATUS);
        }

        system("$EMDROOT/bin/emdctl stop agent >$devNull 2>&1");
        local $tries=30;
      
        my($rc);
        while( $tries > 0 )
        {
           sleep 1;

           $rc = istatusCEMD();
           if ($rc < 2)
           {
              last; 
           }
           $tries = $tries-1;
           print ".";
        }

        # print appropriate started or failed error message.
        if( $rc < 2 ) 
        { 
          print " stopped.\n"; 
          return 0;
        }
        else 
        { 
          print " failed.\n"; 
          return 1;
        }
    }
 
    return 0;
}

#
# subroutine to status the cemd [internal]
# Suppresses the status agent output by redirecting it to /dev/Null
#
sub istatusCEMD
{
  my($status) = 0xffff & system("$EMDROOT/bin/emdctl status agent >$devNull 2>&1");
  $status >>= 8;

  return $status;
}

#
# subroutine to status the cemd
#
sub statusCEMD
{
  local (*args) = @_;
  shift(@args); # -- shift out "status"
  shift(@args); # -- shift out "agent"

    print "---------------------------------------------------------------\n";
    $rc = 0xffff & system("$EMDROOT/bin/emdctl status agent @args 2> $devNull ");
    $rc >>= 8;

    if( $rc == 3 ) 
    { 
      print "---------------------------------------------------------------\n";
      print "Agent is Running and Ready\n"; 
      $rc = 0;
    }
    elsif( $rc == 4 ) 
    { 
      print "---------------------------------------------------------------\n";
      print "Agent is Running but Not Ready\n"; 
      $rc = 0;
    }
    else 
    { 
      print "Agent is Not Running\n"; 
    }

    exit $rc;
}

# 
# sub reload agent
# takes
# 1) $action which is expected to be either reload or upload
#
sub reloadCEMD
{
  local (*args) = @_;

  testCEMDAvail();
  if($IS_WINDOWS eq "TRUE") 
  {
    ;
  } 
  else
  {
    $ENV{PATH}="";
  }

  if ($EMDROOT =~ /(.*)/) {
      $EMDROOT = $1;
  }

    $rc = 0xffff & system("$EMDROOT/bin/emdctl status agent >$devNull 2>&1");
    $rc >>= 8;

    if ($rc < 2) 
    { 
      print "Agent is Not Running\n"; 
      if($action eq "reload")
      {
	  system("$EMDROOT/bin/emdctl encrypt");
          # make backup of targets.xml (we save up to 10 versions)
          if (-e "$EMDROOT/sysman/emd/targets.xml")
          {
            rotateFile("$EMDROOT/sysman/emd/targets.xml", 10);
          }
	  exit 0;
      }
      exit -1;
    }

  my @newargs;
  foreach $my_arg (@args)
  {
      $my_arg =~ /(.*)/;
      push(@newargs, $1);
  }

    $rc = 0xffff & system("$EMDROOT/bin/emdctl @newargs");
    $rc >>= 8;

    # make backup of targets.xml (we save up to 10 versions)
    if (-e "$EMDROOT/sysman/emd/targets.xml")
    {
      rotateFile("$EMDROOT/sysman/emd/targets.xml", 10);
    }

    exit $rc;
}

# 
# sub clearstate agent
# takes
# 1) $action which is expected to be clearstate
#
sub clearCEMDstate
{
    local ($clearState) = @_;

    $rc = 0xffff & system("$EMDROOT/bin/emdctl $clearState");
    $rc >>= 8;
    exit $rc;
}

#
# blackout agent
# takes
# 1) Array of arguments
#
sub blackoutCEMD
{
    local (*args) = @_;

    testCEMDAvail();

    $rc = 0xffff & system("$EMDROOT/bin/emdctl @args");
    $rc >>= 8;
    exit $rc;
}

#
# Subroutine to check if the existing DB Console is running
#
sub checkEM_SAConsole
{
    if ( -e "$PID_FILE" )
    {
       my($PID);
       open(PIDFILE, "<$PID_FILE");
       while(<PIDFILE>)
       {
         $PID = $_;
       }
       close(PIDFILE);

       chomp($PID);
       if( $PID ne undef )
       {
         if( $IS_WINDOWS eq "TRUE" )
         {
           if( (kill 0, $PID) ) 
           {
             print " - An instance of Oracle Enterprise Manager 10g Database Control is already running. \n";
  	     exit 1;
           }
         }
         else
         {
           # for unix, we could have a old PID file laying around pointing to some randome process
           # this could happen if you reboot abruptly, emctl didn't have time to delete the PID file
           # check and make sure this process is really a dbcontrol process
           my $ps=`ps -p $PID -o cmd --cols 1000 |grep DEMDROOT`; 
           if( $ps ne "" ) 
           {
             print " - An instance of Oracle Enterprise Manager 10g Database Control is already running. \n";
  	     exit 1;
           }
         }
       }

       unlink("$PID_FILE");
       unlink("$EMDROOT/bin/emctl_sa.msg");
    }
}

#
# start EM_SAConsole
# This starts up the EM_SAConsole [or the StandaloneConsole]
#
sub startEM_SAConsole
{
    # Check wether the DB Console is running or not
    checkEM_SAConsole();

    # If the agent is running separately... restart the agent.
    checkAndStopCEMD();

    if( $OSNAME eq "linux") {

      ($rc,$emdPropFile,$agentTZRegion,$envTZRegion) = checkAgentTZSync();

      if($rc == 1) {

       print("\nTimezone mismatch: The agentTZRegion value ($agentTZRegion) in\n $emdPropFile\ndoes not match the current environment TZ setting($ENV{TZ}).\nThe dbconsole cannot run with this mismatch.\n\nIf $agentTZRegion is the correct timezone, set your timezone environment variable to $agentTZRegion and repeat the 'emctl start dbconsole' operation.\n\nIf $agentTZRegion is not the correct timezone, make sure that the timezone in your environment is correct, and then run the following command in your local Oracle Home: 'emctl resetTZ agent'\n\nThe output of this command will include detailed instructions to follow, to correct the mismatch.\n\n");

	exit 1;
      }
    }

    print "Starting Oracle Enterprise Manager 10g Database Control ...";

    if($IS_WINDOWS eq "TRUE")
    {
       $returnCode =  system("$ENV{WINDIR}\\system32\\net.exe start $ENV{DBCONSOLE_SERVICE_NAME}");
       $returnCode >>= 8;
       exit $returnCode;
    }
    else
    {
       $CHILD_PROCESS = fork();
    }

    #
    # If IS_WINDOWS then we need to use win32 perl libraries to fork/exec
    #
    if( $CHILD_PROCESS == 0 )
    {
        # Need to close the STD handles
        close(STDIN);
        close(STDOUT);
        close(STDERR);

        # Assume the process group leadership...
        setpgrp(0, 0);

        # Exec the emwd process ...
        exec("$PERL_BIN/perl $EMDROOT/bin/emwd.pl dbconsole ".
             " $DB_NOHUPFILE ");
        exit 0; # In case it returns we do not fall back into the parent..
    }
    else
    {
      my ($consoleTries, $rc) = (90, 99);
     
      sleep 4; # sleep for 4 secs to give the emwd a chance ...

      while( $consoleTries > 0 )
      { 
         print ".";

         $rc = statusSAConsole_Internal("dbconsole", "true");

         # print appropriate started or failed error message.
         if($rc == $STATUS_PROCESS_OK)
         {
            $consoleTries = 0;
            last;
         }

         $consoleTries--;
         sleep 2;
      }

      if( $rc == $STATUS_PROCESS_OK )
      {
         print " started. \n";
         footer();
         exit 0;
      }

      print " failed. \n";
      footer();
      exit 1;
    }
}

#
# stop EM_SAConsole
# This stops the EM_SAConsole [or the Standalone Console]
# 1) argument list
#
sub stopEM_SAConsole
{
    local (*args) = @_;

    if($IS_WINDOWS eq "TRUE")
    {
       $returnCode = system("$ENV{WINDIR}\\system32\\net.exe stop $ENV{DBCONSOLE_SERVICE_NAME}");
       $returnCode >>= 8;
       exit $returnCode;
    }

    return istopEM_SAConsole();
}

#
# This is the internal subroutine to stop the SAC
#
# if OMS_RECV_DIR_SET=1, OMS+agent will be stopped
#                    =0, agent only will be stopped
#
sub istopEM_SAConsole
{
    local (*args) = @_;

    if($IS_WINDOWS eq "TRUE")
    {
      open(EXITSTATUS, ">$EXITFILE");
      print {EXITSTATUS} "0";
      close(EXITSTATUS);
      $ENV{EM_ADMIN_PWD} = "mozart";
    }

    print "Stopping Oracle Enterprise Manager 10g Database Control ... \n";

    if ($OMS_RECV_DIR_SET) {
        my($pid) = 999999;
        
        if ( -e "$PID_FILE" )
        {
            open(PIDFILE, "<$PID_FILE");
            while(<PIDFILE>)
            {
                $pid = $_;
            }
            close(PIDFILE);
            chomp($pid);
            if( ($pid eq undef) or ($pid eq "") )
            {
                print "\n Cannot determine Oracle Enterprise Manager 10g Database Control process from ".$PID_FILE." \n";
                return 0;
            }
        }
        else
        {
            print "\n Cannot determine Oracle Enterprise Manager 10g Database Control process. ".$PID_FILE." does not exist. \n";
            return 0;
        }
        
        $tries = 30;
        
        my $dbConsole = new DBConsole();
        $dbConsole->Initialize($pid, time(), $DEBUG_ENABLED);
        $rc = $dbConsole->stop("random"); 
        
        if($rc != 0)
        {
            # The failure may be due to invalid password...
            print " failed.\n";
            return $rc;
        }
        else
        {
            unlink ("$PID_FILE");
            
            if( $IN_VOB eq "TRUE")
            {
                print " Stopped. \n";
                
                return $rc;
            }
        }
    }

    # Keep the user interest busy ...
    print " ... ";
    
    # Now we stop the agent...
    my $emAgent = new EMAgent();
    $emAgent->Initialize($pid, time(), $DEBUG_ENABLED);
    $rc = $emAgent->stop($tries); 
    
    if( $rc < 2 )
    { 
        $rc = 0;
        print " Stopped. \n";
    }
    else
    {
        print " Failed. \n";
    }      

    return $rc;
}

#
# restartDBCConsole
# 1) argument list
#

sub restartEM_SAConsole
{
    local (*args) = @_;

    ($EM_ADMIN_PWD, $EM_ADMIN_PORT) = util_getPort_sa( \@args );

    $rmiPort = getORMIPort($EM_OC4J_HOME);
 
    $rc = 0xffff & system("$JAVA_HOME/bin/java -jar $ORACLE_HOME/oc4j/j2ee/home/admin.jar ormi://localhost:$rmiPort admin $EM_ADMIN_PWD -restart");

    $rc >>= 8;
    exit $rc;
}

sub checkAndStopCEMD
{
  unless($INSTALL_TYPE_AGENT)
  {
   if($IN_VOB ne "TRUE")
   {
    # Check wether agent is running first and if it is
    # running then stop it.
    my($rc) = 0xffff & system("$EMDROOT/bin/emdctl status agent 2> $devNull ");
    $rc >>= 8;
    if( $rc == 3 or $rc == 4 )
    {
      # Indicates Agent is started.
      print "Agent is already started. Will restart the agent \n";
      stopCEMD();
    }
   }
  }
}


sub checkAgentTZSync
{
  my($emdPropFile,$tzRegion,$EMDPROP,$propValue,$propName,$emdPropLine,$remain);
  my $rc = 0;
  my $envTZRegion = "";
  $tzRegion="";

  $emdPropFile="$EMHOME/sysman/config/emd.properties";
  #print "DEBUG emdPropFile = $emdPropFile\n";

  if (not (-e "$emdPropFile"))
  {
    print STDERR "Required configuration file $emdPropFile is not found \n";
    return (-1,"","","");
  }

  open(EMDPROP,"< $emdPropFile" ) or die "Fatal error can not open:$emdPropFile to look for the property  'agentTZRegion': $!";

  while ($emdPropLine=<EMDPROP>) {
    chomp($emdPropLine);
    #strip all leading  white space characters.
    $emdPropLine =~ s/^\s*//;

    if( ($emdPropLine =~ /^\#/ ) || ( length($emdPropLine) <= 0 ) ) {
    #print "discarding  \"$emdPropLine\" ,since it is a comment \n";
       next;
    }
    ($propName, $propValue , $remain) = split(/\=/ , $emdPropLine , 3);
    #remove leading and trailing white space.
    $propName =~ s/\s*$//;
    $propValue =~ s/^\s*//;
    $propValue =~ s/\s*$//;
    $lengthPropName = length($propName);
    $lengthPropValue = length($propValue);
    if ( ($lengthPropName) > 0  && ($lengthPropValue > 0 ))
    {
       if ( $propName eq "agentTZRegion" )  
       {
         $tzRegion=$propValue;
	 last ;
       }
    }
  } 
  close(EMDPROP);

  if(length ($tzRegion) <= 0 )
  {
    # TZ region not present is not an error as it will get populated by emwd.pl
    return (0,"","","");
  }

  #Validating the tzRegion obtained from emd.properties to that present in the
  #environment

  $rc = validateTZAgainstAgent($tzRegion);
  if ( $rc != 0 )
  {
    return (1,$emdPropFile,$tzRegion,$envTZRegion);
  }


  return 0;
  
}

#
# Tests for OMS (Central Console) availibility
#
sub testOMSAvail
{
  die "Oracle Enterprise Manager 10g Grid Control not installed. Request Ignored.\n" unless ($INSTALL_TYPE_CENTRAL);
}

#
# Tests for SAConsole Availibility
#
#
sub testSAConsoleAvail
{
   die "Agent Only Install. Request Ignored.\n" unless ($INSTALL_TYPE_IAS or $INSTALL_TYPE_CENTRAL or $INSTALL_TYPE_DB);
}

#
# Subroutine to check if the existing SA Console is running
#
sub checkSAConsole
{
    if ( -e "$PID_FILE" )
    {
       my($PID);
       open(PIDFILE, "<$PID_FILE");
       while(<PIDFILE>)
       {
         $PID = $_;
       }
       close(PIDFILE);


       chomp($PID);
       if( $PID ne undef )
       {
         if( $IS_WINDOWS eq "TRUE" )
         {
           if( (kill 0, $PID) ) 
           {
             print "- An instance of Oracle 10g Application Server Control is already running.\n";
             exit 1;
           }
         }
         else
         {
           # for unix, we could have a old PID file laying around pointing to some randome process
           # this could happen if you reboot abruptly, emctl didn't have time to delete the PID file
           # check and make sure this process is really a dbcontrol process
           my $ps=`ps -p $PID -o cmd --cols 1000 |grep DEMDROOT`; 
           if( $ps ne "" ) 
           {
             print " - An instance of Oracle Enterprise Manager 10g Database Control is already running. \n";
  	     exit 1;
           }
         }
       }

       # Unlink is perl function so non-OSD
       unlink ("$PID_FILE");
       
       # No idea what emctl.msg does ...
       unlink ("$EMDROOT/bin/emctl.msg");

    }
}

#
# configIASConsole allows for modifying the HTTP listen port or 
# RMI port for the AS Control OC4J instance
#
sub configIASConsole
{
  local (*args) = @_;
  shift(@args);                  # -- shift out config...

  if ($args[1] eq "port" or $args[1] eq "rmiport") #emctl config iasconsole [rmi]port
  {
    $rc = statusSAConsole_Internal("iasconsole", "false");
    # check if console is up, stop if so
    if ( $rc == $STATUS_PROCESS_OK or $rc == $STATUS_PROCESS_PARTIAL )
    {
      print "You must stop Oracle10g Application Server Control before changing port values.\n";
      exit 1;
    }
    # Now we update the agent port information
    my $iasConsole = new IASConsole();
    $iasConsole->Initialize($pid, time(), $DEBUG_ENABLED);
    $rc = $iasConsole->updatePort($args[1], $args[2]); 
    exit $rc;
  }
}

#
# start iASConsole
# This starts up the iASConsole [or the StandaloneConsole]
#
sub startSAConsole
{
    my $delayStatusCheck = 5;

    # Check whether the SA Console is running or not
    checkSAConsole();

    # If the agent is running separately... restart the agent.
    checkAndStopCEMD();

    print "Starting Oracle 10g Application Server Control ...";

    if($IS_WINDOWS eq "TRUE")
    {
       $returnCode =  system("$ENV{WINDIR}\\system32\\net.exe start $ENV{SAC_SERVICE_NAME}");
       $returnCode >>= 8;
       exit $returnCode;
    }
    else
    {
       $CHILD_PROCESS = fork();
    }

    #
    # If IS_WINDOWS then we need to use win32 perl libraries to fork/exec
    #
    if( $CHILD_PROCESS == 0 )
    {
        # Need to close the STD handles
        close(STDIN);
        close(STDOUT);
        close(STDERR);

        # Assume the process group leadership...
        setpgrp(0, 0);

        # Exec the emwd process ...
        exec("$PERL_BIN/perl $EMDROOT/bin/emwd.pl iasconsole ".
             " $IAS_NOHUPFILE ");
        exit 0; # In case it returns we do not fall back into the parent..
    }
    else
    {
      if ($IN_VOB eq "TRUE")
      {
        $delayStatusCheck = 20;
      }
      sleep $delayStatusCheck; # sleep for a bit to give the emwd a chance ...

      my ($waitCycles, $logUpdate) = (5, 0);

      while ($waitCycles > 0)
      {
        # wait for response
        $rc = waitForSAConsole();

        if( $rc == $STATUS_PROCESS_OK )
        {
            print " started successfully. \n";
            exit 0;
        }
        $waitCycles--;
        print "\n No response, checking logs for initialization activity.\n";

        # check diff from last log update
        $logUpdate = checkSAConsoleLogActivity() - $logUpdate;
        if ($logUpdate == 0)
        {
            last;
        }
        else
        {
            print "waiting for response from console ";
        }
      }
      print " Console startup";
      if ($logUpdate > 0)
      {
          print " continuing, check files in $IAS_LOGDIR for progress.\n";
          exit 0;
      }
      else
      {
          print " failed to start. \n";
          exit 1;
      }
    }
}

#
# wait 1 minute for iAS console response
#
sub waitForSAConsole
{
    # 12 console tries * 5 seconds wait per = 1 minute
    my $delayStatusCheck = 5;
    my $statusCheckRetries = 12;

    # in VOB, wait more... triage failures otherwise
    # 24 tries * 10 seconds = 4 minutes
    if ($IN_VOB eq "TRUE")
    {
      $delayStatusCheck = 10;
      $statusCheckRetries = 24;
    }

    my ($consoleTries, $rc) = ($statusCheckRetries, 99);
     
    while( $consoleTries > 0 )
    { 
       print ".";

       $rc = statusSAConsole_Internal("iasconsole", "true");

       # print appropriate started or failed error message.
       if( $rc == $STATUS_PROCESS_OK )
       {
          $consoleTries = 0;
          last;
       }

       $consoleTries--;
       sleep $delayStatusCheck;
    }
    return $rc;
}


#
# stat the relevant logs in IAS_LOGDIR and return the last mod time
#
sub checkSAConsoleLogActivity
{
    my ($sb);
    my ($logFile, $lastMtime) = ("", 0);

    $logFile = "$IAS_LOGDIR/server.log";
    if (-e $logFile)
    {
      $sb = stat($logFile);
      $lastMtime = ( $sb->mtime > $lastMtime ) ? $sb->mtime : $lastMtime;
    }
    $logFile = "$IAS_LOGDIR/rmi.log";
    if (-e $logFile)
    {
      $sb = stat($logFile);
      $lastMtime = ( $sb->mtime > $lastMtime ) ? $sb->mtime : $lastMtime;
    }
    $logFile = "$IAS_LOGDIR/em-application.log";
    if (-e $logFile)
    {
      $sb = stat($logFile);
      $lastMtime = ( $sb->mtime > $lastMtime ) ? $sb->mtime : $lastMtime;
    }
    $logFile = "$IAS_LOGDIR/emias.log";
    if (-e $logFile)
    {
      $sb = stat($logFile);
      $lastMtime = ( $sb->mtime > $lastMtime ) ? $sb->mtime : $lastMtime;
    }
    return $lastMtime;
}



#
# stop iASConsole
# This stops the iASConsole and the agent associated with it
# 1) argument list
#
sub stopSAConsole
{
    local (*args) = @_;

    if($IS_WINDOWS eq "TRUE")
    {
       $returnCode =  system("$ENV{WINDIR}\\system32\\net.exe stop $ENV{SAC_SERVICE_NAME}");
       $returnCode >>= 8;
       exit $returnCode;
    }

    return istopSAConsole(\@args);
}

#
# This is the internal subroutine to stop the SAC
#
sub istopSAConsole
{
    local (*args) = @_;

    if($IS_WINDOWS eq "TRUE")
    {
      open(EXITSTATUS, ">$EXITFILE");
      print {EXITSTATUS} "0";
      close(EXITSTATUS);
      $ENV{EM_ADMIN_PWD} = "mozart"; # Hardcoding the password on NT...
                                     # svc registry can call this function.
    }

    print "\nStopping Oracle 10g Application Server Control ... ";

    my($pid) = "";

    if ( -e "$PID_FILE" )
    {
     open(PIDFILE, "<$PID_FILE");
     while(<PIDFILE>)
     {
       $pid = $_;
     }
     close(PIDFILE);
     chomp($pid);
 
     if( ($pid eq undef) or ($pid eq "") )
     {
       print "\n Cannot determine Oracle 10g Application Server Control process.";
       return 0;
     }
    }
    else
    {
       print "\n Cannot determine Oracle 10g Application Server Control process; ".
             $PID_FILE." does not exist.\nOracle 10g Application Server Control may not be running.\n";
       return 0;
    }
 
    $tries = 30;
    
    $iasConsole = new IASConsole();
    $iasConsole->Initialize($pid, time(), $DEBUG_ENABLED);
    $rc = $iasConsole->stop("random");
    
    if($rc != 0)
    {
       # The failure may be due to invalid password...
       print " failed.\n";
    }
    else
    {
       # Unlink is perl function 
       unlink ("$PID_FILE");

       if( $IN_VOB eq "TRUE")
       {
           print " Stopped. \n";
           return $rc;
       }
       # Keep the user interest busy ...
       print " ... ";
       
       # Now we stop the agent...
       $emAgent = new EMAgent();
       $emAgent->Initialize($pid, time(), $DEBUG_ENABLED);
       $rc = $emAgent->stop($tries); 
       
       if( $rc < 2 )
       { 
          $rc = 0;
          print " Stopped. \n";
       }
       else
       {
          print " Failed. \n";
       }

       # No idea what emctl.msg does ...
       unlink ("$EMDROOT/bin/emctl.msg");
    }
    
    return $rc;
}

#
# restartSACConsole
# 1) argument list
#

sub restartSAConsole
{
    local (*args) = @_;

    ($EM_ADMIN_PWD, $EM_ADMIN_PORT) = util_getPort( \@args );
 
    $rc = 0xffff & system("$JAVA_HOME/bin/java ".
                          "-Doracle.home=$FORMFACTOR_BASE -DOPMN=true ".
                          "-jar $ORACLE_HOME/j2ee/home/admin.jar ".
                          "ormi://localhost$EM_ADMIN_PORT ".
                          "ias_admin random -restart");

    $rc >>= 8;
    exit $rc;
}

#
# statusSAConsole_Internal is called during SACConsole to 
# check for both IASConsole and Agent Process liveness
#
# statusSAConsole_Internal() does not print any messages ....
#
# If OMS_RECV_DIR_SET=1, status for both agent+OMS will be checked
#                    =0, status for agent only will be checked
#
sub statusSAConsole_Internal
{
  my ($component) = shift;
  my ($checkImages) = shift;

  my ($console, $rc, $result, $pid);

  if ($OMS_RECV_DIR_SET) {
      # On slow systems, the PID_FILE may take time to be written out...
      unless( -e "$PID_FILE")
      {
          sleep 4;
      }

      if ( -e "$PID_FILE" )
      {
          my($pid);
          open(PIDFILE, "<$PID_FILE");
          while(<PIDFILE>)
          {
              $pid = $_;
          }
          close(PIDFILE);
          
          chomp($pid);
          if( ($pid eq undef) or ($pid eq "") )
          {
              return $STATUS_NO_SUCH_PROCESS;
          }
          
          if( $component eq "dbconsole") 
          {
              $console = new DBConsole();
          }
          else
          {
              $console = new IASConsole();
          }
          
          $console->Initialize($PID, time(), $DEBUG_ENABLED);
          if ($checkImages eq "false")
          {
              $console->setImageCacheInitialized();
          }
          $rc = $console->status();
          
          if( ($rc == $STATUS_NO_SUCH_PROCESS) or
              ($rc == $STATUS_PROCESS_HANG) )
          {
              return $rc;
          }
      }
      else
      {
          return $STATUS_NO_SUCH_PROCESS;
      }
  }
  else {
      # recv dir not set, check status of agent only
      $rc = $STATUS_PROCESS_OK;
  }  

    if($rc == $STATUS_PROCESS_OK)
    {
      if( $IN_VOB eq "TRUE")
      {
        return $rc;
      }

      # We need to check the Agent process...
      $rc = 0xffff & system("$EMDROOT/bin/emdctl status agent >$devNull 2>&1");
      $rc >>= 8;

      # bug 4279661: when omsRecvDir not set, return STATUS_PROCESS_UNKOWN
      #              if agent is down; if omsRecvDir is set, preserve 
      #              existing logic
      if (($rc == 3) || ($rc ==4))
      { 
        if ($OMS_RECV_DIR_SET) {
          # agent is started
          return $STATUS_PROCESS_OK; 
        }
        else {
	 if ($rc == 3) 
	 {
            # agent is started
            return $STATUS_PROCESS_OK; 
         }
         elsif ($rc == 4)
         { 
            # agent process is partially started 
            return $STATUS_PROCESS_PARTIAL;
         }
        }
      }
      else 
      {
 	if ($OMS_RECV_DIR_SET) {
          # db console was started but agent could not be started
          return $STATUS_PROCESS_PARTIAL;
        }
        else {
          # agent is not started
          return $STATUS_PROCESS_UNKNOWN;
        }
      }
    }
}

    
#
# Called as "emctl status em"
# statusSAConsole
# 1) argument list
#
# If OMS_RECV_DIR_SET=1, check status for OMS+agent
#                    =0, check status for agent onl
#
sub statusSAConsole
{
  my ($consoleType) = @_;
  
  my $result;
  my $emProduct = "";
  my ($console, $rc, $URL);

  if( $consoleType eq "dbconsole")
  { 
    $console = new DBConsole();
    $URL = $DB_URL;
    if ($OMS_RECV_DIR_SET) {
	$emProduct = "Oracle Enterprise Manager 10g";
    }
    else {
	$emProduct = "EM Daemon";
    }
  }
  else
  {
    $console = new IASConsole();
    $URL = $IAS_URL;
    $emProduct = "Oracle 10g Application Server Control";
  }

  if ($OMS_RECV_DIR_SET) {
      if ( -e "$PID_FILE" )
      {
          my($PID);
          open(PIDFILE, "<$PID_FILE");
          while(<PIDFILE>)
          {
              $PID = $_;
          }
          close(PIDFILE);
          
          chomp($PID);
          
          die "$emProduct is not running.\n"
              if ($PID eq "");
          
          $console->Initialize($PID, time(), $DEBUG_ENABLED);
          if ($consoleType eq "iasconsole")
          {
              $console->setImageCacheInitialized();
          }
          $rc = $console->status();
          
          if($rc == $STATUS_NO_SUCH_PROCESS)
          {
              print "$emProduct is not running. \n";
              footer();
              exit $rc;
          }
          
          if($IN_VOB eq "TRUE")
          {
              print "$emProduct is running.\n";
              footer();
              exit 0;
          }
      }
      else
      {
          die "$emProduct is not running.\n";
      }
  }

  # We need to check the Agent process...
  $rc = 0xffff & system("$EMDROOT/bin/emdctl status agent >$devNull 2>&1");
  $rc >>= 8;
  
  if( ($rc == 3) or ($rc == 4) ) 
     { 
         print "$emProduct is running. \n";
         footer();
         exit 0;
     }
  else 
  { 
      print "EM Daemon is not running.\n"; 
      footer();
      exit $rc;
  }
}

#
# startOMS
#
sub startOMS
{
  $rc = 0xffff & system("$ORACLE_HOME/opmn/bin/opmnctl start >$devNull 2>&1");
  $rc >>= 8;

  die "Could not start opmn.\n" if ($rc != 0 and $rc != 1);

  @states = `$ORACLE_HOME/dcm/bin/dcmctl getState -v -d`;

  $status = statusOHS( \@states );

  if( $status ne "Up" )
  {
     print "Starting HTTP Server ...\n";
     $rc = 0xffff & system("$ORACLE_HOME/opmn/bin/opmnctl startproc type=ohs >$devNull 2>&1");
     $rc >>= 8;
  }

  $status = statusOMS( \@states );
  if( $status eq "Up" )
  {
     print "Oracle Management Server Already Started.\n";
  }
  else
  {
     print "Starting Oracle Management Server ...\n";
     $rc = 0xffff & system("$ORACLE_HOME/opmn/bin/opmnctl startproc type=oc4j process-type=OC4J_EM >$devNull 2>&1");
     $rc >>= 8;

     print "Checking Oracle Management Server Status ...\n";
     statusOMS();
  }
}

#
# stopOMS
#
sub stopOMS
{
    $rc = 0xffff & system("$ORACLE_HOME/opmn/bin/opmnctl stopproc type=oc4j process-type=OC4J_EM >$devNull 2>&1");
    $rc >>= 8;

    statusOMS();
}

#
# statusOMS
#
sub statusOMS
{
  local (*args) = @_;
  my $count = scalar(@args);
  my $printMessage = "TRUE";

#
# Executing dcmctl getState -v -d returns the following information. 
#
# Current State for Instance:/ade/dmshah_em/oracle.dlsun1276
# 
# Component               Type          Up Status     In Sync Status          
# ==========================================================================
# 1   home                    oc4j          Down          True
# 2   HTTP Server             ohs           Up            True
# 3   OC4J_EM                 oc4j          Up            True

   if ( $count <= 0)
   {
     @args = `$ORACLE_HOME/dcm/bin/dcmctl getState -v -d`;
     $count = scalar(@args);
     $printMessage = "TRUE";
   }
   else
   {
     $printMessage = "FALSE";
   }

   my $omsStatus = "Up";
   my $i=0;
   while( $i < $count)
   {
     @comp = split /\s+/, $args[$i];
     if( $comp[1] eq "OC4J_EM")
     {
        $omsStatus = $comp[3];
        last;
     }
     $i = $i + 1;
   }

  if ($omsStatus ne "Up")
  {
      $omsStatus = "initializing" if ($omsStatus eq "partially");
      print "Oracle Management Server is $omsStatus\n" unless ($printMessage eq "FALSE");
      return $omsStatus;
  }

  # Here, the OC4j_EM process is up but that is not enough to conclude that
  # OMS is up. We need to hit the site to verify that the OMS is fully
  # up. If there is a problem (context not initialized correctly, connection
  # to the database failed, unsupported repository database version) the 
  # console filter ContextInitFilter will generate a 503 Service Unavailable 
  # and an error message in the response.
  
  # Find the OMS Port in emoms.properties
  my $in_file="$EMHOME/sysman/config/emoms.properties";
  open(INFILE, "$in_file") || die "Could not open $in_file\n";
    
  #loop through file
  my $omsPort = -1;
  while(<INFILE>) 
  {
    if (/oracle.sysman.emSDK.svlt.ConsoleServerPort=(.*)/)
    {
      $omsPort = $1;
      last;
    }
  }
  close(INFILE);

  die "Could not find Console Server Port in $in_file\n" if ($omsPort == -1);

  my $OMS_URL="http://127.0.0.1:$omsPort/em/genwallet";
  my $url = URI->new($OMS_URL);
  my $ua = LWP::UserAgent->new;
  $ua->agent('Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)');
  my $resp = $ua->get($url->as_string());

  my $errMessage = "";

  if ($resp->is_error())
  {
      $omsStatus = "not functioning because of the following reason:";

      my $omsCode = $resp->headers->header('STATUS-OMS');
      if ($omsCode eq "1")
      {
	  $errMessage = "Context is not fully initialized yet\n";
      }
      elsif ($omsCode eq "2")
      {
	  $errMessage = "Oracle Management Server version is not compatible with repository version\n";
      }
      elsif ($omsCode eq "3")
      {
	  $errMessage = "Connection to the repository failed. Verify that the repository connection information provided is correct.\n";
      }
      elsif ($omsCode eq "4")
      {
	  $errMessage = "OMS mode is not compatible with the repository mode.\n";
      }
      else 
      { 
	  $errMessage = "Unexpected error occurred. Check error and log files\n";
      }
  }

  print "Oracle Management Server is $omsStatus\n$errMessage" unless ($printMessage eq "FALSE");
  return $omsStatus;
}

#
# statusOHS Returns the status of HTTP Server
#
sub statusOHS
{
  local (*args) = @_;
  my $count = scalar(@args);

  my $i=0;
  while( $i < $count)
  {
     @comp = split /\s+/, $args[$i];
     if( ($comp[1] eq "HTTP") or ($comp[3] eq "ohs"))
     {
        return $comp[4];
     }
     $i = $i + 1;
  }
}

#
# setupSecure takes
# 1) Array of arguments
#
# Secure::secure leads to other perl modules that make use of a shell
# env var DEFAULT_CLASSPATH 
#
sub setupSecure
{
  local (*args) = @_;
  shift(@args);
  Secure::secure( @args );
}

#
# Config Agent takes
# 1) Array of arguments
#
# Original : emctl config console ...
#            emctl config addTarget ...
#            emctl config deleteTarget ...
#            emctl set credential ...
# Modified :
#            emctl config console ...
#            emctl config agent addTarget ...
#            emctl config agent deleteTarget ...
#            emctl config agent credential ...
#
sub configAgent
{
  local (*args) = @_;
  my ($rc, $pid);

  if ($component eq "agent") #emctl config agent
  {
    shift(@args);                  # -- shift out config...
    if ($args[1] eq "credentials") #emctl config agent credentials
    {
      shift(@args);                # -- shift out agent ...
      $rc = 0xffff & system ("$EMDROOT/bin/emdctl set @args"); # emdctl set credential <args>
      $rc >>= 8;
      exit $rc;
    }
    if ($args[1] eq "port") #emctl config agent port <portNumber>
    {
      $rc = statusSAConsole_Internal($CONSOLE_CFG, "false");
      # check if console is up, warn user to stop if so
      # (stopping console also stops agent...)
      if ( $rc == $STATUS_PROCESS_OK or $rc == $STATUS_PROCESS_PARTIAL )
      {
        my ($consoleBanner) = "Oracle 10g Application Server Control";
        if( $CONSOLE_CFG eq "dbconsole") 
        {
          $consoleBanner = "Oracle Enterprise Manager 10g Database Control";
        }
        print "You must stop ${consoleBanner} before changing port values.\n";
        exit 1;
      }
      # Now we update the agent port information
      my $emAgent = new EMAgent();
      $emAgent->Initialize($pid, time(), $DEBUG_ENABLED);
      $rc = $emAgent->updatePort($args[2]); 
      exit $rc;
    }
  }

  shift(@args);                     # -- shift out config or agent...

  if ( $args[0] eq "updateTZ" or $args[0] eq "addtarget" or
            $args[0] eq "addtargets" or $args[0] eq "deletetarget" or
            $args[0] eq "deletetargets" )
  {
    umask $agentUmask;
  }

  delete($ENV{EMSTATE});
  delete($ENV{REMOTE_EMDROOT});

  if(EmctlCommon::isWindows() eq "true")
  {
    $pathSeparator = ';';
  }
  else
  {
    $pathSeparator = ':';
  }

  $CLASSPATH = "$ORACLE_HOME/jlib/emConfigInstall.jar"."$pathSeparator"."$ORACLE_HOME/jlib/http_client.jar"."$pathSeparator"."$ORACLE_HOME/jlib/ojmisc.jar"."$pathSeparator"."$ORACLE_HOME/jlib/jssl-1_1.jar"."$pathSeparator"."$ORACLE_HOME/jlib/javax-ssl-1_1.jar";

  $rc = 0xffff & system("${JRE_HOME}/bin/java -classpath $CLASSPATH -DORACLE_HOME=$EMDROOT -DEMHOME=$EMHOME oracle.sysman.emSDK.conf.TargetInstaller @args");

  $rc >>= 8;

  exit $rc;
}

#
# Config OMS takes
# 1) Array of arguments
#            emctl config oms sso ...
#
sub configOMS
{
  local (*args) = @_;

  shift(@args);                  # -- shift out config...
  shift(@args);                  # -- shift out oms ...

  if ($args[0] eq "sso") #emctl config oms sso
  {
      sso( \@args );
  }
  else 
  {
      displayHelp();
      exit 2;
  }
}

######################################################################
# setReposPasswd()
#   Set the repostory password in emoms.properties. The password is obfuscated 
# before it is written to the file.
######################################################################
sub setReposPasswd()
{
  if(EmctlCommon::isWindows() eq "true")
  {
    $clsSeparator = ';';
  }
  else
  {
    $clsSeparator = ':';
  }
  $CLASSPATH = "$EMDROOT/sysman/jlib/emCORE.jar"."$clsSeparator".
               "$EMDROOT/sysman/jlib/log4j-core.jar"."$clsSeparator".
               "$ORACLE_HOME/j2ee/OC4J_EM/applications/em/em/WEB-INF/lib/emCORE.jar"."$clsSeparator".
               "$ORACLE_HOME/sysman/lib/emCORE.jar"."$clsSeparator".
               "$ORACLE_HOME/sysman/lib/log4j-core.jar";
  my $newPasswd = EmctlCommon::promptUserPasswd("Please enter new repository password: ", 0);
  open(SETPWD, "| $JAVA_HOME/bin/java -classpath $CLASSPATH ".
                  "-DEMSTATE=$EMHOME oracle.sysman.emSDK.conf.ConfigManager ".
                  "-setPasswd >$devNull");
  print SETPWD "$newPasswd";
  close(SETPWD);
  print("Repository password successfully updated.\n");
}


#
# deploy Agent takes
# 1) Array of arguments
#
#            emctl deploy agent [-m rac] [-p <password>] <deploy-dir> <deployhostname:port> <hostname> <sid>
#
sub deploy
{
  local (*args) = @_;

  shift(@args); # -- shift out "deploy"
  $mode = shift(@args);

  getopts('bn:u:p:s:');

  my ($stateDir, $hostPort, $srcHost, $sid, $sourceEMDROOT,$replaceEMDROOT);

  if($mode eq "agent") 
  {
    if(@args < 3)
    {
      print STDERR "Incorrect number of arguments.\n";
      printDeployUsage();
      exit -1;
    }

    ($stateDir, $hostPort, $srcHost) = ($args[0],$args[1],$args[2]);

  }
  elsif($mode eq "dbconsole")
  {
    if(@args < 4)
    {
	print STDERR "Incorrect number of arguments.\n";
	printDeployUsage();
	exit -1;
    }

    ($stateDir, $hostPort, $srcHost, $sid) = 
	($args[0],$args[1],$args[2],$args[3]);

  }
  else 
  {
      printDeployUsage();
      exit -1;
  }

  if($ENV{REMOTE_EMDROOT} ne "")
  {
      $sourceEMDROOT = $ENV{REMOTE_EMDROOT};
      $replaceEMDROOT = $ENV{LOCAL_EMDROOT}; #LOCAL_EMDROOT env is also set
  }
  else
  {
      $sourceEMDROOT = $EMDROOT;
      $replaceEMDROOT = $EMDROOT;
  }

  -e "$sourceEMDROOT" or die "EMDROOT location: $sourceEMDROOT does not exist";

  my $deployObj = new EMDeploy();
  $deployObj->doDeploy($mode, $stateDir, $hostPort, $srcHost, $sid, $sourceEMDROOT, $replaceEMDROOT, $opt_s, $opt_n, $opt_u, $opt_p, $opt_b);
}


#
# runILINT takes
# 1) Array of arguments
#
# ILINT performs static validation of the XML metadata:
# target, instance, and collection.

sub runILINT
{
  use Cwd;
  local (*args) = @_;

  shift(@args); # -- shift out ilint...
  $oldpwd = cwd;
  $printxmlprefix = "";
  if ($args[0] eq "-o")
  {
     $printxmlprefix = $args[1];
     chdir("$ENV{EMDROOT}"."/sysman/admin/metadata");
  }
  die "Missing ilint executable"
     if (! -e "$EMDROOT/bin/nmei"."$binExt");

  $rc = 0xffff & system ("$EMDROOT/bin/nmei -e @args"); # ilint <args>
  $rc >>= 8;
  if ($printxmlprefix ne "")
  {
      copy "${printxmlprefix}.xml.tmp1", "$oldpwd";
      unlink "${printxmlprefix}.xml.tmp1";
      copy "${printxmlprefix}.xml.tmp2", "$oldpwd";
      unlink "${printxmlprefix}.xml.tmp2";
  }
  exit $rc;
}

#
# setPassword
# 1) Array of arguments
#
sub setPassword
{
    local (*args) = @_;

    local $curdir=`pwd`;      # get the current directory
    chomp($curdir);           # remove trailing spaces

    # make backup of jazn-data.xml (we save up to 10 versions)
    if (-e "$EMDROOT/sysman/j2ee/config/jazn-data.xml")
    {
      rotateFile("$EMDROOT/sysman/j2ee/config/jazn-data.xml", 10);
    }

    chdir("$EM_OC4J_HOME");
    system("$JAVA_HOME/bin/java -jar $ORACLE_HOME/oc4j/j2ee/home/jazn.jar -setpasswd enterprise-manager ias_admin $args[2] $args[3]");

    chdir($curdir);
}

#
# authenticate
# 1) Array of arguments
#
sub authenticate
{
    local (*args) = @_;

    $CLASSPATH="$EMDROOT/sysman/jlib/emd_java.jar:$ORACLE_HOME/oc4j/j2ee/home/jazn.jar";

    $rc = 0xffff & system("$JAVA_HOME/bin/java -classpath $CLASSPATH $EM_OC4J_OPTS -Doracle.security.jazn.config=$EMDROOT/sysman/j2ee/config/jazn.xml -DEMDROOT=$EMDROOT oracle.sysman.eml.sec.pwd.SecurePasswordRead enterprise-manager ias_admin $args[1]");
    $rc >>= 8;

    if ( $rc == 0 )
    {
        print "success\n";
    }
    elsif ( $rc == 2 )
    {
        print "invalid password\n";
    }
    else
    {
        print "failure\n";
    }
    exit $rc
}

#
# setSASSL
# 1) array of arguments
#
sub setSASSL
{
    local (*args) = @_;

    $EM_IAS_CONSOLE_PORT = $ENV{EM_IAS_CONSOLE_PORT};
    if($EM_IAS_CONSOLE_PORT eq "")
    {
       $EM_IAS_CONSOLE_PORT=1810;
        print "Defaulting EM IAS Console port to $EM_IAS_CONSOLE_PORT\n";
    }

    $EM_CONSOLE_SERVLET_PORT = $ENV{EM_CONSOLE_SERVLET_PORT};
    if($EM_CONSOLE_SERVLET_PORT eq "")
    {
        $EM_CONSOLE_SERVLET_PORT=1812;
        print "Defaulting EM CONSOLE port to $EM_CONSOLE_SERVLET_PORT\n";
    }

    $EMD_KEYSTORE_FILE = $ENV{EMD_KEYSTORE_FILE};
    if ($EMD_KEYSTORE_FILE eq "")
    {
        $EMD_KEYSTORE_FILE="keystore.test";
        print "Setting EMD_KEYSTORE_FILE to $EMD_KEYSTORE_FILE\n";
    }

    if ($args[2] eq "test")
    {
	$EMD_SECURE = $ENV{EMD_SECURE};
	if ($EMD_SECURE eq "")
	{
	    $EMD_SECURE="true";
	    print "Setting EMD_SECURE to $EMD_SECURE\n";
	}

        $EMD_KEYSTORE_FILE = $ENV{EMD_KEYSTORE_FILE};
        if ($EMD_KEYSTORE_FILE eq "")
        {
            $EMD_KEYSTORE_FILE="keystore.test";
            print "Setting EMD_KEYSTORE_FILE to $EMD_KEYSTORE_FILE\n";
        }

	if ( $args[3] eq "agent" ) 
	{
	    $TEMPLATE_FILE = "$EMDROOT/sysman/j2ee/config/emd-web-site.xml.template";
	    $REPLACED_FILE = "$EMDROOT/sysman/j2ee/config/emd-web-site.xml";
	    @tr = ('%EM_IAS_CONSOLE_PORT%', '%EMD_SECURE%', '%EMD_KEYSTORE_FILE%');
	    @rb = ("$EM_IAS_CONSOLE_PORT", "$EMD_SECURE", "$EMD_KEYSTORE_FILE");
	    my_sed(*tr, *rb,  $TEMPLATE_FILE, $REPLACED_FILE);

	}elsif ( $args[3] eq "em" ) 
	{
	    $TEMPLATE_FILE="$EMDROOT/sysman/j2ee/config/em-web-site.xml.ssl.template";
	    $REPLACED_FILE="$EMDROOT/sysman/j2ee/config/em-web-site.ssl.xml";
	    @tr =('%EM_CONSOLE_SERVLET_PORT%', '%EMD_SECURE%', '%EMD_KEYSTORE_FILE%');
	    @rb =("$EM_CONSOLE_SERVLET_PORT", "$EMD_SECURE", "$EMD_KEYSTORE_FILE");
	    my_sed(*tr, *rb,  $TEMPLATE_FILE, $REPLACED_FILE);

	}elsif ( $args[3] eq "both" ) 
	{
	    $TEMPLATE_FILE = "$EMDROOT/sysman/j2ee/config/emd-web-site.xml.template";
	    $REPLACED_FILE = "$EMDROOT/sysman/j2ee/config/emd-web-site.xml";
	    @tr = ('%EM_IAS_CONSOLE_PORT%', '%EMD_SECURE%', '%EMD_KEYSTORE_FILE%');
	    @rb = ("$EM_IAS_CONSOLE_PORT", "$EMD_SECURE", "$EMD_KEYSTORE_FILE");
	    my_sed(*tr, *rb,  $TEMPLATE_FILE, $REPLACED_FILE);

	    $TEMPLATE_FILE="$EMDROOT/sysman/j2ee/config/em-web-site.xml.ssl.template";
	    $REPLACED_FILE="$EMDROOT/sysman/j2ee/config/em-web-site.ssl.xml";

	    @tr =('%EM_CONSOLE_SERVLET_PORT%', '%EMD_SECURE%', '%EMD_KEYSTORE_FILE%');
	    @rb =("$EM_CONSOLE_SERVLET_PORT", "$EMD_SECURE", "$EMD_KEYSTORE_FILE");
	    my_sed(*tr, *rb,  $TEMPLATE_FILE, $REPLACED_FILE);
	}
    } 
    elsif ($args[2] eq "off") 
    {
	$EMD_SECURE = $ENV{EMD_SECURE};
	if ($EMD_SECURE eq "")
	{
	    $EMD_SECURE="false";
	    print "Setting EMD_SECURE to $EMD_SECURE\n";
	}

        $EMD_KEYSTORE_FILE = $ENV{EMD_KEYSTORE_FILE};
        if ($EMD_KEYSTORE_FILE eq "")
        {
            $EMD_KEYSTORE_FILE="keystore.test";
            print "Setting EMD_KEYSTORE_FILE to $EMD_KEYSTORE_FILE\n";
        }

	if ( $args[3] eq "agent" ) 
	{
	    $TEMPLATE_FILE = "$EMDROOT/sysman/j2ee/config/emd-web-site.xml.template";
	    $REPLACED_FILE = "$EMDROOT/sysman/j2ee/config/emd-web-site.xml";
	    @tr = ('%EM_IAS_CONSOLE_PORT%', '%EMD_SECURE%', '%EMD_KEYSTORE_FILE%');
	    @rb = ("$EM_IAS_CONSOLE_PORT", "$EMD_SECURE", "$EMD_KEYSTORE_FILE");
	    my_sed(*tr, *rb,  $TEMPLATE_FILE, $REPLACED_FILE);

	}elsif ( $args[3] eq "em" ) 
	{
	    $TEMPLATE_FILE="$EMDROOT/sysman/j2ee/config/em-web-site.xml.ssl.template";
	    $REPLACED_FILE="$EMDROOT/sysman/j2ee/config/em-web-site.ssl.xml";
	    @tr =('%EM_CONSOLE_SERVLET_PORT%', '%EMD_SECURE%', '%EMD_KEYSTORE_FILE%');
	    @rb =("$EM_CONSOLE_SERVLET_PORT", "$EMD_SECURE", "$EMD_KEYSTORE_FILE");
	    my_sed(*tr, *rb,  $TEMPLATE_FILE, $REPLACED_FILE);

	}elsif ( $args[3] eq "both" ) 
	{
	    $TEMPLATE_FILE = "$EMDROOT/sysman/j2ee/config/emd-web-site.xml.template";
	    $REPLACED_FILE = "$EMDROOT/sysman/j2ee/config/emd-web-site.xml";
	    @tr = ('%EM_IAS_CONSOLE_PORT%', '%EMD_SECURE%', '%EMD_KEYSTORE_FILE%');
	    @rb = ("$EM_IAS_CONSOLE_PORT", "$EMD_SECURE", "$EMD_KEYSTORE_FILE");
	    my_sed(*tr, *rb,  $TEMPLATE_FILE, $REPLACED_FILE);

	    $TEMPLATE_FILE="$EMDROOT/sysman/j2ee/config/em-web-site.xml.ssl.template";
	    $REPLACED_FILE="$EMDROOT/sysman/j2ee/config/em-web-site.ssl.xml";
	    @tr =('%EM_CONSOLE_SERVLET_PORT%', '%EMD_SECURE%', '%EMD_KEYSTORE_FILE%');
	    @rb =("$EM_CONSOLE_SERVLET_PORT", "$EMD_SECURE", "$EMD_KEYSTORE_FILE");
	    my_sed(*tr, *rb,  $TEMPLATE_FILE, $REPLACED_FILE);
	}
    }
    elsif ($args[2] eq "on")
    {
	$EMD_SECURE = $ENV{EMD_SECURE};
	if ($EMD_SECURE eq "")
	{
	    $EMD_SECURE="true";
	    print "Setting EMD_SECURE to $EMD_SECURE\n";
	}

        $EMD_KEYSTORE_FILE = $ENV{EMD_KEYSTORE_FILE};
        if ($EMD_KEYSTORE_FILE eq "")
	{
	    $EMD_KEYSTORE_FILE="keystore.secure";
	    print "Setting EMD_KEYSTORE_FILE to $EMD_KEYSTORE_FILE\n";
	}

	if ( $ARGV[3] eq "agent" ) 
	{
	    $TEMPLATE_FILE = "$EMDROOT/sysman/j2ee/config/emd-web-site.xml.template";
	    $REPLACED_FILE = "$EMDROOT/sysman/j2ee/config/emd-web-site.xml";
	    @tr = ('%EM_IAS_CONSOLE_PORT%', '%EMD_SECURE%', '%EMD_KEYSTORE_FILE%');
	    @rb = ("$EM_IAS_CONSOLE_PORT", "$EMD_SECURE", "$EMD_KEYSTORE_FILE");
	    my_sed(*tr, *rb,  $TEMPLATE_FILE, $REPLACED_FILE);

	}elsif ( $ARGV[3] eq "em" ) 
	{
	    $TEMPLATE_FILE="$EMDROOT/sysman/j2ee/config/em-web-site.xml.ssl.template";
	    $REPLACED_FILE="$EMDROOT/sysman/j2ee/config/em-web-site.ssl.xml";
	    @tr =('%EM_CONSOLE_SERVLET_PORT%', '%EMD_SECURE%', '%EMD_KEYSTORE_FILE%');
	    @rb =("$EM_CONSOLE_SERVLET_PORT", "$EMD_SECURE", "$EMD_KEYSTORE_FILE");
	    my_sed(*tr, *rb,  $TEMPLATE_FILE, $REPLACED_FILE);

	}elsif ( $ARGV[3] eq "both" ) 
	{
	    $TEMPLATE_FILE="$EMDROOT/sysman/j2ee/config/emd-web-site.xml.template";
	    $REPLACED_FILE="$EMDROOT/sysman/j2ee/config/emd-web-site.xml";
	    @tr = ('%EM_IAS_CONSOLE_PORT%', '%EMD_SECURE%', '%EMD_KEYSTORE_FILE%');
	    @rb = ("$EM_IAS_CONSOLE_PORT", "$EMD_SECURE", "$EMD_KEYSTORE_FILE");
	    my_sed(*tr, *rb,  $TEMPLATE_FILE, $REPLACED_FILE);

	    $TEMPLATE_FILE="$EMDROOT/sysman/j2ee/config/em-web-site.xml.ssl.template";
	    $REPLACED_FILE="$EMDROOT/sysman/j2ee/config/em-web-site.ssl.xml";
	    @tr =('%EM_CONSOLE_SERVLET_PORT%', '%EMD_SECURE%', '%EMD_KEYSTORE_FILE%');
	    @rb =("$EM_CONSOLE_SERVLET_PORT", "$EMD_SECURE", "$EMD_KEYSTORE_FILE");
	    my_sed(*tr, *rb,  $TEMPLATE_FILE, $REPLACED_FILE);
	}
    }
    else
    {
	displayHelp();
	exit 2;
    }
}


#
# Sets up the SSO
#
sub sso
{
  local (*args) = @_;

  # SSO needs to be a perl medule
  shift (args);
  require "$EMDROOT/bin/setsso.pl";
  # Should have exited in the require call above...
  die("Error in call to $EMDROOT/bin/setsso.pl");
}


# sed utility.
# takes 
# 1) a list of things to be replaced
# 2) a lits of things that will replace 1)
# 3) input file name
# 4) output filename


sub my_sed
{
    local (*var_to_replace, *replace_list, $in_file, $out_file) = @_;

    print "$in_file - $out_file\n";
    open(INFILE, "$in_file") || die "Could not open $in_file\n";
    open(OUTFILE, ">$out_file") || die "Could not open $out_file\n";
    
    #loop through file and do substitution
    while(<INFILE>) {
        for($i = 0; $i < @var_to_replace; $i++)
        {
            $_ =~ s/$var_to_replace[$i]/$replace_list[$i]/g;
        }
        print OUTFILE;
    }
    close(INFILE);
    close(OUTFILE);
}

#
# admin port/pwd utility
# Constructs admin port and password to stop/restart/status Standalone Console
#
# Note: returns 1818 as port if EM_ADMIN_PORT is not found

sub util_getPort_sa
{
    local (*args) = @_;
    ($EM_ADMIN_PWD, $EM_ADMIN_PORT) = util_getPort_impl( \@args );
    if ($EM_ADMIN_PORT eq "") 
    {
        $EM_ADMIN_PORT=":1818";
    } 
    @rarray = ( $EM_ADMIN_PWD, $EM_ADMIN_PORT);
    return @rarray;
}

#
# admin port/pwd utility
# Constructs admin port and password to stop/restart/status Standalone Console
#
# Note: returns 1811 as port if EM_ADMIN_PORT is not found

sub util_getPort
{
    local (*args) = @_;
    ($EM_ADMIN_PWD, $EM_ADMIN_PORT) = util_getPort_impl( \@args );
    if ($EM_ADMIN_PORT eq "") 
    {
        $EM_ADMIN_PORT=":1811";
    } 
    @rarray = ( $EM_ADMIN_PWD, $EM_ADMIN_PORT);
    return @rarray;
}

#
# admin port/pwd utility
# Constructs admin port and password to stop/restart/status Standalone Console
# Note: returns "" if EM_ADMIN_PORT is not found

sub util_getPort_impl
{
    local (*args) = @_;

    $EM_ADMIN_PWD = $ENV{EM_ADMIN_PWD};
    if ($EM_ADMIN_PWD eq "") 
    {
        print "Enter Management password : ";
        system "stty -echo"; # Non portable until ReadKey is picked up ...
        $EM_ADMIN_PWD=<STDIN>;
        system "stty echo";  # Non portable until ReadKey is picked up ...
                             # Once ReadKey is picked up use the following.
                             # ReadMode('noecho');
                             # $EM_ADMIN_PWD = ReadLine(0);
                             # ReadMode('normal');
        chomp ($EM_ADMIN_PWD);
    }

    $EM_ADMIN_PORT = $args[2];
    if ($EM_ADMIN_PORT eq "") 
    {
        if ($ENV{EM_ADMIN_PORT} eq "")
        {
            $EM_ADMIN_PORT=":";
        } 
        else 
        {
            $EM_ADMIN_PORT=":".$ENV{EM_ADMIN_PORT};
        }
    }
    else 
    {
       $EM_ADMIN_PORT=":".$args[2];
    }

    @rarray = ( $EM_ADMIN_PWD, $EM_ADMIN_PORT);
    return @rarray;
}

#
# startSubAgent starts the emsubagent. A cutover from the 
# older dbsnmp
#
sub startSubAgent
{
    local $curdir=`pwd`;      # get the current directory
    chomp($curdir);           # remove trailing spaces

    if( $IS_WINDOWS eq "TRUE" )
    {
      print "Running sub agent ...";
      system("$EMDROOT/bin/emsubagent >> $EMHOME/sysman/log/emsubagent.nohup 2>&1");
      print "..stopped\n";
    }
    else
    {
      # Start the agent and wait for 30 secs
      print "Starting sub agent ...";
      system("nohup $EMDROOT/bin/emsubagent >> $EMHOME/sysman/log/emsubagent.nohup 2>&1 &");

      print "..started\n";
    }

    chdir("$curdir");

    exit 0;
}

sub statusSubAgent
{
  my $found = 0;
  my @procs = ``;

  if( $IS_WINDOWS eq "TRUE" )
  {
    @procs = `ps -eo "pid,args" | grep "emsubagent"`;
  }
  else
  {
    @procs = `ps -eo "pid,args" | grep "$EMDROOT/bin/emsubagent"`;
  }
  foreach $item (@procs) {
   if ( $item !~ /grep/ ) {
     $found = 1;
   }
  }
  return $found;
}

sub stopSubAgent
{
  my @procs = ``;

  if( $IS_WINDOWS eq "TRUE" )
  {
    @procs = `ps -eo "pid,args" | grep "emsubagent"`;
  }
  else
  {
    @procs = `ps -eo "pid,args" | grep "$EMDROOT/bin/emsubagent"`;
  }
  print "Stopping sub agent...";
  foreach $item (@procs) {
   if ( $item !~ /grep/ ) {
     ($subAgentPid, $arg) = split(" ", $item);
      kill 9, $subAgentPid;
      print "stopped\n";
   }
  }
}

# routines to make backups of files critical to AS Control operation
sub makeBackups
{
  my ($xmlFile, $lastMtime);

  if (! -e "$EMDROOT/sysman/config/iasadmin.properties.1")
  {
    rotateFile("$EMDROOT/sysman/config/iasadmin.properties", 2);
  }
  if (! -e "$EMDROOT/sysman/webapps/emd/WEB-INF/config/consoleConfig.xml.1")
  {
    rotateFile("$EMDROOT/sysman/config/iasadmin.properties", 2);
  }
  if (! -e "$EMDROOT/sysman/emd/targets.xml.1")
  {
    rotateFile("$EMDROOT/sysman/emd/targets.xml", 2);
  }
  if (! -e "$EMDROOT/sysman/j2ee/config/jazn-data.xml.1")
  {
    rotateFile("$EMDROOT/sysman/j2ee/config/jazn-data.xml", 2);
  }
  else
  {
    $xmlFile = "$EMDROOT/sysman/j2ee/config/jazn-data.xml";
    if (-e $xmlFile)
    {
      $sb = stat($xmlFile);
      $lastMtime = $sb->mtime;
    }
    $xmlFile = "$EMDROOT/sysman/j2ee/config/jazn-data.xml.1";
    if (-e $xmlFile)
    {
      $sb = stat($xmlFile);
      if ($lastMtime > $sb->mtime)
      {
        rotateFile("$EMDROOT/sysman/j2ee/config/jazn-data.xml", 10);
      }
    }
  }
}

sub rotateFile 
{
    my ($i,$file, $maxbakups,$tmpfile,$tmpfile2);
    ($file, $maxbakups) = @_;
    
    if( -e $file.".".$maxbakups )
    {
	unlink ($file.".".$maxbakups);
    }

    for($i=$maxbakups -1 ; $i >=1 ;$i--) 
    {
	my $nextindex = $i + 1;
	$tmpfile = $file.".".$i;
	$tmpfile2 = $file.".".$nextindex;

	if( -e $tmpfile) 
        {
	    rename($tmpfile,$tmpfile2);
	}
    }
    copy($file,$file."."."1");
}    

#resets the agent time zone setting in emd.properties. Also clears the
#state directory,upload directory. 
sub resetTZ()
{
  $EMHOME=getEMHome($CONSOLE_CFG);
  $uploadDir = "$EMHOME"."/sysman/emd/upload";
  $stateDir = "$EMHOME"."/sysman/emd/state";
  my $emdPropFile = "$EMHOME"."/sysman/config/emd.properties";
  $status = istatusCEMD();
  if( $status == 1 )
  {
       
      $retVal1 = clearDirContents($uploadDir);
      $retVal2 = clearDirContents($stateDir);
      if( ($retVal1 == 1 ) || ($retVal2 == 1) )
      {
        print("Some files in $uploadDir or $stateDir couldn't be removed.Delete them manually and rerun the command.\n");
        exit(1);
      }

      my($fh,$tmpfilename) = tempfile(UNLINK => 1);
      close $fh; # closing to prevent file sharing violations on Windows
      print ("Updating $emdPropFile...\n");
      $rc = 0xffff & system("$JRE_HOME/bin/java -DORACLE_HOME=$EMDROOT -DEMHOME=$EMHOME -jar $ORACLE_HOME/jlib/emConfigInstall.jar updateTZ > $tmpfilename 2>&1");
      $rc >>= 8;
      if ($rc == 1 )
      {
          open ($fh,"<$tmpfilename");
          while (<$fh>) {
              print("$_");
          }
          close $fh;

        print("resetTZ:Failed to update  the property 'agentTZRegion' in $emdPropFile.Needs to be manually updated.Execute 'emctl config agent getTZ' to see if this value is appropriate.");
        exit(1);
      }
      ($agentName,$tzRegion) = getEMAgentNameAndTZ("$emdPropFile");
      $rc = validateTZAgainstAgent($tzRegion);
      if ( $rc != 0 )
      {
        print("resetTZ failed.\n");
        print("The agentTZRegion in:\n");
        print("$emdPropFile\n"); 
        print("is not in agreement with what the agent thinks it should be.\n"); 
        print("Fix your environment.\n");
        print("Pick a TZ value that corresponds to time zone settings listed in:\n");
        print("$EMDROOT/sysman/admin/supportedtzs.lst\n");      
        exit($rc);
      }

      if($CONSOLE_CFG eq "agent")
      {
	print("Time zone set to $tzRegion.\n\n");

	print("To complete this process, you must connect to the Grid Control repository as user sysman, and execute:\n\n");
	
	print("SQL> exec mgmt_target.set_agent_tzrgn(\'$agentName\',\'$tzRegion\')\n\n");
	exit(0);
      }
      else
      {

	print("Time zone set to $tzRegion.\n\n");

	print("To complete this process, you must either:\n\n");
	print("connect to the database served by this DBConsole as user 'sysman', and execute:\n\n");
	print("SQL> exec mgmt_target.set_agent_tzrgn(\'$agentName\',\'$tzRegion\')\n\n");
	print("\t\t\t-- or --\n\n");
	print("connect to the database served by this DBConsole as user 'sys', and execute:\n\n");
	print("SQL> alter session set current_schema = SYSMAN;\n");
	print("SQL> exec mgmt_target.set_agent_tzrgn(\'$agentName\',\'$tzRegion\')\n\n");
	

	exit(0);
      }
  }
  else
  {
    print("Agent is running. Stop the agent and rerun the command.\n");
    exit(1);
  }
}

sub clearDirContents()
{
  my ($dirname) = @_;
  my $retVal = 0;
  
  opendir(DIR, $dirname) or die "Delete the files manually from dir $dirname,can't opendir $dirname: $!";
  while (defined($filename = readdir(DIR))) {
    $filename = "$dirname"."/$filename";
    if ( -f $filename)
    {
      $rc = unlink($filename);
      if( $rc != 1)
      {
        print("Unable to delete the file $filename. Need to manually delete this file.\n");
        $retVal = 1;
      }
    }
  }
  closedir(DIR);

  return $retVal;
}    
