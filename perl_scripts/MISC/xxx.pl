#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use ParsePDB;
  use Time::HiRes qw( usleep ualarm gettimeofday tv_interval
   clock_gettime clock_getres  clock
   );


use PDB;
use Atom;
use Residue;

use POSIX qw(floor);
use Math::Combinatorics;
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($pdb1,$pdb2,$infile,$outfile,$residx,$dontrunpymol);
my ($interactive,$annotate,$dist,$findresidues,$maxresults,$inconf,$outconf,$resultfile,$checkself);
my ($grpconfig) = $ENV{CONFIGGRP} or die ;
my $MINDIST = 2 ;
$, = "  ";
GetOptions(
            "pdb1=s"=>\$pdb1 ,
            "annotate"=>\$annotate ,
            "interactive"=>\$interactive ,
            "checkself"=>\$checkself ,
            "dontrunpymol"=>\$dontrunpymol ,
            "findresidues"=>\$findresidues ,
            "residx=s"=>\$residx ,
            "resultfile=s"=>\$resultfile ,
            "maxresults=i"=>\$maxresults ,
            "dist=f"=>\$dist ,
            "inconf=s"=>\$inconf ,
            "outconf=s"=>\$outconf ,
            "grpconfig=s"=>\$grpconfig ,
            "outfile=s"=>\$outfile 
           );


# initialize a PDB object
 my $PDB = ParsePDB->new (FileName => '4mbn.pdb');
 $PDB->Parse;

 # renumber items in the PDB
 $PDB->RenumberModels (ModelStart => '1');
 $PDB->RenumberChains (ChainStart => "A");
 #$PDB->RenumberResidues (ResidueStart => 'A');
 #$PDB->RenumberAtoms (AtomStart => '1');

# # count items in the PDB
 my $a = $PDB->CountModels;
$PDB->CountChains;
 $PDB->CountResidues;
 $PDB->CountAtoms;

print "Count models = $a \n";
