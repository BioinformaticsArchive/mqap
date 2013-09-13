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
use Statistics::Distributions;

use Time::HiRes qw( usleep ualarm gettimeofday tv_interval clock_gettime clock_getres  clock);
use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($P,$what,$promvalue,$infile,$outslope,$outrsquare,$outfile,$which_tech,$dist,$reverse,$listfile,$protein);
my (@expressions);
my $howmany = 100000 ;
my $verbose = 1 ;
my $MAX = 10000 ;
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "reverse=i"=>\$reverse,
            "protein=s"=>\$protein ,
            "what=s"=>\$what ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "outrsquare=s"=>\$outrsquare ,
            "expr=s"=>\@expressions,
            "P=f"=>\$P ,
            "max=i"=>\$MAX ,
            "promvalue=f"=>\$promvalue ,
            "dist=i"=>\$dist ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
usage( "Need to give a input file name => option -dist ") if(!defined $dist);
usage( "Need to give a input file name => option -what ") if(!defined $what);
usage( "Need to give a promvalue => option -promvalue ") if(!defined $promvalue);
usage( "Need to give a input file name => option -infile ") if(!defined $infile);
usage( "Need to give a P => option -P ") if(!defined $P);
my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC) = util_SetEnvVars();
my $PWD = cwd;

$outfile = "$what.proportion";
my $ofh= util_append($outfile);

my $table = {};

$table->{Polar} = 39 ;
$table->{Acidic} = 20 ;
$table->{Basic} = 20 ;
$table->{AcidBasic} = 20 ;



my $cutoff = $table->{$what} or die ;

my ($total, $pos,$neg) ;
if($reverse eq 0){
   ($total, $pos,$neg) = PromProteins($infile,$promvalue,$cutoff);
}
elsif ($reverse eq 1){
   ($total, $pos,$neg) = NonPromProteins($infile,$promvalue,$cutoff);
}
else{
   ($total, $pos,$neg) = Both($infile,$promvalue,$cutoff);
}

my $cnt = $pos + $neg ; 
my $percent = ($pos/($cnt));
$percent = (int($percent*100))/100 ;

my $sigma = sqrt(($P* (1-$P))/$cnt);
my $z = ($percent - $P)/($sigma) ;

my $nfh = util_append("number");
print $nfh "$dist cnt = $cnt pos = $pos neg = $neg percemt = $percent P = $P z = $z sigma = $sigma\n";



#$z = -1.75 ;
my $uprob=Statistics::Distributions::uprob ($z);
#$uprob = 1 - $uprob ;
 #my $u=Statistics::Distributions::udistr (.05);
#print "upper probability of the u distribution (u = -0.85): Q(u) " ."= 1-G(u) = $uprob\n";

my $ifhsigma   = util_append("$what.$P.sigma");
my $ifhz       = util_append("$what.$P.z");
my $ifhp       = util_append("$what.$P.p");
my $ifhpercent = util_append("$what.$P.percent");

print $ifhsigma "$dist $sigma\n";
print $ifhp "$dist $uprob\n";
print $ifhz "$dist $z\n";
my $realpercentage = $percent * 100 ;
print $ifhpercent "$dist $realpercentage\n";

print $ofh "$what $dist total = $cnt percent = $percent sigma = $sigma , z = $z uprob = $uprob   \n";

sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}


sub PromProteins{
	my ($in,$promvalue,$cutoff) = @_ ; 
	my ($t,$p,$n) ; 
	$t = $p = $n = 0 ; 
    my $ifh = util_read($in);
    while(<$ifh>){
        next if(/^\s*$/);
        s/,/ /g;
	    my ($x,$y) = split ; 
	    next if($x < $promvalue);
	    if($y > $cutoff){
		     $p++ ;
	    }
	    else{
		     $n++ ;
	    }
	    $t++;
    }
   close($ifh);
   return ($t,$p,$n);
}


sub NonPromProteins{
	my ($in,$promvalue,$cutoff) = @_ ; 
	my ($t,$p,$n) ; 
	$t = $p = $n = 0 ; 
    my $ifh = util_read($in);
    while(<$ifh>){
        next if(/^\s*$/);
        s/,/ /g;
	    my ($x,$y) = split ; 
	    next if($y >= $cutoff);
	    if($x > $promvalue){
		     $n++ ;
	    }
	    else{
		     $p++ ;
	    }
	    $t++;
    }
   close($ifh);
   return ($t,$p,$n);
}

sub Both{
	my ($in,$promvalue,$cutoff) = @_ ; 
	my ($t,$p,$n) ; 
	$t = $p = $n = 0 ; 
    my $ifh = util_read($in);
    while(<$ifh>){
        next if(/^\s*$/);
        s/,/ /g;
	    my ($x,$y) = split ; 
	    next if($y > $cutoff && $x < $promvalue);
	    if(($x >= $promvalue && $y <= $cutoff) || ($y >= $cutoff && $x <= $promvalue) ){
		     $n++ ;
	    }
	    else{
		     $p++ ;
	    }
	    $t++;
    }
   close($ifh);
   return ($t,$p,$n);
}
