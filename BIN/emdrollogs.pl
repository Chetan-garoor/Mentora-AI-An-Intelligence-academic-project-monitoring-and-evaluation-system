#!/usr/local/bin/perl
# 
# $Header: emdrollogs.pl 04-apr-2002.12:13:44 jabramso Exp $
#
# rollogs.pl
# 
# Copyright (c) 2001, 2002, Oracle Corporation.  All rights reserved.  
#
#    NAME
#      rollogs.pl - script to rotate log files 
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
# Script to contain size of log files by switching(rename/replace) log files
# the script takes as inp parameters
#  filename - acts as a prefix for generating filename when log files overflow
#  maxsize - size to limit the filesize (expressing in MB)
#  maxbackups - specifies the rollover count. When this count is exceeded the 
#              the oldest file is purged.
#  checkFreq - determines frequency of file size check when a new line is 
#              written. Default is 0 which checks file size always.
#
# Statements to be logged are expected  from STDIN
#
#    MODIFIED   (MM/DD/YY)
#    jabramso    04/04/02 - Allow explicit continuation of nohup file
#    vnukal      10/11/01 - Merged vnukal_rollover_log
#    vnukal      10/11/01 - Review changes
#    vnukal      10/11/01 - Creation
# 

# Setting up defaults to parameters not passed

my ($filename,$maxsize,$maxbackups,$Count,$checkFreq,$resume_log);

($filename, $maxsize, $maxbackups, $checkFreq, $resume_log) = @ARGV;

if (!defined($filename)) {
    # filename is a mandatory parameter. So print usage and exit
    Usage();
    exit;
}

if (!defined($maxsize) || $maxsize <= 0) {
    $maxsize = 10485760 ; # 10 MB default
}else {
    $maxsize *= 1024 * 1024;
}

if (!defined($maxbackups) || $maxbackups < 1) {
    $maxbackups = 3;
}

if (!defined($checkFreq) || $checkFreq <= 0) {
    $checkFreq = 0;
}

if (!defined($resume_log) || $resume_log != "continue") {
    $resume_log = "rotate";
}

$Count = $checkFreq;

if($resume_log != "continue") {
    rotatefile($filename, $maxbackups);
}
open(LOGFILE,">>$filename") 
    or die "Opening $filename in append mode failed: $!\n";

while(<STDIN>) {
    
    if($Count == 0) {
	my ($size);
	($size) = (stat(LOGFILE))[7];

	if( $size > $maxsize) { # size exceeds limit
	    close(LOGFILE);
	    rotatefile($filename, $maxbackups);
	    open(LOGFILE,">$filename") 
		or die "Reopening $filename in overwrite mode: $!\n";
	}

	# resetting optimize count if asked for.
	if($checkFreq > 0) {
	    $Count = $checkFreq;
	}
    }else {
	$Count--;
    }
	
    print LOGFILE $_;
    select((select(LOGFILE), $| =1)[0]); # flush
}  
close(LOGFILE);


sub rotatefile {
    my ($i,$file, $maxbakups,$tmpfile,$tmpfile2);
    ($file, $maxbakups) = @_;

    if( -e $file.".".$maxbakups ){
	unlink ($file.".".$maxbakups);
    }

    for($i=$maxbakups -1 ; $i >=1 ;$i--) {
	my $nextindex = $i + 1;
	$tmpfile = $file.".".$i;
	$tmpfile2 = $file.".".$nextindex;

	if( -e $tmpfile) {
	    rename($tmpfile,$tmpfile2);
	}
    }
    rename($file,$file."."."1");
}    

sub Usage {
    print "\nUsage : \n";
    print "  $0 <filename> [<maxsz> <maxbackups> <check-freq> <continue>] \n\n";
    print "\tif not specified <maxsz>,<maxbackups> will assume defaults\n";
    print "\t <maxsz> specified in MB. Default is 10 MB \n";
    print "\t Default <maxbackups> is 3 \n";
    print "\t <continue> specifies that we should continue writing to";
    print "\t            existing <filename>";
    print "\tEg: to specify rolling over with 10 maxbackups and default maxsize \n";
    print "\t  $0 em-servlet.log 0 10 \n";
}
