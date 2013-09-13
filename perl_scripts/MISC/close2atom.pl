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
my ($interactive,$annotate,$justone,$ignorewater,$dist,$findresidues,$maxresults,$inconf,$outconf,$resultfile,$checkself);
my ($grpconfig) = $ENV{CONFIGGRP} or die ;
my $MINDIST = 2 ;
$, = "  ";
GetOptions(
            "pdb1=s"=>\$pdb1 ,
            "atomidx=s"=>\$atomidx ,
            "dist=f"=>\$dist ,
            "inconf=s"=>\$inconf ,
            "ignorewater"=>\$ignorewater ,
            "justone"=>\$justone ,
            "outconf=s"=>\$outconf ,
            "outfile=s"=>\$outfile 
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give pdb ") if(!defined $pdb1);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
usage( "Need to give a dist") if(!defined $dist);
usage( "Need to give a atom index") if(!defined $atomidx);
my $ofh = util_write($outfile);


my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC) = util_SetEnvVars();
#usage( "Need to give a second protein pdb name => option -pdb2 ") if(!defined $pdb2);
my $origpdb = $pdb1 ;

my $pdb = new PDB();
$pdb->SetLogFile($ofh);
$pdb->ReadPDB($pdb1);

my @listofatomsclose;
my @names;
my $atom = $pdb->GetAtomIdx($atomidx);

my $list = util_make_list($atom);
my ($junk,$neigh)  = $pdb->GetNeighbourHoodAtom($list,$dist);
my $done ;


my $sort = {} ;
foreach my $a (@{$neigh}){
    my $d = $pdb->DistanceAtoms($atom,$a);
    my $num = $a->GetResNum();
	$a->Print();
    print " $num dist =$d \n";
	$sort->{$d} = $a ; 

    my $atomstr = $a->GetAtomStr();
	next if($atomstr ne "ATOM");
    if(! exists $done->{$num} && defined $justone) {
                      push @listofatomsclose , $num ;
                      my $name = $a->Print();
                      push @names , $name ;
                      $done->{$num} = 1 ;
                      print " $num dist =$d \n";
                      #print " $name =================== NAME \n";
    }
}
foreach my $k (sort {$a <=> $b}  keys %{$sort}){
	my $a = $sort->{$k};
	my $nm = $a->GetName();
    my $atomstr = $a->GetAtomStr();
	next if($atomstr ne "ATOM");
	print "$nm $k\n";
}

my $fastafh = util_write("$origpdb.$atomidx.ALL.fasta");
util_WriteFastaFromAtoms($pdb,$neigh,$fastafh,$origpdb);
print $ofh "\n";
print STDERR "Wrote $origpdb.$atomidx.ALL.fasta \n";





sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
