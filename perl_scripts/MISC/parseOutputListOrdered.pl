#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use MyGeom;
use PDB;
use ConfigPDB;

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
my $ifh = util_read("list.ordered.scores");
while(<$ifh>){
     next if(/^\s*$/);
	 my ($pdb,$score,$aa,$pot,$dis) = (/(.*)RESULT 0  SCORE (.*) AA: (.*) POT: BFILE (.*) DIST: (.*)/) ;
	 my @AA = split " ",$aa ; 
	 my @POT = split " ",$pot ; 
	 my @DIS = split " ",$dis ; 

	 $, = "," ;
	 print "PDB == $pdb\n";
	 print "AA = @AA \n";
	 print "POT = @POT \n";
	 print "DIS = @DIS \n";
}

sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
