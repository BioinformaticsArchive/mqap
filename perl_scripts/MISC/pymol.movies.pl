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
use MyPymol;

use POSIX qw(floor);
use Math::Combinatorics;
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($pdb1,$pdb2,$infile,$scriptname,$outfile,$atomidx,$dontrunpymol);
my ($interactive,$annotate,$ignorewater,$dist,$findresidues,$maxresults,$inconf,$outconf,$resultfile,$checkself);
my ($grpconfig) = $ENV{CONFIGGRP} or die ;
my $MINDIST = 2 ;
$, = "  ";
GetOptions(
            "pdb1=s"=>\$pdb1 ,
            "atomidx=s"=>\$atomidx ,
            "dist=f"=>\$dist ,
            "inconf=s"=>\$inconf ,
            "scriptname=s"=>\$scriptname ,
            "outconf=s"=>\$outconf ,
            "outfile=s"=>\$outfile 
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give pdb ") if(!defined $pdb1);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
usage( "Need to give a scriptname") if(!defined $scriptname);
#usage( "Need to give a atom index") if(!defined $atomidx);



my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC) = util_SetEnvVars();
my $origpdb = $pdb1 ;
$pdb1 = "$PDBDIR/$pdb1.pdb";

my $pdb = new PDB();
$pdb->ReadPDB($pdb1);


my @res = $pdb->GetResidues();
my $N = @res;
my $cnt = 0 ;
my @images ;
foreach my $res (@res){
    $cnt++;
    next if($res->GetAtomStr() ne "ATOM");
	my $num = $res->GetResNum();
	my $imagenm = "image$num.png";
	if(! -e $imagenm){
        my $ofh = util_write($outfile);
	    print $ofh "blue 0 $num\n";
	    print STDERR "Processing residue $cnt from $N \n";
	    system("pymol.2oneprotein.pl -out ooo.p1m -pdb1 $origpdb -in $outfile ");
	    `pymol -c ooo.p1m -g $imagenm ` ;
	    push @images, $imagenm ;
	    close($ofh);
	}
	#last if($cnt eq 5 );
}

util_MakeMovieFromImages($scriptname,@images);


sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
