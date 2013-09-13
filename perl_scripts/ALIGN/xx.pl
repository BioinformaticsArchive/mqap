#!/usr/bin/perl -w 
use strict ;
use PDB;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use ConfigPDB;
use MyGeom;
use MyPymol;
use Math::Geometry ;
use Math::VectorReal qw(:all);  # Include O X Y Z axis constant vectors




my $ADDONLYREACTIVE = 0 ; 
my $MATCHREVERSE = 0 ;
my $POTENTIALMATCH = 0 ;
my $DISTANCEMATCH = 1  ;

use Time::HiRes qw( usleep ualarm gettimeofday tv_interval clock_gettime clock_getres  clock);
use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($ann,$config,$p1,$p2,$infile,$outfile,$which_tech,$listfile,$protein);
my $DISTANCEWITHOUTSEQMATCH = 1 ;
my $verbose = 1 ;

my ($verify,$radii,$before1,$before2);
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "protein=s"=>\$protein ,
            "verify"=>\$verify ,
            "p1=s"=>\$p1 ,
            "p2=s"=>\$p2 ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "ann=s"=>\$ann ,
            "config=s"=>\$config,
            "radii=i"=>\$radii ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);

my @outfiles ; 
my @proteins = qw (IMI MER 1RG);
foreach my $i (@proteins){
   my $outfile1 = "$i.rotated.pdb";
   push @outfiles, $outfile1 ;
}

my @atoms ;
my $outpymol = "XXX.p1m";
my $outpymolfh = util_write($outpymol);
util_PrintPymolWithAllProteins($outpymolfh,\@outfiles,\@atoms);

