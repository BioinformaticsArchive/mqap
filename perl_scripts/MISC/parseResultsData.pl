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
my ($infile,$outfile,$which_tech,$listfile,$protein);
my (@expressions,$potential,$distance);
my $howmany = 100000 ;
my $verbose = 1 ;
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "protein=s"=>\$protein ,
            "potential"=>\$potential ,
            "distance"=>\$distance ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "expr=s"=>\@expressions,
            "howmany=i"=>\$howmany ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
my $ofh = util_write($outfile);


usage( "Need to give a listfile -option -listfile  ") if(!defined $listfile);
my @list= util_read_list_sentences($listfile);
my $list = {};
map { s/\s*//g ; $list->{$_} = 1 ; } @list ;

foreach my $i (@list){
	processProtein($i);
}



sub processProtein{
   my ($i) = @_ ;
   my $infile = "$i.data";
   my $ifh = util_read($infile);

   my $potdone = 0 ;
   my $scoredone = 0 ;
	print $ofh "$i ";
	my $score = 0 ;
while(<$ifh>){
	chop ;
	if(defined $potential && /pot.diff/ && !$potdone){
		$_ = <$ifh> ;
		s/.*pot.diff//;
		my @value = split ;
		foreach my $v (@value){
			my $l = int($v);
	        print $ofh " $l ";
		}
		$potdone = 1 ;
	}
	if(/SCORE/ && ! $scoredone){
		s/.*SCORE//;
		s/-//g;
		$score = util_format_float($_,3);
		$score = 10 * $score ;
		$scoredone = 1 ;

		$_ = <$ifh> ;
		s/-//g;
		s/#//g;
		my @value = split ;

		foreach my $v (@value){
			my @l = split "/", $v ;
	        print $ofh " $l[0]$l[1] ";
		}

	}
	if(defined $distance && /DIST/ ){
		$_ = <$ifh> ;
		my @value = split ;
		foreach my $v (@value){
			my $l = util_format_float($v,3);
	        print $ofh " $l ";
		}
	}
}
close($ifh);
	    print $ofh " $score ";
	    print $ofh " \n";
}

chmod 0777, $outfile ;

sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
