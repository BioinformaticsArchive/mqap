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
my ($infile,$outfile,$which_tech,$debug,$listfile,$protein);
my (@expressions,$from,$to,$colorfile);
my $howmany = 100000 ;
my $verbose = 1 ;
GetOptions(
            "from=s"=>\$from ,
            "to=s"=>\$to ,
            "protein=s"=>\$protein ,
            "infile=s"=>\$infile ,
            "colorfile=s"=>\$colorfile ,
            "outfile=s"=>\$outfile ,
            "debug"=>\$debug ,
            "expr=s"=>\@expressions,
            "howmany=i"=>\$howmany ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
my $ofh = util_write($outfile);



my $image = new MyMagick();

$image->DebugInfo() if(defined $debug);

my $w = $image->GetWidth();
my $h = $image->GetHeight();

print "W = $w H = $h\n";

my $obj = $image->GetObj();

if(defined $colorfile){
	my @pixel ;
     my $ifh = util_read($colorfile);
     while(<$ifh>){
        next if(/^\s*$/);
	    chop ;
	    s/,//g;
		my @f = split ; 
		push @pixel, @f ; 
	}
	die "Need 3 points" if(@pixel != 3);
    $image->SetColorToFullImage(\@pixel);
}

#$image->GetObj()->Rotate(45);
#$image->GetObj()->Draw(fill=>'blue', stroke=>'red', primitive=>'circle', points=>' 90 50 50');

$image->Write($outfile);
system("eog $outfile");


sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ;
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}

