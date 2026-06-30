package EmctlCommon;
require Exporter;
use English;
use IPC::Open3;
use Symbol;
use File::Spec;
use File::Temp qw/ tempfile /;

our @ISA    = qw(Exporter);
our @EXPORT = qw($EMDROOT $JAVA_HOME $JRE_HOME $ORACLE_HOME $CONSOLE_CFG 
                 $EM_OC4J_OPTS $EMLOC_OVERRIDE $IASCONFIG_LOC 
                 $STATUS_PROCESS_OK $STATUS_NO_SUCH_PROCESS $STATUS_PROCESS_HANG
                 $STATUS_AGENT_NOT_READY $STATUS_AGENT_ABNORMAL 
                 $STATUS_PROCESS_PARTIAL $STATUS_PROCESS_UNKNOWN $PERL_BIN 
                 $IAS_NOHUPFILE $IAS_URL $PID_FILE $EMD_HANG_CHECK_STATUS_TIME
                 $AGENT_NOHUPFILE $DB_NOHUPFILE $DB_URL $IN_VOB $IS_WINDOWS
                 $binExt $devNull $EMAGENT_TIMESCALE 
		 $NUMBER_AGENT_STATUS_RETRIES
                 $EMAGENT_RECYCLE_DAYS $EMAGENT_MEMCHECK_HOURS $OC4JLOC
                 $EMAGENT_RECYCLE_MAXMEMORY $EMAGENT_MAXMEM_INCREASE
		 $CFS_RAC $HOSTNAME $DEBUG_ENABLED &getEMAgentNameAndTZ
                 $INSTALL_TYPE_IAS $INSTALL_TYPE_CENTRAL $INSTALL_TYPE_AGENT 
                 $INSTALL_TYPE_DB $TIME_BETWEEN_STATUS_CHECK $IAS_LOGDIR
                 &getOC4JHome &getEMHome &getWebUrl &getORMIPort
                 $FORMFACTOR_BASE $FORMFACTOR_FILE &getTimeouts &checkFreePort
                 &isOmsRecvDirSet &validateTZAgainstAgent);
                 
# Some Global variables...
$STATUS_PROCESS_OK = 0;   # Indicates that the process is up 
$STATUS_NO_SUCH_PROCESS = 99; # Indicates that the process is not there
$STATUS_PROCESS_HANG = 98; # Indicates that the process is up but unresponsive
$STATUS_PROCESS_UNKNOWN=1; # Indicates an unknown/indeterminate state
$STATUS_AGENT_NOT_READY = 4; # Specific to agent...
$STATUS_AGENT_ABNORMAL  = 7; # Agent tells watch dog to act same as for HANG
$STATUS_PROCESS_PARTIAL=5; # In dual mode system [Console+Agent], either console
                           # or agent is running.

if(defined($ENV{EMCTL_DEBUG}))
{
  $DEBUG_ENABLED=1;
}

# setup the environment ...
$EMLOC_OVERRIDE="";
$PERL_BIN=$ENV{PERL_BIN};
$OC4JLOC="oc4j/";

if(!defined($ENV{NUMBER_AGENT_STATUS_RETRIES}))
{
    $NUMBER_AGENT_STATUS_RETRIES=2;
}
else
{
    $NUMBER_AGENT_STATUS_RETRIES=$ENV{NUMBER_AGENT_STATUS_RETRIES};
}

if( $ENV{EMD_HANG_CHECK_STATUS_TIME} eq undef )
{
  $EMD_HANG_CHECK_STATUS_TIME=300; # Timeout parameter for emdctl status...
}
else
{
  $EMD_HANG_CHECK_STATUS_TIME=$ENV{EMD_HANG_CHECK_STATUS_TIME};
}

$EM_OC4J_OPTS=$ENV{EM_OC4J_OPTS};
$IASCONFIG_LOC=$ENV{IASCONFIG_LOC};
$JAVA_HOME=$ENV{JAVA_HOME};
$JRE_HOME=$ENV{JRE_HOME};
$EMDROOT=$ENV{EMDROOT};
$ORACLE_HOME=$ENV{ORACLE_HOME};
$CONSOLE_CFG=$ENV{CONSOLE_CFG};

$INSTALL_TYPE_IAS = 0;
$INSTALL_TYPE_CENTRAL = 0;
$INSTALL_TYPE_AGENT = 0;
$INSTALL_TYPE_DB = 0;

