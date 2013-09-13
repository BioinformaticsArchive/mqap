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
my ($pdb1,$pdb2,$infile,$outfile,$metalion,$dontrunpymol);
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
            "metalion=s"=>\$metalion ,
            "resultfile=s"=>\$resultfile ,
            "maxresults=i"=>\$maxresults ,
            "dist=f"=>\$dist ,
            "inconf=s"=>\$inconf ,
            "outconf=s"=>\$outconf ,
            "grpconfig=s"=>\$grpconfig ,
            "outfile=s"=>\$outfile 
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
usage( "Need to give a dist") if(!defined $dist);
usage( "Need to give a metalion") if(!defined $metalion);
usage( "Need to give a protein") if(!defined $pdb1);
my $ofh = util_append($outfile);
my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC) = util_SetEnvVars();


#usage( "Need to give a second protein pdb name => option -pdb2 ") if(!defined $pdb2);
my $protein = $pdb1 ;
$pdb1 = "$PDBDIR/$pdb1.pdb";

my $pdb = new PDB();
$pdb->SetLogFile($ofh);
$pdb->ReadPDB($pdb1);
my $return = $pdb->ProcessMetalIon($metalion,$dist);



foreach my $r (keys %{$return}){
	my $doneatoms = $return->{$r} ; 
    #foreach my $k (sort {$a <=> $b}  values %{$doneatoms}){
    my @newScores ; 
    foreach my $k (sort {$a <=> $b}  keys %{$doneatoms}){
	    my $a = $pdb->GetAtomIdx($k);
	    my $atomnm = $a->GetName();
		my $resname = $a->GetResName();
		my $atomtype = $a->GetType();
		my $KEY = "$resname/$atomtype";
		my $KEYONLYRES = "$resname";

		my $dist = $doneatoms->{$k};
		my $X ; 
		$X->{NEWSCORE} = $dist ;
		$X->{ATOMNM} = $atomnm ;
		$X->{IDX} = $k ;
		$X->{KEY} = $KEY ;
		$X->{KEYONLYRES} = $KEYONLYRES ;
		push @newScores, $X ;
	}

    my @resultssorted = sort { $a->{NEWSCORE} <=> $b->{NEWSCORE} } @newScores ;
	my $sumofkeys = "";
	my $sumofkeysonlyres = "";
    foreach my $X (@resultssorted){
		    my $dist = $X->{NEWSCORE} ;
		    my $atomnm = $X->{ATOMNM} ;
			next if($atomnm =~ /HOH/);
		    my $idx = $X->{IDX} ;
		    my $KEY = $X->{KEY} ;
		    my $KEYONLYRES = $X->{KEYONLYRES} ;
			$sumofkeys = $sumofkeys . ".$KEY";
			$sumofkeysonlyres = $sumofkeysonlyres . ".$KEYONLYRES";
	        print $ofh "$dist,$atomnm,$idx, ";
    }
	print $ofh " $sumofkeys \n";
	print $ofh "KEY $protein $sumofkeys \n";
	print $ofh "KEYONLYRES $protein $sumofkeysonlyres \n";
}

sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
