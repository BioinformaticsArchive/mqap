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
my ($infile,$outfile,$which_tech,$listfile,$protein);
my (@expressions);
my $howmany = 100000 ;
my $verbose = 1 ;
my ($kobs,$vf,$vo);
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "protein=s"=>\$protein ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "kobs=s"=>\$kobs ,
            "vo=s"=>\$vo ,
            "vf=s"=>\$vf ,
            "outfile=s"=>\$outfile ,
            "expr=s"=>\@expressions,
            "howmany=i"=>\$howmany ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a input file name => option -infile ") if(!defined $infile);
my $ifh = util_read($infile);
usage( "Need to give a -option -kobs  ") if(!defined $kobs);
usage( "Need to give a -option -vf  ") if(!defined $vf);
usage( "Need to give a -option -vo  ") if(!defined $vo);

$outfile = "out." . "$infile" . ".csv";
my $ofh = util_write($outfile);

my (@kobs) = GetValuesForVariable($kobs);
my (@vf) = GetValuesForVariable($vf);
my (@vo) = GetValuesForVariable($vo);

my @values ; 
while(<$ifh>){
    next if(/^\s*$/);
	my ($t,$A) = split ; 
	push @values, $t ;
	push @values, $A ;
}

my @newScores;
foreach my $a (@kobs){
    foreach my $b (@vf){
        foreach my $c (@vo){
            my ($x,$y,$z,$M,$SD) = EvalOneEquation($a,$b,$c,\@values);
			#die ;
			next if (!defined $x || $x eq "nan");
			next if (abs($M) > 1);
			#next if ($SD > 0.1);

			my $XX = {};
			$XX->{NEWSCORE} = $M ; 
			$XX->{STR} = "$x,$y,$z,$M,$SD\n";
			push @newScores,$XX ;

		    #print $ofh "$x,$y,$z,$M,$SD \n";
			#print "$a $b $c \n";
		}
	
	}
}

my @resultssorted = sort { $a->{NEWSCORE} <=> $b->{NEWSCORE} } @newScores ;
foreach my $x (@resultssorted){
	print $ofh "$x->{STR}"; ; 
}

sub EvalOneEquation{
	my ($KOBS,$VF,$VO,$values) = @_ ;
	print "Eval equantion with $KOBS,$VF,$VO \n";
	my @VALUES = @{$values}; 
	my @devs ;
	my $diff  = ($VO - $VF) ;
	return  if($KOBS*$VF*$VO eq 0);
	my $cnt = 0 ; 
	my $Ainit ; 
	while(@VALUES){
		my $t = shift @VALUES ;
		my $A = shift @VALUES ;
		if(! defined $Ainit){
			$Ainit = $A ; 
			next ;
		}
		my $kt = $KOBS*$t ; 
		my $vft = $VF*$t ;

		#my $inv = POSIX::pow($diff,$kt);
		#my $calc = 1/$inv ; 
		#my $lhs = ($vft + $calc)/$KOBS ;

		my $inv = POSIX::pow(2.7182,$kt);
		my $calc = 1 -  1/$inv ; 

		my $G = ($diff*$calc)/$KOBS;
		my $lhs = $Ainit + $vft + $G ; 

		my $dev = $A - $lhs ;
		#print "t = $t kt = $kt diff = $diff vf = $vft inv = $inv calc = $calc lhs = $lhs dev = $dev\n";
		if(abs($dev) > 10000 ){
	        $cnt++;
		}
		if($cnt > 9){
			return ;
		}
		push @devs, $dev ; 
	}
	my $N = @devs ;
	my $mean = Math::NumberCruncher::Mean(\@devs) or warn "Mean not found" ;
	if($mean eq "nan"){
	    return ;
	}
	my $sd = Math::NumberCruncher::StandardDeviation(\@devs) or warn "sd not found" ;
	$mean = util_format_float($mean,3);
	$sd = util_format_float($sd,3);

	print "mean = $mean $sd $N \n";

	return ($KOBS,$VF,$VO,$mean,$sd) ;
}

sub SplitIntoValues{
	my ($a) = @_ ;
	$a =~ s/-/ /g ;
	my @l = split " ",$a ;
	return @l 
}

sub GetValuesForVariable{
	my ($var) = @_ ; 
    my ($start,$end,$del) = SplitIntoValues($var);
	print "$var gave $start,$end,$del \n";
	my @ret ; 
	my $v = $start;
	while($v < $end ){
		push @ret , $v ; 
		$v = $v + $del ;
	}
	$, = " , ";
	print @ret , "\n";
	return @ret ;
}

sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