#Values for HOST_SID_OFFSET_ENABLED : "" (unset), "host_sid", "host_only"
$HOST_SID_OFFSET_ENABLED=$ENV{HOST_SID_OFFSET_ENABLED};

if($CONSOLE_CFG eq "iasconsole")
{
  # Central Console aka OMS commands are *not* applicable
  # Agent and IASConsole is managed together by a single Process Monitor

  $INSTALL_TYPE_IAS = 1;
}
elsif($CONSOLE_CFG eq "central")
{
  # Central Console aka OMS commands are applicable
  # The Central agent is assumed to be in a different home
  # Since IAS is installed, IASConsole is present and
  # hence central=iasconsole+oms

  $INSTALL_TYPE_CENTRAL = 1;
}
elsif($CONSOLE_CFG eq "agent")
{
  # IASConsole and Central Console commands are *not* applicable

  $INSTALL_TYPE_AGENT = 1;
}
elsif($CONSOLE_CFG eq "dbconsole")
{
  # Same as iasconsole, only thing is dbconsole is now managed
  $INSTALL_TYPE_DB=1;
}
else
{
  # Most likely in views. All commands are applicable, different
  # process monitors.
  $INSTALL_TYPE_CENTRAL = 1;
  $INSTALL_TYPE_AGENT = 1;
  $INSTALL_TYPE_IAS = 1;
  $INSTALL_TYPE_DB = 1;
  $IN_VOB="TRUE";
}

$IS_WINDOWS="";
$binExt = "";
$devNull = "/dev/null";
$cpSep = ":";

if( ($OSNAME eq "MSWin32") or ($OSNAME eq "Windows_NT") )
{
 $IS_WINDOWS="TRUE";
 $binExt = "\.exe";
 $devNull = "nul";
 $cpSep = ";";
}
else
{
 $IS_WINDOWS="FALSE";
}


# This is specific to the EMAGENT
# Set EMAGENT_MEMCHECK_HOURS to 0 to skip memory check
#
if( !defined ($ENV{EMAGENT_MEMCHECK_HOURS} ) )
{
  $EMAGENT_MEMCHECK_HOURS=1;
}
else
{
  $EMAGENT_MEMCHECK_HOURS = $ENV{EMAGENT_MEMCHECK_HOURS};
}

if( !defined ($ENV{EMAGENT_RECYCLE_MAXMEMORY} ) )
{
  $EMAGENT_RECYCLE_MAXMEMORY=200;
  if( ($OSNAME eq "linux") )
  {
    $EMAGENT_RECYCLE_MAXMEMORY=350;
  }
}
else
{
  $EMAGENT_RECYCLE_MAXMEMORY= $ENV{EMAGENT_RECYCLE_MAXMEMORY};
}

if( !defined ($ENV{EMAGENT_MAXMEM_INCREASE} ) )
{
  $EMAGENT_MAXMEM_INCREASE=1;
}
else
{
  $EMAGENT_MAXMEM_INCREASE= $ENV{EMAGENT_MAXMEM_INCREASE};
}


if( !defined ($ENV{EMAGENT_TIMESCALE} ) )
{
  $EMAGENT_TIMESCALE=1;
}
else
{
  $EMAGENT_TIMESCALE= $ENV{EMAGENT_TIMESCALE};
}

#
# Set EMAGENT_RECYCLE_DAYS to 0 to skip agent recycling based on time
#
if( !defined ($ENV{EMAGENT_RECYCLE_DAYS} ) )
{
  $EMAGENT_RECYCLE_DAYS=0;
}
else
{
  $EMAGENT_RECYCLE_DAYS = $ENV{EMAGENT_RECYCLE_DAYS};
}

# This checks wether the EM_CHECK_STATUS_INTERVAL is enabled or
# not. If it is enabled it is parsed here....
# By default, leave it to 0, so that status is checked every time the
# emwd wakes up. However for Enh. 3082538, the idea is to 
# prolong the status check.

$TIME_BETWEEN_STATUS_CHECK = 0;

