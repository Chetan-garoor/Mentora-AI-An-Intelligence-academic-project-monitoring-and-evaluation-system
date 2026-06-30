#  $Header:
#
#
# Copyright (c) 2001, 2005, Oracle. All rights reserved.  
#
#    NAME
#      emwd.pl - Perl script to provide the watchdog functionality for 
#                the Consoles and the agent
#
#    DESCRIPTION
#       This script provides the Process Monitor functionality for 
#       the console and the agents
#
#    USAGE
#      emwd <COMPONENT> <NOHUP FILENAME>
#      where the 
#        <COMPONENT> : Is either iASConsole or DBConsole or EMAgent 
#        <NOHUP>   : Is the nohup destination for the Command
#
#     Process Monitoring functionality
#      The process monitoring functionality is a two step process.
#      Step 1 : Check for the existence of the Process ID from the PID FILE. 
#               If success go to Step 2
#      Step 2 : Check for the "liveness" of the Process. 
#               The "liveness" is accomplished as follows :
#               a. If iASConsole or DBConsole
#                  Do HTTP get aboutApplication URL. 
#                   If succeed, process is alive go check for agent liveness 
#                   else step 3
#                  Do emdctl status agent. If agent is down go to step 4
#               b. if emagent
#                  Do emdctl status agent. If agent is down go to step 5.
#      Step 3 : Means that the console is down, agent status unknown[up or down]
#               Reap the child console process [using non-block waitpid]
#                   If normal exit, then we stop agent and exit...
#               If not normal exit...
#               Check for Console Thrashing. 
#               If not thrashing....
#                  Start Console.
#               If thrashing,
#                  bring both console+agent down
#                  exit
#      Step 4 : Means that the agent is down, console status unknown[up or down]
#               Reap the child agent process [using non-block waitpid]
#                       If normal exit, then we stop[kill] console[?] and exit..
#               If not normal exit...
#               Check for agent Thrashing. If not thrashing....
#                  Start Agent
#               If thrashing,
#                  bring both agent+console down.
#                  exit
#      Step 5 : Means that we care only about agent
#               Check for Thrashing. If not thrashing....
#               Start agent if down and the child reaper indicates abnormal exit.
#      Thrashing : If any process has to be restarted more than 3 times in last 10 minutes, it is thrashing.
#                  We will keep separate counters for iASConsole+agent, DBConsole+agent, agent only
#
#      Startup
#       If the Command is either iASConsole or DBConsole,
#          
#       emctl kicks off emwd for the appropriate processes [agent+Console] or 
#                                                          [agent]
#       
#       Then falls into the watchdog loop...
#
#       Starting Console+Agent
#
#             Check wether Console+Agent is running [emctl part]
#             If [Console+Agent] Running,
#                Ask to restart.
#                If restart
#                   Shutdown Console+Agent, restart Console+Agent
#               
#            If [Console only] or [Agent only] Running 
#             Ask to restart. 
#                If restart
#                   Shutdown Console+Agent, restart Console+Agent
#
#      Stop
#       emwd exits out of the loop when any child process exits normally....
#
#    MODIFIED   (MM/DD/YY)
#      vkapur    04/26/05 - fix bug 4330879 
#      vkapur    04/11/05 - fix bug 4150933 
#      blivshit  01/06/05 - raise maxPermSize for 10.1 also 
#      blivshit  01/05/05 - up the maxPermSize for Dana Joly's lrg tests 
#      kduvvuri  12/03/04 - RFI 3811245. 
#      njagathe  11/10/04 - Deal with other corefile name 
#      blivshit  10/21/04 - lower java usage to 256 meg, per werner's request 
#      vkapur    10/14/04 - retrieve OMS_RECV_DIR_SET in startDBConsole() 
#      vkapur    10/11/04 - ER 3406918: determine if oms is configured locally 
#                           before starting (dbconsole only) 
#      smpbuild  09/02/04 - alawler -- replace with ple element 
#      dkapoor   08/24/04 - fix bug#3802284 
#      aaitghez  02/27/04 - bug 3358285. For agent component, don't hang if 
#                           status takes long time 
#      mbhoopat  12/21/03 - Fix bug 3120377 
#      rzazueta  12/16/03 - Add hang detection timeout 
#      rzazueta  12/01/03 - Deprecate password to shutdown DBConsole 
#      kduvvuri  11/20/03 - accept time zones of the form [+,-]HH:MM 
#      kduvvuri  11/06/03 - check for supportedTZ, only if REPOSITORY_URL is 
#                           present.
#      rzazueta  11/05/03 - Fix bug 3164505: Deprecate password to shutdown IASConsole
#      gachen    11/05/03 - check rc before call reap again 
#      gachen    11/04/03 - 3227492: restart agent when hang
#      vnukal    10/15/03 - isalive on NT 
#      vnukal    10/14/03 - WIN:defaulting exitCode in reapChild 
#      njagathe  10/10/03 - Also check for process status 
#      njagathe  10/10/03 - Fix for bug 3006402 
#      kduvvuri  10/07/03 - change the location of supportedtzs.lst to 
#                           $ORACLE_HOME/sysman/admin.
#      rzazueta  09/28/03 - Fix bug 3164310 
#      dmshah    09/17/03 - 
#      dmshah    09/17/03 - Code review changes 
#      dmshah    09/15/03 - 
#      dmshah    09/15/03 - Integration testing changes 
#      dmshah    09/11/03 - Check for stack dump during stop 
#      dmshah    09/09/03 - 
#      kduvvuri  08/19/03 - fix bug 3099682. Update emd.properties in EMHOME 
#                           insteaad of ORACLE_HOME 
#      kduvvuri  07/28/03 - fix updateTZ. bug 2994615
#      kduvvuri  07/24/03 - exit, if can't determine the time zone region.
#      rzkrishn  07/22/03 - Agent telling watch dog to behave for its abnormal state as in HANG
#      dmshah    07/21/03 - internal command syntax to start agent is "agent"
#      dmshah    07/18/03 - Fixing save of PID on NT
#      dmshah    07/08/03 - Adding NT svc hookup for emctl/emwd
#      kduvvuri  07/08/03 - make a backup copy of emd.properties before 
#                           updating it with  'agentTZRegion'
#      kduvvuri  07/08/03   before lauching the agent search 
#                           emd.properties for the property agentTZRegion,
#                           if it not present update it with the value 
#                           obtained thru JAVA api  
#      dmshah    06/25/03 - Modifying emwd.pl for NT
#      szhu      06/18/03 - MAINSA setup on NT
#      vnukal    06/17/03 - adding okToRestart method
#      hsu       06/13/03 - add mem param
#      njagathe  06/12/03 - Create last run copy of nohup
#      dmshah    05/16/03 - grabtrans 'dmshah_fix_emagentdeploy_beta1'
#      dmshah    05/14/03 - 
#      dmshah    05/14/03 - For CFS-RAC, need to specify the jsputilloc
#      dmshah    05/06/03 - Adding extra property EMSTATE for CFS
#      dkapoor   04/25/03 - impl dynamic deploy
#      dmshah    04/17/03 - No thrashcount increment on process initiated restart
#      dmshah    04/08/03 - Modifying the startup for CFS
#      dmshah    04/06/03 - Fixing implicit shell launch
#      dmshah    04/02/03 - Adding func for monitoring dbConsole
#      dmshah    04/02/03 - grabtrans 'dmshah_fix_oc4j_startup'
#      rpinnama  04/02/03 - rpinnama_bug-2835783_main
#      dmshah    04/07/03 - Review comments
#      dmshah    04/07/03 - Removing shell specific metacharacters while launching console
#      rpinnama  03/31/03 - Add -Djava.awt.headless while starting SA console
#      dmshah    03/28/03 - Additional timeout parameter for first time startup
#      dmshah    03/20/03 - Only way to kill is SIGKILL
#      dmshah    04/02/03 - grabtrans 'dmshah_fix_2849086_2'
#      dmshah    03/18/03 - Adding separate print routine for core dump messages
#      jsutton   03/14/03 - Disco needs java2.policy
#      dmshah    03/13/03 - Bug fix 2849086 and moving PERL BIN
#      dmshah    03/11/03 - dmshah_em_watchdog
#      dmshah    03/10/03 - Adding extra print statements for tvmaq logs
#      dmshah    03/09/03 - Making emctl start em compatible for VOBs
#      dmshah    03/06/03 - Using signal 0 for process liveness
#      dmshah    03/03/03 - Correcting the nohup file locations
#      dmshah    03/03/03 - Fixing restartonHang
#      dmshah    02/26/03 - Adding code for monitoring processes
#      dmshah    02/19/03 - Created.

