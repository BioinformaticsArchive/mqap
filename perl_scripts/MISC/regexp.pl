#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
  use Time::HiRes qw( usleep ualarm gettimeofday tv_interval
   clock_gettime clock_getres  clock
   );

my $UUU = "QQFQQQQQQQQQQQQQQFQQQQQQQQQQEQQQEQQQQQQQQQQQQQFQQQEQQQFQEQQQQQQQQQQQQQQQQQQQQQFQQQQQQQEQQQQFQFQQQQQEFQQQQQQEQQQQQQQQQQQQQQQQQQQEQQQQQQQQQQQQQQQEQQQQQQQQQQFQQQFQQQQQQQQQEQQQQQQQFQQQQQEQEQQQQQQQQFQQQQQQQFQQQQQQQQQQQQQQQQQQQQQQQQQFQQQQQQQQQEQQQQQQQEQFFFQQQQQQQEQQQQ";

use PDB;
use Atom;
use Residue;
use ConfigPDB;


use POSIX qw(floor);
use Math::Combinatorics;
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($pdb1,$pdb2,$infile,$outfile,$atomidx,$dontrunpymol);
my ($anndir,$interactive,$annotate,$aalist,$dist,$findresidues,$maxresults,$inconf,$outconf,$resultfile,$checkself);
my ($grpconfig) = $ENV{CONFIGGRP} or die ;
my $MINDIST = 2 ;
$, = "  ";
my $LEN = 10 ; 
GetOptions(
            "pdb1=s"=>\$pdb1 ,
            "anndir=s"=>\$anndir ,
            "interactive"=>\$interactive ,
            "checkself"=>\$checkself ,
            "dontrunpymol"=>\$dontrunpymol ,
            "findresidues"=>\$findresidues ,
            "atomidx=s"=>\$atomidx ,
            "resultfile=s"=>\$resultfile ,
            "maxresults=i"=>\$maxresults ,
            "dist=f"=>\$dist ,
            "len=i"=>\$LEN ,
            "inconf=s"=>\$inconf ,
            "aalist=s"=>\$aalist ,
            "grpconfig=s"=>\$grpconfig ,
            "outfile=s"=>\$outfile 
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give pdb ") if(!defined $pdb1);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
usage( "Need to give a anndir => option -anndir ") if(!defined $anndir);
usage( "Need to give a aalist => option -aalist ") if(!defined $aalist);
#usage( "Need to give a residue number") if(!defined $atomidx);
my $ofh = util_write($outfile);
my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC,$MATCH3D,$ANNDIR, $UNIPROT) = util_SetEnvVars();

ConfigPDB_Init($grpconfig);

my $pdb =util_readPDB($pdb1);
my $annfile = "$anndir/$pdb1.outconf.annotated";

my ($aainfo,$grplist) = util_ParseAAGroups($aalist);

die "$annfile annotate file does not exist" if(! -e $annfile);
my (@l) =  util_Ann2Simple($annfile);
my @sl = sort {$a <=> $b}  @l ; 

my @sortedlist ; 
my $last ; 
## ignore residues that are close by 
my @lens ; 
foreach my $i (@sl){
     if(!defined $last){
	 	$last = $i ; 
		push @sortedlist,$i ;
		push @lens,$LEN ;
	 }
	 else{
	    if(abs($i - $last) < $LEN){
			# last remains the same 
			$lens[@lens -1] = $lens[@lens -1] + $LEN ; 
		}
		else{
			push @sortedlist,$i ;
	 	    $last = $i ; 
		    push @lens,$LEN ;
		}
	 }
}

my @seq = $pdb->GetSeq();
my @seqt ;
my $seqtrans = "";
print "Seq translated = \n";
foreach my $x (@seq){
	die "Expected aa $x" if(!defined $aainfo->{$x});
	my $xt = $aainfo->{$x}; 
	push @seqt, $xt ; 
	print "$xt";
	$seqtrans = $seqtrans . $xt ;
}
print "\n";


foreach my $n (@sortedlist){
	print "$n \n";
	
	my $LLL = shift @lens ;
	my ($neighbouringresidues,$neighbouringresiduereplaced) = $pdb->NeighbouringResiduesofResidue($n,$LLL);
    my $str = "";
    my $strtranslated = "";
    foreach my $r (@{$neighbouringresidues}){
			my $x =  $r->PrintSingleLetter($pdb);
			$str = $str . $x ;
			die "Expected aa $x" if(!defined $aainfo->{$x});
			my $xt = $aainfo->{$x}; 
			$strtranslated = $strtranslated . $xt ;
	}
	my $len = length($str);
	my $s1 = substr $str , $LLL +1  ; 
	my $s2 = reverse(substr reverse($str) , $LLL +1)  ; 
	print "$str $strtranslated \n";
 

    my $expr = $strtranslated ;
	foreach my $g (@{$grplist}){
        my $XXXX = $g . $g . "+";
	    $expr =~ s/$XXXX/$g+/g; 
	    print "EXPR = $expr\n";
	}

    #my ($RRR) = ($seqtrans =~/($expr)/);
    my ($RRR) = ($UUU =~/($expr)/);
	print "RRR = $RRR\n";
}


sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;

}
