#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use ConfigPDB;
use MyGeom;

use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($infile,$outfile,$which_tech,$listfile);
my ($scale,@expressions,$sec2min);
my $cutoff ;
my $idx = 0;
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "sec2min"=>\$sec2min ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "idx=i"=>\$idx ,
            "scale=f"=>\$scale ,
            "outfile=s"=>\$outfile ,
            "expr=s"=>\@expressions,
            "cutoff=f"=>\$cutoff ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
my $ofh = util_write($outfile);
usage( "Need to give a input file name => option -infile ") if(!defined $infile);
my $ifh = util_read($infile);
my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET) = util_SetEnvVars();
my $PWD = cwd;


my $CNT = 1 ; 
my $ignored = 0 ; 
while(<$ifh>){
	chop ;
	s/,//g;
	my (@l) = split ;
	my $v = $l[$idx];
	if(defined $cutoff && $v > $cutoff){
		$ignored++;
		next ; 
	}
	$v = $scale * $v if(defined $scale);
    print $ofh "$CNT $v \n";
	$CNT++ ;
}

if(defined $cutoff){
    print "ignored $ignored for cutoff $cutoff \n";
}
close($ifh);

print STDERR "Output written in $outfile\n";

chmod 0777, $outfile ;
sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
