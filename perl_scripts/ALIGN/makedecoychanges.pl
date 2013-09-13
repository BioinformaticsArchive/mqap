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
my ($infile,$outfile,$which_tech,$script,$listfile,$protein);
my (@expressions);
my $howmany = 100000 ;
my $verbose = 1 ;
my $runall = 1 ;
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "protein=s"=>\$protein ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "script=s"=>\$script ,
            "expr=s"=>\@expressions,
            "runall=i"=>\$runall ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
my $ofh = util_write($outfile);
my $ofhscript = util_write($script);
usage( "Need to give a listfile -option -listfile  ") if(!defined $listfile);
my $CNT = 0 ; 
my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC) = util_SetEnvVars();
my $PWD = cwd;

my @list= util_read_list_sentences($listfile);
my $list = {};
map { s/\s*//g ; $list->{$_} = 1 ; } @list ;

foreach my $i (@list){
	my $justpdb = $i;
	$justpdb =~ s/.pdb//;
	$justpdb =~ s/\.//g;
	$justpdb =~ s/://g;
	$justpdb =~ s/\_//g;
	$justpdb =~ s/-//g;
	$justpdb = uc($justpdb);

	print $ofhscript "mv -f $i $justpdb.pdb\n";

	print $ofh "$justpdb\n";
}


if($runall){
   print $ofhscript "getPDBModel1ChainAlist.csh list\n";
   print $ofhscript "mv -f *pdb $PDBDIR\n";
   #print $ofhscript "s ~/CLEANAPBS.csh list\n";
   print $ofhscript "apbs.csh list\n";
}


sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
