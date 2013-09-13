#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use ConfigPDB;
use MyGeom;
use PDB;
use Primer;
  use Bio::Tools::CodonTable;
 my $myCodonTable   = Bio::Tools::CodonTable->new();
 

use Time::HiRes qw( usleep ualarm gettimeofday tv_interval clock_gettime clock_getres  clock);
use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($infile,$outfile,$which_tech,$listfile,$protein);
my (@expressions,@indices,@towhichresidue,$origseq);
my $howmany = 100000 ;
my $verbose = 1 ;
my $TEMP = 78 ;
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "towhichresidue=s"=>\@towhichresidue ,
            #"idx=i"=>\$idx ,
            "protein=s"=>\$protein ,
            "infile=s"=>\$infile ,
            "origseq=s"=>\$origseq ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "indices=i"=>\@indices,
            "howmany=i"=>\$howmany ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);

my ($line,$width,@l) = ReadSeq($infile);
my ($oline,$owidth,@ol) = ReadSeq($origseq);

my $GCCount_percent = GetGCCountPercent($line,$width); 
my $temp  = GetTemperature($GCCount_percent,(3*100)/42,$width);

print "gcontent = $GCCount_percent width $width TEMP = $temp line = $line \n";
print "width $owidth  line = $oline \n";

my $cnt = 1 ;
while(@l){
	my $a = shift @ol;
	my $b = shift @l;
	if($a ne $b){
		print "Differ in count $cnt - $a and $b \n";
	}
	$cnt++ ; 
}



