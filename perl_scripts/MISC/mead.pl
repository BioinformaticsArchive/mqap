#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;
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
my $MINDIST = 2 ;
$, = "  ";

my ($RESULTDIR,$PDBDIR) = util_SetEnvVars();

GetOptions(
            "infile=s"=>\$infile ,
            "outfile=s"=>\$outfile ,
            "onatom"=>\$onatom 
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);

usage( "Need to give a infile => option -infile ") if(!defined $infile);
my $ftp = "$infile.fpt";
my $ofh     = util_write($ftp);
my $ogm = "$infile.ogm";
my $ofhogm  ;
$ofhogm     = util_write($ogm) if(defined $onatom); 

ProcessOne($infile);



sub ProcessOne{
      my ($proteinName) = @_ ; 

       my $pdbfile = $PDBDIR . uc($proteinName) . ".pdb";
       my $pdb = new PDB();
       $pdb->SetLogFile($ofh);
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
	           ($finalscore,$bestCavityNum,$maxdoesexist,$mindoesntexist) = ConfigPDB_ScoreSingleResultForCavity($result,$cavities,$ofh,$finalscore);
	           print " finalscore,bestCavityNum,maxdoesexist,mindoesntexist $finalscore,$bestCavityNum,$maxdoesexist,$mindoesntexist \n;";
                my @atoms = @{$result->{ATOMS}}; 
				ProcessAtomList($proteinName,$pdb,\@atoms);
			}
}

sub ProcessAtomList{
      my ($proteinName,$pdb,$atoms) = @_ ; 
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
	        print $ofh "( $x , $y , $z ) \n";
			if($once && $onatom){
	            print $ofhogm " $x  $y  $z 201 1.0 \n";
				$once = 0 ; 
			}
       }

	print $ofh "\n";
}

    
sub usage{
my ($msg) = @_ ;
print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
   die ;
}
