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
my $del ;
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
            "del=i"=>\$del ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);

usage( "Need to give a input file name => option -infile ") if(!defined $infile);
my $ifh = util_read($infile);
usage( "Need to give a from -option -from  ") if(!defined $from);
usage( "Need to give a to -option -to  ") if(!defined $to);
usage( "Need to give a to -option -del") if(!defined $del);


$outfile  ="$from.2.$to.png" if(!defined $outfile);
my $ofh = util_write($outfile);

my $image = new MyMagick($infile);

$image->DebugInfo() if(defined $debug);

my $w = $image->GetWidth();
my $h = $image->GetHeight();

print "W = $w H = $h\n";

my $obj = $image->GetObj();

my $colorinfo = $image->GetColorInfo();

    foreach my $i (1..$h){
        my $p = $image->GetRowStraightorReversed(0,$i);
        while(@{$p}){
	        my $l = shift @{$p};
		    my ($r,$g,$b,$x,$y) = @{$l} ;
	        my @l = ($r,$g,$b);
	        my ($val,$name) = $image->IsColor(\@l,$image->GetAvailableColors());
		    if($name eq "red"){
				my @circle = geom_GetCircleAroundPoint($x,$y,10);
				my $allblack = 1 ;
				while(@circle){
					my $X = shift @circle;
					my $Y = shift @circle;
					next if($X <=0 || $Y <=0);
			        next if(!$image->CheckPixelIsFine($X,$Y));
			        my @pixel = $image->GetPixel($X,$Y);
	                my ($v,$name) = $image->IsSingleColor(@pixel);
			        if($name ne "black"){
						$allblack = 0 ; 
						last ;
					}
				}
				if($allblack){
                    $image->SetColorToPixelByColorName($x,$y,"black");
				}
		    }
        }
	}

$image->Write($outfile,$display);

sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ;
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}

