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
usage( "Need to give a listfile -option -listfile  ") if(!defined $listfile);
my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC) = util_SetEnvVars();
my $PWD = cwd;

my @list= util_read_list_sentences($listfile);
my $list = {};
map { s/\s*//g ; $list->{$_} = 1 ; } @list ;


my $totalN = @list; 
my $first = 1 ; 
my @first ; 
my @neg ; 
my @pos ; 
my $CNT = 0; 
foreach my $i (@list){
    my $ifh = util_read("pot.$i");
	$CNT++ ;

	my $cnt = 0; 
	my $TOT = 0; 
    while(<$ifh>){
	     my ($nm,$junk) = split ; 
		 $TOT = $TOT + abs($junk);
		 if($first){
		 	 push @first, $junk ;
		 	 push @neg, 0 ;
		 	 push @pos, 0 ;
		 }
		 else{
			if($junk < 0){
				$neg[$cnt] = $neg[$cnt] + 1 ; 
			}
			else{
				$pos[$cnt] = $pos[$cnt] + 1 ; 
			}
		 }

		 $cnt++ ; 
    }
	$first = 0 ; 
   close($ifh);
   print $ofh "$CNT $TOT\n";
}

my $N = @pos -1 ; 
foreach my $i (0..$N){
	print "$i = $pos[$i] $neg[$i] \n";
}


sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
