#!/usr/local/bin/perl
#
# insert the commands you wish to execute when eml fails to stay running. 
#
#
# Mail to specified user
#
#  uncomment out the following lines and specify a valid email address
#  in place of nobody@somewhere.nowhere to send the failure email.
#  The message text is passed in as the first parameter. 
#  The subject is passed in as the optional second parameter.  Default subject is 'Enterprise Manager is down'
#

use strict;
use Oraperl;
use Time::HiRes;

require "emd_common.pl";
require "semd_common.pl";

sub send_mailx
{
  my $start_time = Time::HiRes::time;
  my $targetname = "$ENV{EM_REPOS_USER}1234";
  my $fn = get_tmp_filename ($targetname, "emrepdown");
  EMD_PERL_DEBUG("opened $fn");
  system "date > $fn";
  if(!open(FH, ">>$fn")) 
  {
    EMD_PERL_ERROR("Could not open $fn for error messages");
  }
  my $subject="Enterprise Manager is Down";
  if ($#ARGV+1 > 0) 
  {
    if ($#ARGV+1 > 1) 
    {
      print FH "$ARGV[1]\n";
      print FH "Error message: ";
      print FH "$ARGV[0]\n";
      $subject=$ARGV[1]; 
    } 
    else 
    {
      print FH "Enterprise Manager is down.\n";
      print FH "Error message: ";
      print FH "$ARGV[0]\n";
    }
  } 
  else 
  {
    print FH "Enterprise Manager is down.\n";
  }

  if(!close FH) 
  {
    EMD_PERL_ERROR("Could not close $fn");
  }

  my $filename="../sysman/config/emd.properties";
  if ( $ENV{EMDROOT} ne "" ) 
  {
    $filename="$ENV{EMDROOT}/sysman/config/emd.properties";
  }

  my $command1="cat $filename | grep -i EMD_EMAIL_ADDRESS= | sed s?EMD_EMAIL_ADDRESS=??i | awk '{print $1}'";
  EMD_PERL_DEBUG ("list command1=$command1");
  my $list=`$command1` or EMD_PERL_ERROR("Could not execute $command1");
  $command1="cat $filename | grep -i EMD_FROM_EMAIL_ADDRESS= | sed s?EMD_FROM_EMAIL_ADDRESS=??i | awk '{print $1}'";
  EMD_PERL_DEBUG ("return command1=$command1");
  my $return=`$command1` or EMD_PERL_ERROR("Could not execute $command1");
  my $out;
  chomp($return);
  chomp($list);
  EMD_PERL_DEBUG ("list=$list");
  EMD_PERL_DEBUG ("return=$return");

  if ( "$list" eq "" ) 
  {
    EMD_PERL_ERROR("email address list is empty");
  } 
  else 
  {
    if ("$return" eq "" ) 
    {
      $command1 = "`mailx -s \"$subject\" $list \< $fn`";
      EMD_PERL_DEBUG("command1=$command1");
      system $command1;
    } 
    else 
    {
      $command1 = "`mailx -s \"$subject\" -r $return $list < $fn`";
      EMD_PERL_DEBUG("command1=$command1");
      system $command1;
    }
  }
  $out = `rm $fn`;
  EMD_PERL_DEBUG("out=$out");
}

my $platform = get_osType();
if(($platform eq "SOL") ||
   ($platform eq "HP") ||
   ($platform eq "LNX") ||
   ($platform eq "AIX") ||
   ($platform eq "OSF1"))
{
  send_mailx();  
}
else
{
  EMD_PERL_ERROR("Platform $platform does not support mailx.");
}
