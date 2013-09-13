#!/usr/bin/perl -w 
use MyGeom;
use MyMagick;
use MyUtils;
use MyBlock;
use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use ConfigPDB;
use PDB;
use POSIX ;
use Algorithm::Combinatorics qw(combinations) ;
use Math::Geometry ;
use Math::Geometry::Planar;
my $polygon = Math::Geometry::Planar->new; 
   #$contour = Math::Geometry::Planar->new; creates a new contour object;


use Time::HiRes qw( usleep ualarm gettimeofday tv_interval clock_gettime clock_getres  clock);
use POSIX qw(floor);
$, = " ";
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($infile,$outfile,$which_tech,$display,$listfile,$protein);
my ($csv,$contourcolor,$color,@expressions,$from,$to,@colornms);
my $howmany = 100000 ;
my $verbose = 0 ;
my $NUMITERS = 100 ; 
GetOptions(
            "from=s"=>\$from ,
            "to=s"=>\$to ,
            "csv=s"=>\$csv ,
            "protein=s"=>\$protein ,
            "contourcolor"=>\$contourcolor ,
            "display"=>\$display ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "color=s"=>\@colornms ,
            "outfile=s"=>\$outfile ,
            "expr=s"=>\@expressions,
            "howmany=i"=>\$howmany ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
my $ofh = util_write($outfile);
usage( "Need to give a input file name => option -infile ") if(!defined $infile);
usage( "Need to give a color => option -color ") if(!@colornms);
my $ifh = util_read($infile);
#usage( "Need to give a from -option -from  ") if(!defined $from);
#usage( "Need to give a to -option -to  ") if(!defined $to);
usage( "Need to give a csv => option -csv ") if(!defined $csv);
my $ofhcsv = util_write($csv);


my $colornms = util_make_table(\@colornms);

my $image = new MyMagick($infile);

my $w = $image->GetWidth();
my $h = $image->GetHeight();

print "W = $w H = $h\n";

my $obj = $image->GetObj();


my $blkcnt = 0 ;
my @blocks ; 
my $block ; 
my $globalblockinfo = {};
my @colors = @{$image->GetAvailableColors()};
foreach my $i (1..$image->{HEIGHT}){
        my $p = $image->GetRowStraightorReversed(0,$i);
		my $seen = 0 ; 
        while(@{$p}){
	        my $l = shift @{$p};
		    my ($r,$g,$b,$x,$y) = @{$l} ;
	        my @l = ($r,$g,$b);
	        my ($val,$name) = $image->IsColor(\@l,$image->GetAvailableColors());
			if(!($x > 132 && $x < 148 && $y > 450 && $y < 455) ){
		         $image->SetColorToPixelByColorName($x,$y,"white");
			}
			if($colornms->{$name}){
				if($seen){
					$block->Add($x,$y,$globalblockinfo);
				}
				else{
					$block = new MyBlock($blkcnt++);
					$block->Add($x,$y,$globalblockinfo);
					push @blocks, $block ;
					$seen = 1 ;
				}
			}
			else{
				$seen = 0 ; 
			}
        }
}
print "Number of blks = $blkcnt \n";
$image->Write("hhh.png");
exit ;

