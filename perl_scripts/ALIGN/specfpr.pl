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
my (@expressions,$idx,$tag);
my $verbose = 1 ;
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "protein=s"=>\$protein ,
            "infile=s"=>\$infile ,
            "idx=i"=>\$idx ,
            "cutoff=f"=>\$cutoff ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "tag=s"=>\$tag ,
            "expr=s"=>\@expressions,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
my $ofh = util_write($outfile);
usage( "Need to give a infile -option -infile  ") if(!defined $infile);

my $firstval ; 
$firstval = $cutoff if(defined $cutoff);
my @sumvals ;
foreach my $howmany (0..5){

	next if($howmany > 0);
	my $percent = $howmany * 5 ; 
    my $ifh = util_read($infile);
	my $TN = 0 ; 
	my $FP = 0 ; 
    while(<$ifh>){
     next if(/^\s*$/);
	 my (@l) = split ; 
	 my $val = $l[$idx];
	 if(!defined $firstval){
	    $firstval = $val  ;
	 }
	 else{
	    my $incr = ($firstval/100) * $percent ;
		if(!$incr){
            push @sumvals, $val ; 
		}
	 	if($firstval + $incr  > $val){
			$FP++;
		}
		else{
			$TN++;
		}
	 }
    }
	my $spec = util_format_float($TN/($FP + $TN),1);
    my $ofhspec = util_write("spec.$idx.$infile");
	print $ofhspec "$percent $spec \n";
	if(!$howmany){
    my $OFH = util_write("spec.$idx.$tag");
	print $OFH "$spec \n";
	}
}

my ($mean,$sd) = util_GetMeanSD(\@sumvals);
my $zscore = ($mean - $firstval)/$sd ; 
print $ofh "zscore = $zscore \n";

chmod 0777, $outfile ;

sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
