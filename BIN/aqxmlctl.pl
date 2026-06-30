#!/usr/local/bin/perl
# 
# $Header: aqxmlctl.pl 04-nov-2004.14:01:50 rbhyrava Exp $
#
# aqxmlctl.pl
# 
# Copyright (c) 2004, Oracle. All rights reserved.  
#
#    NAME
#      aqxmlctl.pl - Single controller script for start and
#                       stop aqxml access
#
#    DESCRIPTION
#      Single entry point script for start and shutdown isqlplus server
#      This perl script is called by shell script aqxmlctl 
#      All the system variables are set from the shell script aqxmlctl
#
#      The usage of this script is:
#         sh aqxmlctl start|stop|deploy
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    rbhyrava    11/04/04 - rbhyrava_aqxml_demo_oc4jdoc
#    rbhyrava    10/29/04 - Creation
# 
#
# get the action, component and argument count ...

$action = $ARGV[0];
$argCount = scalar(@ARGV);

$SD="\/";
$SP=":";
$OS = $ENV{'OS'};
$SD="\\" if($os =~ /Win/i);
$SP=";" if($os =~ /Win/i);

$JAVA_HOME = $ENV{'JAVA_HOME'};
$ORACLE_HOME = $ENV{'ORACLE_HOME'};

$DB_SID = $ENV{'ORACLE_SID'};
$DB_HOST = $ENV{'HOST'};
$DB_PORT = '1521';

$AQXML_OC4J_HOME = "${ORACLE_HOME}${SD}oc4j";
$AQXML_RMI_FILE=
    "${AQXML_OC4J_HOME}${SD}j2ee${SD}OC4J_AQ${SD}config${SD}rmi.xml";
$J2EE_HOME = "${AQXML_OC4J_HOME}${SD}j2ee${SD}home";

banner();                                        # print the banner.

if ($argCount ge 1)     #isqlplusctl start/stop
{
    if ($action eq "start")
    {
      startaqxml();
    }
    elsif ($action eq "stop")
    {
      stopaqxml();
    }
    elsif ($action eq "deploy")
    {
      deployaqxml();
    }
    else 
    {
      displayHelp();
    }
}
else 
{
    displayHelp();
}


# subroutine to display banner
sub banner()
{
  print "AQXML 10.2.0.0\n";
  print "Copyright (c) 2004 Oracle.  All rights reserved.\n";
}



# subroutine to display help

sub displayHelp()
{ 
    print "Invalid arguments\n";
    print "\nUnknown command option $action\n"; 
    print "Usage:: \n";
    print "       aqxmlctl start|stop\n";
}

# 
# Sub routine to stop the AQXML Instance
#
sub stopaqxml()
{
#
# Get rmi port from rmi.xml
#
    $rmiportno = getrmiport();
    $AQ_RMI_PORT = "$rmiportno";
    print $rmiportno; 
    my($timeinmills) = time();

    print "\nStopping AQXML ...\n";

    chdir("$J2EE_HOME");

    system("${JAVA_HOME}${SD}bin${SD}java -jar ${J2EE_HOME}${SD}admin.jar ".
          " ormi://localhost:$AQ_RMI_PORT/aqxmldemo admin welcome " .
          " -shutdown force");

   # Give JAVA enough time to stop aqxml instance 
    sleep(30);
    print "AQXML instance stopped.\n";
    exit 0;
}

sub getrmiport()
{
# Open the rmi.xml file

open(AQXMLRMI,"$AQXML_RMI_FILE") || die "Cannot open ${AQXML_RMI_FILE}.\n";
# Read the file line by line
while (<AQXMLRMI>)
{
  # Check for the line containing the word "port="
  if (/^\s*<rmi-server port=/i)
  {
    if(/"[0-9]+"/)
    {
        $& =~ /[0-9]+/;
        $rmiport = "$&";
        last; # break out of the loop
    }
  }
}
# Now the port variable just contains the port number
close(AQXMLRMI);
return $rmiport;
}

# startaqxml
# 1) argument list
#

