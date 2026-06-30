#  $Header:
#
# Copyright (c) 2001, 2004, Oracle. All rights reserved.  
#
#    NAME
#      IASConsole.pm - Perl Module to provide start, stop, status functionality
#
#    DESCRIPTION
#       This script provides the stop, status, debug functionality for 
#       the emwd and the emctl. Additionally it may hold other
#       states like the start time, its PID, thrashCount etc.
#
#    NOTE :
#       Any addition to the API which is accessed by emwd needs to be added
#       to DBConsole and EMAgent as well.
#
#    MODIFIED   (MM/DD/YY)
#      jsutton   05/18/04 - Allow port config 
#      rzazueta  11/05/03 - Fix bug 3164505: Deprecate password to shutdown 
#      jsutton   10/15/03 - Expose routine to set imageCacheInit flag 
#      rzazueta  09/28/03 - Fix bug 3164310 
#      dmshah    09/17/03 - Code review changes 
#      dmshah    09/15/03 - Integration testing changes 
#      dmshah    09/11/03 - Check for stack dump during stop 
#      dmshah    09/03/03 - Removing dependency on instantiated port settings 
#      jtrichar  09/05/03 - workaround NT kill issue 
#      jtrichar  09/03/03 - don't use opmn during shutdown of SAC 
#      jtrichar  09/02/03 - porting from 401: jsutton's startup backoff 
#      vnukal    06/17/03 - adding okToRestart method
#      dmshah    05/08/03 - Obsoleting getProcList
#      dmshah    04/06/03 - dmshah_bug-2849086_mainsa
#      dmshah    04/08/03 - Removing hardcoded pid from stopSAC
#      dmshah    03/20/03 - Only way to kill is SIGKILL
#      dmshah    04/02/03 - grabtrans 'dmshah_fix_2849086_2'
#      dmshah    03/14/03 - Adding restart code
#      dmshah    03/13/03 - Adding incThrashCount
#      dmshah    03/11/03 - dmshah_em_watchdog
#      dmshah    03/09/03 - Making emctl start em compatible for VOBs
#      dmshah    03/06/03 - Using signal 0 for process liveness
#      dmshah    03/03/03 - Fixing constructor syntax
#      dmshah    03/03/03 - Testing if..else block
#      dmshah    02/26/03 - Created.
#

package IASConsole;
use strict;
use EmctlCommon;

sub new
{
  my ($class) = @_;
  my $self =
  {
     PID => -1,
     name => undef,
     startTime => -1,
     thrashCount => 0,
     imageCacheInitialized => 0,
     debug => 0,
     emHome => getEMHome("iasconsole"),
     oc4jHome => getOC4JHome("iasconsole"),
     url => getWebUrl(getOC4JHome("iasconsole"), 
                      getEMHome("iasconsole"), "iasconsole"),
     rmiPort => getORMIPort( getOC4JHome("iasconsole") ),
     initialized => 0
  };
  
  bless $self, $class;
  return $self;
}

#
# Initialize 
# Ensure that the values are correct.
#
sub Initialize
{
  my $self = shift;
  my $inPID = shift;
  my $inStartTime = shift;
  my $debugFlag = shift;

  $self->{PID} = $inPID;
  $self->{startTime} = $inStartTime;
  $self->{thrashCount} = 0;
  $self->{name} = "IASConsole";
  $self->{initialized} = 1;

  $self->{debug} = $debugFlag if defined($debugFlag);

  return 1;
}

