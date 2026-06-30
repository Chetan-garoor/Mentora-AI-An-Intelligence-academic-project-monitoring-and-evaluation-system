#  $Header:
#
# Copyright (c) 2001, 2004, Oracle. All rights reserved.  
#
#    NAME
#      EMDeploy.pm - Perl Module to deploy state-only installs
#
#    DESCRIPTION
#       This script creates state-only installs from full-install agents
#
#    MODIFIED   (MM/DD/YY)
#    njagathe    12/14/04 - Only symlink lib if in agent deploy mode 
#    njagathe    12/09/04 - Create link back to source oracle_home/lib 
#    asawant     11/08/04 - Adding ORACLE_HOSTNAME for NT services 
#    blivshit    09/08/04 - remove dependency between dbcontrol service and 
#                           database service on NT 
#    vnukal      03/02/04 - cr comments 
#    vnukal      03/02/04 - escaping spaces with quotes 
#    vnukal      02/12/04 - Patternizing replaceEMDRoot 
#    vnukal      01/12/04 - registry creation script NT4.0 compatible 
#    vnukal      12/30/03 - permission bits for targets.xml 
#    mbhoopat    12/18/03 - Fix bug 3328281 
#    vnukal      12/11/03 - forward slashes emomslogging.properties 
#    vnukal      12/08/03 - adding emdRepServer 
#    vnukal      12/05/03 - adding dependancy to OracleService 
#    vnukal      12/01/03 - creating service for DBConsole 
#    vnukal      11/19/03 - adding emtgtctl 
#    vnukal      11/14/03 - NFS install changes 
#    njagathe    10/29/03 - Allowing for REMOTE_EMDROOT override 
#    vnukal      10/22/03 - servicename not mandatory for dbconsole deploy 
#    vnukal      10/16/03 - vnukal_bug-3076576 
#    vnukal      10/15/03 - adding b64InternetCertificate and OUIinventories 
#    vnukal      10/13/03 - fix substitution issue 
#    vnukal      10/08/03 - Initial version
#
package EMDeploy;
use strict;
use EmctlCommon;
use LWP::Simple;
use File::Copy;
use File::Temp qw/ tempfile /;

sub new
{
  my ($class) = @_;
  my $self = {
      mode => "agent",
      StateDir => "",
      localHost => "",
      sid => "",
      sourceEMDROOT => "",
      replaceEMDROOT => "",
      installPassword => "",
      NtServiceName => "",
      NtServiceUserName => "",
      NtServicePassword => "",
      batchFileCreate => 0
  };
  bless $self, $class;
  return $self;
}

#
# doDeploy
#
sub doDeploy
{
    my $self = shift;
    my $mode = shift;
    $self->{StateDir} = shift; # directory to install state files
    $self->{hostPort} = shift; # host-port combination to insert in EMD_URL
    $self->{localHost} = shift; # host where EM was 'oui'nstalled. 
	                        # Used as a replacement target
    $self->{sid} = shift; # SID : used in dbconsole deploys
    $self->{sourceEMDROOT} = shift; # location where EM was 'oui'nstalled.
				    # In NFS installs the NFS pathname is used.
    $self->{replaceEMDROOT} = shift; # location where EM was 'oui'installed
				    # In NFS installs the non-NFS pathname used
    $self->{installPassword} = shift;
    $self->{NtServiceName} = shift;
    $self->{NtServiceUserName} = shift;
    $self->{NtServicePassword} = shift;
    $self->{batchFileCreate} = shift;

    $self->{racMode} = $mode ne "agent"; # determines deploy mode (agent or db)

    print "Creating shared install...\n";
    print "Source location: $self->{sourceEMDROOT}\n";
    print "Local location: $self->{replaceEMDROOT}\n" if ($self->{sourceEMDROOT} ne $self->{replaceEMDROOT});
    print "Destination (shared install) : $self->{StateDir}\n";
    print "DeployMode : $mode\n\n";

    if($IS_WINDOWS eq "TRUE")
    {
	# make the replaceEMDROOT a search pattern which matches a path
	# with either '/' or '\' 
	# For e.g.
	# c:\oracle\em_1 => c:[\\/]oracle[\\/]em_1
	# c:/oracle\em_1 => c:[\\/]oracle[\\/]em_1

	$self->{replaceEMDROOT} =~ s/[\/\\]/\[\\\\\/\]/g;
    }
    

    $self->createDirs();

    #TODO validate port to be number
    my ($hostname, $port)  = split /:/, $self->{hostPort};

    if(!$self->{racMode})  
    {
	$self->createTargetsXml($hostname);
	$self->createEmctlScript();
	$self->createTgtCtlScript();
    }
    else
    {
	$self->createEMConfigFiles($hostname);
    }

    my $secureMode = $self->createAgentConfigFiles($hostname);

    if ($secureMode==1) 
    {
	print "\nSource Agent operating in secure mode.\n";
	if($self->{installPassword} ne "") 
	{
	    print  "Securing shared agent ... \n";
	    system("$self->{StateDir}/bin/emctl secure agent $self->{installPassword}");
	}
	else 
	{
	    print "Run \"$self->{StateDir}/bin/emctl secure agent\" to secure agent\n";
	}
    }

    if($IS_WINDOWS eq "TRUE")
    {
	$self->createNtService();
    }

    return 0;
}
  
