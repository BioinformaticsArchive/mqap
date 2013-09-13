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
my ($infile,$outfile,$which_tech,$listfile,$protein,$runscript);
my (@expressions);
my $howmany = 100000 ;
my $verbose = 1 ;
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "runscript=s"=>\$runscript ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "expr=s"=>\@expressions,
            "howmany=i"=>\$howmany ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);

usage( "Need to give a input file name => option -infile ") if(!defined $infile);
usage( "Need to give a input file name => option -runscript ") if(!defined $runscript);
usage( "Need to give a input file name => option -which_tech ") if(!defined $which_tech);
$outfile = "$which_tech.html";
my $ofh = util_write($outfile);
my $ofhscr = util_write($runscript);

my $ifh = util_read($infile);
my $CNT = 0 ; 
my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC) = util_SetEnvVars();
my $PWD = cwd;

my $rundir = "ALLRUNS.$which_tech";


my $info = {};
print $ofhscr "mkdir -p $rundir\n";
while(<$ifh>){
     next if(/^\s*$/);
	 chomp ; 
	 s/..//; 

	 my $orig = $_ ;
	 s/\//\./g; 
	 s/\./ /g; 
	 my @l = split ;
	 my $N = @l ; 
	 #print "$N $l[0]  $l[1]  $l[2]  $l[3] $l[4] $l[5]   lll\n";
	 #./Mouse.Q8VCY6.Saccharomyces.Q02354.gap.25.size30/mainlevel.Mouse.Q8VCY6.Saccharomyces.Q02354.html

#print << "JABWEMET" ; 
print $ofh "<li> <a href=\"$rundir/$orig\">\n";
                print $ofh "<strong>$l[0].$l[1] to $l[2].$l[3] for sequence fragment gap = $l[5] and  $l[6] </strong></a>\n";

     print $ofhscr "cp -r $l[0].$l[1].$l[2].$l[3].$l[4].$l[5].$l[6] $rundir\n";


}
     print $ofhscr "TAR $rundir \n";
chmod 0777, $outfile ;
print STDERR "Wrote to file $outfile\n";


sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
