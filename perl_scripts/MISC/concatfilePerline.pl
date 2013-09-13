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
my ($infile,$outfile,$which_tech,$listfile,$protein);
my (@expressions);
my $howmany = 100000 ;
my $verbose = 1 ;
GetOptions(
            "outfile=s"=>\$outfile ,
           );
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
my $ofh = util_write($outfile);


my @lists ; 
my $N ; 
foreach my $i (@ARGV){
    my $ifh = util_read($i);
	my @l ; 
    while(<$ifh>){
        next if(/^\s*$/);
		chop ;
	    push @l , $_ ; 
    }
	if(!defined $N){
		 $N = @l ; 
	}
	else{
		die "expected same size " if($N ne @l);
	}
	push @lists, \@l ; 
}

$N = $N -1 ;
foreach my $idx (0..$N){
	my $sentence = "";
	foreach my $l (@lists){
		my $x = $l->[$idx]; 
		$sentence = $sentence . " ". $x ; 
	}
	$sentence =~ s/ - //g ;
	$sentence =~ s/#/ /g ;
	$sentence =~ s/SCORES ....- - RESULT 0  SCORE //g ;
	$sentence =~ s/DIST ....//g ;
	$sentence =~ s/POT ....//g ;
	$sentence =~ s/\/(..|...) / /g ;
	$sentence =~ s/\///g ;
	print $ofh $sentence , "\n";
}


sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