use LWP::Simple;
use POSIX ":sys_wait_h"; # This gives us waitpid. 
use EmctlCommon;
use EMAgent;
use IASConsole;
use DBConsole;
use Config;
use POSIX ;
use File::Copy cp;
use File::Temp qw/ tempfile /;

my @signame; # This is the signal table...
$EMAGENT_DONT_RESTART=55;

# Set up the signal table ...
# This does not seem to work...
# defined $Config{sig_name} || die "No sigs?";
# foreach $name (split(' ', $Config{sig_name})) 
# {
# 	$signame[$i] = $name;
# 	$i++;
#}


# Process states for the child processes ...
$PROCESS_OK=0;           # Process is okay [alive]
$PROCESS_EXIT_NORMAL=1;  # Process has exited normally...
$PROCESS_EXIT_SIGNAL=2;  # Process has exited due to signal
$PROCESS_DUMPED_CORE=3;  # Process has dumped core...

$CONSOLE_START_TIME = 0;
$AGENT_START_TIME = 0;

$EMWD_MONITOR_WAIT_TIME=30;

# Resolving the input command string ....
# Usage : perl emwd [iASConsole|DBConsole|emAgent] <nohup file>
# The input command string ...
my @COMMAND_STR=@ARGV;
my $COMMAND = lc($COMMAND_STR[0]);

my $EM_OC4J_HOME=getOC4JHome($COMMAND);
$EMHOME=getEMHome($COMMAND);

printDebugMessage("emwd has resolved the Homes to $EM_OC4J_HOME and $EMHOME");

my ($STARTUP_TIMEOUT, $HANG_DETECTION_TIMEOUT) = getTimeouts($EMHOME);

# On WinNT, this file records the exitStatus [pseudo] of the child process.
my $EXITFILE=$EMHOME."/sysman/log/exitStatus_".$COMMAND;
unlink($EXITFILE);

# Assign NOHUP_FILE if not part of the command string ...
if ($NOHUP_FILE eq "")
{
  if($COMMAND eq "iasconsole")
  {
    $NOHUP_FILE = $IAS_NOHUPFILE;
  }
  elsif( $COMMAND eq "dbconsole")
  {
    $NOHUP_FILE = $DB_NOHUPFILE;
  }
  else
  {
    $NOHUP_FILE = $AGENT_NOHUPFILE;
  }
}

printDebugMessage("Nohup file for output is $NOHUP_FILE");

open(NOHUPFILE, ">>$NOHUP_FILE") || die "Could not write to $NOHUP_FILE \n";
select(NOHUPFILE);
$|=1; # Set AUTOFLUSH on

open(STDOUT, ">> $NOHUP_FILE"); # Redirect the stdout & stderr to nohup
open(STDERR, ">> $NOHUP_FILE");

if($COMMAND eq "iasconsole")
{
  startIASConsole();
}
elsif($COMMAND eq "dbconsole")
{
  startDBConsole();
}
elsif($COMMAND eq "agent")
{
  startCEMD();
}
else
{
    # print "$COMMAND, $NOHUP_FILE, $PID_FILE \n";
}

close(NOHUPFILE);
# We are falling out of main...
exit;


#
# startIASConsole. 
# Launches the console and falls into monitor process loop
#

sub startIASConsole()
{
    my (@agentPID, @consolePID, @consoleRow, @agentRow, @referenceTable, $emAgent, $console, $temp);

    printMessage("iASConsole. Monitoring Agent+Console");
    
    # launches and stats the Console Process.
    # Returns Return PID[0], Start time[2]....
    $temp = launchIASConsole();
    @consolePID = @$temp;
    
    # Initialize the console object ...
    $console = new IASConsole();
    $console->Initialize($consolePID[0], $consolePID[1], $DEBUG_ENABLED);
   
    if( $IN_VOB ne "TRUE")
    {
      # Launches and stats the Agent Process.
      # Returns array. PID [0], Start Time [1].
      $temp = launchAgent();
      @agentPID = @$temp;

      # Initialize the emagent object....    
      $emAgent = new EMAgent();
      $emAgent->Initialize($agentPID[0], $agentPID[1], $DEBUG_ENABLED);
    
      # The starting reference table for the monitor is as follows :
      # Component'sObjectReference    RestartHandler()
      # console                       launchIASConsole
      # emagent                       launchAgent
      #
      # NOTE : ANY ADDITION OR SUBTRACTION OF COLUMNS TO 
      # THE ABOVE NEED TO BE REFLECTED IN $NUM_COLS variable below

      # Create component row with the component object and the restart handler..
      @consoleRow = ($console, \&launchIASConsole);
      @agentRow = ($emAgent, \&launchAgent);
                 
      # Stuffit in the table and hand it over to the monitor...
      @referenceTable = (@consoleRow, @agentRow);
                 
      monitor( \@referenceTable ); 
    }
    else
    {
      @consoleRow = ($console, \&launchIASConsole);
      monitor( \@consoleRow );
    }

    # Exit...
    exit 0;
}