sub startaqxml()
{
    system("rm -fr ${AQXML_OC4J_HOME}${SD}aq");
    system("mkdir ${AQXML_OC4J_HOME}${SD}aq");
    system("cp $ORACLE_HOME${SD}lib${SD}xmlparserv2.jar ${AQXML_OC4J_HOME}${SD}aq");
    system("cp $ORACLE_HOME${SD}lib${SD}xsu12.jar ${AQXML_OC4J_HOME}${SD}aq");
    system("cp $ORACLE_HOME${SD}lib${SD}xschema.jar ${AQXML_OC4J_HOME}${SD}aq");
    system("cp $ORACLE_HOME${SD}jdbc${SD}lib${SD}classes12dms.jar ${AQXML_OC4J_HOME}${SD}aq");
    system("cp $ORACLE_HOME${SD}jdbc${SD}lib${SD}dms2Server.jar ${AQXML_OC4J_HOME}${SD}aq${SD}dms.jar");
    system("cp $ORACLE_HOME${SD}jlib${SD}orai18*.jar ${AQXML_OC4J_HOME}${SD}aq");
    system("cp $ORACLE_HOME${SD}rdbms${SD}jlib/aqxml.jar ${AQXML_OC4J_HOME}${SD}aq");
    system("cp $ORACLE_HOME${SD}rdbms${SD}jlib/xdb.jar ${AQXML_OC4J_HOME}${SD}aq");
    system("cp $ORACLE_HOME${SD}network${SD}jlib/*ssl*-1_1.jar ${AQXML_OC4J_HOME}${SD}aq");
    
    print "Starting AQXML instance....\n";
    chdir("$J2EE_HOME");
    #print "$DB_HOST $DB_PORT $DB_SID\n" ;
    system("$JAVA_HOME${SD}bin${SD}java " . 
           " -DMYDB_HOST=\"$DB_HOST\"" .
           " -DMYDB_PORT=\"$DB_PORT\"" .
           " -DMYDB_SID=\"$DB_SID\"" .
           " -Djava.ext.dirs=\"${AQXML_OC4J_HOME}${SD}aq${SP}" .
           "${J2EE_HOME}${SD}lib${SP}".
           "${J2EE_HOME}${SP}".
           "${J2EE_HOME}${SD}oc4j${SD}jdbc${SD}lib\"".
           " -jar ${J2EE_HOME}${SD}oc4j.jar ".
 " -config ${AQXML_OC4J_HOME}${SD}j2ee${SD}OC4J_AQ${SD}config${SD}server.xml&"
        );

    sleep(20);
    print "AQXML started.\n";
    exit 0;
}


sub deployaqxml 
{
    create_deployini();

    print "Deploying  AQXML instance....\n";
    system("cp ${ORACLE_HOME}${SD}..${SD}javavm${SD}j2ee${SD}deploytool/db_oc4j_deploy.jar $J2EE_HOME") ;
    chdir("$J2EE_HOME");
    system("$JAVA_HOME${SD}bin${SD}java -classpath " .
            "${ORACLE_HOME}${SD}opsm${SD}jlib${SD}srvm.jar${SP}".
            "${J2EE_HOME}${SD}db_oc4j_deploy.jar${SP}".
            "${J2EE_HOME}${SD}oc4j.jar".
            " oracle.j2ee.tools.deploy.DbOc4jDeploy".
            " -oraclehome $ORACLE_HOME -password welcome ".
            " -inifile ${ORACLE_HOME}${SD}rdbms${SD}demo${SD}aqxml.ini"
           ) ;
    print "Deploying  AQXML Completed....\n";
    make_secure();
    print "Deploy Done ....\n";
    sleep(2);
    exit 0;

}
sub create_deployini {
  print "Creating rdbms${SD}demo${SD}aqxml.ini....\n";
  
  $fl = "$ORACLE_HOME${SD}rdbms${SD}demo${SD}aqxml.ini";
   system("rm $fl" ) ;
   system("echo '[component]' >$fl" ) ;
   system("echo 'CMP_NAME=OC4J_AQ' >>$fl" ) ;
   system("echo 'HTTP_PORT=5760'>>$fl" ) ;
   system("echo 'JMS_PORT=5740'>>$fl" ) ;
   system("echo 'RMI_PORT=5720'>>$fl" ) ;
   system("echo 'DISTRIBUTED=false\n\n'>>$fl" ) ;
   system("echo '[application]'>>$fl" ) ;
   system("echo 'CMP_NAME=OC4J_AQ'>>$fl" ) ;
   system("echo 'APP_DEPLOYMENT_NAME=aqxmldemo'>>$fl" ) ;
   system("echo 'APP_LOCATION=$ORACLE_HOME/rdbms/demo/aqxmldemo.ear'>>$fl" ) ;
   system("echo 'WEB_APP_NAME=aqxmldemo_web'>>$fl" ) ;
   system("echo 'CONTEXT_ROOT=/aqserv/servlet\n\n'>>$fl" ) ;
}

sub make_secure {
 print "Secure website ....\n";
$file =
    "${AQXML_OC4J_HOME}${SD}j2ee${SD}OC4J_AQ${SD}config${SD}http-web-site.xml";
$keystorefile= "${ORACLE_HOME}${SD}rdbms${SD}demo${SD}keystore";
  system ("cp $file $file.prot") ;
  open(IN, "< $file.prot");
  open(OUT, ">$file");
  while (<IN>) {
    s!port=!secure="true" port=!;
    s!load-on-startup!max-inactivity-time="200" shared="true" load-on-startup!;
    s!</web-site>!<ssl-config keystore="$keystorefile" keystore-password="welcome" />\n</web-site>!;
  print OUT;
  }
  close IN ; close OUT;
}
