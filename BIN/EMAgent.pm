#  $Header:
#
# Copyright (c) 2001, 2004, Oracle. All rights reserved.  
#
#    NAME
#      EMAgent.pm - Perl Module to provide start, stop, status functionality
#
#    DESCRIPTION
#       This script provides the stop,status,debug functionality for 
#       the emwd and the emctl. Additionally it may hold other
#       states like the start time, its PID, thrashCount etc.
#
#    MODIFIED   (MM/DD/YY)
#      vnukal    10/22/04 - optimizing nmupm launch 
#      smpbuild  09/21/04 - 
#      njagathe  09/16/04 - Reintroduce Solaris changes 
#      aaitghez  07/20/04 - mbhoopat_linux_port_1 fix 
#      jsutton   05/18/04 - Allow port config 
#      rzkrishn  03/15/04 - going back to emdctl 
#      rzkrishn  03/12/04 - Recycle functionality on windows
#      aaitghez  02/27/04 - bug 3358285. Retry on agent status in certain
#      rlal      01/20/04 - kill hung threads
#      rlal      01/12/04 - recycle changes for Linux 
#      rzkrishn  12/23/03 - review changes 
#      rzkrishn  12/22/03 - compute memIncrease 
#      rzkrishn  10/08/03 - remove extra cores. 
#      gachen    10/06/03 - redirect stderr in debug 
#      gachen    09/24/03 - generate core in mainsa 
#      dmshah    09/15/03 - 
#      dmshah    09/15/03 - Integration testing changes 
#      dmshah    09/11/03 - Adding Debug flag 
#      gachen    09/17/03 - add pfile/pstack/lsof to EMAgent 
#      vnukal    08/13/03 - fixing leading whitespace of ps o/p 
#      vnukal    08/07/03 - modify ps args to hit correct emagent 
#      rzkrishn  07/23/03 - get core always when hung
#      rzkrishn  07/22/03 - agent tells watch dog to act same as for HANG in abnormal state
#      dmshah    07/08/03 - Bug fixes from 401 branch
#      vnukal    06/17/03 - adding okToRestart method
#      dmshah    04/06/03 - dmshah_bug-2849086_mainsa
#      dmshah    03/20/03 - Only way to kill is SIGKILL
#      dmshah    04/02/03 - grabtrans 'dmshah_fix_2849086_2'
#      dmshah    03/14/03 - Adding restart code
#      dmshah    03/13/03 - Bug fix 2849086 and moving PERL BIN
#      dmshah    03/11/03 - dmshah_em_watchdog
#      dmshah    03/09/03 - Making emctl start em compatible for VOBs
#      dmshah    03/06/03 - Adding debug core file logic
#      dmshah    03/03/03 - Fixing constructor syntax
#      dmshah    03/03/03 - Testing if..else block
#      dmshah    02/26/03 - Created.
#

package EMAgent;
use strict;
use EmctlCommon;
use LWP::Simple;

