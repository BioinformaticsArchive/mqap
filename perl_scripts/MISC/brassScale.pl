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
my ($infile,$outfile,$which_tech,$listfile,$protein);
my (@expressions);
my $howmany = 100000 ;
my $verbose = 1 ;
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "protein=s"=>\$protein ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "expr=s"=>\@expressions,
            "howmany=i"=>\$howmany ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
my $ofh = util_write($outfile);
usage( "Need to give a input file name => option -infile ") if(!defined $infile);
my $ifh = util_read($infile);

ScaleIndices($infile,$outfile);

sub ScaleIndices{
   my ($infile,$outfile) = @_ ; 
   my $ifh = util_read($infile);
   my $ofh = util_write($outfile);
   my $maxProm = 0 ;
   print "Wrote $infile to scaled filr $outfile\n";
   while(<$ifh>){
        chomp ;
        next if(/^\s*$/);
	    my (@l) = split " " , $_ ; 
		my $promIndex = $l[1]; 
		$maxProm = $promIndex if($maxProm < $promIndex);
		print "$promIndex $maxProm ==  \n";
   }


   $ifh = util_read($infile);
   while(<$ifh>){
        chomp ;
        next if(/^\s*$/);
	    my (@l) = split " " , $_ ; 

		my $p = $l[0]; 
		my $promIndex = $l[1]; 
		my $pidx = (1* $promIndex) / $maxProm ;
		print "$pidx \n";
	    print $ofh "$p $pidx \n";
   }

}

chmod 0777, $outfile ;

sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
