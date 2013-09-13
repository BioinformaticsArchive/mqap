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
my ($pdb,$score) ;
my ($size) = 300  ;
my $MINDIST = 2 ;
$, = "  ";


my ($RESULTDIR,$PDBDIR) = util_SetEnvVars();
#my $PDBDIR = "/home/ws18/PDB.all/";

GetOptions(
            "pdb=s"=>\$pdb ,
            "size=i"=>\$size ,
            "outfile=s"=>\$outfile ,
            "onatom"=>\$onatom 
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);

usage( "Need to give a pdb id => option -pdb") if(!defined $pdb);
usage( "Need to give a output option -out") if(!defined $outfile);

ProcessOne($pdb);


my $ofhprm ;

sub ProcessOne{
      my ($proteinName) = @_ ; 

       my $pdbfile = $PDBDIR . uc($proteinName) . ".pdb";
       my $pdb = new PDB();
       $pdb->ReadPDB($pdbfile);

	   my $before = $pdb->DistanceMatrix();
	   my $lc = lc($proteinName); 
	   my $uc = uc($proteinName); 
    
            my @atoms = (); 
            my $resultfile = $RESULTDIR .  $uc . ".pdb.out";
			print "Resultfile is $resultfile \n";
			my $howmany ;
			$howmany = 1 if(!defined $single);
			$howmany = 1 ;
            my @r= ConfigPDB_ParseResultsFile($resultfile,$howmany);
			foreach my $result (@r){
               my ($finalscore,$bestCavityNum,$maxdoesexist,$mindoesntexist) ;
               $finalscore = 10000 ;
			   my $cavities ;
	           ($finalscore,$bestCavityNum,$maxdoesexist,$mindoesntexist) = ConfigPDB_ScoreSingleResultForCavity($result,$cavities,$ofhprm,$finalscore);
                my @atoms = @{$result->{ATOMS}}; 
				my $a0 = $pdb->ParseAtomLine($atoms[0]);
				my $a1 = $pdb->ParseAtomLine($atoms[1]);

				$pdb->AlignXto2Atoms($a0,$a1);
			}

			my $after = $pdb->DistanceMatrix();
			print STDERR "Verifying distances \n";
			if(! $pdb->VerifyDistanceMatices($after,$before)){
				die "PDBS are different \n";
			}

	$pdb->WritePDB($outfile);
}

    
sub usage{
my ($msg) = @_ ;
print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
   die ;
}