sub startDBConsole()
{
    my (@agentPID, @consolePID, @consoleRow, @agentRow, @referenceTable, $emAgent, $console, $temp);

    printMessage("DBConsole. Monitoring Agent+Console");
 
    # If omsRecvDir is set, OMS is local and both OMS+agent will be started
    # If it is present but commented, OMS is remote and only agent will be started
    # If it is not present, default to start both OMS+agent 
    $OMS_RECV_DIR_SET = isOmsRecvDirSet();
    printDebugMessage ("omsRecvDir is set? = $OMS_RECV_DIR_SET");
    
    if ($OMS_RECV_DIR_SET) {
        # launches and stats the Console Process.
        # Returns Return PID[0], Start time[2]....
        $temp = launchDBConsole();
        @consolePID = @$temp;
    
        # Initialize the console object ...
        $console = new DBConsole();
        $console->Initialize($consolePID[0], $consolePID[1], $DEBUG_ENABLED);
    }
    else {
        printMessage ("Remote OMS configured, starting agent only.");
    }
   
    if( $IN_VOB ne "TRUE")
    {
      # Launches and stats the Agent Process.
      # Returns array. PID [0], Start Time [1].
      $temp = launchAgent();
      @agentPID = @$temp;

      # Initialize the emagent object....    
      $emAgent = new EMAgent();
      $emAgent->Initialize($agentPID[0], $agentPID[1], $DEBUG_ENABLED);
    
      # The starting reference table for the monitor is as follows :
      # Component'sObjectReference    RestartHandler()
      # console                       launchDBConsole
      # emagent                       launchAgent
      #
      # NOTE : ANY ADDITION OR SUBTRACTION OF COLUMNS TO 
      # THE ABOVE NEED TO BE REFLECTED IN $NUM_COLS variable below

      # Create component row with the component object and the restart handler..
      if ($OMS_RECV_DIR_SET) {
        @consoleRow = ($console, \&launchDBConsole);
        @agentRow = ($emAgent, \&launchAgent);
                 
        # Stuffit in the table and hand it over to the monitor...
        @referenceTable = (@consoleRow, @agentRow);
      }
      else {
        # bug 4150933: do not add consoleRow when omsrecvdir not set
        @agentRow = ($emAgent, \&launchAgent);
                 
        # Stuffit in the table and hand it over to the monitor...
        @referenceTable = (@agentRow);
      }

      monitor( \@referenceTable ); 

    }
    else
    {
      if ($OMS_RECV_DIR_SET) {
        @consoleRow = ($console, \&launchDBConsole);
        monitor( \@consoleRow );
      }
    }

    # Exit...
    exit 0;
}


sub startCEMD()
{
   my (@agentPID, @agentRow, $emAgent, $temp);

   printMessage("Agent Only Monitor.");
    
   # Launches and stats the Agent Process.
   # Returns reference to array. PID [0], Start Time [2].
   $temp = launchAgent();
   @agentPID = @$temp;

   # Initialize the emagent object....    
   $emAgent = new EMAgent();
   $emAgent->Initialize($agentPID[0], $agentPID[1], $DEBUG_ENABLED);


   # Construct the component, launch_subroutine for the emagent.
   @agentRow = ($emAgent, \&launchAgent);    

   # Call the monitor/restart loop...
   monitor( \@agentRow ); 

   # Exit...
   exit 0;
}

