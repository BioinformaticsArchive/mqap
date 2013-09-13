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
            "which_tech=s"=>\$which_tech ,
            "protein=s"=>\$protein ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "expr=s"=>\@expressions,
            "howmany=i"=>\$howmany ,
           );
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
my $ofh = util_write($outfile);
usage( "Need to give a input file name => option -infile ") if(!defined $infile);
my $ifh = util_read($infile);

my $info = {};
{
	my $fnm = "list.ann";
     my $ifh = util_read($fnm);
     while(<$ifh>){
         next if(/^\s*$/);
         chop ;
	     my ($nm,$i) = split ; 
	     $info->{$nm} = $i ; 
	 }
	 close($ifh);
}

while(<$ifh>){
     next if(/^\s*$/);
     if(/^\s*>/){
	     my ($nm) = (/^\s*>(....)/);
	     die "$nm" if(!exists $info->{$nm});
	     my $infonm = $info->{$nm};
	     s/^\s*>..../>$nm.$infonm/;
	 }
	 print $ofh $_ ; 
	
}
close($ifh);


sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
