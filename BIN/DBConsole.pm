#  $Header:
#
# Copyright (c) 2001, 2004, Oracle. All rights reserved.  
#
#    NAME
#      DBConsole.pm - Perl Module to provide start, stop, status functionality
#
#    DESCRIPTION
#       This script provides the stop,status,debug functionality for 
#       the emwd and the emctl. Additionally it may hold other
#       states like the start time, its PID, thrashCount etc.
#
#    MODIFIED   (MM/DD/YY)
#      blivshit  10/13/04 - merge for RLAL 
#      jsoule    09/17/04 - use kill for hard stop 
#      rlal      01/20/04 - change all to user
#      hmoreau   12/29/03 - Merge bug 3320420 with 3292158 
#      rlal      12/15/03 - Fix for bug 3320420 
#      rzazueta  12/17/03 - Increase sleep time in debug 
#      rzazueta  12/01/03 - Deprecate password to shutdown DBConsole 
#      dmshah    09/17/03 - Code review changes 
#      dmshah    09/15/03 - Integration testing changes 
#      dmshah    09/11/03 - Check for stack dump during stop 
#      dmshah    09/03/03 - Removing dependency on instantiated port settings 
#      dmshah    07/09/03 - Testing changes
#      dkapoor   07/07/03 - use admin instead of ias_admin
#      szhu      06/20/03 - Workaround for status()
#      vnukal    06/17/03 - adding okToRestart method
#      dmshah    05/08/03 - Obsoleting getProcList
#      dmshah    04/06/03 - dmshah_bug-2849086_mainsa
#      dmshah    04/08/03 - Removing hardcoded pid from stopSAC
#      dmshah    03/14/03 - Adding restart code
#      dmshah    03/13/03 - Adding incThrashCount
#      dmshah    03/11/03 - dmshah_em_watchdog
#      dmshah    03/06/03 - Using signal 0 for process liveness
#      dmshah    03/03/03 - Fixing constructor syntax
#      dmshah    03/03/03 - Testing if..else block
#      dmshah    02/26/03 - Created.
#

package DBConsole;
use strict;
use EmctlCommon;
use LWP::Simple;
use LWP::UserAgent;
use URI;

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
     emHome => getEMHome("dbconsole"),
     oc4jHome => getOC4JHome("dbconsole"),
     url => getWebUrl(getOC4JHome("dbconsole"), 
                      getEMHome("dbconsole"), "dbconsole"),
     rmiPort => getORMIPort( getOC4JHome("dbconsole") ),
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
  my ($self) = shift;
  my ($inPID) = shift;
  my ($inStartTime) = shift;
  my ($debugFlag) = shift;

  $self->{PID} = $inPID;
  $self->{startTime} = $inStartTime;
  $self->{thrashCount} = 0;
  $self->{name} = "DBConsole";
  $self->{initialized} = 1;

  $self->{debug} = $debugFlag if defined($debugFlag);

  if($self->{debug})
  {
    print "The following is set for the DBConsole : \n";
    print "OC4JHome : $self->{oc4jHome} \n";
    print "EMHome : $self->{emHome} \n";
    print "DBConsole URL : $self->{url} \n";
    print "ORMI Port : $self->{rmiPort} \n";
  }

  $self->{initialized} = 1;
  return 1;
}

