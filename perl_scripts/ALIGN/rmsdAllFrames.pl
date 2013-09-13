#!/usr/bin/perl -w 
use strict ;
use PDB;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use ConfigPDB;
use MyGeom;
use MyPymol;
use Math::Geometry ;
use Math::VectorReal qw(:all);  # Include O X Y Z axis constant vectors




use Time::HiRes qw( usleep ualarm gettimeofday tv_interval clock_gettime clock_getres  clock);
use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($p1,$p2,$infile,$outfile,$dist,$which_tech,$listfile,$protein);
my (@expressions);
my $maxdist = 3 ;
my $verbose = 1 ;
my ($moveZ,$verify,$decaaf,$before1,$before2);
my $file1 ;
my $file2 ;
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "protein=s"=>\$protein ,
            "verify"=>\$verify ,
            "p1=s"=>\$p1 ,
            "p2=s"=>\$p2 ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "file1=s"=>\$file1 ,
            "file2=s"=>\$file2 ,
            "expr=s"=>\@expressions,
            "maxdist=i"=>\$maxdist ,
            "moveZ=i"=>\$moveZ ,
            "dist=f"=>\$dist ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
my $ofh = util_write($outfile);
usage( "Need to give a listfile -option -listfile  ") if(!defined $listfile);

my @list= util_read_list_sentences($listfile);
my $list = {};
map { s/\s*//g ; $list->{$_} = 1 ; } @list ;

my $N = @list ; 

my $i = 0 ;
my $j = 1 ;
while ($j < $N){
	my $file1 = $list[$i] . ".pdb";
	my $file2 = $list[$j] . ".pdb";
	$i++;
	$j++;

    my $pdb1 = new PDB();
    $pdb1->ReadPDB($file1);
    my $pdb2 = new PDB();
    $pdb2->ReadPDB($file2);

	my $rmsd = util_FindRmsd($pdb1,$pdb2);
	print $ofh "$i $rmsd \n";
}



sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
