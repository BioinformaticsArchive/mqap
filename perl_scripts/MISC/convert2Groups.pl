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
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
my $ofh = util_write($outfile);
usage( "Need to give a input file name => option -infile ") if(!defined $infile);
my $ifh = util_read($infile);
while(<$ifh>){
#s/PROONLY/PROONLY/;

#s/ALAONLY/NONPOLAR/;
#s/GLYONLY/NONPOLAR/;
#s/ILEONLY/NONPOLAR/;
#s/LEUONLY/NONPOLAR/;
#s/METONLY/NONPOLAR/;
#s/VALONLY/NONPOLAR/;

s/(ALAONLY|GLYONLY|ILEONLY|LEUONLY|METONLY|VALONLY)/NONPOLAR/;

s/CYSONLY/SERINE/g;
s/SERONLY/SERINE/g;
s/THRONLY/SERINE/g;
s/TYRONLY/SERINE/g;

s/HISONLY/BASIC/g;
s/ARGONLY/BASIC/g;
s/LYSONLY/BASIC/g;

s/PHEONLY/AROMATIC/g;
s/TRPONLY/AROMATIC/g;

s/ASPONLY/ACIDIC/g;
s/GLUONLY/ACIDIC/g;

s/GLNONLY/AMIDE/g;
s/ASNONLY/AMIDE/g;
print $ofh $_ ;
}


sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
