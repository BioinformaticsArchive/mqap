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
my ($l1,$l2,$infile,$outfile,$which_tech,$listfile,$protein);
my (@expressions);
my $howmany = 100000 ;
my $verbose = 1 ;
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "protein=s"=>\$protein ,
            "infile=s"=>\$infile ,
            "l1=s"=>\$l1 ,
            "l2=s"=>\$l2 ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "expr=s"=>\@expressions,
            "howmany=i"=>\$howmany ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
my $ofh = util_write($outfile);
usage( "Need to give a input file name => option -infile ") if(!defined $l1);
usage( "Need to give a input file name => option -infile ") if(!defined $l2);
my $protein ; 
my $ifh = util_read($l1);
while(<$ifh>){
     next if(/^\s*$/);
     chop ;
	 ($protein) = split ; 
	 last ;
}

usage( "Need to give a listfile -option -listfile  ") if(!defined $listfile);
my $CNT = 0 ; 
my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC) = util_SetEnvVars();
my $PWD = cwd;


my @list= util_read_list_words($listfile);
my $list = {};
map { s/\s*//g ; $list->{$_} = 1 ; } @list ;
my $NRES = @list ; 
print "number of residues = $NRES\n";

print $ofh "#\!/bin/csh -f \n";
print $ofh "\$SRC/SHELLSCRIPTS/createCLASPinput.csh $protein $listfile $NRES $NRES \n";
print $ofh "if(\! -e ANNOTATE) then \n";
print $ofh "ln -s ANNOTATE.$NRES ANNOTATE\n";
print $ofh "endif \n";
print $ofh "\$SRC/CSA/runRefExtractEasilyNamed.csh $l1 $l2 0";


chmod 0777, $outfile ;
close($outfile);

sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