#
# status
# Checks the PID liveness test first and then uses the appropriate handler
# to check the about Page of the console
#
sub status
{
  my($self) = @_;
  
  if($self->{initialized})
  {
    my $rc;
    $rc = 0xffff & system("$EMDROOT/bin/emdctl status url $self->{url} >$devNull 2>&1");
    $rc >>= 8;

    if( $rc eq 3 )  #DBConsole is UP and running...
    {
      $rc = $STATUS_PROCESS_OK;

      unless($self->{imageCacheInitialized})
      {
        print "## Connected to $self->{url}. Initializing image Cache. \n" if $self->{debug};
        $self->checkAboutPage();
        $self->{imageCacheInitialized} = 1;
      }
    }
    elsif( $rc eq 1 ) # DBConsole process is dead... No Connection by emdctl
    {
      $rc = $STATUS_NO_SUCH_PROCESS;
    }
    elsif( $rc eq 2 ) # DBConsole is hanging ... TIMEOUT from emdctl
    {
       $rc = $STATUS_PROCESS_HANG;
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
# Stops the Console
#
sub stop
{
  my $self = shift;
  my $password = shift;
        
  if($self->{initialized})
  {
    unless( (kill 0, $self->{PID}) )
    {
      #On windows platform [NT 4.0 and Win2k, Perl 5.6's kill is flaky...
      if($IS_WINDOWS ne "TRUE")
      {
         return 0;
      }
    }

    if($password eq undef)
    {
      print "--- DBConsole internal stop. No OC4J admin passwd hence hard stop. ---\n";
      if ($^O eq "linux")
      {
        my $proc = "";
        my @procs = `/bin/ps uxww | /bin/grep "$ORACLE_HOME/jdk/bin/java" | /bin/grep "DEMSTATE" | /bin/grep -v grep`;
        foreach $proc (@procs)
        {
          my @parts = split ( /\s+/ , $proc );
          kill 9, $parts[1];
        }
      }
      else
      {
        kill 9, $self->{PID};
      }
      return 0;
    }
    else
    {
      my($timeInMillis) = time();
      my($pwdfile);

      open($pwdfile, "> $FORMFACTOR_FILE");
      print {$pwdfile} $timeInMillis;
      close($pwdfile);

      # redirect stdout/stderr; save old handles
      open(OLDOUT, ">&STDOUT");
      open(OLDERR, ">&STDERR");
      open(STDOUT, ">> $self->{emHome}/sysman/log/stopDBConsole.out");
      open(STDERR, ">> $self->{emHome}/sysman/log/stopDBConsole.out");

      print "## Stopping DBConsole on ormi port : $self->{rmiPort}. \n";

      my $rc;
      $rc = 0xffff & system("$JAVA_HOME/bin/java -jar ".
                            "-Doracle.home=$FORMFACTOR_BASE -DOPMN=true ".
                            "-Djava.net.preferIPv4Stack=true ".
                            "$ORACLE_HOME/$OC4JLOC"."j2ee/home/admin.jar ".
                            "ormi://localhost:$self->{rmiPort} admin ".
                            "$password -shutdown force");

      $rc >>= 8;

      # delete the formfactor file now ...
      unlink ($FORMFACTOR_FILE);

      # close file with redirected output, restore old handles
      close(STDOUT);
      close(STDERR);
      open(STDOUT, ">&OLDOUT");
      open(STDERR, ">&OLDERR");

      # scan output file for exceptions, then remove
      open(EMOUT, "stopDBConsole.out");
      while(<EMOUT>)
      {
        if (index($_, "AuthenticationException") >= 0)
        {
          print("Incorrect password provided\n");
          $rc = (1<<8);
          last;
        }
        if (index($_, "ConnectException") >= 0)
        {
          print("Incorrect EM_ADMIN_PORT specified\n");
          $rc = (2<<8);
          last;
        }
        if (index($_, "xception") >= 0)
        {
          print("Exception during shutdown\n");
          $rc = (3<<8);
          last;
        }
      }
      close(EMOUT);
      unlink ("$self->{emHome}/sysman/log/stopDBConsole.out") unless $self->{debug};

      print "--- Failed to shutdown DBConsole Gracefully --- \n" if( $rc gt 0 ); # Error during shutdown

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
     return 0;
  }
  else
  {
     return 1;
  }
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
# Returns the PID for the DBConsole
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
# Returns the start time of the DBConsole
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
       sleep 10;
       print "----- Attempting to dump threads for $tPid ----- \n";
       kill 3, $tPid;
       sleep 10;
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


#checkAboutPage
#This subroutine pings the DBConsole, saves the resultant
#html page and then searches and gets the images. The resultant
#effect is that the Server image cache is initialized.

sub checkAboutPage
{
  my $self = shift;

  my($htmlPage) = $self->{emHome}."/sysman/log/aboutAppPage_dbconsole.temp";
  my($rvalue);

  $rvalue = 0xffff & system("$EMDROOT/bin/emdctl status url $self->{url} >$htmlPage 2>&1");
  $rvalue >>= 8;

  if($rvalue eq 3) #HTML page is up... we parse it for image
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
           my($urlTemp, undef) = split /\/em/, $self->{url};
           $img = $urlTemp.$img;

           $rvalue = 0xffff & system("$EMDROOT/bin/emdctl status url $img >$devNull 2>&1");
           $rvalue >>= 8;

           if($rvalue ne 3)
           {
              print "## Unable to load $img on $self->{url}. Error code returned is $rvalue \n" if $self->{debug};
              last;
           }
         }
       }
     }

     close (HTMLFILE);
  }

  unlink ($htmlPage);
  return $rvalue;
}

sub setImageCacheInitialized
{
;
}


sub DESTROY {
    my $self = shift;
}


1;
