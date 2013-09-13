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
my ($infile,$outfile,$which_tech,$listfile,$protein,$in1,$in2,$index);
my (@expressions);
my $howmany = 100000 ;
my $verbose = 1 ;
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "protein=s"=>\$protein ,
            "in1=s"=>\$in1 ,
            "in2=s"=>\$in2 ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "expr=s"=>\@expressions,
            "index=i"=>\$index ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
my $ofh = util_write($outfile);
usage( "Need to give a input file name => option -in1 ") if(!defined $in1);
usage( "Need to give a input file name => option -in2 ") if(!defined $in2);

my $l1 = getFile($in1,0);
my $l2 = getFile($in2,$index);
my @l1 = @{$l1};
my @l2 = @{$l2};

my $s1 = @l1 ;
my $s2 = @l2 ;
die if($s1 != $s2);

while(@l1){
	my $v1 = shift @l1 ;
	my $v2 = shift @l2 ;
	my $diff = util_format_float($v1 - $v2,3) ; 
	print $ofh "$diff ";

}

print $ofh "\n";


sub getFile{
    my ($infile,$index) = @_ ; 
    my $info = {};
    my $ifh = util_read($infile);
	my $cnt = 0;
    while(<$ifh>){
		if($cnt == $index){
	        my @l = split ;
	        return \@l ;
		}
		$cnt++;
    }
}

chmod 0777, $outfile ;
sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
