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
my ($prefix,$infile,$outfile,$onecolor,$listfile,$protein);
my (@expressions);
my $howmany = 100000 ;
my $verbose = 1 ;
GetOptions(
            "onecolor=s"=>\$onecolor ,
            "prefix=s"=>\$prefix ,
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
usage( "Need to give a prefix pdb id -option -prefix  ") if(!defined $prefix);
my $CNT = 0 ; 
my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC) = util_SetEnvVars();
my $PWD = cwd;

my @colors = qw ( magenta cyan yellow blue black red green gray orange  ) ;


my $N = @colors ; 
my @list= util_read_list_sentences($listfile);
my $list = {};
map { s/\s*//g ; $list->{$_} = 1 ; } @list ;

my $cnt = 0 ; 
foreach my $i (@list){
	$cnt++ ; 
	$cnt = 0 if($cnt >= $N);
	my $color = defined $onecolor ? $onecolor : $colors[$cnt]   ; 
	my $prefixed = $prefix . $i ; 
	print "\\addplot[only marks,mark=+,color=$color] file {$prefixed}; \n";
	print $ofh "\\addplot[only marks,mark=+,color=$color] file {$prefixed}; \n";
	$i =~ s/_//g;
	print "\\addlegendentry{$prefixed} \n";
	print $ofh "\\addlegendentry{$prefixed} \n";
}


chmod 0777, $outfile ;

sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