#
# status
# Checks the PID liveness test first and then uses the appropriate handler
# to check the about Page of the console
# Note: This gives the status of the console process only.
#
sub status
{
  my($self) = @_;
  
  if($self->{initialized})
  {
    # Time calc is costly, so it is better to check wether it is needed or not.
    if($TIME_BETWEEN_STATUS_CHECK != 0)
    {
      if($TIME_BETWEEN_STATUS_CHECK < 0)
      {
        # Status check is completely disabled ...
        return $STATUS_PROCESS_OK;
      }

      my($currTime) = time();
      my($timeSinceLastStatus) = $currTime - $self->{lastStatusCheckTime};

      if($timeSinceLastStatus < $TIME_BETWEEN_STATUS_CHECK)
      {
         return $STATUS_PROCESS_OK;
      }
      else
      {
         $self->{lastStatusCheckTime} = $currTime;
      }
    }

    my $rc;         
    $rc = 0xffff & system("$EMDROOT/bin/emdctl status url $self->{url} >$devNull 2>&1");
    $rc >>= 8;

    if( $rc eq 3 )  #IASConsole is UP and running...
    {
      $rc = $STATUS_PROCESS_OK;

      unless($self->{imageCacheInitialized})
      {
        $self->checkAboutPage();
        $self->{imageCacheInitialized} = 1;
      }
    }
    elsif( $rc eq 1 ) #IASCOnsole process is dead...
    {
      $rc = $STATUS_NO_SUCH_PROCESS;
    }
    elsif( $rc eq 2 ) #IASConsole is hanging ...
    {
      if ($self->{imageCacheInitialized})
      {
        $rc = $STATUS_PROCESS_HANG;
      }
      else
      {
        $rc = $STATUS_AGENT_NOT_READY;
      }
    }
    elsif( $rc eq 6 ) # emdctl internal error... print for debug purposes
    {
       print "## $EMDROOT/bin/emdctl status url $self->{url} returns internal error. \n";
       $rc = $STATUS_PROCESS_UNKNOWN;
    }
    else
    {
       print "## Status URL returned unknown status. Return Code : $rc.\n" if $self->{debug};
       $rc = $STATUS_PROCESS_UNKNOWN; #This should not happen...
    }
    return $rc;
  }
}

#
# stop
# Stops the Console.
# The only way we can currently stop the console
# is to kill it, if no ADMIN_PWD and ADMIN_PORT is supplied. 
#
sub stop
{
  my $self = shift;
  my $adminPassword = shift;
        
  if($self->{initialized})
  {
    my($tPid) = $self->{PID};

    unless( (kill 0, $self->{PID}) )
    {
      # On windows platform [NT 4.0 and Win2k, Perl 5.6's kill is flaky...
      if($IS_WINDOWS ne "TRUE")
      {
         return 0;
      }
    }

    my($timeInMillis) = time();
    my($pwdfile);

    open($pwdfile, "> $FORMFACTOR_FILE");
    print {$pwdfile} $timeInMillis;
    close($pwdfile);

    # redirect stdout/stderr; save old handles
    open(OLDOUT, ">&STDOUT");
    open(OLDERR, ">&STDERR");
    open(STDOUT, ">> stopIASConsole.out");
    open(STDERR, ">> stopIASConsole.out");

    my $rc;
    $rc = 0xffff & system("$JAVA_HOME/bin/java ".
                          "-Doracle.home=$FORMFACTOR_BASE -DOPMN=true ".
                          "-jar $ORACLE_HOME/j2ee/home/admin.jar ".
                          "ormi://localhost:$self->{rmiPort} ".
                          "ias_admin $adminPassword -shutdown force");

    $rc >>= 8;

    # delete the formfactor file now ...
    unlink ($FORMFACTOR_FILE);

    # close file with redirected output, restore old handles
    close(STDOUT);
    close(STDERR);
    open(STDOUT, ">&OLDOUT");
    open(STDERR, ">&OLDERR");

    # scan output file for exceptions, then remove
    open(EMOUT, "stopIASConsole.out");
    my $chkOut;
    while($chkOut = <EMOUT>)
    {
      if (index($chkOut, "AuthenticationException") >= 0)
      {
        print("Incorrect password provided\n");
        $rc = (1<<8);
        last;
      }
      if (index($chkOut, "ConnectException") >= 0)
      {
        print("Incorrect EM_ADMIN_PORT specified\n");
        $rc = (2<<8);
        last;
      }
      if (index($chkOut, "xception") >= 0)
      {
        print("Exception during shutdown\n");
        $rc = (3<<8);
        last;
      }
    }
    close(EMOUT);
    unlink ("stopIASConsole.out");

    if( $rc gt 0 ) # Returned with an error condition 
    {
        print "----- Failed to shutdown iASConsole Gracefully!.  -----\n";
        return $rc;
    }
    else
    {
      return $rc;
    }
  }
  else
  {
     return 1; # We should never be here...
  }
}

#
# gatherProcessStatistics
# Gathers process Statistics like Memory size etc
#
sub gatherProcessStatistics
{
  my($self) = @_;        
  if($self->{initialized})
  {
  }
}

#
# reInitialize
# Update after a restart, the PID and the start time are changed now
# and needs to be reflected.
# 
sub reInitialize
{
  my($self, $inPID, $inStartTime) = @_;        
  if($self->{initialized})
  {
     $self->{PID} = $inPID;
     $self->{startTime} = $inStartTime;
     $self->{imageCacheInitialized} = 0;
     $self->{lastStatusCheckTime} = 0;
     return 0;
  }
  else
  {
     return 1;
  }
}