#
# monitor
# Accepts a reference table of the following format
# The following are subscripts
#    0               1             |baseCtr        
# console[0]     launchIASConsole  |  0
# emagent[2]     launchAgent       |  2
# [dbconsole][4] [launchDb]        |  4 [in future]
# 
# NOTE : ANY ADDITION OR SUBTRACTION OF COLUMNS TO THE ABOVE NEED TO BE
# REFLECTED IN $NUM_COLS variable below
#
# Takes the following sequence in a loop
# 1. sleeps for <m> seconds
# 2. Call status() on the component object.
# 3. If the status returns bad or no process state
# 4. reapChild
# 5. If the child has exited normally. Exit loop
# 6. If the child has died abnormally, call restartHandler on that comp
# 6. If the child has died abnormally and is in hung state.. 
#       call debughandler on that comp
# 7. Update PID and ThrashCount accordingly...
# 8. If the component is thrashing, exit after stopping the rest of the comps.
# Thrashing : 3 Restarts in 10 minutes.
#
sub monitor
{
  my ($input_array_ref) = @_;

  # Type cast the input array reference to the array itself.
  my( @components ) = @$input_array_ref;

  # Unfortunately, PERL does not provide true array of arrays.
  # Count the number of rows. (= components)
  # We divide the total by the number of columns...

  my($NUM_COLS) = 2;
  my($NUM_COMPONENTS) = (scalar(@components)/$NUM_COLS); 
 
  printDebugMessage("EMWD. Monitoring $NUM_COMPONENTS Components.");

  # Establish the offsets...
  my($object_offset, $restart_offset) = (0,1);
  my ($normalShutdown) = "FALSE";

  # marked all components as just started
  my @compJustStarted;
  for $i ( 0 .. ($NUM_COMPONENTS-1) ) 
  {
    $compJustStarted[$i] = 1;
  }

  while($NUM_COMPONENTS > 0)
  {
    # Sleep for the given amount of time ...
    sleep $EMWD_MONITOR_WAIT_TIME;
  
    printDebugMessage("EMWD Checking status of components...");
    
    # Iterate over the components,
    # Check for status
    # If status is not ok
    #    reapChild
    # Increment the thrashing count and if thrashes, prepare to exit.

    for($i=0, $baseCtr=0; $i < $NUM_COMPONENTS; $i++, $baseCtr+=2)
    { 
      my($objRef, $name, $pid, $rc);

      # Get the objectReference..      
      $objRef = $components[$baseCtr+$object_offset];
      
      $name = $objRef->getName();
      $pid=$objRef->getPID();

      printDebugMessage("EMWD. Checking Status for $name $pid");
      
      # Reap the child .... returns an array.
      # [0] : How the process exited [normal/signal/coredump].
      # [1] : Exit code/Signal Code
      local (*processExit) = reapChild( $pid, $name );

      my $timeout = $HANG_DETECTION_TIMEOUT;
      if ( $compJustStarted[$i] )
      {
        $timeout = $STARTUP_TIMEOUT;
      }

      my $timeoutForThisRun = $timeout;

      my $statusCheckStartTime = time;

      # Call the status
      $rc = $STATUS_PROCESS_OK;
      if ($pid != -1)
      {
        $rc = $objRef->status();
        $timeout -= (time - $statusCheckStartTime); 
      }

      printDebugMessage("Status for $pid : ($processExit[0], $processExit[1]), $rc");

#      my $timeout = $ENV{EMWD_PROCESS_STATUS_TIMEOUT};
#      $timeout = 120 unless defined($timeout);

      # If the status of the process is Unknown, do a retry
      # until a timeout is reached ...
      while( ($rc == $STATUS_PROCESS_UNKNOWN) and
             ($timeout > 0))
      {
        $statusCheckStartTime = time;
        $rc = $objRef->status();
        $timeout -= (time - $statusCheckStartTime);

        sleep 10;
        $timeout -= 10; 
      }

      # If the status of the process is Hang, do a retry
      # until a timeout is reached...
      while( ($rc == $STATUS_PROCESS_HANG) and
             ($timeout > 0))
      {
        $statusCheckStartTime = time;
        $rc = $objRef->status();
        $timeout -= (time - $statusCheckStartTime); 
      }
      
      if($rc != $STATUS_PROCESS_OK)
      {	
	  $rc = $STATUS_PROCESS_HANG if ($timeout <= 0 );
      }

      # If the status is no_process or process_hang ...
      if( ($rc == $STATUS_NO_SUCH_PROCESS) or
          ($rc == $STATUS_PROCESS_HANG) or 
          ($rc == $STATUS_AGENT_ABNORMAL) or
          ( $processExit[0] != $PROCESS_OK ) )
      {
         printDebugMessage("Checking status of $name : $pid");

         # If the process is in hung / abnormal state, we need to call the debug routine..
         if ( ( $rc == $STATUS_PROCESS_HANG ) or
              ( $rc == $STATUS_AGENT_ABNORMAL ) )
         {
           if ( $rc == $STATUS_PROCESS_HANG )
           {
             printMessage("Hang detected for $name : $pid");
             printMessage("Debugging component $name");
           }
           else
           {
             printMessage("Abnormality reported for $name : $pid");
             printMessage("Debugging component $name");
           }
           
           # debug routine is called...
           $objRef->debug(); 

           if ( $processExit[0] == $PROCESS_OK )
           {
             # we need to update the process status because it might be just killed in debug routine
             (*processExit) = reapChild( $pid, $name );
           }
         }
         
         # Note the current crash time ...
         my($currentCrashTime) = time;

         if( $processExit[0] == $PROCESS_EXIT_NORMAL )
         {
            my($tmpMsg) = $name." exited at ".localtime($currentCrashTime).
                          " with return value $processExit[1].";
            printMessage($tmpMsg);

            if( ($processExit[1] > 128) and ($processExit[1] <= 255) )
            {
              my($signalNum) = ($processExit[1] - 128);

              # A process hang might have killed the process with signum 9
              if( ($signalNum == 9) and 
                  ($rc != $STATUS_PROCESS_HANG) and
                  ($rc != $STATUS_AGENT_ABNORMAL) )  
              {
                 printMessage("$name has been forcibly killed.");
                 printMessage("Stopping other components.");
                      
                 # Call the subroutine that exits out each of the component
                 stopComponents(\@components, $NUM_COLS, $NUM_COMPONENTS, $baseCtr);
            
                 # Time to hang our boots and exit...
                 $normalShutdown = "TRUE";
                 $NUM_COMPONENTS = 0;
                 last;
              }
              else
              {
                checkAndRenameCore($name, $pid, $objRef);

                $objRef->incThrashCount();
              }
            } # End of signal check between 128 to 255
            elsif( ($processExit[1] == 55) or ($processExit[1] == 0) )
            {
               if($processExit[1] == 55) # This is agent initialization failure...
               {
                 printMessage("$name has exited due to initialization failure.");
                 printMessage("Stopping other components.");
                      
                 # Call the subroutine that exits out each of the component
                 stopComponents(\@components, $NUM_COLS, $NUM_COMPONENTS, $baseCtr);
               }
 
               # Time to hang our boots and exit...
               printMessage("Exiting watchdog loop");
               $normalShutdown = "TRUE";
               $NUM_COMPONENTS = 0;
               last;
            }
            else
            {
               if( $processExit[1] == 3 )
               {
                 # The process has requested a restart...
                 printMessage("$name has requested a restart.");
               }
            }
         }
         elsif( $processExit[0] == $PROCESS_EXIT_SIGNAL )
         {
            my($tmpMsg) = $name." exited at ".localtime($currentCrashTime).
                          " with signal ".$processExit[1];
            printMessage($tmpMsg);
                  
            if( ($processExit[1] != 9) and
                ($processExit[1] != 15) ) # Not a SIGKILL/SIGTERM Signal ..
            {
                checkAndRenameCore($name, $pid, $objRef);

                # Bump up the thrash count...
                $objRef->incThrashCount();
            
                my($tmpMsg) = $name." exit via signal ".$processExit[1].
                             " .Thrash count is ".$objRef->getThrashCount();
                printDebugMessage($tmpMsg);
            }
            else # We need to exit the rest on SIGKILL or SIGTERM signal
            {
              # debug kills a hung process by 9 or 15. We do restart if killed due to hang..
              if( ( $rc != $STATUS_PROCESS_HANG ) and
                  ( $rc != $STATUS_AGENT_ABNORMAL ) )
              {
                printMessage("$name has been forcibly killed.");
                printMessage("Stopping other components.");
                      
                # Call the subroutine that exits out each of the component
                stopComponents(\@components, $NUM_COLS, $NUM_COMPONENTS, $baseCtr);
            
                # Time to hang our boots and exit...
                $normalShutdown = "TRUE";
                $NUM_COMPONENTS = 0;
                last;
              } 
              else
              {
                $objRef->incThrashCount();
              }
            }
         }
         elsif( $processExit[0] == $PROCESS_OK )
         {
           # We are in this situation only for a false alarm...
           # We drop to the bottom of the loop...
           $compJustStarted[$i] = 0;
           next;
         }
         else # The only likely hood is core dump ...
         {
            # But check for the dump core condition anyway ...
            if ($processExit[0] == $PROCESS_DUMPED_CORE)
            {
              # Bump up the thrash count...
              $objRef->incThrashCount();
 
              my($tmpMsg) = $name." exited at ".localtime($currentCrashTime).
                          " with return value ".$processExit[1];
              printMessage($tmpMsg);

              checkAndRenameCore($name, $pid, $objRef);

              # debug routine is called...
              $objRef->debug(); 

              # reapChild and ignore
              my ($ignore) = reapChild( $pid, $name );
            } # End of if dumped Core Check...
         }
         
         printDebugMessage("EMWD Checking for Thrash Scenario");
         
         # Check for the Thrash logic ...
         my ($timeCrashDelta);
         $timeCrashDelta = $currentCrashTime - ($objRef->getStartTime());
                                        
         # Thrash 3 times in 10 minutes if $timeoutForThisRun < 180 (3 minutes)
         # Otherwise, Thrash 3 times in $timeoutForThisRun+420 (7 minutes)
         # 420 = 90 (wait after startup) 
         #       + 30 (wait at beginning of while loop)
         #       + 120 (max time to return from first status check, HANG takes 2 min)
         #       + 120 (if status is called right before timeout expires inside HANG loop)
         #       + 60 (time to do other processing like reapChild, etc.) 
         # If more than x minutes than we start over. 
                                               
         my $maxThrashInterval = 600;   # The default
         if ($timeoutForThisRun >= 180)
         {
           $maxThrashInterval = $timeoutForThisRun + 420;
         }

         if( $timeCrashDelta > $maxThrashInterval )
         {
             # We reset the thrash count ...
             $objRef->setThrashCount(1);
         }
         
         if (($objRef->getThrashCount()) >= 3)
         {
           $normalShutdown = "FALSE";
           printMessage("$name is Thrashing. Exiting loop.");
           
           # Shutdown the rest of the components
           # Call the subroutine that exits out each of the component
           stopComponents( \@components, $NUM_COLS, $NUM_COMPONENTS, $baseCtr);

           # Reset the loop...
           $NUM_COMPONENTS=0;
           last;
         }
         else
         {
           # Restart required.
           # Tag component to be restarted by setting PID to -1;
           $objRef->reInitialize(-1,0);
         }
      } # endif process not okay

      if($objRef->getPID() == -1)
      {
	# Indicates object needs to be restarted.
        if($objRef->okToRestart() eq "TRUE")
        {
          printMessage("Restarting $name.");
                 
          # We use the components restartHandler to restart the component
          # returns PID, StartTime
          my ($tmp, @restartInfo);
          $tmp = &{$components[$baseCtr+$restart_offset]}();
          @restartInfo = @$tmp;
          $objRef->reInitialize($restartInfo[0], $restartInfo[1]);
          $compJustStarted[$i] = 1;
        }
        # Either we did restart or did not. In both cases move to the
	# next process object
        next;
      }

      $compJustStarted[$i] = 0;

      # Check for restart request from the process
      my($recycleRequest) = $objRef->recycle();
      if($recycleRequest eq "TRUE")
      {
        printMessage("Received restart request from $name : $pid");
        printMessage("Stopping $name : $pid");

        # This is for agent so that it does not send updown signals
        $ENV{EMAGENT_SILENT_RECYCLE} = "TRUE";

        $objRef->stop(); # Try to stop the process.
        # reapChild and ignore
        my ($ignore) = reapChild( $pid, $name );

        # We use the components restartHandler to restart the component
        # returns PID, StartTime

        my ($tmp, @restartInfo);

        $tmp = &{$components[$baseCtr+$restart_offset]}();
        @restartInfo = @$tmp;
        $objRef->reInitialize($restartInfo[0], $restartInfo[1]);
        $objRef->setThrashCount(1);
        $compJustStarted[$i] = 1;
        $ENV{EMAGENT_SILENT_RECYCLE} = "";
      }

      printDebugMessage("Monitor alive.");
      
      # our chance to do additional stuff here... like ...
      #
      # gatherProcessStatistics
      $objRef->gatherProcessStatistics();

    } # end for loop


    if($NUM_COMPONENTS == 0)
    {
      if($normalShutdown eq "FALSE")
      {
        printMessage("Exited due to Thrash.");
      }
    }
    
  } # end while iteration ...
} # end subroutine

