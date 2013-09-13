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
my ($pdb1,$pdb2,$infile,$outfile,$atomidx,$dontrunpymol);
my ($interactive,$annotate,$dist,$mutatefile,$maxresults,$inconf,$outconf,$resultfile,$checkself);
my ($grpconfig) = $ENV{CONFIGGRP} or die ;
my $MINDIST = 2 ;
$, = "  ";
GetOptions(
            "pdb1=s"=>\$pdb1 ,
            "mutatefile=s"=>\$mutatefile ,
            "outfile=s"=>\$outfile 
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give pdb ") if(!defined $pdb1);
my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC) = util_SetEnvVars();


usage( "Need to pdb name => option -pdb ") if(!defined $pdb1);
my $origpdb = $pdb1 ;
$pdb1 = "$PDBDIR/$pdb1.pdb";

my $pdb = new PDB();
$pdb->ReadPDB($pdb1);

$outfile = "$origpdb.ALL.1.fasta";
my $ofh = util_write($outfile);
if(defined $mutatefile){
    $pdb->Mutate($mutatefile);
}
$pdb->WriteFasta($origpdb,$ofh);
print STDERR "Wrote fasta in $outfile\n";




sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
