#!/usr/bin/perl -w 
use MyMagick;
use MyUtils;
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
my ($infile,$outfile,$display,$which_tech,$debug,$listfile,$protein);
my (@expressions,$from,$to);
my $howmany = 100000 ;
my $verbose = 1 ;
GetOptions(
            "from=s"=>\$from ,
            "to=s"=>\$to ,
            "protein=s"=>\$protein ,
            "infile=s"=>\$infile ,
            "display"=>\$display ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "debug"=>\$debug ,
            "expr=s"=>\@expressions,
            "howmany=i"=>\$howmany ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);

usage( "Need to give a input file name => option -infile ") if(!defined $infile);
my $ifh = util_read($infile);
usage( "Need to give a from -option -from  ") if(!defined $from);
usage( "Need to give a to -option -to  ") if(!defined $to);


$outfile  ="$from.2.$to.png" if(!defined $outfile);
my $ofh = util_write($outfile);

my $image = new MyMagick($infile);

$image->DebugInfo() if(defined $debug);

my $w = $image->GetWidth();
my $h = $image->GetHeight();

print "W = $w H = $h\n";

my $obj = $image->GetObj();

my $table ; 
$table->{$from} = $to ;
$image->ChangeColor($table);
$image->Write($outfile,$display);


sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ;
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}