#
# checkAndRenameCore
# Checks for the core file and renames appropriately
# Parameters
# PID : The process Id of the child process
sub checkAndRenameCore()
{
   my ($name, $pid, $objRef) = @_;

   printMessage("$name has exited due to an internal error");
   printMessage(" - checking for corefile at $EMHOME/sysman/emd");

   my $coreFile;
   my @coreLocs = ( "$EMHOME/sysman/emd/core", 
                    "$EMHOME/sysman/emd/core.$pid",
                    "$EMDROOT/bin/core" );
   my $coreFileFound = 0;

   foreach $coreFile (@coreLocs)
   {
     # We move the core as component name+localtime...
     if( -e $coreFile)
     {
        my($tmpMsg) = $name." coredump found at ".$coreFile;
        printCoreDbgMsg($tmpMsg);

        my($appender) = $name."_".time();
        my($destFile) = "$EMHOME/sysman/emd/core_".$appender;
        rename $coreFile, $destFile;

        printCoreDbgMsg("Core file moved to $destFile");
               
        $objRef->debugCore( $destFile );

        $coreFileFound = 1;
        last;
     }
   }
   if ( !$coreFileFound)
   {
      printDebugMessage("$name coredump not found!!");
   }
}

# reapChild
# Reaps the Child process. 
# The child process can be under following status
# alive 
# exited
#    exited due to normal shutdown
#    exited due to SIGQUIT signal
#    exited after core dump
# Parameters
# PID : The process Id of the child process
# Returns Array [0][1]
#   Array Element [0] is 
#       PROCESS_OK : If the process is okay
#       PROCESS_EXIT_NORMAL : If the process has exited normally
#       PROCESS_EXIT_SIGNAL : If the process exit is due to signal 
#       PROCESS_DUMPED_CORE : If the process has dumped core
#   Array Element [1] is 
#       PROCESS_OK : If the process is okay
#       exit code of the process if PROCESS_EXIT_NORMAL
#       signal that caused process death if PROCESS_EXIT_SIGNAL
#       PROCESS_DUMPED_CORE if PROCESS_DUMPED_CORE
sub reapChild()
{
  my($cpid, $name) = @_;

  printDebugMessage("try reapChild pid=$cpid\n");

  # timeout for the waitpid... 
  my ($timeOut, $processStatus) = (0,0);
  my ($reaped, @status);

  if($cpid == -1)
  {
    @status = ($PROCESS_OK, $PROCESS_OK);      
    return (\@status);
  }

  if($IS_WINDOWS eq "TRUE")
  {

    @status = ($PROCESS_OK, $PROCESS_OK);

    #check if process is alive
    
    $processStatus = `$ORACLE_HOME/bin/nmelproc isalive $cpid`;
    chomp($processStatus);

    printDebugMessage("isAlive on Pid $cpid returned $processStatus");
    if($processStatus == -1)
    {
	printMessage("Process with pid $cpid not found. Checking for file $EXITFILE");
	if( -e "$EXITFILE" )
	{
	    printDebugMessage("Found $EXITFILE.Reaping exit code");
	    open(EXITSTATUS, "<$EXITFILE");
	    while(<EXITSTATUS>)
	    {
		chomp $_;
		if($_ eq "0")
		{
		    @status = ($PROCESS_EXIT_NORMAL, 0);
		    last;
		}
	    }
	    close(EXITSTATUS);
	}
	else
	{
	    printMessage("Exitfile $EXITFILE not found. Signaling abnormal exit");
	    @status = ($PROCESS_EXIT_SIGNAL, 99);
	}
    }

    return (\@status);
  }

  # waitpid returns processid that is reaped and sets $? to the wait 
  # status of the defunct process. This status is two 8-bits in one 
  # 16-bit number. The high byte is the exit value of the process. 
  # The low 7 bits represent the number of the signal that 
  # killed the process, with the 8th bit indicating whether a core 
  # dump occurred

  $reaped = waitpid($cpid, &WNOHANG);
  $processStatus = $?;
  while( ($reaped == 0) and ($timeOut < 30) )
  {
    sleep 1;
    $timeOut++;
    $reaped = waitpid($cpid, &WNOHANG);
    $processStatus = $?;
  } 

  if(($reaped == -1) ||
     ($reaped == 0))  # ...the child process is alive and kicking
  {
    @status = ($PROCESS_OK, $PROCESS_OK);      
  }
  elsif(WIFEXITED($processStatus)) # The process exited normally...
  {
    @status = ($PROCESS_EXIT_NORMAL, WEXITSTATUS($processStatus) );
  }
  elsif(WIFSIGNALED($processStatus)) # The process was signaled to exit...
  {
    $signal = WTERMSIG($processStatus); 
    @status = ($PROCESS_EXIT_SIGNAL, $signal );      
  }
  else # The only possibility now is a core dump ...
  {
    if( $processStatus == -1 )
    {
       printDebugMessage("Process Status is $processStatus. This is a false alarm.");
       @status = ($PROCESS_OK, $PROCESS_OK);
    }
    else
    {
      # Process might have core dumped or waitpid raised a false alarm...
      # The dump cored bit is the LSB
      my($dumped_core) = $processStatus & 1;
      $signal = WTERMSIG($processStatus);
      if($dumped_core == 1)
      {
        printMessage("ProcessStatus is $processStatus. Process core dumped.");
        @status = ($PROCESS_DUMPED_CORE, $signal);    
      }
      else # Indicates a false alarm ...
      {
        printDebugMessage("ProcessStatus is $processStatus. This is a false alarm.");
        @status = ($PROCESS_OK, $signal);            
      }
    }
  }

  printDebugMessage("reapChild pid=$cpid, status = $status[0], $status[1]\n");
  
  return (\@status);     
}


