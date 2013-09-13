#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use MyUtils;
use ConfigPDB;
use BP;

use Bio::Perl;
use Bio::DB::SwissProt;
use Bio::Tools::Run::Alignment::Clustalw;
use Bio::AlignIO;
use Bio::Align::DNAStatistics;
use Bio::Tree::DistanceFactory;
use Bio::TreeIO;
use Bio::Tree::Draw::Cladogram;



use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($id,$infile,$outfile,$listfile);
my (@expressions,$pdbid,$swissid);
my $howmany = 100000 ;
GetOptions(
            "id=s"=>\$id ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "pdbid=s"=>\$pdbid ,
            "swissid=s"=>\$swissid ,
            "outfile=s"=>\$outfile ,
            "expr=s"=>\@expressions,
            "howmany=i"=>\$howmany ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);

usage( "Need to give a pdbid -option -pdbid  ") if(!defined $pdbid);
usage( "Need to give a swissid -option -swissid  ") if(!defined $swissid);


$id = "ALL";
my $arr ; 
my $done = {};
(BP_GetSequence($id,$done,$arr,$pdbid,$swissid,1));





sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
