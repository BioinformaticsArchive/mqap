#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
  use Time::HiRes qw( usleep ualarm gettimeofday tv_interval
   clock_gettime clock_getres  clock
   );

use Algorithm::Combinatorics qw( variations permutations combinations) ;

use PDB;
use Atom;
use Residue;

use POSIX qw(floor);
use Math::Combinatorics;
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($pdb1,$pdb2,$infile,$outfile,$atomidx,$dontrunpymol);
my ($interactive,$annotate,$size,$justone,$ignorewater,$dist,$findresidues,$maxresults,$inconf,$outconf,$resultfile,$checkself);
my ($grpconfig) = $ENV{CONFIGGRP} or die ;
my $MINDIST = 2 ;
$, = "  ";
GetOptions(
            "pdb1=s"=>\$pdb1 ,
            "atomidx=s"=>\$atomidx ,
            "size=i"=>\$size ,
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
usage( "Need to give a size ") if(!defined $size);
my $ofh = util_write($outfile);


my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC) = util_SetEnvVars();
#usage( "Need to give a second protein pdb name => option -pdb2 ") if(!defined $pdb2);
my $origpdb = $pdb1 ;
$pdb1 = "$PDBDIR/$pdb1.pdb";

my $pdb = new PDB();
$pdb->SetLogFile($ofh);
$pdb->ReadPDB($pdb1);

#my @dist = qw (3.786 6.583 5.834); ## MBL
my @dist = qw ( 4.940    5.029    4.597    6.294    6.408    6.428    7.970    9.525   10.218    4.394);
my @reslist = $pdb->GetResidues();
die if(@reslist ne 1 );
my $r = shift @reslist ;
my @atoms = $r->GetAtoms();

my @resultsall ; 
my $DONE ;
foreach my $atom (@atoms){
     my $list = util_make_list($atom);
	 my $dist = 15 ; 
     my ($junk,$neighatoms)  = $pdb->GetNeighbourHoodAtom($list,$dist);
	 my @r = ProcessNeightAtoms($neighatoms,$DONE);
	 push @resultsall, @r ;
}

my @resultssorted = sort { $a->{SCORE} <=> $b->{SCORE} } @resultsall ;
my $CNT = 0 ; 
foreach my $r (@resultssorted){
	$CNT++;
	my $nm = $r->{NAME};
	my $score = $r->{SCORE};
	print STDERR "NAME = $nm score = $score \n";
	last if($CNT eq 10);
}

sub ProcessNeightAtoms{
	my ($neighatoms,$done) = @_ ; 
    my $iter = variations($neighatoms, $size);
    my @results ;
    while (my $x = $iter->next) {
	    $CNT++ ;
        my @combo = @{$x} ; 
		my @sort = sort @combo ;
		my $str = join " ", @sort;
		if(exists $done->{$str}){
		#print "skip $str\n";
		next  ;
		}
		$done->{$str} = 1 ; 
        my ($a,$b,$c) = @combo ; 
	    my @l = $pdb->ScoreGivenSetOfAtom(\@combo,15);
	    next if(!@l);
    
	    my $N = @l -1 ;
	    my $absscore = 0 ; 
	    my $nm = $a->GetName() . "-" . $b->GetName() . "-" . $c->GetName();
        my $info = {};
	    foreach my $idx (0..$N){
		    my $d1 = $l[$idx];
		    my $d2 = $dist[$idx];
		    my $diff = abs ($d1 - $d2);
		    $absscore = $absscore + $diff ;
	    }
	    $info->{NAME} = $nm;
	    $info->{SCORE} = $absscore;
	    push @results, $info ;
    }
	return @results ;
}

sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
