#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use Time::HiRes qw( usleep ualarm gettimeofday tv_interval clock_gettime clock_getres clock);


use PDB;
use Atom;
use Residue;
use ConfigPDB ;
use SimNode ;
use SimState ;
use SimConfig ;

use POSIX qw(floor);
use Math::Combinatorics;
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($junk,$pdb1,$pdb2,$infile,$data,$delforpot,$outfile,$atomidx,$dontrunpymol);
my ($resnum,$interactive,$annotate,$wdist,$dist,$findresidues,$maxresults,$inconf,$outconf,$resultfile,$checkself);
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
            "atomidx=s"=>\$atomidx ,
            "resultfile=s"=>\$resultfile ,
            "maxresults=i"=>\$maxresults ,
            "delforpot=i"=>\$delforpot,
            "resnum=i"=>\$resnum ,
            "dist=f"=>\$dist ,
            "wdist=f"=>\$wdist ,
            "inconf=s"=>\$inconf ,
            "outconf=s"=>\$outconf ,
            "grpconfig=s"=>\$grpconfig ,
            "outfile=s"=>\$outfile 
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give pdb ") if(!defined $pdb1);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
usage( "Need to give a dist") if(!defined $dist);
usage( "Need to give a wdist") if(!defined $wdist);
usage( "Need to give a atom index or residue number") if(!defined $atomidx && !defined $resnum);
my $ofh = util_append($outfile);
my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC) = util_SetEnvVars();

($grpconfig) = $ENV{CONFIGGRP} or die ;
ConfigPDB_Init($grpconfig);

my $FH = util_read($outfile);
my $seenPaths = {};
while(<$FH>){
     next if(/^\s*$/);
	 chomp; 
	 my ($nm,@junk) = split ;
	 $seenPaths->{$nm} = 1 ;
}

#usage( "Need to give a second protein pdb name => option -pdb2 ") if(!defined $pdb2);
my $origpdb = $pdb1 ;
$pdb1 = "$PDBDIR/$pdb1.pdb";

my $pdb = new PDB();
$pdb->SetLogFile($ofh);
$pdb->ReadPDB($pdb1);

my ($pqr,$pots) = util_readAPBSPotentialFromStart($origpdb,$APBSDIR);


if(defined $resnum){
      my $res = $pdb->GetResidueIdx($resnum);
	  my $type = ConfigPDB_GetAtom($res->GetName());
	  my $atom = $pdb->GetAtomFromResidueAndType($resnum,$type);
	  $atomidx = $atom->GetIdx();

}

my $atom = $pdb->GetAtomIdx($atomidx);
my @atomsdone;
my $done = {};
my $indices = {} ; 
$indices->{$atomidx} = 1 ;
my $simnodes ; 
my $simnode = new SimNode($atomidx,$pdb,$pqr,$pots);
#$simnode->ProcessForces($dist);
#exit ;
$simnode->ProcessSingleAtom($dist,$wdist,$indices);
$simnodes->{$atomidx} = $simnode ;

foreach my $idx (sort keys %{$indices}){
	next if($idx == $atomidx);
    my $simnode = new SimNode($idx,$pdb,$pqr,$pots);
    $simnode->ProcessSingleAtom($dist,$wdist,$indices);
    $simnodes->{$idx} = $simnode ;
}

### You need to stop somewhere - now ProcessSingleAtom will only look at atoms that are
### already there
foreach my $idx (sort keys %{$indices}){
	if(!exists $simnodes->{$idx}){
         my $simnode = new SimNode($idx,$pdb,$pqr,$pots);
         $simnode->ProcessSingleAtom($dist,$wdist,$indices,$indices);
         $simnodes->{$idx} = $simnode ;
	}
}

print STDERR "=====================  Simnodes--------------- \n";
my @allatoms ;
my @allresidues ;
my $allres  = {};
foreach my $idx (keys %{$simnodes}){
	my $atom = $pdb->GetAtomIdx($idx);
	$atom->Print();
	my $resnum = $atom->GetResNum();
	my ($res) = $pdb->GetResidueIdx($resnum);
	my @atoms = $res->GetAtoms();
	push @allatoms ,@atoms ; 
	push @allresidues ,$res ; 
	$allres->{$res->GetResNum()} = $res ; 
}
my $allatomsN = @allatoms ;
my $allresiduesN = @allresidues ;
my $fastafh = util_write("$origpdb.fasta");
my $s2 = "";
my $s1 = "";
foreach my $i (sort  { $a <=> $b }  keys %{$allres}){
	my $r = $allres->{$i} ; 
	my $s = $r->PrintSingleLetter($pdb);
	$s1 = $s1 .  "$s$i," ;
	$s2 = $s2 . "$s" ;
}
print $fastafh "\>$origpdb.$s1;\n";
print $fastafh "$s2\n";

print STDERR "=====================  There are $allatomsN All Atoms and $allresiduesN residues --------------- \n";



my $simconfig = new SimConfig($indices,$simnodes,$pdb,$pqr,$pots,$atomidx,$delforpot,\@allatoms);
my $simstate  = new SimState($indices,$simnodes,$pdb,$pqr,$pots,$atomidx,$simconfig);
my $simnodeInit = $simnodes->{$atomidx} ;

## this will recursively call Step
my ($ret,$list,$endstates,$cnt) = $simstate->Step(0);

my $minmoves ={};


### now ignore paths that end at the same end point - same nodes and same pot diff 
### and choose the one with the smallest path
foreach my $end (@{$endstates}){
	  my ($N,$str) = $end->LastMove();
	  if(!exists $minmoves->{MOVES}->{$str}){
	  	 $minmoves->{MOVES}->{$str} = $N; 
	  	 $minmoves->{SIMNODE}->{$str} = $end; 
	  }
	  else{
	  	 my $v = $minmoves->{MOVES}->{$str};
		 if($v > $N){
	  	      $minmoves->{MOVES}->{$str} = $N ;
	  	      $minmoves->{SIMNODE}->{$str} = $end; 
	     }
		 	
	  }
}

foreach my $end (values %{$minmoves->{SIMNODE}}){
	print STDERR "mmmmmmmmmmm $end \n";
    my $str = $end->PrintPath();
	if(!exists $seenPaths->{$str}){
	    print $ofh "$str $dist $wdist\n" ; 
	}
}



sub usage{
    my ($msg) = @_ ;
    print STDERR $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}

