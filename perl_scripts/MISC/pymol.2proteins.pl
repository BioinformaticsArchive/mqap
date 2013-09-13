#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use MyPymol;

use PDB;
use Atom;
use Residue;

use POSIX qw(floor);
use Math::Combinatorics;
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($pdb1,$pdb2,$infile,$outfile,$dontrunPymol,$dontshowsurface);
my ($name1,$name2);
my @expressions ;
my @distances ;
GetOptions(
            "pdb1=s"=>\$pdb1 ,
            "pdb2=s"=>\$pdb2 ,
            "dontrunPymol"=>\$dontrunPymol ,
            "dontshowsurface"=>\$dontshowsurface ,
            "infile=s"=>\$infile ,
            "expr=s"=>\@expressions,
            "dist:s"=>\@distances,
            "outfile=s"=>\$outfile,
            "name1=s"=>\$name1 
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
my $ofh = util_write($outfile);

usage( "Need to give a first protein pdb name => option -pdb1 ") if(!defined $pdb1);
usage( "Need to give a first protein pdb name => option -pdb2 ") if(!defined $pdb2);

my ($list1,$list2);
util_PrintPymolWith2Proteins($ofh,$pdb1,$pdb2,$list1,$list2);


sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
