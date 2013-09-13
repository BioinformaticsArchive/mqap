#!/usr/bin/perl -w 
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
use strict ;
my $commandline = util_get_cmdline("",\@ARGV) ;
my $onatom ;
my ($pdb1,$pdb2,$proteinName,$outfile,$weightfile,$dontrunpymol,$svm,$single);
my ($interactive,$annotate,$positive,$negative,$maxresults,$inconf,$outconf,$train,$check,$meanfile);
my ($grpconfig) = $ENV{CONFIGGRP} or die ;
my ($pqrfile,$extrapoint,$distancefile) ;
my ($potential) ;
my $MINDIST = 2 ;
$, = "  ";


my ($RESULTDIR,$PDBDIR) = util_SetEnvVars();

my $index ; 

my $resultfile ;
my $howmany = 1 ;
GetOptions(
            "proteinName=s"=>\$proteinName ,
            "pqrfile=s"=>\$pqrfile ,
            "potential=s"=>\$potential ,
            "extrapoint"=>\$extrapoint ,
            "outfile=s"=>\$outfile ,
            "distancefile=s"=>\$distancefile ,
            "resultfile=s"=>\$resultfile ,
            "index=i"=>\$index ,
            "howmany=i"=>\$howmany ,
            "onatom"=>\$onatom 
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);

usage( "Need to give a proteinName => option -proteinName ") if(!defined $proteinName);
usage( "Need to give a pqrfile => option -pqrfile ") if(!defined $pqrfile);
usage( "Need to give a outfile => option -outfile ") if(!defined $outfile);
usage( "Need to give a distancefile => option -distancefile ") if(!defined $distancefile);
usage( "Need to give a potential => option -potential ") if(!defined $potential);
#usage( "Need to give a index => option -index ") if(!defined $index);
usage( "Need to give a resultfile => option -resultfile ") if(!defined $resultfile);
my $ofh = util_append($outfile);
my $ofhdist = util_append($distancefile);
print STDERR "Writing output to file $outfile \n";

my @pots = ();
util_readAPBSPotential(\@pots,$potential);


my $pqr = new PDB();
$pqr->ReadPDB($pqrfile);


ProcessOne($proteinName);




sub ProcessOne{
      my ($proteinName) = @_ ; 

       my $pdbfile = $PDBDIR ."/" . uc($proteinName) . ".pdb";
       my $pdb = new PDB();
       $pdb->ReadPDB($pdbfile);

	   my $lc = lc($proteinName); 
	   my $uc = uc($proteinName); 
    
            my @atoms = (); 
            my @r= ConfigPDB_ParseResultsFile($resultfile,$howmany);

			my $lll = @r ;
			print "There were $lll \n";
			foreach my $result (@r){
print $ofh "Starting read\n";
print $ofh "Resultfile is $resultfile \n";
               my ($finalscore,$bestCavityNum,$maxdoesexist,$mindoesntexist) ;
               $finalscore = 10000 ;
			   my $cavities ;
			   my $ofhprm ;
	           ($finalscore,$bestCavityNum,$maxdoesexist,$mindoesntexist) = ConfigPDB_ScoreSingleResultForCavity($result,$cavities,$ofhprm,$finalscore);
                my @atoms = @{$result->{ATOMS}}; 
				ProcessAtomList($proteinName,$pdb,\@atoms);
print $ofh "Ending read\n";
			}
}

sub ProcessAtomList{
      my ($proteinName,$pdb,$atoms) = @_ ; 
	  my @atoms = @{$atoms};

       my @values = ();
       my @atomlist = (); 
	   my $once = 1 ; 
	   my $natoms = @atoms ;
	   #print STDERR " =========================== \n";
	   #print STDERR " There were $natoms atoms \n";
	   #print STDERR " =========================== \n";

	   my @atomobjs ; 
       foreach my $atom (@atoms){
       		my ($res,$num,$type) = split "/", $atom ;
			#$type = "NE2" if($type eq "ND1");
    		#print "$res,$num,$type\n";
    		my $resObj = $pdb->GetResidueIdx($num);
    		my ($a) = $pdb->GetAtomFromResidueAndType($num,$type) or die ;
			push @atomobjs, $a ;

    		my $resObjPqr = $pqr->GetResidueIdx($num);
    		my ($aPqr) = $pqr->GetAtomFromResidueAndType($num,$type) or die ;

			my ($x,$y,$z) = $a->Coords();
			my ($x1,$y1,$z1) = $aPqr->Coords();

			my ($i1) = $a->GetIdx();
			my ($i2) = $aPqr->GetIdx();


			print $ofh " ($x,$y,$z, index in pdb $i1) \n";
			print $ofh " ($x1,$y1,$z1,index in pqr $i2) \n";

			#imp -1 
			my $pot = $pots[$i2-1] or die "Expected to find potential";
			print $ofh " potential = $pot \n";

       }

	   my @distlist = @{$pdb->DistanceInGivenSetOfAtoms(\@atomobjs)};
	   print $ofhdist  @distlist, "\n";


	   if(defined $extrapoint){
    	#my ($aPqr) = $pqr->GetAtomFromResidueAndType(26,"Na") or die ;
		my @a = $pqr->GetAtoms();
		my $idx = 0 ;
		foreach my $a (@a){
		    my ($i2) = $a->GetIdx();
		    if($i2 == 20000){
	           my $pot = $pots[$idx];
		       print $ofh " potential = $pot \n";
			}
			$idx++;
		}
	   }

}

    
sub usage{
my ($msg) = @_ ;
print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
   die ;
}