sub createDirs
{
  my($self) = @_;

    # Create directory structure underneath StateDir
    #
    # For AGENT_ONLY mode
    #
    # StateDir
    #   |-------bin
    #   |       `-------emctl
    #   |-------(lib) (link back to source oracle home for os libs)
    #   |
    #   `-------sysman
    #           |-------config 
    #           |       |-------emagentlogging.properties
    #           |       |-------b64InternetCertificate.txt
    #           |       |-------OUIinventories.add
    #           |       `-------emd.properties
    #           |-------emd
    #           |       |-------collection
    #           |       |-------state
    #           |       |-------upload
    #           |       `-------targets.xml
    #           |-------log
    #           `-------recv
    #
    # For DBConsole mode
    #
    # StateDir
    #   `-------sysman
    #        |-------config
    #        |       |-------b64InternetCertificate.txt
    #        |       |-------OUIinventories.add
    #        |       |-------emagentlogging.properties
    #        |       |-------emd.properties
    #        |       |-------emoms.properties
    #        |       |-------emomsintg.xml
    #        |       `-------emomslogging.properties
    #        |-------emd
    #        |       |-------collection
    #        |       |-------state
    #        |       `-------upload
    #        |-------log
    #        `-------recv
    #

    print "Creating directories...\n";
    -e "$self->{StateDir}" or mkdir "$self->{StateDir}" or 
	die "Unable to create $self->{StateDir}: $!\n";

    if (!$self->{racMode}) {
	# emctl script gets generated in the bin directory when only the
	# agent is deployed.
	-e "$self->{StateDir}/bin" or mkdir "$self->{StateDir}/bin" or 
	    die "Unable to create $self->{StateDir}/bin: $!\n";
    }

    -e "$self->{StateDir}/sysman" or mkdir "$self->{StateDir}/sysman" or 
	die "Unable to create $self->{StateDir}/sysman: $!\n";
    -e "$self->{StateDir}/sysman/config" or 
	mkdir "$self->{StateDir}/sysman/config" or 
	    die "Unable to create $self->{StateDir}/sysman/config: $!\n";
    -e "$self->{StateDir}/sysman/emd" or 
	mkdir "$self->{StateDir}/sysman/emd" or 
	    die "Unable to create $self->{StateDir}/sysman/emd: $!\n";
    -e "$self->{StateDir}/sysman/emd/collection" or 
	mkdir "$self->{StateDir}/sysman/emd/collection" or 
	    die "Unable to create $self->{StateDir}/sysman/collection: $!\n";
    -e "$self->{StateDir}/sysman/emd/upload" or 
	mkdir "$self->{StateDir}/sysman/emd/upload" 
	    or die "Unable to create $self->{StateDir}/sysman/upload: $!\n";
    -e "$self->{StateDir}/sysman/emd/state" or 
	mkdir "$self->{StateDir}/sysman/emd/state" 
	    or die "Unable to create $self->{StateDir}/sysman/state: $!\n";
    -e "$self->{StateDir}/sysman/log" or 
	mkdir "$self->{StateDir}/sysman/log" or 
	    die "Unable to create $self->{StateDir}/sysman/log: $!\n"; 
    -e "$self->{StateDir}/sysman/recv" or 
	mkdir "$self->{StateDir}/sysman/recv" or 
	    die "Unable to create $self->{StateDir}/sysman/recv: $!\n"; 

    # On linux, we need to have access to intel linux system libraries that are
    # shipped in the $ORACLE_HOME/lib directory from the deployed agent home.
    # Note : Only required for agent deployments
    if(($IS_WINDOWS ne "TRUE") && (!$self->{racMode}))
    {
      eval { symlink ("$self->{sourceEMDROOT}/lib", 
                      "$self->{StateDir}/lib"); 1 };
    }
  
  #
  # Properties file under $EMDROOT/sysman/config/
  #
  copy("$self->{sourceEMDROOT}/sysman/config/emagentlogging.properties", 
       "$self->{StateDir}/sysman/config/emagentlogging.properties.$$") or 
	   die "Unable to copy $self->{sourceEMDROOT}/sysman/config/emagentlogging.properties to $self->{StateDir}/sysman/config/emagentlogging.properties.$$: $!";
  
  copy("$self->{sourceEMDROOT}/sysman/config/emd.properties", 
       "$self->{StateDir}/sysman/config/emd.properties.$$") or 
	   die "Unable to copy $self->{sourceEMDROOT}/sysman/config/emd.properties to $self->{StateDir}/sysman/config/emd.properties.$$: $!";

  copy("$self->{sourceEMDROOT}/sysman/config/OUIinventories.add", 
       "$self->{StateDir}/sysman/config/OUIinventories.add") or 
	   die "Unable to copy $self->{sourceEMDROOT}/sysman/config/OUIinventories.add to $self->{StateDir}/sysman/config/OUIinventories.add: $!";

#
# Internet certificate list.
#
  copy("$self->{sourceEMDROOT}/sysman/config/b64InternetCertificate.txt", 
       "$self->{StateDir}/sysman/config/b64InternetCertificate.txt") or 
	   die "Unable to copy $self->{sourceEMDROOT}/sysman/config/b64InternetCertificate.txt to $self->{StateDir}/sysman/config/b64InternetCertificate.txt: $!";
  
  
  if ($self->{racMode}) 
  {
    copy("$self->{sourceEMDROOT}/sysman/config/emomsintg.xml",
	 "$self->{StateDir}/sysman/config/emomsintg.xml") or 
	     die "Unable to copy $self->{sourceEMDROOT}/sysman/config/emomsintg.xml to $self->{StateDir}/sysman/config/emomsintg.xml: $!";
    copy("$self->{sourceEMDROOT}/sysman/config/emoms.properties", 
	 "$self->{StateDir}/sysman/config/emoms.properties.$$") or 
	     die "Unable to copy $self->{sourceEMDROOT}/sysman/config/emoms.properties to $self->{StateDir}/sysman/config/emoms.properties.$$: $!";
    copy("$self->{sourceEMDROOT}/sysman/config/emomslogging.properties", 
	 "$self->{StateDir}/sysman/config/emomslogging.properties.$$") or 
	     die "Unable to copy $self->{sourceEMDROOT}/sysman/config/emomslogging.properties to $self->{StateDir}/sysman/config/emomslogging.properties.$$: $!";
  }
  return 0;
}