if( defined ($ENV{EM_CHECK_INTERVAL}) )
{
  my($multiplier, $SLEEP_TIME) = (1,30);

  my($EM_CHECK_INTERVAL) = $ENV{EM_CHECK_INTERVAL};

  if($EM_CHECK_INTERVAL =~ /[a-gi-ln-rt-zA-GI-LN-RT-Z]/)
  {
    die "Illegal character set defined for $EM_CHECK_INTERVAL. \n";
  }

  if($EM_CHECK_INTERVAL =~ /[sS]$/ )
  {
    my($num, undef) = split /[sS]/,$EM_CHECK_INTERVAL;
    $SLEEP_TIME = $num;
    $multiplier = 1;
  }
  elsif($EM_CHECK_INTERVAL =~ /[mM]$/ )
  {
    my($num, undef) = split /[mM]/,$EM_CHECK_INTERVAL;
    $SLEEP_TIME = $num;
    $multiplier = 60;
  }
  elsif($EM_CHECK_INTERVAL =~ /[hH]$/ )
  {
    my($num, undef) = split /[hH]/,$EM_CHECK_INTERVAL;
    $SLEEP_TIME = $num;
    $multiplier = 3600;
  }
  else
  {
    die "Illegal format defined for EM_CHECK_INTERVAL. Define <number>[sSmMhH] instead of $EM_CHECK_INTERVAL \n";
  }

  $TIME_BETWEEN_STATUS_CHECK = $SLEEP_TIME * $multiplier;

  if($TIME_BETWEEN_STATUS_CHECK < 0)
  {
     print "\nHealth Check for the current component is disabled vide env. variable EM_CHECK_INTERVAL. \n";
  }
}

sub getEMAgentNameAndTZ
{ 
  ($emdPropFile) = @_;
  my ($EMDPROP,$emdPropLine,$tzRegion,$propValue,$propName,$remain,$found,$emdURL,$agentName); 
  
  $repURL = "";
  $tzRegion = "";

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
       if ( ($propName eq "EMD_URL") )
       {
         $emdURL=$propValue;
         if( $emdURL =~ /(.*https?\:\/\/)(.*)(\/emd\/main)/) 
         {
           $agentName=$2;
         }
       } 
    }
  } 
  close(EMDPROP);
  return("$agentName","$tzRegion"); 
}

#Validates the timezone in emd.properties with that of  agent's time zone.
#
sub validateTZAgainstAgent
{
  my ($tzRegion) = @_;
  my $rc = 0;

  #validate what is in emd.properties is in conformance with 
  #what agent thinks it should be.
  my($fh,$tmpfilename) = tempfile(UNLINK => 1);
  close $fh; # closing to prevent file sharing violations on Windows
  $rc = 0xffff & system("$EMDROOT/bin/emdctl validateTZ agent  $tzRegion > $tmpfilename 2>&1");

  #if ( $rc != 0 )
  #{
  #   open ($fh,"<$tmpfilename");
  #   while (<$fh>) {
  #     printDMessage ("$_");
  #   }
  #   close $fh;
  #}
  return $rc;
}
sub printDMessage()
{
 my ($message) = @_;
 print "----- ".localtime()."::".$message." -----\n";
}

# Sets the FORMFACTOR_BASE and FORMFACTOR_FILE.
# For shutting down without the password, both admin.jar and 
# oc4j.jar handshake on <dir>/opmn/conf/.formfactor file.
# For our standalone consoles, the <dir> is $emHome/sysman
# i.e., the .formfactor is stored in $emHome/sysman/opmn/conf
# and we establish that directory here.
#
sub setFormFactor
{
  my $emHome = shift;

  $formFactorLocation = "$emHome/sysman/opmn/conf";
  $FORMFACTOR_BASE = "$emHome/sysman";  # This is exported out to emctl/emwd/pm's.
  $FORMFACTOR_FILE = "$formFactorLocation/.formfactor"; # exported to emctl

  -e "$FORMFACTOR_BASE" or mkdir "$FORMFACTOR_BASE" or die "Unable to create $FORMFACTOR_BASE: $!\n";
  -e "$FORMFACTOR_BASE/opmn" or mkdir "$FORMFACTOR_BASE/opmn" or die "Unable to create $FORMFACTOR_BASE/opmn: $!\n";
  -e "$formFactorLocation" or mkdir "$emHome/sysman/opmn/conf" or die "Unable to create $formFactorLocation : $!\n";    
}

