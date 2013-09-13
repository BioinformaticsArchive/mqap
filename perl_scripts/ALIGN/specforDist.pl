#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use MyGeom;
use PDB;
use ConfigPDB;

use Time::HiRes qw( usleep ualarm gettimeofday tv_interval clock_gettime clock_getres  clock);
use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($infile,$cutoff,$outfile,$which_tech,$listfile,$protein);
my (@expressions,$idx);
my $verbose = 1 ;
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "protein=s"=>\$protein ,
            "infile=s"=>\$infile ,
            "idx=i"=>\$idx ,
            "cutoff=f"=>\$cutoff ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "expr=s"=>\@expressions,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
my $ofh = util_write($outfile);
usage( "Need to give a listfile -option -listfile  ") if(!defined $listfile);

my @list= util_read_list_sentences($listfile);
my $list = {};
map { s/\s*//g ; $list->{$_} = 1 ; } @list ;

my @sumvals ;
foreach my $incr (0..30){
	$incr = $incr*0.001 ; 
foreach my $i (@list){
    my $ifh = util_read($i);
	my $TN = 0 ; 
	my $FP = 0 ; 
    while(<$ifh>){
     next if(/^\s*$/);
	 my (@l) = split ; 
	 my $val = $l[$idx];
	 	if($incr  < $val){
			$FP++;
		}
		else{
			$TN++;
		}
	 }
	my $spec = $TN/($FP + $TN);
    my $ofhspec = util_append("spec.$i");
	my $incr1000 = 1000 * $incr ;
	print $ofhspec "$incr1000 $spec \n";
}
}


chmod 0777, $outfile ;

sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