sub createTargetsXml
{
  my($self,$hostname) = @_;

  print "Creating targets.xml...\n";
  open (TARGETSXML,">$self->{StateDir}/sysman/emd/targets.xml") or 
      die "Unable to create $self->{StateDir}/sysman/emd/targets.xml\n";
    
  print TARGETSXML <<TARGETS;
<Targets>
<Target TYPE="host" NAME="$hostname" DISPLAY_NAME="$hostname"/>
</Targets>
TARGETS
    
    close TARGETSXML;
    chmod 0640, "$self->{StateDir}/sysman/emd/targets.xml";

  return 0;
}

sub createEmctlScript
{
  my($self) = @_;

  # Create a redirecter emctl script
  # The emctl calls into the root emctl after 
  # setting the StateDir and AGENTSTATE
  #
  print "Creating emctl control program...\n";
  if($IS_WINDOWS eq "TRUE")
  {
      open(EMCTLBATCH,">$self->{StateDir}/bin/emctl.bat") or 
	  die "Unable to create $self->{StateDir}/bin/emctl.bat: $!\n";
      
      print EMCTLBATCH <<HEADER;
\@echo off
REM ++
REM
REM  08-oct-03.15:38:56 vnukal   
REM
REM Copyright (c) 2002, 2004, Oracle. All rights reserved.  
REM
REM  emctl - control script for state-only agent installs.
REM
REM    MODIFIED   (MM/DD/YY)
REM    vnukal       10/08/03 - Creation
REM --
setlocal
set REMOTE_EMDROOT=$self->{sourceEMDROOT}
set EMSTATE=$self->{StateDir}
set AGENT_SERVICE_NAME=$self->{NtServiceName}
$self->{sourceEMDROOT}/bin/emctl.bat \%*
endlocal
HEADER
    close EMCTLBATCH;
  }
  else
  {
      open(EMCTLSCRIPT,">$self->{StateDir}/bin/emctl") or 
	  die "Unable to create $self->{StateDir}/bin/emctl: $!\n";
      
      print EMCTLSCRIPT <<HEADER;
#!/bin/sh -f
#++
#
#  16-dec-02.15:38:56 vnukal   
#
# Copyright (c) 2002, 2004, Oracle. All rights reserved.  
#
#  emctl - control script for state-only agent installs.
#
#    MODIFIED   (MM/DD/YY)
#    vnukal       12/16/02 - Creation
#--
REMOTE_EMDROOT=$self->{sourceEMDROOT}
export REMOTE_EMDROOT
EMSTATE=$self->{StateDir}
export EMSTATE
$self->{sourceEMDROOT}/bin/emctl \$*
HEADER
    close EMCTLSCRIPT;
      chmod 0744, "$self->{StateDir}/bin/emctl";
  }

  return 0;

}

