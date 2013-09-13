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
my ($pdb1,$pdb2,$infile,$outfile,$atomidx,$dontrunpymol);
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
            "maxresults=i"=>\$maxresults ,
            "dist=f"=>\$dist ,
            "inconf=s"=>\$inconf ,
            "outconf=s"=>\$outconf ,
            "grpconfig=s"=>\$grpconfig ,
            "outfile=s"=>\$outfile 
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give pdb ") if(!defined $pdb1);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
usage( "Need to give a resultsfile") if(!defined $resultfile);
#usage( "Need to give a residue number") if(!defined $atomidx);
my $ofh = util_write($outfile);
my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC,$MATCH3D,$ANNDIR) = util_SetEnvVars();

ConfigPDB_Init($grpconfig);

my $pdb =util_readPDB($pdb1);
my $annfile = "$ANNDIR/$pdb1.outconf.annotated";
my $atomlist = $pdb->GetActiveResidues($annfile);
my ($j1,$j2,$residues) = $pdb->GetNeighbourHoodAtom($atomlist,$dist);
util_table_print($residues);


my @r= ConfigPDB_ParseResultsFile($resultfile,1);
foreach my $result (@r){
	print "$result->{SCORE} \n";
	my $score = int(10* $result->{SCORE}); 
	$score = $score/10.0 ;
    my @atoms = @{$result->{ATOMS}};

    foreach my $atom (@atoms){
         my ($res,$num,$type) = split "/", $atom ;
		 if(exists $residues->{$num}){
		 	print "$num is close to active site\n";
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
