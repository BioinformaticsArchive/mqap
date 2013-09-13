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
my ($pdb1,$pdb2,$infile,$outfile,$weightfile,$dontrunpymol,$svm,$single);
my ($interactive,$annotate,$positive,$negative,$maxresults,$inconf,$outconf,$train,$check,$meanfile);
my ($grpconfig) = $ENV{CONFIGGRP} or die ;
my ($score) ;
my $MINDIST = 2 ;
$, = "  ";


my ($RESULTDIR,$PDBDIR) = util_SetEnvVars();

GetOptions(
            "train"=>\$train ,
            "single=s"=>\$single ,
            "svm=s"=>\$svm ,
            "infile=s"=>\$infile ,
            "negative=s"=>\$negative ,
            "positive=s"=>\$positive ,
            "weightfile=s"=>\$weightfile ,
            "maxresults=i"=>\$maxresults ,
            "outfile=s"=>\$outfile 
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);

usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
my $ofh     = util_write($outfile);
usage( "Need to give a output file for svm train=> option -svm ") if(!defined $svm);
my $svmofh     = util_write($svm);


if(defined $single){
    GetFeaturesForProteins("+1",$single);
}
else{
    usage( "Need to give a input file for positive training => option -positive ") if(!defined $positive);
    usage( "Need to give a input file for negative training => option -negative ") if(!defined $negative);
    ProcessOneRun($positive,$negative);
}




sub ProcessOneRun{
	my ($positive,$negative) = @_ ; 
	print "Processing Postives\n";
    GetFeaturesForProteins("+1",$positive);
    GetFeaturesForProteins("-1",$negative);
}

sub GetFeaturesForProtein{
      my ($val,$proteinName,$results) = @_ ; 

       my $pdbfile = $PDBDIR . uc($proteinName) . ".pdb";
       my $pdb = new PDB();
       $pdb->SetLogFile($ofh);
       $pdb->ReadPDB($pdbfile);
	   my $lc = lc($proteinName); 
	   my $uc = uc($proteinName); 
	   print "/home/cavity/CAVITY/ALL.1.4/working/JID$lc*poc \n";
       #my $cavityfile = </home/cavity/CAVITY/ALL.1.4/working/JID$lc*poc> or die;
       my $cavityfile = "$lc.poc";
	   print "$cavityfile lll \n";
       my $cavities ; 
       # $cavities =  ConfigPDB_ParseCavityFile($cavityfile);
    
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
	           ($finalscore,$bestCavityNum,$maxdoesexist,$mindoesntexist) = ConfigPDB_ScoreSingleResultForCavity($result,$cavities,$ofh,$finalscore);
	           print " finalscore,bestCavityNum,maxdoesexist,mindoesntexist $finalscore,$bestCavityNum,$maxdoesexist,$mindoesntexist \n;";
                my @atoms = @{$result->{ATOMS}}; 
				ProcessAtomList($val,$proteinName,$pdb,$results,\@atoms,$maxdoesexist);
			}
}

sub ProcessAtomList{
      my ($val,$proteinName,$pdb,$results,$atoms,$maxdoesexist) = @_ ; 
	  my @atoms = @{$atoms};

       my @values = ();
       my @atomlist = (); 
       foreach my $atom (@atoms){
       		my ($res,$num,$type) = split "/", $atom ;
    		#print "$res,$num,$type\n";
    		my $resObj = $pdb->GetResidueIdx($num);
    		my ($a) = $pdb->GetAtomFromResidueAndType($num,$type) or die ;
    		push @atomlist, $a ;
       }

	   my $len = @atomlist ;
	   print "Size of atomlist = $len \n";
    
    
    	#print "Now getting distances \n";
        my $iter = combinations(\@atomlist, 2);
        while (my $c = $iter->next) {
            my @combo = @{$c} ; 
    		my ($atom1) = $combo[0];
    		my ($atom2) = $combo[1];

			# todo - why r we getting here for 2DNQ
			next if(!defined $atom1);
			next if(!defined $atom2);

    		my $d = $atom1->Distance($atom2) ;
    		push @values, $d ; 
    	}
    
    	#print "Now getting angles \n";
        my $iter = combinations(\@atomlist, 3);
		my $cnt =0 ; 
        while (my $c = $iter->next) {
            my @combo = @{$c} ; 
    		my ($atom1) = $combo[0] or next;
    		my ($atom2) = $combo[1] or next;
    		my ($atom3) = $combo[2] or next;

			# todo - why r we getting here for 2GLU
			next  if(!defined $atom1);
			next if(!defined $atom2);
			next if(!defined $atom3);
			$cnt++;

    		my (@angles) = $pdb->AngleBetweenThreeGivenAtomsPermuted($atom1,$atom2,$atom3);
    		# push @values, @angles;
    	}
		print "cnt = $cnt\n";

    	$, = "\t";
    	print $ofh  "$proteinName ", @values, "\n";
    	push @{$results}, \@values; 
		PrintSVM($maxdoesexist,$val,@values);
}

sub PrintSVM{
	my ($maxdoesexist,$val,@values) = @_ ; 
	print $svmofh "$val ";
	my $cnt = 1 ; 
	foreach my $v (@values){
	     print $svmofh " $cnt:$v ";
		 $cnt++ ;
	}
	#print $svmofh " $cnt:$maxdoesexist ";

	print $svmofh "\n";
}

sub GetFeaturesForProteins{
	my ($val,$infileOrName) = @_ ; 
    my @results ; 
	if(defined $single){
	    GetFeaturesForProtein($val,$single,\@results);
	}
	else{
        my @proteinSet = util_read_list_words($infileOrName);
        foreach my $proteinName (@proteinSet){
			print "====================\n\n";
	        GetFeaturesForProtein($val,$proteinName,\@results);
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