sub createTgtCtlScript
{
  my($self) = @_;

  # Create a redirecter emtgtctl script
  # The emtgtctl script calls into the root OH
  # setting the StateDir and AGENTSTATE
  #
  print "Creating emtgtctl control program...\n";
  if($IS_WINDOWS eq "TRUE")
  {
      open(EMTGTCTLBATCH,">$self->{StateDir}/bin/emtgtctl.bat") or 
	  die "Unable to create $self->{StateDir}/bin/emtgtctl.bat: $!\n";
      
      print EMTGTCTLBATCH <<HEADER;
\@echo off
REM ++
REM
REM  19-nov-03.15:38:56 vnukal   
REM
REM Copyright (c) 2002, 2004, Oracle. All rights reserved.  
REM
REM  emtgtctl - Redirector script for emtgtctl
REM
REM    MODIFIED   (MM/DD/YY)
REM    vnukal       11/19/03 - Creation
REM --
setlocal
set ORACLE_HOME=$self->{sourceEMDROOT}
set REMOTE_EMDROOT=$self->{sourceEMDROOT}
set EMSTATE=$self->{StateDir}
$self->{sourceEMDROOT}/bin/emtgtctl \%*
endlocal
HEADER
    close EMTGTCTLBATCH;
  }
  else
  {
      open(EMTGTCTLSCRIPT,">$self->{StateDir}/bin/emtgtctl") or 
	  die "Unable to create $self->{StateDir}/bin/emtgtctl: $!\n";
      
      print EMTGTCTLSCRIPT <<HEADER;
#!$self->{sourceEMDROOT}/perl/bin/perl
#++
#
#  19-nov-03.15:38:56 vnukal   
#
# Copyright (c) 2002, 2004, Oracle. All rights reserved.  
#
#  emtgtctl - Redirector script for emtgtctl
#
#    MODIFIED   (MM/DD/YY)
#    vnukal       11/19/03 - Creation
#--
for(\$i = 3;\$i < 1024; \$i++)
{
    if (!open(TMPHANDLE, "<&=\$i")) {
        close(TMPHANDLE);
    }
}
\$ENV{"ORACLE_HOME"}="$self->{sourceEMDROOT}";
\$ENV{"REMOTE_EMDROOT"}="$self->{sourceEMDROOT}";
\$ENV{"EMSTATE"}="$self->{StateDir}";
exec("$self->{sourceEMDROOT}/bin/emtgtctl \@ARGV");
HEADER
    close EMTGTCTLSCRIPT;
      chmod 0774, "$self->{StateDir}/bin/emtgtctl";
  }

  return 0;

}

