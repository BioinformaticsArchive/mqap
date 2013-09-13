#!/usr/bin/perl -w 
use lib '/home/b/Bio/Code/perl_scripts/perl_scripts/';
use MyGeom;
use MyMagick;
use MyUtils;
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


#use Time::HiRes qw( usleep ualarm gettimeofday tv_interval clock_gettime clock_getres  clock);
use POSIX qw(floor);
$, = " ";
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($infile,$outfile,$which_tech,$display,$listfile,$protein);
my ($justidentify,$csv,$contourcolor,$color,$distfromperiphery,@expressions,$from,$to,@colornms,$specifiedcolor);
my $delta ;
my $verbose = 1 ;
my $NUMITERS = 100 ; 
my $SCALE = 1/7 ; 
GetOptions(
            "from=s"=>\$from ,
            "to=s"=>\$to ,
            "csv=s"=>\$csv ,
            "protein=s"=>\$protein ,
            "contourcolor"=>\$contourcolor ,
            "display"=>\$display ,
            "infile=s"=>\$infile ,
            "specifiedcolor=s"=>\$specifiedcolor ,
            "listfile=s"=>\$listfile ,
            "color=s"=>\@colornms ,
            "outfile=s"=>\$outfile ,
            "justidentify=s"=>\$justidentify ,
            "expr=s"=>\@expressions,
            "delta=f"=>\$delta ,
            "distfromperiphery"=>\$distfromperiphery ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
my $ofh = util_write($outfile);
usage( "Need to give a listfile ile name => option -listfile ") if(!defined $listfile );

my @list= util_read_list_sentences($listfile);
my $cnt = 0; 
my @l ; 
foreach my $i (@list){
	$cnt++ ;

    my $image = new MyMagick($i);
    my (@blue) = $image->FindCoordsForColor("blue");
    my (@red) = $image->FindCoordsForColor("red");
	if(@blue || @red){
		print $ofh "$i\n";
		push @l, $i ;
	}
}

my $N = @l ;
my $mid = $l[int($N/2)];
my $ofhmid = util_write("midfile");
print $ofhmid "$mid\n";




sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ;
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}