sub new
{
  my ($class) = @_;
  my $self =
  {
     PID => -1,
     name => undef,
     startTime => -1,
     thrashCount => 0,
     initialized => 0,
     printCounter => 0,
     lastMemChkTime => 0,
     emHome => getEMHome("agent"),
     debug => 0,
     prevMemSize => 0
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
  $self->{name} = "EMAgent";
  $self->{initialized} = 1;
  $self->{printCounter} = 0;
  $self->{lastMemChkTime} = 0;
  $self->{prevMemSize} = 0;

  $self->{debug} = $debugFlag if defined($debugFlag);

  return 1;
}

#
# status
# Checks the PID liveness test first and then uses the appropriate handler
# to check the about Page of the agent
#
sub status
{
  my($self) = @_;

  if($self->{initialized})
  {
    my $rc = 2;
    my $numStatusRetries = $NUMBER_AGENT_STATUS_RETRIES;
    while(($numStatusRetries > 0) &&
           (($rc eq 4) ||
           ($rc eq 7) ||
           ($rc eq 2)))
    {
        $rc = 0xffff & system("$EMDROOT/bin/emdctl status agent ".
                              " $EMD_HANG_CHECK_STATUS_TIME >$devNull 2>&1");
        $rc >>= 8;
        $numStatusRetries = $numStatusRetries - 1;
    }

    if( $rc eq 3 )   #emAgent is UP and running...
    {
      $rc = $STATUS_PROCESS_OK;
    }
    elsif( $rc eq 4 )  #emAgent is UP but not ready... 
    { 
      $rc = $STATUS_AGENT_NOT_READY;
    }
    elsif( $rc eq 1 ) #emAgent process is dead...
    {
      $rc = $STATUS_NO_SUCH_PROCESS;
    }
    elsif( $rc eq 2 ) #emAgent is hanging ...
    {
       $rc = $STATUS_PROCESS_HANG;
    }
    elsif( $rc eq 7 ) #emAgent is in abnormal state ...
    {
       $rc = $STATUS_AGENT_ABNORMAL;
    }
    else
    {
       $rc = $STATUS_NO_SUCH_PROCESS; # This should not happen...
    }

    return $rc;
  }
}

#
# stop
# Stops the Agent
#
sub stop
{
  my($self, $tries) = @_;
        
  if($self->{initialized})
  {
   # Relying on the fact that emdctl status never fails...     
   system("$EMDROOT/bin/emdctl stop agent >$devNull 2>&1 &");
   
   my $rc;
   if ($tries eq undef )
   {
      $tries = 30;
   }

   while( $tries gt 0 )
   {
      $tries--;

      $rc = 0xffff & system("$EMDROOT/bin/emdctl status agent ".
            " $EMD_HANG_CHECK_STATUS_TIME >$devNull 2>&1");
      $rc >>= 8;

      if ($rc lt 2) # Agent stop succeeded...
      {
         last; 
      }
      
      if($tries gt 0)
      {
         sleep 1;
      }
   }

   if($rc ge 2) # Agent is still running
   {
     print "----- Failed to stop agent! -----\n";
     print "----- Attempting to kill $self->{name} : $self->{PID} -----\n";
     kill 9, $self->{PID}; # Force a SEGKILL ...
   }
   
   return $rc;
   
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
     $self->{printCounter} = 0;
     $self->{lastMemChkTime} = 0;
     $self->{prevMemSize} = 0;
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
    my ($tPid) = $self->{PID};
    my $EMHOME = $self->{emHome};

    my ($coreFile) = $EMHOME."/sysman/emd/core.hung.".$tPid;
    my ($coreFile2) = $coreFile;
    my ($gcorecmd)="/bin/gcore -o ".$EMHOME."/sysman/emd/core.hung ".$tPid;
    if($^O eq "MSWin32")
    {
      $coreFile = $EMDROOT . "/sysman/emd/emagent.dmp";
      $coreFile2 = $EMHOME . "/sysman/emd/core.hang." . $tPid;
      $gcorecmd  = $EMDROOT ."\\bin\\userdump.exe ". $tPid;
    }

    #
    # generate gcore 
    #
    print "----- ".localtime()."::generate first core file $coreFile for diagnosis -----\n";
    system("$gcorecmd");

    my($currTime) = time();

    if( -e $coreFile )
    {
      rename $coreFile, $coreFile2."_".$currTime;
    }

    #
    # sleep 10 seconds.
    #
    sleep 10;

    #
    # generate second gcore
    #
    print "----- ".localtime()."::generate second core file $coreFile for diagnosis -----\n";
    system("$gcorecmd");

    if( -e $coreFile )
    {
      rename $coreFile, $coreFile2."_".$currTime . "_10s_after" ;

      if($^O ne "MSWin32")
      {
        $self->debugCore( $coreFile2."_".$currTime);
      }
    }

    #
    #  generate lsof to see the fd usage
    #
    if($^O ne "MSWin32")
    {
      print "----- ".localtime()."::generate $coreFile.lsof.1 for diagnosis -----\n";
      system("/usr/local/bin/lsof -p $tPid > $coreFile.lsof.1 2>&1");
    }

    print "----- Attempting to kill $self->{name} : $self->{PID} -----\n";
    if ( $^O eq "linux" )
    {
	# On Linux the threads of a process are represented as separate
	# processes on the OS, so we need to kill all the threads
	# which are obtained using ps.
	my(@procs) = `/bin/ps uxww`;
	my $proc = "";
	my $binary = $EMDROOT."/bin/emagent";
	foreach $proc (@procs)
	{
	  if ( $proc =~ m/$binary/ )
	  {
		my @cols = split ( /\s+/ , $proc );
		kill 9, $cols[1]; # Force a SEGV ...
	  }
	}
     }
     else
     {
	kill 9, $self->{PID}; # Force a SEGV ...
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
    my($GDB) = "/usr/bin/gdb";
    my($DBX) = "/opt/SunProd/SUNWspro6.1/bin/dbx";

    if( -e $GDB )
    {
      my($traceBack) = $debugFile.".traceback";
      my($threads) = $debugFile.".threads";
      my($tempFile) = $debugFile.".tmp";
      my ($EMHOME) = $self->{emHome};

      #Delete old core files if neccessary
      deleteExtraAgentCores($EMHOME); 

      # Create a tempFile for inputting dbx commands ...
      system("echo where > $tempFile");
      system("echo info threads >> $tempFile");
      system("echo quit >> $tempFile");

      system("$GDB $EMDROOT/bin/emagent $debugFile <$tempFile > $traceBack 2>&1");
   
      # Need to glob the threads file to dbx individual threads
      unlink("$tempFile");
    }
    elsif( -e $DBX )
    {
      my($traceBack) = $debugFile.".traceback";
      my($threads) = $debugFile.".threads";
      my($tempFile) = $debugFile.".tmp";
      my ($EMHOME) = $self->{emHome};

      #Delete old core files if neccessary
      deleteExtraAgentCores($EMHOME); 

      # Create a tempFile for inputting dbx commands ...
      system("echo === > $tempFile");
      system("echo where >> $tempFile");
      system("echo === >> $tempFile");
      system("echo threads >> $tempFile");
      system("echo === >> $tempFile");
      system("echo exit >> $tempFile");

      system("$DBX $EMDROOT/bin/emagent $debugFile <$tempFile > $traceBack 2>&1");
   
      # Just get the threads again ...
      system("echo threads > $tempFile");
      system("$DBX $EMDROOT/bin/emagent $debugFile <$tempFile > $threads 2>&1");

      # Now get the debug per thread ...
      my (@perthreadinfo, @threadColumns, @threadNums);
      open (THREADFILE, $threads);
      while (<THREADFILE>)
      {
        my($line) = $_;
        chomp($line);

        if($line =~ /t@/)
        {
          if( $line =~ /idle/)
          {
            next;
          }
          else
          {
            @threadColumns = split(/@/, $line);
            @threadNums = split(/\s+/, @threadColumns[1]);
            push @perthreadinfo, $threadNums[0];
          }
        }
        else
        {
          next;
        }
      }

      close(THREADFILE);
      foreach (@perthreadinfo)
      {
        my($string) = "thread t@".$_;
        system("echo ============================================================================ > $tempFile");
        system("echo           $string >> $tempFile");
        system("echo ============================================================================ >> $tempFile");
        system("echo $string >> $tempFile");
        system("echo where >> $tempFile");
        system("echo >> $tempFile");
        system("echo ====== >> $tempFile");
        system("echo thread -blocks >> $tempFile");
        system("echo >> $tempFile");
        system("echo ====== >> $tempFile");
        system("echo thread -blockedby >> $tempFile");
        system("echo >> $tempFile");
        system("echo >>$tempFile");

        system("$DBX $EMDROOT/bin/emagent $debugFile <$tempFile >> $traceBack 2>&1");
      }
      # Need to glob the threads file to dbx individual threads
      unlink("$tempFile");
    }
  }
}

#
# Delete extra cores.
#
sub deleteExtraAgentCores 
{
  my ($agentHome) = @_[0];
  my ($deletecores) = $agentHome."/sysman/emd/deletecores.tmp";
  my (@lines) ;
  my (@files) ;
  my ($count)  = 0;
  my ($LS) = "/bin/ls";
  
  if ( -e $LS ) 
  {
    # defaulting to 3 cores(core + .threads+.traceback)
    my ($maxCores) = 9; 
 
    if (defined($ENV{EMAGENT_MAX_CORES}))
    {
      $maxCores = $ENV{EMAGENT_MAX_CORES};
      $maxCores = $maxCores * 3;
    }

    @files = system ("$LS -tr $agentHome/sysman/emd/core_* > $deletecores" );
    
 
    open (DELETECORES, $deletecores);
 
    while (<DELETECORES>)
    {
      chomp($_);
      push @lines, $_;
      $count++;
    }
    close (DELETECORES);
    unlink("$deletecores");
 
    if ( ($count + 2) <= $maxCores ) 
    {
      return;
    }
    else
    {
      my ($deleteCount) = $count + 2 - $maxCores;  
 
      while ($deleteCount > 0)
      {
        unlink(@lines[$deleteCount-1]);
        $deleteCount --;
      }
    }
  }
}

#
# recycle
# Checks wether the current process requires a recycle or not.
# 
sub recycle
{
  my($self) = @_;        
  if($self->{initialized})
  {
    my($recycleInterval,$recycleSecs);
    my($memCheckInterval) = $EMAGENT_MEMCHECK_HOURS * 3600;
    my($currTime) = time();
    my($implemented) = 0;
    my($pid) = 0;
    my($vmSize) = 0;

    $recycleSecs = 3600/$EMAGENT_TIMESCALE;
    $recycleInterval = $EMAGENT_RECYCLE_DAYS * 24 * $recycleSecs;

    # Restart the agent every $EMAGENT_RECYCLE_DAYS. Default is never
    if($recycleInterval > 0 )
    {
      my($timeSinceStart) = $currTime - $self->{startTime};
      if($timeSinceStart > $recycleInterval)
      {
        my($timeSinceStart_hour) = $timeSinceStart / 3600;
        print "--- Recycling process. Up for $timeSinceStart_hour hours ---\n";
        return "TRUE";
      }
    }

    if($memCheckInterval == 0)
    {
       return "FALSE";
    }

    if($self->{lastMemChkTime} == 0)
    {
       $self->{lastMemChkTime} = $currTime;
       $self->{prevMemSize} = $vmSize;
       return "FALSE";
    }
      
    my($timeSinceLastCheck) = $currTime - $self->{lastMemChkTime};
    if($timeSinceLastCheck < $memCheckInterval)
    {
      return "FALSE";
    }
    $self->{lastMemChkTime} = $currTime;
    
    $pid = $self->{PID};

    if(($^O eq "SunOS") or ($^O eq "solaris") or ($^O eq "linux"))
    {
      my($tpid,$pvmSize) = 
                        (`ps -p $pid -o "pid,vsz"`)[1] =~ m/(\w+)\s+(\w+)/g;
            
      return "FALSE" if($pid != $tpid);

      chomp($pvmSize);
                                                                                                                
      $vmSize = $pvmSize;
 
      $implemented = 1;
    }
    elsif (($^O eq "MSWin32") or ($^O eq "Windows_NT"))
    {
      my($result) = (`$EMDROOT/bin/nmupm procInfo $pid`);

      my($tpid,$cpu,$pvmSize,$resmSize,$remain) = split(/\|/, $result, 5);

      chomp($pvmSize);

      $vmSize = $pvmSize;

      $implemented = 1;
    }

    if ($implemented == 1)
    {
      $vmSize = $vmSize/1024; # Change to MB

      if( $vmSize > $EMAGENT_RECYCLE_MAXMEMORY )
      {
        my $memIncrease = $vmSize - $self->{prevMemSize} ;
        if ($memIncrease > $EMAGENT_MAXMEM_INCREASE) 
        {
	  print "--- Recycling process. VMSize is $vmSize MB ---\n";
          return "TRUE";
        }
      }	
    }
  }
  return "FALSE";
}


#
# okToRestart
# Determines if sufficient resources or conditions exist for the component
# to be started
# 
sub okToRestart
{

  my($self) = @_;
  if($self->{initialized})
  {
    if(($^O eq "SunOS") or ($^O eq "solaris")) {

      my $rc;
    
      # agentok script returns 0 when it is Ok to start the agent. Non-zero
      # return code otherwise.  
      $rc = 0xffff & system("$EMDROOT/bin/agentok.sh >$devNull 2>&1");
      $rc >>= 8;

      if($rc != 0) # Insufficient resources exist.
      {
	if (($self->{printCounter} % 120) == 0) {
	  print "---- Insufficient resources exist to restart agent -----\n";
          $self->{printCounter} = 0;
	}
	$self->{printCounter} ++;
        return "FALSE";
      }
    }
  }
  else
  {
    return undef;
  }

  return "TRUE";
}

#
# updatePort - takes desired port# as input
# updates emd.properties so EMD_URL has that port, *if available*
#
sub updatePort
{
  my $self = shift;
  my $newPort = shift;
  my $emHome = getEMHome();
  my $newUrl = "";
  my $newProperties =  "$emHome/sysman/config/emd.properties.new";
  my $origProperties = "$emHome/sysman/config/emd.properties";
  my $rc = 0;

  $rc = checkFreePort($newPort);

  if ($rc eq 0)
  {
    -e "$origProperties" or die "Unable to locate $origProperties : $!\n";
    open(EMDPROPERTIES, "< $origProperties");
    my @originalLines = <EMDPROPERTIES>;
    close (EMDPROPERTIES);

    if (open(NEWFILE, ">", $newProperties))
    {
      foreach $_ (@originalLines)
      {
        if(/^(\s*EMD_URL)/) # Search for EMD_URL...
        {
          my (undef, $value) = /([^=]+)\s*=\s*(.+)/;
          my ($protocol,$machine,$port) = /([^:]+):\/\/([^:]+):([0-9]+)\/.*/, $value;
          $newUrl = $protocol."://".$machine.":".$newPort."/emd/main/";
          print (NEWFILE "$newUrl");
          next;
        }
        print (NEWFILE $_);
      }
      close(NEWFILE);
      if (! rename $origProperties, "${origProperties}.bak.$$") 
      {
         die "Could not rename properties file\n$!\n";
      }
      if (! rename $newProperties, $origProperties) 
      {
         die "Could not rename new properties file\n$!\n";
      }
    }
  }
  print "Oracle Enterprise Manager 10g Agent configuration update ";
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

1;