sub createEMConfigFiles
{
  my($self,$hostname) = @_;

  print "Setting console properties ... \n";
  open (OMSFILE, "<$self->{StateDir}/sysman/config/emoms.properties.$$")
      or die "Unable to read $self->{StateDir}/sysman/config/emoms.properties.$$: $!\n";
  open (OMSFILEBAK, ">$self->{StateDir}/sysman/config/emoms.properties")
      or die "Unable to write $self->{StateDir}/sysman/config/emoms.properties: $!\n";
  
  while (<OMSFILE>) {
      if(/ConsoleServerHost=/)
      {
	  s/$self->{localHost}/$hostname/;
	  print OMSFILEBAK;
	  next;
      }
	  
      if(/ConsoleServerName=/)
      {
	  s/$self->{localHost}/$hostname/;
	  print OMSFILEBAK;
	  next;
      }
      
      if(/repAgentUrl=/)
      {
	  s/$self->{localHost}/$hostname/;
	  print OMSFILEBAK;
	  next;
      }

      if(/emdRepServer=/)
      {
      	  s/$self->{localHost}/$hostname/;
          print OMSFILEBAK;
          next;
      }

      if(/emdRepSID=/)
      {
	  my @line = split /=/;
	  print OMSFILEBAK $line[0]."=".$self->{sid}."\n";
	  next;
      }
      
      if(/isqlplusUrl=/)
      {
	  s/$self->{localHost}/$hostname/;
	  print OMSFILEBAK;
	  next;
      }
      if(/isqlplusWebDBAUrl=/)
      {
	  s/$self->{localHost}/$hostname/;
	  print OMSFILEBAK;
	  next;
      }
      print OMSFILEBAK;
  }
  
  close OMSFILE;
  close OMSFILEBAK;
  unlink "$self->{StateDir}/sysman/config/emoms.properties.$$";
  
  print "Setting log and trace files locations for Console ... \n";
  open (OMSLOGFILE, "<$self->{StateDir}/sysman/config/emomslogging.properties.$$")
      or die "Unable to read $self->{StateDir}/sysman/config/emomslogging.properties.$$: $!\n";
  open (OMSLOGFILEBAK, ">$self->{StateDir}/sysman/config/emomslogging.properties")
      or die "Unable to write $self->{StateDir}/sysman/config/emomslogging.properties: $!\n";
  
  while (<OMSLOGFILE>)
  {
      if(/File=/)
      {
	  s/$self->{replaceEMDROOT}/$self->{StateDir}/;
	  s/\\/\//g; # replace with forward slashes
	  print OMSLOGFILEBAK;
	  next;
      }
      
      print OMSLOGFILEBAK;
  }
  
  close OMSLOGFILE;
  close OMSLOGFILEBAK;
  unlink "$self->{StateDir}/sysman/config/emomslogging.properties.$$";
}

