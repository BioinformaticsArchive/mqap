#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use ConfigPDB;
use MyGeom;

use Time::HiRes qw( usleep ualarm gettimeofday tv_interval clock_gettime clock_getres  clock);
use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($infile,$ext,$outfile,$which_tech,$listfile,$dir);
my (@expressions);
my $howmany = 100000 ;
$ext = "";
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "dir=s"=>\$dir ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "ext=s"=>\$ext ,
            "outfile=s"=>\$outfile ,
            "expr=s"=>\@expressions,
            "howmany=i"=>\$howmany ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a listfile -option -listfile  ") if(!defined $listfile);
usage( "Need to give a dir pdb id -option -dir  ") if(!defined $dir);
my $CNT = 0 ; 
my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC) = util_SetEnvVars();
my $PWD = cwd;

my  ($seconds, $microseconds) = gettimeofday;

my $exists = util_write("exists");
my $nonexists = util_write("nonexists");

print STDERR "Writing file exists and nonexists \n";

my @list= util_read_list_sentences($listfile);
my $list = {};
map { $list->{$_} = 1 ; } @list ;

foreach my $i (@list){
	my $fnm = "$dir/$i" . $ext ;
    if(-e $fnm){
		print $exists "$i\n";
	}
	else{
		print $nonexists "$i\n";
	}
}

util_printAndDo("wc -l $listfile exists nonexists");

sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
