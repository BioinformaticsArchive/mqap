#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use ConfigPDB;
use MyGeom;
use PDB;

use Time::HiRes qw( usleep ualarm gettimeofday tv_interval clock_gettime clock_getres  clock);
use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($infile,$outfile,$which_tech,$seperate,$listfile,$uniprotid);
my (@expressions);
my $maxdiff = 100 ; 
my $verbose = 1 ;
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "uniprotid=s"=>\$uniprotid ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "expr=s"=>\@expressions,
            "maxdiff=i"=>\$maxdiff ,
            "seperate"=>\$seperate ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
my $ofh = util_append($outfile);
usage( "Need to give a uniprotid pdb id -option -uniprotid  ") if(!defined $uniprotid);
$infile = "$uniprotid.ann";
my $CNT = 0 ; 
my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC) = util_SetEnvVars();
my $PWD = cwd;

my ($inforepeatregion,$infomodified) = util_ReadAnnotateFileFRAGAL($infile,$maxdiff);

my $in = <$FASTADIR/$uniprotid.fasta>;
my $CNT = 0 ; 
foreach my $k (keys %{$inforepeatregion}){
	$CNT++;
	my $s = $inforepeatregion->{$k}->{START} ;
	my $e = $inforepeatregion->{$k}->{END} ;
	print "key = $k s = $s e = $e\n";
	if(defined $seperate){
		$ofh = util_write("$CNT.fasta");
	}
	util_ExtractSliceFromFasta($ofh,$in,$s,$e);
}





sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
