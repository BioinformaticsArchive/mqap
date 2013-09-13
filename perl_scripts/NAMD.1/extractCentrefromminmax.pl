#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use ConfigPDB;
use MyGeom;
use PDB;

use Time::HiRes qw( usleep ualarm gettimeofday tv_interval clock_gettime clock_getres  clock);
use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($logfile,$outfile,$which_tech,$config,$protein);
my (@expressions);
my $howmany = 100000 ;
my $verbose = 1 ;
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "protein=s"=>\$protein ,
            "logfile=s"=>\$logfile ,
            "config=s"=>\$config ,
            "outfile=s"=>\$outfile ,
            "expr=s"=>\@expressions,
            "howmany=i"=>\$howmany ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
my $ofh = util_write($outfile);
usage( "Need to give a input file name => option -logfile ") if(!defined $logfile);
my $ifh = util_read($logfile);
my $ifhconfig = util_read($config);
usage( "Need to give a config -option -config  ") if(!defined $config);

my $line ;
while(<$ifh>){
     if(/^{/){
	 	$line = <$ifh> ; 
		last ; 
	}
}

while(<$ifhconfig>){
     if(/cellOrigin/){
		print $ofh "cellOrigin $line\n";
	}
	else{
		print $ofh $_ ; 
	}
}

print "Changing cellOrigin to $line \n";

sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
