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
my ($infile,$outfile,$dir,$listfile,$protein);
my (@expressions);
my $howmany = 100000 ;
my $verbose = 1 ;
GetOptions(
            "dir=s"=>\$dir ,
            "protein=s"=>\$protein ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "expr=s"=>\@expressions,
            "howmany=i"=>\$howmany ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a dir ") if(!defined $dir);
#my $ofh = util_write($outfile);
my $CNT = 0 ; 
my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC,$MATCH3D,$ANNDIR, $UNIPROT) = util_SetEnvVars();


chdir($dir);
my @l = <*.out> ;
foreach my $i (@l){
    my $orig = $i ;
	$i =~ s/\./ /g;
	my ($a,$b)  = split " " , $i ;

    my $ifh = util_read($orig);
	my $A ; 
	my $B ; 
    while(<$ifh>){
	  if(/fasta/){
	  		($A) = (/.*\/(.*)\.ALL/);
			$_ = <$ifh>;
	  		($B) = (/.*\/(.*)\.ALL/);
			last ;
	  }
    }
	die "$orig is not same for $a $b $A $B for dir $dir\n" if($a ne $A || $b ne $B);
    close($ifh);
}


sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
