#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use MyGeom;
use PDB;
use ConfigPDB;
use BP;

use Time::HiRes qw( usleep ualarm gettimeofday tv_interval clock_gettime clock_getres  clock);
use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($infile,$outfile,$which_tech,$listfile,$protein);
my (@expressions);
my $thresh = 30  ;
my $verbose = 1 ;
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "protein=s"=>\$protein ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "expr=s"=>\@expressions,
            "thresh=i"=>\$thresh ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
my $ofh = util_write($outfile);
#usage( "Need to give a input file name => option -infile ") if(!defined $infile);
#my $ifh = util_read($infile);
#usage( "Need to give a listfile -option -listfile  ") if(!defined $listfile);
#usage( "Need to give a protein pdb id -option -protein  ") if(!defined $protein);
#my $CNT = 0 ; 
#my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC,$MATCH3D,$ANNDIR, $UNIPROT) = util_SetEnvVars();
#my $PWD = cwd;

my @list= <*out> ; 
my $list = {};
map { s/\s*//g ; $list->{$_} = 1 ; } @list ;

my ($fulliden,$fullsimi) = BP_Needle_parseout("full.needle");
print $ofh "$fulliden $fullsimi \n";

foreach my $i (@list){
    my $orig = $i ;
	$i =~ s/\./ /g;
	my ($a,$b)  = split " " , $i ;
    my ($iden,$simi) = BP_Needle_parseout($orig);
	next if($iden < $thresh);
    my $onlysimi = $simi - $iden ;
	my $addto = util_format_float(0.333 * $onlysimi + 0.666 * $iden,1) ; 
	my $addtoNormalized = 0 ; 
	$addtoNormalized =  util_format_float($addto / $fulliden,1)  if(defined $fulliden);
    print $ofh "$a $b $iden $simi $addto $addtoNormalized \n";
}


sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
