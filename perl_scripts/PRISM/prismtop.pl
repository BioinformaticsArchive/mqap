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
my ($junk,$pdb1,$pdb2,$infile,$delforpot,$outfile,$atomidx,$dontiter);
my ($resnum,$interactive,$annotate,$wdist,$dist,$findresidues,$maxresults,$inconf,$outconf,$resultfile,$checkself);
my ($grpconfig) = $ENV{CONFIGGRP} or die ;
my $MINDIST = 2 ;
$, = "  ";
GetOptions(
            "pdb1=s"=>\$pdb1 ,
            "annotate"=>\$annotate ,
            "interactive"=>\$interactive ,
            "checkself"=>\$checkself ,
            "dontiter"=>\$dontiter ,
            "delforpot=i"=>\$delforpot,
            "findresidues"=>\$findresidues ,
            "atomidx=s"=>\$atomidx ,
            "resultfile=s"=>\$resultfile ,
            "maxresults=i"=>\$maxresults ,
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
usage( "Need to give a max dist") if(!defined $dist);
usage( "Need to give a max wdist") if(!defined $wdist);
#usage( "Need to give a atom index or residue number") if(!defined $atomidx && !defined $resnum);
my $ofh = util_write($outfile);
my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC) = util_SetEnvVars();

($grpconfig) = $ENV{CONFIGGRP} or die ;
ConfigPDB_Init($grpconfig);


#usage( "Need to give a second protein pdb name => option -pdb2 ") if(!defined $pdb2);
my $origpdb = $pdb1 ;
$pdb1 = "$PDBDIR/$pdb1.pdb";

my $pdb = new PDB();
$pdb->SetLogFile($ofh);
$pdb->ReadPDB($pdb1);


if(!defined $resnum){
     my $table = util_maketablefromfile("map");
	 $resnum = $table->{$origpdb} or die "could not map $origpdb " ;
}

if(defined $resnum){
      my $res = $pdb->GetResidueIdx($resnum);
	  my $type = ConfigPDB_GetAtom($res->GetName());
	  my $atom = $pdb->GetAtomFromResidueAndType($resnum,$type);
	  $atomidx = $atom->GetIdx();
}


my $del = 0.1 ;
my $d = defined $dontiter ? $dist : 2 ;
while($d <= $dist){
    my $w = $wdist ;
    #my $w = 2 ;
    #while($w < $wdist){
		print STDERR "Running prism.pl -pdb $origpdb -outf $outfile -dist $d -wdis $w -atom $atomidx\n";
        my @f = `prism.pl -pdb $origpdb -outf $outfile -dist $d -wdis $w -atom $atomidx -delforp 0  ` ;
		print STDERR @f ;
	    #$w = $w + $del ;
	#}
	$d = $d + $del ;
	last if(defined $dontiter);
}


sub usage{
    my ($msg) = @_ ;
    print STDERR $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}

