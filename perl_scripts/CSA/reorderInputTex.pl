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
my $CNT = 0 ; 
my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC) = util_SetEnvVars();
my $PWD = cwd;


exit() ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 


my $info = {};
my @list= util_read_list_sentences($listfile);
foreach my $i (@list){
	$i =~ s/\\input\{//;
	$i =~ s/}//;
	print "$i\n";
    my $ifh = util_read($i);
	my $seen = 0 ; 
	my $val ;
    while(<$ifh>){
        next if(/^\s*$/);
        next if(/^\\/);
		$seen = 1 ; 
	    my @l = split ; 
	    my $n = @l ; 
	    ($val) = $l[$n-2];
		last ;
	}
	if($seen){
		$info->{$i} = $val ; 
	}
	else{
		$info->{$i} = 10000;
	}
}

my @sorted = sort { $info->{$a} <=> $info->{$b} } (keys %{$info});
$, = "\n";
print  "", @sorted , "\n"  ;
foreach my $i (@sorted){
print  $ofh "\\input{$i}\n";
print  $ofh "\\pagebreak \n";

}


sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
