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

use POSIX qw(floor);
use Math::Combinatorics;
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($pdb1,$pdb2,$infile,$outfile,$newtype,$dontrunpymol);
my ($interactive,$annotate,$resnum,$findresidues,$maxresults,$inconf,$outconf,$resultfile,$checkself);
my ($grpconfig) = $ENV{CONFIGGRP} or die ;
my $MINresnum = 2 ;
$, = "  ";
GetOptions(
            "pdb=s"=>\$pdb1 ,
            "annotate"=>\$annotate ,
            "interactive"=>\$interactive ,
            "checkself"=>\$checkself ,
            "dontrunpymol"=>\$dontrunpymol ,
            "findresidues"=>\$findresidues ,
            "newtype=s"=>\$newtype ,
            "resultfile=s"=>\$resultfile ,
            "maxresults=i"=>\$maxresults ,
            "resnum=f"=>\$resnum ,
            "inconf=s"=>\$inconf ,
            "outconf=s"=>\$outconf ,
            "grpconfig=s"=>\$grpconfig ,
            "outfile=s"=>\$outfile 
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
usage( "Need to give a resnum") if(!defined $resnum);
usage( "Need to give a newtype") if(!defined $newtype);
my $ofh = util_write($outfile);
my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC) = util_SetEnvVars();


usage( "Need to give a protein pdb name => option -pdb ") if(!defined $pdb1);
$pdb1 = "$PDBDIR/$pdb1.pdb";

my $pdb = new PDB();
$pdb->SetLogFile($ofh);
$pdb->ReadPDB($pdb1);
$pdb->ReplaceType($resnum,$newtype);
$pdb->WritePDB($outfile,1,1);


sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
