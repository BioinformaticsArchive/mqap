#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use MyUtils;
use ConfigPDB;

use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($infile,$outfile,$which_tech,$listfile);
my (@expressions);
my $howmany = 100000 ;
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "expr=s"=>\@expressions,
            "howmany=i"=>\$howmany ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
my $ofh = util_write($outfile);
usage( "Need to give a input file name => option -infile ") if(!defined $infile);
my $ifh = util_read($infile);
my $CNT = 0 ; 

my @nm ;
my @a ;
my @b ;
my @c ;
my @d ;


my @rows ; 

my @l ; 
while(<$ifh>){
     next if(/^\s*$/);
     chop ;
	 last if($CNT > $howmany) ;
	 my ($nm,$junk) = split ; 
	 if(1){
		push @nm, $_ ;
	 	my $a = <$ifh> ;
		chop $a ;
		(@l) = split " ",$a ; 
		my $len = length($l[3]) ;
		if($len > 7 ){
		     my ($sss) = ($l[3] =~ s/.......//);
		}
		else{
			$l[3] = $l[4];
		}

		push @a, $l[3] ;
		$a = $l[3];

	 	my $b = <$ifh> ;
		chop $b ;
		(@l) = split " ",$b ; 
		my $len = length($l[3]) ;
		if($len > 7 ){
		     my ($sss) = ($l[3] =~ s/.......//);
		}
		else{
			$l[3] = $l[4];
		}
		push @b, $l[3]; 
		$b = $l[3];

	 	my $c = <$ifh> ;
		chop $c ;
		(@l) = split " ",$c ; 
		my $len = length($l[3]) ;
		if($len > 7 ){
		     my ($sss) = ($l[3] =~ s/.......//);
		}
		else{
			$l[3] = $l[4];
		}
		push @c, $l[3]; 
		$c = $l[3];

	 	my $d = <$ifh> ;
		chop $d ;
		(@l) = split " ",$d ; 
		my $len = length($l[3]) ;
		if($len > 7 ){
		     my ($sss) = ($l[3] =~ s/.......//);
		}
		else{
			$l[3] = $l[4];
		}
		push @d, $l[3]; 
		$d = $l[3];

		my $X = $a +  $b + $c + $d;
	    next if(!defined $X);

		my $junk = <$ifh>;

		my $a_b = $a - $b ; 
		my $a_c = $a - $c ; 
		my $a_d = $a - $d ; 
		my $b_c = $b - $c ; 
		my $b_d = $b - $d ; 
		my $c_d = $c - $d ; 
	    #print "$nm      $a      $b      $c      $d\n";
	    print "$nm      $a_b    $a_c    $a_d     $b_c    $b_d    $c_d \n";
	    my @v  = (  $a_b ,    $a_c  ,  $a_d   ,  $b_c  ,  $b_d  ,  $c_d );
		push @rows, \@v ;
	 }
}

my $nrows = @rows - 1;
my @cols ; 


foreach my $i (0..$nrows){
	my $row = $rows[$i];
	my @row = @{$row};
	my $ncol = @row - 1 ;
    foreach my $j (0..$ncol){
		if(!defined $cols[$j]){
			my @l = ();
			$cols[$j] = \@l;
		}
		push @{$cols[$j]}, $row[$j];
	}
}

foreach my $container (@cols){
    my $mean = Math::NumberCruncher::Mean($container) or die ;
    my $sd = Math::NumberCruncher::StandardDeviation($container) or die ;
my $top = 1200 ; 
my $low = 700 ; 
    my $incnt = 0 ;
    my $outcnt = 0 ;
	foreach my $i (@{$container}){
		$i = -($i);
		if($i > $low && $i < $top){
			$incnt++;
		}
		else{
			$outcnt++;
		}
	}
	print "$mean $sd outcnt = $outcnt incnt = $incnt \n";
}


while(@nm){
	my $nm = pop @nm ; 
	my $a = pop @nm ; 
	my $b = pop @nm ; 
	my $c = pop @nm ; 
	my $d = pop @nm ; 

}

close($ifh);


chmod 0777, $outfile ;
sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