# 
# stopComponents
# Helper that takes the components array, the current component's base
# where the problem occurred and the number of columns [added/sub to base] and 
# stop() all components other than current component.
#
sub stopComponents
{
   local( *comps, $numCols, $numComponents, $baseCtr) = @_;

   my($bbase) = $baseCtr-$numCols;
   my($fbase) = $baseCtr+$numCols;
   my($maxElements) = ($numCols * $numComponents);

   while($bbase >= 0)
   {
     $objRef = $comps[$bbase];

     my ($name) = $objRef->getName();
     printMessage("EMWD Stopping $name.");

     $objRef->stop();
     $bbase-=$numCols;
   }
   
   while($fbase < $maxElements)
   {
     $objRef = $comps[$fbase];

     my ($name) = $objRef->getName();
     print localtime()."::EMWD Stopping $name \n";

     $objRef->stop();
     $fbase+=$numCols;
   }

   printDebugMessage("Stopped all other components.");
   printMessage("Commiting Process death.");

   # Commenting out the following. Since this seems to kill the oratst
   # and hence the short regression itself...
   # setpgrp(0, 0); # Become the process group leader...
   # kill -9, 0;  # Kill itself and all its subprocess....
}

# launchIASConsole
# Launches the IASConsole process.
#
# Returns
# Array {
#            PID, # PID if Successful, <0 if failure
#            startTime # Starttime [or failure time]
#       }
#
sub launchIASConsole()
{
  my @returnArray = ();
  my ($CONSOLE_CHILD_PROCESS, $startTime);
  
  # At the outset we need to fork, since we have to launch the
  # console in a different process...

  # If IS_WINDOWS then we need to use win32 perl libraries to fork/exec
  if($IS_WINDOWS eq "TRUE")
  {
    my($commandString) = getIASConsoleLaunchCmd();
   
    system("$ORACLE_HOME/bin/nmelproc launch $NOHUP_FILE $commandString > $PID_FILE");
    $retValue =$?;

    open(PIDFILE, "<$PID_FILE");
    while(<PIDFILE>)
    {
      $CONSOLE_CHILD_PROCESS=$_;
    }
    close(PIDFILE);
    chomp($CONSOLE_CHILD_PROCESS);
  }
  else
  {
    $CONSOLE_CHILD_PROCESS = fork();
  }
  
  if( $CONSOLE_CHILD_PROCESS == 0 )
  {
    # This is the child process... we exec the java...
    execIASConsoleProcess();
    exit 0;
  }
  else
  {
    # This is the parent process ...
    $startTime = time; # Record the time of launching the console...
    
    my($tempString) = "Console Launched with PID ".$CONSOLE_CHILD_PROCESS.
                      " at time ".localtime($startTime);
    printMessage($tempString);

    # Update the PID_FILE
    system("echo $CONSOLE_CHILD_PROCESS > $PID_FILE");

    (@returnArray) = ($CONSOLE_CHILD_PROCESS, $startTime);

    # Additional timeout for first time OC4J startup
    sleep 90;

    return (\@returnArray);
  }
}

# launchDBConsole
# Launches the IASConsole process.
#
# Returns
# Array {
#            PID, # PID if Successful, <0 if failure
#            startTime # Starttime [or failure time]
#       }
#
sub launchDBConsole()
{
  my @returnArray = ();
  my ($CONSOLE_CHILD_PROCESS, $startTime);
  
  # At the outset we need to fork, since we have to launch the
  # console in a different process...

  # If IS_WINDOWS then we need to use win32 perl libraries to fork/exec
  if($IS_WINDOWS eq "TRUE")
  {
    my($commandString) = getDBConsoleLaunchCmd();
   
    system("$ORACLE_HOME/bin/nmelproc launch $NOHUP_FILE $commandString > $PID_FILE");
    $retValue =$?;

    open(PIDFILE, "<$PID_FILE");
    while(<PIDFILE>)
    {
      $CONSOLE_CHILD_PROCESS=$_;
    }
    close(PIDFILE);
    chomp($CONSOLE_CHILD_PROCESS);
  }
  else
  {
    $CONSOLE_CHILD_PROCESS = fork();
  }

  if( $CONSOLE_CHILD_PROCESS == 0 )
  {
    # This is the child process... we exec the java...
    execDBConsoleProcess();
    exit 0;
  }
  else
  {
    # This is the parent process ...
    $startTime = time; # Record the time of launching the console...
    
    my($tempString) = "Console Launched with PID ".$CONSOLE_CHILD_PROCESS.
                      " at time ".localtime($startTime);
    printMessage($tempString);

    # Update the PID_FILE
    system("echo $CONSOLE_CHILD_PROCESS > $PID_FILE");

    (@returnArray) = ($CONSOLE_CHILD_PROCESS, $startTime);

    # Additional timeout for first time OC4J startup
    sleep 90;

    return (\@returnArray);
  }
}

