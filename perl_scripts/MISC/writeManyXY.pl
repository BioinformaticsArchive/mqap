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
my ($infile,$outfile,$tag,$listfile,$protein);
my (@expressions);
my $howmany = 100000 ;
my $verbose = 1 ;
GetOptions(
            "protein=s"=>\$protein ,
            "infile=s"=>\$infile ,
            "tag=s"=>\$tag ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "expr=s"=>\@expressions,
            "howmany=i"=>\$howmany ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a input file name => option -infile ") if(!defined $infile);
usage( "Need to give a input file name => option -tag ") if(!defined $tag);
my $ifh = util_read($infile);


my $cnt = 0 ; 
my @fhs ; 
while(<$ifh>){
     next if(/^\s*$/);
     chop ;
	 my @l = split ;
	 my $v = shift @l ;
	 my $N = @l ; 

	while(@l){
	     my $a = shift @l ;
	     my $nm = "$tag" . ".in." . $cnt++ ; 
         my $ofh = util_write($nm);
		 push @fhs , $ofh ;
	}
	last ;
}

$ifh = util_read($infile);
while(<$ifh>){
     next if(/^\s*$/);
     chop ;
	 my @l = split ;
	 my $v = shift @l ;

	 my @TT = @fhs ;
	 while(@l){
	     my $a = shift @l ;
	     my $ofh = shift @TT ;
	     print $ofh "$v $a\n";
	 }

}

sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
