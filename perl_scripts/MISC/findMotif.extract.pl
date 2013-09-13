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
my (@expressions);
my $howmany = 100000 ;
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "expr=s"=>\@expressions,
            "howmany=i"=>\$howmany ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a input file name => option -infile ") if(!defined $infile);
my $ifh = util_read($infile);


my @diffs ;
my $info = {};
while(<$ifh>){
     chop ;
     my (@l) = split ;
     my $v = $l[3];
my @diff ; 
	 push @diff , $v ;
push @diffs,\@diff ;
}
close($ifh);


		    my ($means,$sds) = util_ProcessRowAndColumnsForMean(\@diffs,250,150);

sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