#
# update emd.properties with agentTZRegion if it not already present.
#
sub updateAgentTZIfNecessary()
{
  my $emdPropFile=getEmdPropFile();
  my $repURL = "";
  my $tzRegion = "";
  my $tzRegionFound = 0;
  my $rc = 0;
  if (not (-e "$emdPropFile" ))
  {
     die "Missing emd.properties from EMHOME/sysman/config  \n";
  }

  ($tzRegion,$repURL) = getAgentTZAndRepURL();

  if( length( $repURL) <= 0 ) 
  {
    return; #No tz check if Repository URL is found.
  }

  if( length( $tzRegion) > 0 ) 
  {
     $tzRegionFound = 1;
  }

  if ( ($tzRegionFound == 1 )  && !supportedTZ($tzRegion) ) 
  {
    printMessage("property 'agentTZregion' in '$emdPropFile' contains an invalid value of '$tzRegion'\.Agent start up can not proceed\."."This value might have been manually modified to be an incorrect value\."."This value needs to be set to one of the  values listed in '$EMDROOT/sysman/admin/supportedtzs\.lst'\. Execute 'emctl config agent getTZ' and see if this is an appropriate value.");
    exit($EMAGENT_DONT_RESTART);
  }

  if ( $tzRegionFound == 0  )
  {
    printMessage("Property 'agentTZRegion' is  missing from  $emdPropFile. This is normal when the agent is started for the very first time.Updating it...");
      #create a back up of emd.properites 
      my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time); 
      $year=$year+1900;
      $mon=$mon+1;
      my $backFile =  sprintf "%s.%4d\-%02d\-%02d\-%02d\-%02d\-%02d", $emdPropFile,$year,$mon,$mday,$hour,$min,$sec;

      my($tempString) = "$emdPropFile copied to $backFile while updating the property  'agentTZRegion'"; 
      printMessage($tempString);
      cp($emdPropFile,$backFile);

    $rc = updateAgentTZRegion(); 
    if ( $rc == 1 )
    {
      printMessage("Failed to update  the property 'agentTZRegion' in $emdPropFile.Needs to be manually updated.Execute 'emctl config agent getTZ' to see if this value is appropriate."); 
      exit($EMAGENT_DONT_RESTART);
    }
        # Read back  the value we just put in thru java.
    ($tzRegion,$repURL) = getAgentTZAndRepURL();
    printMessage("An agentTZregion of '$tzRegion' is installed in $emdPropFile.");
  }
  else 
  {
    printDebugMessage("agentTZRegion already exists in $emdPropFile."); 
  }
  #Whether installing for the first time,or already there , alway validate
  #tz offset corresponging to 'agentTZRegion' in emd.properties against the 
  #value used by the agent.

  $rc = validateTZAgainstAgent($tzRegion);
  if ( $rc != 0 )
  {
       printMessage("The agentTZRegion value in $emdPropFile is not in agreement with what agent thinks it should be.Please verify your environment to make sure that TZ setting has not changed since the last start of the agent\.\n"."If you modified the timezone setting in the environment, please stop the agent and exectute 'emctl resetTZ agent' and also execute the script 'mgmt_target.set_agent_tzrgn' to get the value propagated to repository");  
    exit($EMAGENT_DONT_RESTART);  # dont' restart.
  }
  else
  {
    printDebugMessage("agentTZRegion successfully validated.");
  }
}

sub updateAgentTZRegion
{
      my $rc = 0;

      my($fh,$tmpfilename) = tempfile(UNLINK => 1);
      close $fh; # closing to prevent file sharing violations on Windows

      $rc = 0xffff & system("$JRE_HOME/bin/java -DORACLE_HOME=$EMDROOT -DAGENT_STATE=$EMHOME -jar $ORACLE_HOME/jlib/emConfigInstall.jar updateTZ > $tmpfilename 2>&1");
      $rc >>= 8;
      if ($rc == 1 )
      {
	  open ($fh,"<$tmpfilename");
	  while (<$fh>) {
	      printMessage ("$_");
      }
	  close $fh;

  }
      return $rc;

}

sub getAgentTZAndRepURL
{ 
  my ($emdPropFile,$EMDPROP,$emdPropLine,$tzRegion,$propValue,$propName,$remain,$found,$repURL); 

  $repURL = "";
  $tzRegion = "";

  $emdPropFile = getEmdPropFile();
  
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
    }
       if ( ($propName eq "REPOSITORY_URL") )
       {
         $repURL=$propValue;
  } 
    }
  } 
  close(EMDPROP);
  return("$tzRegion","$repURL"); 
    }

sub getEmdPropFile {
  return "$EMHOME/sysman/config/emd.properties";
}
sub supportedTZ 
{
    my ($inpTZ) = @_;
    my $found = 0;

    my $tzRead;

   # if the timzezone region is of the form [+,-]HH:MM , accept it.
   if ( $inpTZ =~ /^[+-][0-2][0-9]:[0-5][0-9]$/ ) {
     $found = 1;
   }
   else
   {
    open (INFILE, "$ENV{EMDROOT}/sysman/admin/supportedtzs.lst");

    while (<INFILE>) {
        $tzRead = $_;
        # Remove the new line.
        chomp($tzRead);

        ## Trim the tzRead..
        for ($tzRead)
        {
            s/^\s+//;
            s/\s+$//;
        }

        if (/^#/) {
            next;
        }

        if ($tzRead eq $inpTZ) {
            $found = 1;
        }
#    print "TZ = $inpTZ, Read =  $tzRead. Found = $found.\n";
    }

    close INFILE;
   } # else time zone in not HH:MM format.

    return $found;
}

#
# launchAgent
# Launches the Agent Process in a different process space
# Additionally, it stats the process for 30 tries before giving up. 
#
# Returns
# Array {
#            PID, # Process id of the child process which execs the emagent
#            startTime # Starttime [or failure time]
#       }
#
sub launchAgent()
{
  updateAgentTZIfNecessary();
  my @returnArray = ();
  
  # Check for any core dumps ...      
  if ( -e "$EMHOME/sysman/emd/core" )
  {
     # Move the corefile...
     printMessage("Detected Core File. Moving core file to core.0");
     rename "$EMHOME/sysman/emd/core", "$EMHOME/sysman/emd/core.0";
  }

  copyLastRunDetails();

  # At the outset we need to fork, since we have to launch the
  # agent in a different process...
  my $EMAGENT_CHILD_PROCESS;
  if($IS_WINDOWS eq "TRUE")
  {
    my($commandString) = "$EMDROOT/bin/emagent";

    my($PID_FILE2);
    $PID_FILE2 = $PID_FILE . "_agent";

    system("$ORACLE_HOME/bin/nmelproc launch $NOHUP_FILE $commandString > $PID_FILE2");
    $retValue = $?;

    open(FHANDLE, "<$PID_FILE2");
    while(<FHANDLE>)
    {
      $EMAGENT_CHILD_PROCESS = $_;
    }
    close(FHANDLE);
    unlink($PID_FILE2);

    chomp($EMAGENT_CHILD_PROCESS);
  }
  else
  {
    $EMAGENT_CHILD_PROCESS = fork();
  }

  if( $EMAGENT_CHILD_PROCESS == 0 )
  {
      # Set JAVA_HOME env variable to the contents of JRE_HOME
      $ENV{JAVA_HOME} = $JRE_HOME;

      # This is the child process...
      # exec the cmd directly otherwise exec launches the cmd via shell.
      my(@launchAgent) = ("$EMDROOT/bin/emagent");
      exec { $launchAgent[0] } @launchAgent;
      exit 0;
  }
  else
  {
    # This is the parent process ...
    $startTime = time; # Record the time of launching the console...
  
    my($tempString) = "Agent Launched with PID ".$EMAGENT_CHILD_PROCESS.
                      " at time ".localtime($startTime);
    printMessage($tempString);

    (@returnArray) = ($EMAGENT_CHILD_PROCESS, $startTime);    

    return (\@returnArray);
  }
}

