#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use MyUtils;

use PDB;
use Atom;
use Residue;
use ConfigPDB;

use Math::NumberCruncher;
use Algorithm::Combinatorics qw(combinations) ;


use POSIX qw(floor);
use Math::Combinatorics;
my $commandline = util_get_cmdline("",\@ARGV) ;
my $onatom ;
my ($pdb1,$pdb2,$infile,$outfile,$weightfile,$dontrunpymol,$svm,$single);
my ($interactive,$annotate,$positive,$negative,$maxresults,$inconf,$outconf,$train,$check,$meanfile);
my ($grpconfig) = $ENV{CONFIGGRP} or die ;
my ($pqrfile) ;
my ($potential) ;
my $MINDIST = 2 ;
$, = "  ";


my ($RESULTDIR,$PDBDIR) = util_SetEnvVars();

print STDERR "WARNING: Make sure you have the correct RESULTDIR \n";
sleep (1);


GetOptions(
            "infile=s"=>\$infile ,
            "pqrfile=s"=>\$pqrfile ,
            "potential=s"=>\$potential ,
            "outfile=s"=>\$outfile ,
            "onatom"=>\$onatom 
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);

usage( "Need to give a infile => option -infile ") if(!defined $infile);
usage( "Need to give a pqrfile => option -pqrfile ") if(!defined $pqrfile);
usage( "Need to give a outfile => option -outfile ") if(!defined $outfile);

my @l = util_read_list_sentences($infile);
my $l = $l[0];

my $pqr = new PDB();
$pqr->ReadPDB($pqrfile);
$pqr->InsertAtom($l);
$pqr->WritePQR($outfile);


sub usage{
    my ($msg) = @_ ;
	print $msg , "\n" ;
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
	die ;
}