sub createAgentConfigFiles
{
    my($self, $hostname) = @_;

    print "Setting log and trace files locations for Agent ... \n";
    open (LOGFILE, 
	  "<$self->{StateDir}/sysman/config/emagentlogging.properties.$$") or 
	      die "Unable to read $self->{StateDir}/sysman/config/emagentlogging.properties.$$: $! \n";
      open (LOGFILEBAK, 
	    ">$self->{StateDir}/sysman/config/emagentlogging.properties") or 
		die "Unable to write $self->{StateDir}/sysman/config/emagentlogging.properties: $! \n";
      
    while (<LOGFILE>)
    {
	if(/File=/)
	{
	    s/$self->{replaceEMDROOT}/$self->{StateDir}/;
	    s/\\/\//g; # replace with forward slashes
	    print LOGFILEBAK;
	    next;
	}
	
	print LOGFILEBAK;
    }
    
    close LOGFILE;
    close LOGFILEBAK;
    unlink "$self->{StateDir}/sysman/config/emagentlogging.properties.$$";

    open (PROPFILE, "<$self->{StateDir}/sysman/config/emd.properties.$$")
	or die "Unable to read $self->{StateDir}/sysman/config/emd.properties.$$: $!\n";
    
    open (PROPFILEBAK, ">$self->{StateDir}/sysman/config/emd.properties")
	or die "Unable to write $self->{StateDir}/sysman/config/emd.properties: $!\n";
    my $secureMode = 0;
    while (<PROPFILE>) {
	if (/^REPOSITORY_URL=/)
	{
	    s/$self->{localHost}/$hostname/;
	    print PROPFILEBAK;
	    next;
	}
	elsif (/^emdWalletSrcUrl=/)
	{
	    s/$self->{localHost}/$hostname/;
	    print PROPFILEBAK;
	    next;
	}
	elsif (/^EMD_URL=/) 
	{
	    my ($header,$machine,$trailer) = split /:/;
	    if ($header =~ /https$/) 
	    {
		print "Secure agent found. New agent should be configured for secure mode\n";
		$secureMode=1;
	    }
	      
	    print PROPFILEBAK $header,"://",$self->{hostPort},"/emd/main";
	    next;
	} elsif ((/^agentStateDir=/) || (/^chronosRoot=/) ||
		 (/^emdRootCertLoc=/) || (/^internetCertLoc=/) ||
		 (/^emdWalletDest/)) 
	{
	    s/$self->{replaceEMDROOT}/$self->{StateDir}/;
	    s/\\/\//g; # replace with forward slashes
	    print PROPFILEBAK;
	    next;
	} elsif (($self->{replaceEMDROOT} ne $self->{sourceEMDROOT}) &&
		 ((/^scriptsDir=/) || (/^emdRoot=/) ||
		  (/^perlBin=/) || (/^hostConfigClasspath=/) ||
		  (/^CLASSPATH=/) || (/^JAVA_HOME=/) || (/^ouiLoc=/)))
	{
	    s/$self->{replaceEMDROOT}/$self->{sourceEMDROOT}/g;
	    print PROPFILEBAK;
	    next;
	}
	print PROPFILEBAK;
    }
    close PROPFILE;
    close PROPFILEBAK;
    unlink "$self->{StateDir}/sysman/config/emd.properties.$$";
    chmod 0640, "$self->{StateDir}/sysman/config/emd.properties";
    return $secureMode;
}