sub setImageCacheInitialized
{
  my($self) = @_;        
  $self->{imageCacheInitialized} = 1;
}

#
# getThrashCount
# Returns the number of restarts that has occurred
#
sub getThrashCount
{
  my($self) = @_;        
  if($self->{initialized})
  {
     return $self->{thrashCount};
  }
  else
  {
     return -1;
  }
}

#
# setThrashCount
# Reset routine for the setThrashCount
#
sub setThrashCount
{
  my($self, $inThrashCount) = @_;
  if($self->{initialized})
  {
     $self->{thrashCount} = $inThrashCount;
     return 0;
  }
  else
  {
     return 1;
  }
}

#
# incThrashCount
# Increments the thrashCount by 1
#
sub incThrashCount
{
  my($self) = @_;
  if($self->{initialized})
  {
     $self->{thrashCount}++;
     return 0;
  }
  else
  {
     return 1;
  }
}



#
# getPID
# Returns the PID for the IASConsole
# 
sub getPID
{
  my($self) = @_;        
  if($self->{initialized})
  {
     return $self->{PID};
  }
  else
  {
     return -1;
  }
}

#
# getStartTime
# Returns the start time of the IASConsole
#
sub getStartTime
{
  my($self) = @_;        
  if($self->{initialized})
  {
     return $self->{startTime};
  }
  else
  {
     return -1;
  }
}

#
# getName
# Returns the Name
#
sub getName
{
  my($self) = @_;        
  if($self->{initialized})
  {
    return $self->{name};
  }
  else
  {
    return undef;
  }
}

#
# debug
# Provides the Debug functionality
#
sub debug
{
  my($self) = @_;        
  if($self->{initialized})
  {
     my($tPid) = $self->{PID};

     print "----- Attempting to kill $self->{name} : $tPid -----\n";

     if( kill 0, $tPid)
     {
       print "----- Attempting to dump threads for $tPid ----- \n";
       kill 3, $tPid;
       sleep 2;
       print "----- Attempting to dump threads for $tPid ----- \n";
       kill 3, $tPid;
       sleep 2;
       kill 9, $tPid;
     }

     return 0;
  }
}

#
# debugCore
# DebugCore is called when the monitor detects a core dump
# Parameter : CoreFile
#
sub debugCore
{
  my($self, $debugFile) = @_;        
  if($self->{initialized})
  {
  }
}

sub recycle
{
 return "FALSE";
}

sub okToRestart
{
 return "TRUE";
}


# checkAboutPage
# This subroutine pings the IASConsole, saves the resultant
# html page and then searches and gets the images. The resultant
# effect is that the Server image cache is initialized.

sub checkAboutPage
{
  my $self = shift;

  my($htmlPage) = $EMDROOT."/sysman/log/IASConsole_aboutApp.temp";
  my($rvalue, $imgString);
  my %imageList = ();

  $rvalue = 0xffff & system("$EMDROOT/bin/emdctl status url $self->{url} >$htmlPage 2>&1");
  $rvalue >>= 8;

  if($rvalue eq 3) # HTML page is up... we parse it for image
  {
    open(HTMLFILE, "<$htmlPage");
    while(<HTMLFILE>)
    {
      if(/img src/)
      {
        my(undef, $img) = split /img src="/, $_;
        ($img, undef) = split /" /, $img;
        ($img, undef) = split /">/, $img;
        if( ($img =~ /gif/) or ($img =~ /png/) )
        {
          my($urlTemp, undef) = split /\/emd/, $self->{url};
          $img = $urlTemp.$img;
          if (!defined ($imageList{$img}))
          {
            $imageList{$img} = 1;
          }
        }
      }
    }

    close (HTMLFILE);

    my @imageKeys = keys %imageList;
    while (@imageKeys)
    {
      $imgString = pop(@imageKeys);
      $rvalue = 0xffff & system("$EMDROOT/bin/emdctl status url $imgString >$devNull 2>&1");
      $rvalue >>= 8;
      if($rvalue ne 3)
      {
        print "---- Unable to load \{$imgString\}. Error code is $rvalue  ---- \n" if $self->{debug};
      }
    }
  }

  unlink ($htmlPage);
  return $rvalue;
}

