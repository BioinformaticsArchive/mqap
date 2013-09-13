#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use ConfigPDB;
use MyGeom;
use PDB;
use Statistics::LineFit;

use Time::HiRes qw( usleep ualarm gettimeofday tv_interval clock_gettime clock_getres  clock);
use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($what,$infile,$outslope,$outrsquare,$outfile,$which_tech,$dist,$reverse,$listfile,$protein);
my (@expressions);
my $howmany = 100000 ;
my $verbose = 1 ;
my $MAX = 10000 ;
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "reverse"=>\$reverse,
            "protein=s"=>\$protein ,
            "what=s"=>\$what ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "outslope=s"=>\$outslope ,
            "outrsquare=s"=>\$outrsquare ,
            "expr=s"=>\@expressions,
            "max=i"=>\$MAX ,
            "dist=i"=>\$dist ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outslope);
my $fhslope = util_append($outslope);
usage( "Need to give a output file name => option -osquareutfile ") if(!defined $outrsquare);
my $fhrsquare = util_append($outrsquare);
usage( "Need to give a input file name => option -dist ") if(!defined $dist);
usage( "Need to give a input file name => option -what ") if(!defined $what);
usage( "Need to give a input file name => option -infile ") if(!defined $infile);
my $ifh = util_read($infile);
my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC) = util_SetEnvVars();
my $PWD = cwd;



my @xValues ;
my @yValues ;
my $cnt = 0 ;
while(<$ifh>){
    next if(/^\s*$/);
    s/,/ /g;
	$cnt++;
	my ($x,$y) = split ; 
    if(defined $reverse){
	    my ($Y,$X) = ($x,$y);
	    ($x,$y) = ($X,$Y);
    }
     push @xValues, $x;
     push @yValues, $y;
	 last if($cnt > $MAX);


}
close($ifh);

 my $lineFit = Statistics::LineFit->new();
 $lineFit->setData (\@xValues, \@yValues) or die "Invalid data";
 $lineFit->regress();
 my ($intercept, $slope) = $lineFit->coefficients();
 defined $intercept or die "Can't fit line if x values are all equal";
 my $rSquared = $lineFit->rSquared();
 my $meanSquaredError = $lineFit->meanSqError();
 my $durbinWatson = $lineFit->durbinWatson();
 my $sigma = $lineFit->sigma();
 my ($tStatIntercept, $tStatSlope) = $lineFit->tStatistics();
 my @predictedYs = $lineFit->predictedYs();
 my @residuals = $lineFit->residuals();
 my ($varianceIntercept, $varianceSlope) = $lineFit->varianceOfEstimates();


my $res = 0 ;
foreach my $r (@residuals){
	$res = $res + $r ; 
}

print $fhslope "$intercept $slope $what\n";
#$rSquared = $rSquared * 10 ;
print $fhrsquare "$dist $rSquared \n";


sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
