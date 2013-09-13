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
my ($infile,$outfile,$which_tech,$prefix,$listfile,$protein);
my (@expressions);
my $howmany = 100000 ;
my $verbose = 1 ;
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "protein=s"=>\$prefix ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "prefix=s"=>\$prefix ,
            "expr=s"=>\@expressions,
            "howmany=i"=>\$howmany ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
my $ofh = util_write($outfile);
usage( "Need to give a listfile -option -listfile  ") if(!defined $listfile);
usage( "Need to give a prefix pdb id -option -prefix  ") if(!defined $prefix);
my $CNT = 0 ; 

my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC) = util_SetEnvVars();


my @list= util_read_list_sentences($listfile);
my $list = {};
map { s/\s*//g ; $list->{$_} = 1 ; } @list ;

my @newfiles; 
foreach my $i (@list){
	my $newnm = $prefix . $i ; 
	$newnm =~ s/.pdb//i;
	$newnm = uc($newnm);
	push @newfiles, $newnm ;

	system ("cp $i $newnm.pdb");
	print $ofh "$newnm\n";
}

foreach my $x (@newfiles){
    print "$x.pdb $PDBDIR/ \n";
	system("mv $x.pdb $PDBDIR/");	
}


system ("getPDBModel1ChainAlist.csh $outfile");
foreach my $x (@newfiles){
    print "$x.pdb $PDBDIR/ \n";
	system("mv -f $x.pdb $PDBDIR/");	
}

system ("apbsforce.csh $outfile");
system ("cp $outfile list.$prefix");

sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