#
# updatePort - takes desired port# and which port type as input
# if updating emd-web-site
#  updates emd-web-site.xml (see updateJ2eeConfigPort)
#  also updates targets.xml's StandaloneConsoleURL property for the ias instance
# if updating rmi port
#  updates rmi.xml (see updateJ2eeConfigPort)
#
sub updatePort
{
  my $self = shift;
  my $whichOne = shift;
  my $newPort = shift;
  my $inIasTarget = 0;
  my $emHome = getEMHome();
  my $newTargetsXml =  "${emHome}/sysman/emd/targets.xml.new";
  my $origTargetsXml = "${emHome}/sysman/emd/targets.xml";
  my $targetSnippet =  "${emHome}/sysman/emd/iasTargetMod.xml";
  my @iasTargetLines;
  my $rc = 0;

  $rc = checkFreePort($newPort);

  if ($rc eq 0)
  {
    updateJ2eeConfigPort($whichOne, $newPort);

    # if it's "port", we need to update StandaloneConsoleURL in targets.xml
    # [what about centrally managed??] 
    #  need to use TargetInstaller vs. direct update so changes propagate to central agent(s)
    # [what about collapsed console??]
    #  need to let DCM know to update its repository; still a bug?
    #
    if ($whichOne eq "port")
    {
      # test for targets.xml
      -e "$origTargetsXml" or die "Unable to find ${origTargetsXml} : $!\n";

      open(TARGETS, "< ${origTargetsXml}");
      my (@originalLines) = <TARGETS>;
      close (TARGETS);

      foreach $_ (@originalLines)
      {
        # find the oracle_ias target
        #
        if ($inIasTarget eq 0)
        {
          if(/^(.*Target TYPE="oracle_ias")/) # Search for oracle_ias target
          {
            # set flag, then grab lines til end-of-target
            $inIasTarget = 1;
            push(@iasTargetLines, $_);
            next;
          }
        }
        else
        {
          if (/^(.*StandaloneConsoleURL)/)
          {
            # grab everything up to & including the colon before the port
            # grab everything after the port
            # put it back together with the new port
            $_ =~ ~s/^(.*:)[0-9]+(\/.*)/$1${newPort}$2/;
          }
          push(@iasTargetLines, $_);
          if (/^(.*Target>)/)
          {
            last;
          }
        }
      }
      if (open(NEWFILE, ">", "${targetSnippet}"))
      {
        print (NEWFILE @iasTargetLines);
      }
      close (NEWFILE);
      # now need to call targetinstaller modify target...
      $rc = 0xffff & system("$JAVA_HOME/bin/java -jar ${emHome}/jlib/emConfigInstall.jar modifytarget ${targetSnippet} ${emHome}");
    }
  }
  print "Oracle 10g Application Server Control configuration update ";
  if ($rc eq 0)
  {
    print "succeeded.\n";
  }
  else
  {
    print "failed.\n";
  }
  exit $rc;
}

#
# updateJ2eeConfigPort - takes the indicator and desired port# as input
# updates the appropriate config file so the desired port, *if available*, is used
#
sub updateJ2eeConfigPort
{
  # which port (web-site port, RMI port) are we changing
  my $whichOne = shift;
  # what's the new number
  my $newPort = shift;

  my $emHome = getEMHome();
  my $configFile;

  if ($whichOne eq "port")
  {
    $configFile = "emd-web-site.xml";
  }
  elsif ($whichOne eq "rmiport")
  {
    $configFile = "rmi.xml";
  }
  # interim file being created
  my $newXml =  "$emHome/sysman/j2ee/config/${configFile}.new";
  my $origXml = "$emHome/sysman/j2ee/config/${configFile}";

  # test for required file
  -e "$origXml" or die "Unable to find ${origXml} : $!\n";

  open(XML, "< ${origXml}");
  my @originalLines = <XML>;
  close (XML);

  if (open(NEWFILE, ">", $newXml))
  {
    foreach $_ (@originalLines)
    {
      # the line we want to modify contains
      #  port="<portNumber>"
      #
      if(/^(.*port=)/) # Search for "port="
      {
        # capture the first part of the line (up to port="), 
        # throw away the number,
        # capture the remaining part,
        # then substitute the $newPort into the string
        $_ =~ ~s/^(.*port=")[0-9]*(".*)/$1${newPort}$2/;
        print (NEWFILE "$_");
        next;
      }
      print (NEWFILE $_);
    }
    close(NEWFILE);
    if (! rename $origXml, "${origXml}.bak.$$") 
    {
       die "Could not rename configuration file\n$!\n";
    }
    if (! rename $newXml, $origXml) 
    {
       die "Could not rename new configuration file\n$!\n";
    }
  }
}

1;