sub createNtService
{
    my($self) = @_;
    my($serviceName) = "";

    if($self->{racMode})
    {
	$serviceName = "OracleDBConsole".$self->{sid} 
    }
    else
    {
	# in agent deploy mode do not create NT service if one is 
	# not specified.
	if ($self->{NtServiceName} eq "") {
	    return 1;
	}
	$serviceName = $self->{NtServiceName};
    }

    #Create service using 'nmesrvops' executable in EMDROOT/bin
    my @srvcargs = ($self->{sourceEMDROOT}."\\bin\\nmesrvops","create",
		    $serviceName,
		    "$self->{sourceEMDROOT}\\bin\\nmesrvc.exe",
		    "auto");

    if($self->{NtServiceUserName} ne "") 
    {
	push(@srvcargs,$self->{NtServiceUserName});
    }
    if($self->{NtServicePassword} ne "") 
    {
	push(@srvcargs,$self->{NtServicePassword});
    }

    # initialize deleteSrvcCmd for cleanup in case we encounter any errors
    my $deleteSrvcCmd = $self->{sourceEMDROOT}."\\bin\\nmesrvops delete ".$serviceName;

    my ($fh, $tmpfilename);

    if($self->{batchFileCreate})
    {
	print "Generating script for service creation...\n";

	($fh, $tmpfilename) = tempfile(DIR => $self->{StateDir});

	open (SRVCBATCH, ">$self->{StateDir}/CrtSrvc.bat") or
	    die "Unable to create $self->{StateDir}/CrtSrvc.bat\n";
	print SRVCBATCH "\@echo off\n";
	print SRVCBATCH "echo Creating service\n";
	foreach (@srvcargs) {
	    print SRVCBATCH "$_ ";
	}
	print SRVCBATCH "\n";
	print SRVCBATCH "\n";
	print SRVCBATCH "echo Creating service registry entries\n";
	print SRVCBATCH "\%WINDIR\%\\regedit /s \"$tmpfilename\"\n";
	close SRVCBATCH;
    }
    else 
    {
	my ($rc) = 0xffff & system @srvcargs ;
	$rc >>= 8 ;

	die "Service creation failed. Aborting...\n" if($rc);

	($fh, $tmpfilename) = tempfile(UNLINK => 1);
    }
    
    #Now create registry entries
    my ($escEMDROOT, $escORACLE_HOME, $escEMSTATE) = 
	($self->{sourceEMDROOT}, $ORACLE_HOME, $self->{StateDir});
    $escEMDROOT =~ s/\\/\\\\/g;
    $escORACLE_HOME =~ s/\\/\\\\/g;
    $escEMSTATE =~ s/\\/\\\\/g;
    
    print $fh "REGEDIT4\r\n\r\n";
    print $fh "[HKEY_LOCAL_MACHINE\\SOFTWARE\\Oracle\\SYSMAN\\$serviceName]\r\n";
    print $fh "\"EMDROOT\"=\"$escEMDROOT\"\r\n";
    print $fh "\"ORACLE_HOME\"=\"$escORACLE_HOME\"\r\n";
    print $fh "\"EMSTATE\"=\"$escEMSTATE\"\r\n";
    if($self->{racMode}) {
	print $fh "\"CONSOLE_CFG\"=\"dbconsole\"\r\n";
	print $fh "\"ORACLE_SID\"=\"$self->{sid}\"\r\n";
    }else {
	print $fh "\"CONSOLE_CFG\"=\"agent\"\r\n";
    }

    if(defined($ENV{ORACLE_HOSTNAME})) {
        print $fh "\"ORACLE_HOSTNAME\"=\"$ENV{ORACLE_HOSTNAME}\"\r\n";
    }


    print $fh "\"TIMEOUT\"=\"15\"\r\n";
    print $fh "\"TRACE_LEVEL\"=\"16\"\r\n\r\n";

    print $fh "[HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\Eventlog\\Application\\$serviceName]\r\n";
    print $fh "\"EventMessageFile\"=\"$escEMDROOT\\\\bin\\\\orasnmemsg.dll\"\r\n";
    print $fh "\"TypesSupported\"=dword:00000007\r\n";
	
    close $fh or warn "Error closing $tmpfilename. : $!\r\n";

    # call regedit only if not generating script.
    # /s is silent option to regedit
    if(not defined $self->{batchFileCreate})
    {
	# enclose tmpfilename in quotes to escape embedded spaces
	my($rc) = 0xffff & system("$ENV{WINDIR}\\regedit.exe /s \"$tmpfilename\"");
	$rc >>= 8 ;
	if($rc) {
	    system $deleteSrvcCmd;
	    die "Creating registry entries failed. Aborting...\n";
	}
    }
}

 
1;