# Returns the OC4JHome for the given console type.
sub getOC4JHome
{
 my $consoleType = shift;

 my $oc4jHome = "$EMDROOT/sysman/j2ee"; # default for view...

 if(lc($consoleType) eq "iasconsole") # OC4JHOME for iasconsole
 {
   #Assume a defined OC4JHome
   $oc4jHome = "$EMDROOT/sysman/j2ee"; # This should be a no op...
 }
 elsif(lc($consoleType) eq "dbconsole") # OC4JHOME for dbconsole
 {
    $oc4jHome = "$ORACLE_HOME/oc4j/j2ee/OC4J_DBConsole";

    # For DBConsole, OC4J HOME is an offset of hostname_sid
    my $oracleSid = $ENV{ORACLE_SID};
    if($HOST_SID_OFFSET_ENABLED eq "host_sid")
    {
       die "Environment variable ORACLE_SID not defined. Please define it. \n" unless defined ($oracleSid);

      # Grok the current hostname and create the hostname_sid offset to
      # location. We may use a java api here to get the host and domainname.
      my $topDir = &getLocalHostName();

      #  for 10.2 dbcontrol, use node name for RAC  
      if(substr($ENV{EMPRODVER},0,4) ne "10.1")
      {
        if (defined($ENV{CRS_HOME}) and ($ENV{CRS_HOME} ne "#CRS_HOME#"))
        {
          # if we are in RAC, use the local node name
          $topDir = &getLocalRACNode();
                
          if ($topDir eq "") {
              print "RAC node name not found, defaulting to local host name\n" if $DEBUG_ENABLED;
              $topDir = &getLocalHostName();
         }
        }
      }
        
      $oc4jHome=$oc4jHome."_".$topDir."_".$oracleSid;
    }
 }
 else # If the console type is agent or oms.
 {
    # This is the default ...
    $oc4jHome = "$EMDROOT/sysman/j2ee";
 }

 die "OC4J Configuration issue. $oc4jHome not found. \n" unless( -e "$oc4jHome" );

 print "OC4J HOME ==================  $oc4jHome\n"  if $DEBUG_ENABLED;

 return $oc4jHome;
}

# Returns the EMHome for the given console type
sub getEMHome
{
    my $consoleType = shift;
    
    # If the consoleType is undef. default to iasConsole
    $consoleType = "$CONSOLE_CFG" unless defined ($consoleType);
    $consoleType = lc($consoleType);
    
    my $emHome = $EMDROOT;
    
    # ALWAYS set IAS_LOGDIR... used for checking AS Control startup status
    $IAS_LOGDIR="$emHome/sysman/log";

    if($consoleType eq "iasconsole")
    {
	# We initialize the IAS_NOHUPFILE and LOG Dir here...
	$IAS_NOHUPFILE="$emHome/sysman/log/em.nohup";
	$IAS_LOGFILE="$emHome/sysman/log/em.log";
	$PID_FILE="$emHome/emctl.pid";
    }
    elsif($consoleType eq "dbconsole") # EMHome for dbconsole
    {
	# EMSTATE env. var. is set from the script in the em state only bin
	# directory emctl [during NFS installs of state only agents].
	if ( $ENV{EMSTATE} ne "" )
	{
	    $emHome = $ENV{EMSTATE};
	}
	elsif ( $HOST_SID_OFFSET_ENABLED eq "host_sid" )
	{
	    my $oracleSid = $ENV{ORACLE_SID};
	    die "Environment variable ORACLE_SID not defined. Please define it. \n" unless defined ($oracleSid);
	  
           #  for 10.2 dbcontrol, use node name for RAC  
           if(substr($ENV{EMPRODVER},0,4) eq "10.1")
           {
              my $localHost = &getLocalHostName();
	    
	      $emHome = $ORACLE_HOME."/".$localHost."_".$oracleSid;
	   } else {
 	      my $topDir = &getLocalHostName();

              if (defined($ENV{CRS_HOME}) and ($ENV{CRS_HOME} ne "#CRS_HOME#"))
              {
                  # if we are in RAC, use the local node name
                  $topDir = &getLocalRACNode();
                
                  if ($topDir eq "") {
                      print "RAC node name not found, defaulting to local host name\n" if $DEBUG_ENABLED;
                      $topDir = &getLocalHostName();
                  }
              }
        
              $emHome = $ORACLE_HOME."/".$topDir."_".$oracleSid;
           }       

	   $ENV{EMSTATE}=$emHome; # Promote EMSTATE to the env.
	}
	else
	{
	    $emHome = $EMDROOT;
	}
	
	$DB_NOHUPFILE="$emHome/sysman/log/emdb.nohup";
	$PID_FILE="$emHome/emctl_sa.pid";
    }
    else
    {	
	# This is the default in all cases except for MAINSA and dbconsole mode
	$emHome = $EMDROOT;
	
	{
	    if ( defined ($ENV{EMSTATE}) && $ENV{EMSTATE} ne "" )
	    {
		$emHome = $ENV{EMSTATE};
	    }
	    elsif( $HOST_SID_OFFSET_ENABLED eq "host_sid" )
	    {
		my $oracleSid = $ENV{ORACLE_SID};
		die "Environment variable ORACLE_SID not defined. Please define it. \n" unless defined ($oracleSid);
		
		#use Sys::Hostname;
		#use Net::Domain qw(hostdomain);
		#my $localHost=hostname().".".hostdomain();
		
		my $localHost = &getLocalHostName();
		
                #  for 10.2 dbcontrol, use node name for RAC  
                if(substr($ENV{EMPRODVER},0,4) eq "10.1")
                {
                     my $localHost = &getLocalHostName();
             	     $emHome = $ORACLE_HOME."/".$localHost."_".$oracleSid;
                } else {
 	             my $topDir = &getLocalHostName();

                     if (defined($ENV{CRS_HOME}) and ($ENV{CRS_HOME} ne "#CRS_HOME#"))
                     {
                        # if we are in RAC, use the local node name
                        $topDir = &getLocalRACNode();
                
                         if ($topDir eq "") {
                              print "RAC node name not found, defaulting to local host name\n" if $DEBUG_ENABLED;
                              $topDir = &getLocalHostName();
                          }
                     }
                     $emHome = $ORACLE_HOME."/".$topDir."_".$oracleSid;
                }       

		$ENV{EMSTATE} = $emHome;

	    }
            elsif( $HOST_SID_OFFSET_ENABLED eq "host_only" )
            {
                my $localHost = &getLocalHostName();
                
                $emHome = $ORACLE_HOME."/".$localHost;
                $ENV{EMSTATE} = $emHome;
            }
	    else # Reinforcing the default ...
	    { 
		$emHome = $EMDROOT;
	    }
	}
    }      
    
    # Nohup file when only the agent is running.
    $AGENT_NOHUPFILE="$emHome/sysman/log/emagent.nohup";
    $PID_FILE="$emHome/emctl.pid";
    
    die "EM Configuration issue. $emHome not found. \n" unless( -e "$emHome" );

    setFormFactor($emHome);

    print "EMHOME ==================  $emHome\n"  if $DEBUG_ENABLED;

    return $emHome;
}

