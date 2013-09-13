#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
  use Time::HiRes qw( usleep ualarm gettimeofday tv_interval
   clock_gettime clock_getres  clock
   );


use PDB;
use Atom;
use Residue;
use MyPymol;

use POSIX qw(floor);
use Math::Combinatorics;
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($pdb1,$listfile,$pdb2,$infile,$scriptname,$outfile,$atomidx,$dontrunpymol);
my ($interactive,$annotate,$ignorewater,$dist,$findresidues,$maxresults,$inconf,$outconf,$resultfile,$checkself);
my ($grpconfig) = $ENV{CONFIGGRP} or die ;
my $MINDIST = 2 ;
$, = "  ";
GetOptions(
            "pdb1=s"=>\$pdb1 ,
            "atomidx=s"=>\$atomidx ,
            "dist=f"=>\$dist ,
            "listfile=s"=>\$listfile ,
            "inconf=s"=>\$inconf ,
            "scriptname=s"=>\$scriptname ,
            "outconf=s"=>\$outconf ,
            "outfile=s"=>\$outfile 
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a scriptname") if(!defined $scriptname);
usage( "Need to give a listfile -option -listfile  ") if(!defined $listfile);


my @images= util_read_list_sentences($listfile);

util_MakeMovieFromImages($scriptname,@images);


sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
