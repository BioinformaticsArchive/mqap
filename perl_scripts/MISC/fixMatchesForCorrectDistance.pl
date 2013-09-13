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
use ConfigPDB;


use POSIX qw(floor);
use Math::Combinatorics;
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($pdb1,$pdb2,$infile,$outfile,$atomidx,$dontrunpymol,$reference);
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
            "atomidx=s"=>\$atomidx ,
            "resultfile=s"=>\$resultfile ,
            "reference=s"=>\$reference ,
            "maxresults=i"=>\$maxresults ,
            "dist=f"=>\$dist ,
            "inconf=s"=>\$inconf ,
            "outconf=s"=>\$outconf ,
            "grpconfig=s"=>\$grpconfig ,
            "outfile=s"=>\$outfile 
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give pdb ") if(!defined $pdb1);
usage( "Need to give reference ") if(!defined $reference);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
usage( "Need to give a resultsfile") if(!defined $resultfile);
#usage( "Need to give a residue number") if(!defined $atomidx);
my $ofh = util_write($outfile);
my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC,$MATCH3D,$ANNDIR) = util_SetEnvVars();

ConfigPDB_Init($grpconfig);

my $pdb =util_readPDB($pdb1);

print STDERR "Writing to $outfile \n";

system("pwd");
my @r= ConfigPDB_ParseResultsFile($resultfile,10);
foreach my $result (@r){
	my $score = int(10* $result->{SCORE}); 
	$score = $score/10.0 ;
    my @atoms = @{$result->{ATOMS}};

	my $a ; 
	my $b ; 
	my $found = 0 ; 
    foreach my $atom (@atoms){
         my ($res,$num,$type) = split "/", $atom ;
		 if(!defined $a) {$a = $num ;}
		 elsif(!defined $b) {$b = $num ;}
		 if(defined $a && defined $b){
		 	 if(abs($a - $b) == 3){
			 	print $ofh "$pdb1 $reference $result->{SCORE} ",  @atoms , "\n";
				$found = 1 ; 
				last ;
			 }
		 }
    }
	last if($found);

	
}


sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;

}