sub getWebUrl
{
  my $oc4jHome = shift;
  my $emHome = shift;
  my $consoleType = shift;
  $consoleType = lc($consoleType);

  # Ideally we should return the URL for the agent/central oms..
  if(($consoleType eq "agent") or ($consoleType eq "central"))
  {
    return "NULL";
  }

  # Check for the correctness of the oc4jHome location....
  die "Unable to define a url from undefined webapp config location.\n" unless defined($oc4jHome);

  die "Unable to locate web application configuration from $oc4jHome. \n" unless (-e $oc4jHome);

  # Check for the correctness of the emHome location
  die "Unable to locate the EM Application configuration. \n " unless defined($emHome);
  die "Unable to locate the EM Application configuration. \n" unless (-e $emHome);
  
  # Set up the DB URL here...
  my $consolePort = "NULL";
  my $isSecure = "false";
  my $protocol = "http";

  if ($consoleType eq "iasconsole")
  {
    if( -e "$oc4jHome/config/emd-web-site.xml")
    {
      print "Obtaining OC4J Listen Port from $oc4jHome/config/emd-web-site.xml \n" if $DEBUG_ENABLED;
      open(WEBSITECONFIG, "<$oc4jHome/config/emd-web-site.xml");
    }
    else
    {
      die "Unable to determine console port. $oc4jHome/config/emd-web-site.xml not found. $! \n";
    }
  }
  else
  {
    if( -e "$oc4jHome/config/em-web-site.xml")
    {
      print "Obtaining OC4J Listen Port from $oc4jHome/config/em-web-site.xml \n" if $DEBUG_ENABLED;
      open(WEBSITECONFIG, "<$oc4jHome/config/em-web-site.xml");
    }
    elsif( -e "$oc4jHome/config/http-web-site.xml")
    {
      print "Obtaining OC4J Listen Port from $oc4jHome/config/http-web-site.xml \n" if $DEBUG_ENABLED;
      open(WEBSITECONFIG, "<$oc4jHome/config/http-web-site.xml");
    }
    else
    {
      die "Unable to determine console port. $oc4jHome/config/*web-site.xml not found. $! \n";
    }
  }

  while(<WEBSITECONFIG>)
  {
    if(/port/)
    {
      my(undef, $portLine) = split /port="/,$_;
      ($consolePort, undef) = split /"/,$portLine;

      my(undef, $secureLine) = split /secure="/,$portLine;
      ($isSecure, undef) = split /"/,$secureLine;
    }
  } #Loop till the end of the file to swizzle out any $_ variables...

  close (WEBSITECONFIG);

  if(lc($isSecure) eq "true")
  {
    $protocol="https";
  }

  if($consolePort eq "NULL")
  {
    die "Could not determine the correct port. \n";
  }

  -e "$emHome/sysman/config/emd.properties" or die "Unable to determine local host vide $emHome/sysman/config/emd.properties : $!\n";

  open(EMDPROPERTIES, "<$emHome/sysman/config/emd.properties");

  my ($hostName, $machine);
  while(<EMDPROPERTIES>)
  {
    $emdProp = "EMD_URL";
    if ($consoleType eq "dbconsole" ) {
        # Use REPOSITORY_URL for dbconsole to handle remote OMS
        # configurations for RAC.
        $emdProp = "REPOSITORY_URL";
    }

    if(/^(\s*$emdProp)/) # Search for emdProp
    {
      my (undef, $value) = /([^=]+)\s*=\s*(.+)/;
      (undef,$machine,undef) = /([^:]+):\/\/([^:]+):([0-9]+)\/.*/, $value;

      if (! defined($machine) )
      {
        die "Unable to determine local host from URL $_ . \n";
      }
      else
      {
          $hostName = $machine;
          print "Obtained hostname=$machine from $emHome/sysman/config/emd.properties \n" if $DEBUG_ENABLED;
      }
    }
  }

  close (EMDPROPERTIES);

  my $url="$protocol://$hostName:$consolePort";
  $url=$url."/em/console/aboutApplication" if ($consoleType eq "dbconsole");
  $url=$url."/emd/console/aboutApplication" if ($consoleType eq "iasconsole");

  return $url;
}

