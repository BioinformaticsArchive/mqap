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
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
my $ofh = util_write($outfile);
usage( "Need to give a input file name => option -infile ") if(!defined $infile);
my $ifh = util_read($infile);
usage( "Need to give a listfile -option -listfile  ") if(!defined $listfile);
my $CNT = 0 ; 
#my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC) = util_SetEnvVars();
my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC,$MATCH3D,$ANNDIR, $UNIPROT) = util_SetEnvVars();
my $PWD = cwd;

my  ($seconds, $microseconds) = gettimeofday;


my @list= util_read_list_sentences($listfile);
my $list = {};
map { s/\s*//g ; $list->{$_} = 1 ; } @list ;

my $info = {};
my @points1 ; 
while(<$ifh>){
     next if(/^\s*$/);
	 my ($nm,$key) = split ; 
	 $info->{$key} = $nm  ;
	 push @points1, $key ;
}

my $mindist = 1000 ; 
my $mink1 ; 
my $mink2 ; 
my $nm ; 
while(@list){
	my $k1 = shift @list ;
	my ($x1,$y1,$z1) = geom_MakeCoordFromKey($k1);
	foreach my $k2 (@points1){
	    my ($x2,$y2,$z2) = geom_MakeCoordFromKey($k2);
		my $d = geom_Distance($x1,$y1,$z1,$x2,$y2,$z2);
		if($d < $mindist){
			$mindist = $d ;
			$mink1 = $k1;
			$mink2 = $k2;
			$nm = $info->{$k2} ;
		}
	}
}
print "Mindist = $mindist between $mink1 and $mink2: name is $nm\n" ;

sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
