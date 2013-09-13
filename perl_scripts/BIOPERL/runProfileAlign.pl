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
my ($infile,$outfile,$id,$listfile);
my ($infile1,$id1);
my ($infile2,$id2);
my (@expressions);
my $howmany = 100000 ;
GetOptions(
            "id1=s"=>\$id1 ,
            "id2=s"=>\$id2 ,
            "in1=s"=>\$infile1 ,
            "in2=s"=>\$infile2 ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "expr=s"=>\@expressions,
            "howmany=i"=>\$howmany ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
my $ofh = util_write($outfile);
usage( "Need to give an id1 => option -id ") if(!defined $id1);
usage( "Need to give an id2 => option -id ") if(!defined $id2);
usage( "Need to give a input file name => option -in1 ") if(!defined $infile1);
usage( "Need to give a input file name => option -in2 ") if(!defined $infile2);

print "Parsing /home/sandeepc/mapping.txt \n";
my $info = util_read_Mapping_PDB_2_SWISSPROT("/home/sandeepc/mapping.txt");
print "Parsed /home/sandeepc/mapping.txt \n";

$info->{uvi31} = "junk";
$info->{UVI31} = "junk";

my ($factory1,$aln1,$tree1,$arr1) = BP_DoAlignment($infile1,$id1,$info);
my ($factory2,$aln2,$tree2,$arr2) = BP_DoAlignment($infile2,$id2,$info);
my ($factory,$aln,$tree) = BP_DoProfileAlignment($aln1,$aln2,$id1,$id2,$arr1,$arr2);



chmod 0777, $outfile ;
sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