sub getORMIPort
{
  my $oc4jHome = shift;

  -e "$oc4jHome/config/rmi.xml" or die "Unable to determine RMI Port vide $oc4jHome/config/rmi.xml : $! \n";

  my $rmiPort = "NULL";

  open(RMICONFIG, "<$oc4jHome/config/rmi.xml");
  while(<RMICONFIG>)
  {
    if(/^(\s*<\s*rmi-server)/ && /port/)
    {
     ($rmiPort, undef) = /([^"]+)\s*"(\s*[^\d])/;
     die "ormi port value $rmiPort is erroneous.\n" unless ($rmiPort > 0);
    }
   }
   close(RMICONFIG);

   die "Could not decipher ORMI port from $oc4jHome/config/rmi.xml. It is set to $rmiPort" if ($rmiPort eq "NULL");

   return $rmiPort;
}

#
# Returns the startup and hang timeouts defined in emoms.properties.
# If they're not defined in emoms.properties or if its values are less than the
# default values, then it returns the default values.
# Default value for startupTimeout is 4 minutes
# Default value for hangTimeout is 2 minutes
#
sub getTimeouts
{
  my $emHome = shift;
  my $startupTimeout;
  my $hangTimeout;

  if( ! -e "$emHome/sysman/config/emoms.properties")
  {
    $startupTimeout = 360;   # default timeout to 6 minutes
    $hangTimeout = 120;   # default timeout to 2 minutes
    my @rarray = ($startupTimeout, $hangTimeout);
    return @rarray;
  }

  -e "$emHome/sysman/config/emoms.properties" or die "Unable to locate file $emHome/sysman/config/emoms.properties : $!\n";

  open(EMOMSPROPERTIES, "<$emHome/sysman/config/emoms.properties");

  while(<EMOMSPROPERTIES>)
  {
    if(/^(\s*emctl.watchdog.startup_timeout)/) # Search for emctl.watchdog.startup_timeout...
    {
      my (undef, $value) = /([^=]+)\s*=\s*([0-9]+).*/;
 
      if ( defined($value) )
      {
        $startupTimeout = $value;
        if ( defined($hangTimeout) )
        {
          last;              #exit the loop, both timeouts have been read
        }
      }
    }

    if(/^(\s*emctl.watchdog.hang_timeout)/) # Search for emctl.watchdog.hang_timeout...
    {
      my (undef, $value) = /([^=]+)\s*=\s*([0-9]+).*/;
 
      if ( defined($value) )
      {
        $hangTimeout = $value;
        if ( defined($startupTimeout) )
        {
          last;              #exit the loop, both timeouts have been read
        }
      }
    }
  } # end of while loop

  close (EMOMSPROPERTIES);

  if (!defined($startupTimeout) or $startupTimeout<360)
  {
     $startupTimeout = 360;   # default timeout to 6 minutes
  }

  if (!defined($hangTimeout) or $hangTimeout<120)
  {
     $hangTimeout = 120;   # default timeout to 2 minutes
  }

  if ($DEBUG_ENABLED)
  {
    print "Startup timeout: $startupTimeout \n";
    print "Hang detection timeout: $hangTimeout \n";
  }

  my @rarray = ($startupTimeout, $hangTimeout);
  return @rarray;
}

# Determine if omsRecvDir is set in emd.properties
# If it is, return 1
# If it is present but commented, return 0
#
# Note: currently if omsRecvDir is not present, return 1
#       This is temporary until omsRecvDir is set in
#       emd.properties out-of-box.  
#
sub isOmsRecvDirSet
{
    my ($emHome) = getEMHome();
    $filename = "$emHome/sysman/config/emd.properties";
    -e "$filename" or die "Unable to locate file $filename : $!\n";

    if ($DEBUG_ENABLED) {
	print ("isOmsRecvDirSet: emd properties filename = $filename\n");
    }
    
    open (EMD_PROP, $filename);
    @lines = <EMD_PROP>;
    
    $recvDirSet = 0;
    $recvDirCommented = 0;
    
    foreach $line (@lines) {
	if ($line =~ /^\#+ *omsRecvDir/) {
	    # omsRecvDir set but commented
	    $recvDirCommented = 1;
	}
	elsif ($line =~ /^ *omsRecvDir/) {
	    # omsRecvDir set
	    $recvDirSet = 1;
	}
    }

    if (!$recvDirCommented && !$recvDirSet) {
	# omsRecvDir not present, return 1 to support current default
        # Todo: when omsRecvDir is set in emd.properties by default,
        #       need to return 0 here
	$recvDirSet = 1;
    }
    
    close (EMD_PROP);

    return $recvDirSet;
}


# get the RAC local node by calling lsnodes or the Oracle version of that
sub getLocalRACNode
{
  my $localNode = "";
  my $cmd;
  my $lsnodesDir;

  if (defined($ENV{CRS_HOME}) and ($ENV{CRS_HOME} ne "#CRS_HOME#"))
  {      
     $lsnodesDir = $ENV{CRS_HOME}."/bin/olsnodes"."$binExt";
  } else {
     $lsnodesDir = $ORACLE_HOME."/bin/lsnodes"."$binExt";
  }
  $cmd = "$lsnodesDir"." -l";

  print "CRSHOME:  ".$ENV{CRS_HOME}."\n" if $DEBUG_ENABLED;
  print "lsnodes CMD:  ".$cmd."\n" if $DEBUG_ENABLED;

  if (not -e "$lsnodesDir")
  {
     print "Missing ".$lsnodesDir." for RAC\n" if $DEBUG_ENABLED;
  } else {
    my ($pid, $cmdout, $cmderr, $cmdstatus);
    local *NULL;
    my $null_file = File::Spec->devnull();
    open (NULL, $null_file) or confess("Cannot read from $null_file: + $!");

    $pid =  open3("<&NULL", $cmdout, $cmderr, "$cmd");
    $pid = waitpid $pid, 0;
    $cmdstatus = ($? >> 8);

    #  PORTING NOTE:  for NT, need to strip both CR and LF !!!
    chomp($localNode = <$cmdout>);
    $localNode =~ s/^\s+|\s+$//;

    print "OUT: *".$localNode."*\n" if $DEBUG_ENABLED;
    print "ERROR: ".<$cmderr>."\n" if $DEBUG_ENABLED;

    close($cmdout);
    close($cmderr);

    if ($cmdstatus != 0) {
        print "lsnodes command failed!  Status: ".$cmdstatus."\n" if $DEBUG_ENABLED;
        $localNode = "";   
    }
  }

  return $localNode;
}


# Gets the canonocal hostname of localhost for DBConsole.
# An environment override using ORACLE_HOSTNAME is looked up in the java code itself...
sub getLocalHostName
{
  my ($returnStatus) = @_;

  my $javaProps = '';
	if (defined($ENV{ORACLE_HOSTNAME}) && $ENV{ORACLE_HOSTNAME} ne "" )
  {
    $javaProps = "-DORACLE_HOSTNAME=$ENV{ORACLE_HOSTNAME}";
  }

  # Because in a GC install we don't ship emConfigInstall.jar (the one
  # available in $OH/jlib is from the IAS install and is old) we use
  # TargetInstaller from emCORE.jar. Note that in a DBConsole install we will
  # continue to use emConfigInstall.jar because emCORE.jar is not available
  # in $OH/j2ee/OC4J_EM...
  my $localHostCmd = "$JAVA_HOME/bin/java ".
                     "-classpath ".
                     "$ORACLE_HOME/j2ee/OC4J_EM/applications/em/em/WEB-INF/lib/emCORE.jar".
                     "$cpSep".
                     "$ORACLE_HOME/sysman/jlib/log4j-core.jar".
                     "$cpSep".
                     "$ORACLE_HOME/jlib/emConfigInstall.jar ".
                     "$javaProps " .
                     "oracle.sysman.emSDK.conf.TargetInstaller getlocalhost";

  my $localHost = `$localHostCmd`;

  my $status = $?;
  $status >>= 8;

  chomp($localhost);
  $localHost=~ s/^\s+|\s+$//;

  if ($DEBUG_ENABLED)
  {
    print("Hostname: '$localHost'\n");
  }

  if(defined($returnStatus) && $returnStatus)
  {
    my @retArr = ($status, $localHost);
    return(@retArr);
  }
  return($localHost);
}

sub checkFreePort
{
  my $portCheck = shift;
  my @portsInUse = `netstat -a`;
  my $rc = 0;

  foreach $_ (@portsInUse)
  {
    if (/[.:]([0-9]+)\s.*LISTEN.*/)
    {
      if ($1 eq $portCheck)
      {
        print "Port $1 already in use\n";
        $rc = 1;
        last;
      }
    }
  }
  return $rc;
}

######################################################################
# WINReadPasswd()
# prompt: The message to be displayed before the password is read 
# return: user input
# Comment: Do not call this routine directly, instead call promptUserPasswd().
# This routine is only for Windows systems only.
######################################################################
sub WINReadPasswd
{
  my ($prompt) = @_;
  my $passwd = "";
  my $lineCnt = 0;
  my $finaPwd;
  my $cpSep = ';';   # This function is only used on Windows...
  # The java file required can be 2 places (emd_java.jar or emCORE.jar) 
  # but usually only one of these is available per install
  my $CLASSPATH = &Secure::getAgentClassPath() . "$cpSep" .
                  &Secure::getConsoleClassPath();
  eval
  {
    open GETPWD, "$JAVA_HOME/bin/java -classpath $CLASSPATH " .
                 "oracle.sysman.util.winUtil.WinUtil -readPasswd " .
                 "\"$prompt\" -invertFileHandles |";
    while(<GETPWD>)
    {
      $passwd .= $_;
      $lineCnt++;
    };
  };
  if($passwd eq "")
  {
    die("Failed executing java!\n");
  }
  unless(($lineCnt == 1) && (($finalPwd) = $passwd =~ m/Password='(.*)'\n$/o))
  {
    die("Failed parsing password returned from Java.\n$passwd\n");
  }
  return($finalPwd);
}

######################################################################
# promptUserPasswd()
# prompt for user/passwd input
# parament: prompt string, 0/1 for hide/show echo
# return: user input
# Comment: Copied over from emrepmgr.pl
######################################################################
sub promptUserPasswd($$)
{
   my ($prompt, $echo) = @_;
   my $userinput;
   if ($echo eq 0 )
   {
      if(isWindows() eq "false")
      {
        print $prompt;
        system "stty -echo"; # Non portable until ReadKey is picked up ...
        $userinput=<STDIN>;
        system "stty echo";  # Non portable until ReadKey is picked up ...
                             # Once ReadKey is picked up use the following.
                             # ReadMode('noecho');
                             # $userinput = ReadLine(0);
                             # ReadMode('normal');
        print "\n";
      }
      else
      {
        $userinput = WINReadPasswd($prompt);
      }
   }
   else
   {
      print $prompt;
      $userinput=<STDIN>;
      print "\n";
   }
   chomp ($userinput);
   return $userinput;
}


sub isWindows()
{
    if (( $^O eq "Windows_NT") ||
        ( $^O eq "MSWin32"))
    {
        return("true");
    }
    return("false");
}


# All modules return something. By convention it is : 
1;