#
# copyLastRunDetails
# Makes a copy of the most recent contents of the nohup file
#
sub copyLastRunDetails()
{
  my $NOHUP_LASTRUN = $NOHUP_FILE . ".lr";
  
  open(NOHUPLRFILE, ">$NOHUP_LASTRUN");
  open(NOHUPRFILE, "<$NOHUP_FILE");

  seek (NOHUPRFILE, -4096, 2);
  while(read NOHUPRFILE, $buf, 4096) {
    print NOHUPLRFILE $buf;
  }

  close(NOHUPRFILE);
  close(NOHUPLRFILE);
}

#
# execIASConsoleProcess.
# Execs the iASConsole
# 
sub execIASConsoleProcess()
{
  # Set JAVA_HOME env variable to the contents of JAVA_HOME
  # This is to ensure that the JAVA_HOME stays the same throughout console bounce
  # Note that Agent requires JRE_HOME to be set...
  $ENV{JAVA_HOME} = $JAVA_HOME;

  my($command) = getIASConsoleLaunchCmd();

  exec ($command);
}

#
# getIASConsoleLaunchCmd
# Return the command string to launch the IASConsole
#
sub getIASConsoleLaunchCmd()
{
  return "$JAVA_HOME/bin/java -server -Xnoclassgc -Xmx256m " .
         "$EM_OC4J_OPTS " . 
         "-DORACLE_HOME=$ORACLE_HOME " . 
         "-Doracle.dms.gate=true " . 
         "-Doracle.home=$ORACLE_HOME " . 
         "-Doracle.oc4j.localhome=$FORMFACTOR_BASE ".
         "-Doracle.sysman.emSDK.svlt.ConsoleMode=singleNode " . 
         "-Doracle.j2ee.dont.use.memory.archive=true " . 
         "-Djava.protocol.handler.pkgs=HTTPClient " . 
         "-Doracle.security.jazn.config=$EM_OC4J_HOME/config/jazn.xml " . 
         "-Djava.security.policy=$EM_OC4J_HOME/config/java2.policy " .
         "-DEMDROOT=$EMDROOT " . 
         "-Dsmiconfig=$ORACLE_HOME/dcm/config " . 
         "-DemLocOverride=$EMLOC_OVERRIDE " . 
         "-Dsysman.md5password=true " . 
         "-Drepapi.oracle.home=$ORACLE_HOME " . 
         "-Ddisable.checkForUpdate=true " . 
         "-Diasconfig_loc=$IASCONFIG_LOC " . 
         "-Djava.awt.headless=true " . 
         "-jar $ORACLE_HOME/j2ee/home/oc4j.jar " . 
         "-config $EMHOME/sysman/j2ee/config/server.xml";
}

#
# execDBConsoleProcess.
# Execs the iASConsole
# 
sub execDBConsoleProcess()
{
  $ENV{JAVA_HOME} = $JAVA_HOME;

  my($command) = getDBConsoleLaunchCmd();

  exec ($command);
}

#
# getDBConsoleLaunchCmd returns the commandline for 
# DB Execution
#

# lower java usage (256 meg) only for 10.2sa, not 10.1.0.4
sub getDBConsoleLaunchCmd()
{
  if(substr($ENV{EMPRODVER},0,4) eq "10.1")
  {
     return "$JAVA_HOME/bin/java -server -Xmx512M -XX:MaxPermSize=96m " .
	 "-XX:MinHeapFreeRatio=20 -XX:MaxHeapFreeRatio=40 " . 
         "$EM_OC4J_OPTS " . 
         "-DORACLE_HOME=$ORACLE_HOME " . 
         "-Doracle.home=$ORACLE_HOME"."/oc4j ".
         "-Doracle.oc4j.localhome=$FORMFACTOR_BASE ".
         "-DEMSTATE=$EMHOME " .
         "-Doracle.j2ee.dont.use.memory.archive=true " .
         "-Djava.protocol.handler.pkgs=HTTPClient " . 
         "-Doracle.security.jazn.config=$EM_OC4J_HOME/config/jazn.xml " . 
         "-Djava.security.policy=$EM_OC4J_HOME/config/java2.policy " .
         "-Djava.security.properties=$ORACLE_HOME/oc4j/j2ee/home/config/jazn.security.props " .
         "-DEMDROOT=$EMHOME " . 
         "-Dsysman.md5password=true " . 
         "-Drepapi.oracle.home=$ORACLE_HOME " . 
         "-Ddisable.checkForUpdate=true " . 
         "-Djava.awt.headless=true " . 
         "-jar $ORACLE_HOME/$OC4JLOC"."j2ee/home/oc4j.jar " . 
         "-config $EM_OC4J_HOME/config/server.xml";
  }
  else
  {
     return "$JAVA_HOME/bin/java -server -Xmx256M -XX:MaxPermSize=96m " .
	 "-XX:MinHeapFreeRatio=20 -XX:MaxHeapFreeRatio=40 " . 
         "$EM_OC4J_OPTS " . 
         "-DORACLE_HOME=$ORACLE_HOME " . 
         "-Doracle.home=$ORACLE_HOME"."/oc4j ".
         "-Doracle.oc4j.localhome=$FORMFACTOR_BASE ".
         "-DEMSTATE=$EMHOME " .
         "-Doracle.j2ee.dont.use.memory.archive=true " .
         "-Djava.protocol.handler.pkgs=HTTPClient " . 
         "-Doracle.security.jazn.config=$EM_OC4J_HOME/config/jazn.xml " . 
         "-Djava.security.policy=$EM_OC4J_HOME/config/java2.policy " .
         "-Djava.security.properties=$ORACLE_HOME/oc4j/j2ee/home/config/jazn.security.props " .
         "-DEMDROOT=$EMHOME " . 
         "-Dsysman.md5password=true " . 
         "-Drepapi.oracle.home=$ORACLE_HOME " . 
         "-Ddisable.checkForUpdate=true " . 
         "-Djava.awt.headless=true " . 
         "-jar $ORACLE_HOME/$OC4JLOC"."j2ee/home/oc4j.jar " . 
         "-config $EM_OC4J_HOME/config/server.xml";
  }
}

#
# printMessage
# prints EMWD trace messages
# The general format is 
# ------ <localtime>::<message> ----- \n
#
sub printMessage()
{
 my ($message) = @_;
 print "----- ".localtime()."::".$message." -----\n";
}

#
# printCoreDbgMsg
# prints EMWD trace relating to the core files
# The general format is 
# ----- <localtime>::<message> \n
#
sub printCoreDbgMsg()
{
 my ($message) = @_;
 print "----- ".localtime()."::".$message."\n";
}

#
# printDebugMessage
# prints the EMWD Debug message
# Note use this subroutine to debug the EMWD only
# Checks for the DEBUG_ENABLED flag...
#
sub printDebugMessage()
{
 my ($message) = @_;
 print "### ".localtime()."::".$message." ### \n" if $DEBUG_ENABLED;
} 



