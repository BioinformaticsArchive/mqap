#!/usr/bin/perl -w 

use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;

use MyUtils;
use POSIX qw(floor);

my $commandline = util_get_cmdline("",\@ARGV) ;

my ($easy, $nodecimals, $infile,$qpaper,$howmany,$design,$multiple,$answer,$clocked);
$howmany = 0 ;
$multiple = 1 ;
GetOptions(
            "howmany=s"=>\$howmany ,
            "infile=s"=>\$infile ,
            "clocked:s"=>\$clocked ,
            "design=s"=>\$design ,
            "answer=s"=>\$answer ,
            "multiple=i"=>\$multiple ,
            "nodecimals"=>\$nodecimals ,
            "easy"=>\$easy ,
            "qpaper=s"=>\$qpaper );

die "Dont recognize command line arg @ARGV " if(@ARGV);



my @l1 ; 
my @l2 ; 
my @l ; 

push @l1 , genTerm("a");
push @l1 , genTerm("b");

push @l2 , genTerm("a");
push @l2 , genTerm("b");

push @l , \@l1 ;
push @l , \@l2;

my $str = printExpr(@l);
print "$str \n";
my $m = multExpr(@l);
print "$m \n";

sub genTerm{
	my ($a) = @_ ; 
    my $celprob = util_round(rand());
    my $n1 =  floor(10*rand())+1;
	my @term ; 
    if($celprob){
		 push @term , "+";
		 push @term , $n1 ; 
		 push @term , $a ; 
	}
	else{
		 push @term , "-";
		 push @term , $n1 ; 
		 push @term , $a ; 
	}
	return \@term ; 
}

sub printExpr{
	my (@l) = @_ ; 
	my $finalexpr = "";
	foreach my $l (@l){
		my @exprs = @{$l} ; 
        my $expr = "( ";
		foreach my $e (@exprs){
		    my $term = join "",  @{$e};
			$expr = $expr . $term ; 
		}
		$expr = $expr . ") " ; 
		$finalexpr = $finalexpr . $expr ; 
	}
	return $finalexpr ;
}

sub multExpr{
	my (@l) = @_ ; 
	my $finalexpr = "";
	my $l1 = shift (@l);
	my @exprs1 = @{$l1} ; 
	my $l2 = shift (@l);
	my @exprs2 = @{$l2} ; 

    my $finalexpr = "";
	foreach my $e1 (@exprs1){
	    my ($sign1, $coeff1, $nm1) = @{$e1};
	    foreach my $e2 (@exprs2){
			 my ($sign2, $coeff2, $nm2) = @{$e2};
			 my $SIGN = $sign1 eq $sign2 ? "+" : "-";
			 my $COEFF = $coeff1 * $coeff2 ;
			 my $NM = $nm1 . $nm2 ; 
			 my $expr =  " $SIGN$COEFF$NM";
		     $finalexpr = $finalexpr . $expr ; 
		}
	}
	return $finalexpr ;
}
