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
my ($score) ;
my ($size) = 300  ;
my $MINDIST = 2 ;
$, = "  ";

my ($RESULTDIR,$PDBDIR) = util_SetEnvVars();
#my $PDBDIR = "/home/ws18/PDB.all/";

GetOptions(
            "infile=s"=>\$infile ,
            "size=i"=>\$size ,
            "outfile=s"=>\$outfile ,
            "onatom"=>\$onatom 
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);

usage( "Need to give a infile => option -infile ") if(!defined $infile);
my $sites = "$infile.sites.frc";
my $ofhsites     = util_write($sites);

my $prm = "$infile.prm";
my $ofhprm  ;
$ofhprm     = util_write($prm);

ProcessOne($infile);



sub ProcessOne{
      my ($proteinName) = @_ ; 

       my $pdbfile = $PDBDIR . uc($proteinName) . ".pdb";
       my $pdb = new PDB();
       #$pdb->SetLogFile($ofh);
       $pdb->ReadPDB($pdbfile);
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
	           print " finalscore,bestCavityNum,maxdoesexist,mindoesntexist $finalscore,$bestCavityNum,$maxdoesexist,$mindoesntexist \n;";
                my @atoms = @{$result->{ATOMS}}; 
print $ofhprm "gsize=$size \n";
print $ofhprm "scale=1.0 \n";
print $ofhprm "in(pdb,file=\"$pdbfile\") \n";
print $ofhprm "in(siz,file=\"charm22.siz\") \n";
print $ofhprm "in(crg,file=\"charm22.crg\") \n";
print $ofhprm "in(frc,file=\"$infile.sites.frc\") \n";
				ProcessAtomList($proteinName,$pdb,\@atoms,$pdbfile);
print $ofhprm "indi=2.0 \n";
print $ofhprm "exdi=78.0 \n";
print $ofhprm "prbrad=1.4 \n";
print $ofhprm "salt=0.0 \n";
print $ofhprm "ionrad=2.0 \n";
print $ofhprm "bndcon=4 \n";
print $ofhprm "maxc=0.0001 \n";
print $ofhprm "linit=400 \n";
print $ofhprm "!nonit=800 \n";
print $ofhprm "energy(s,c,g) \n";
print $ofhprm "write(frc) \n";
			}
}

sub ProcessAtomList{
      my ($proteinName,$pdb,$atoms,$pdbfile) = @_ ; 
	  my @atoms = @{$atoms};

       my @values = ();
       my @atomlist = (); 
	   my $once = 1 ; 
       foreach my $atom (@atoms){
       		my ($res,$num,$type) = split "/", $atom ;
    		#print "$res,$num,$type\n";
    		my $resObj = $pdb->GetResidueIdx($num);
    		my ($a) = $pdb->GetAtomFromResidueAndType($num,$type) or die ;
    		push @atomlist, $a ;
			my ($x,$y,$z) = $a->Coords();
			my $ORIGLINE = $a->GetOrigLine();
	        print $ofhsites "$ORIGLINE \n";


			if($once){
                print $ofhprm "acenter($x,$y,$z) \n";
				#$once = 0 ; 
			}

       }

	print $ofhprm "\n";
	print $ofhsites "\n";
}

    
sub usage{
my ($msg) = @_ ;
print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
   die ;
}
