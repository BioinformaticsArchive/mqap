
package MyQPaper;
use Carp ;
use MyUtils ;
use POSIX ;
require Exporter;
use Algorithm::Combinatorics qw(combinations) ;
use Math::NumberCruncher;
use Math::MatrixReal;  # Not required for pure vector math as above
use Math::Geometry ; 
use Math::VectorReal qw(:all);  # Include O X Y Z axis constant vectors
#use Math::Trig;
#use Math::Trig ':radial';
no warnings 'redefine';
my $EPSILON = 0.01;

  local $SIG{__WARN__} = sub {};

@ISA = qw(Exporter);
@EXPORT = qw( 
QP_round2place
QP_GetNRandomNumbersBelowValue
QP_GetNRandomNumbersBelowValueSorted
	    );

use strict ;
use FileHandle ;
use Getopt::Long;


sub QP_round2place{
    my ($num) = (@_);
    $num = $num*100 ;

    $num = util_round($num);
    $num = $num/100.0;
    return $num ;
}

sub QP_GetNRandomNumbersBelowValue{
    my ($n1,$n2) = @_ ; 
	my @l ; 
	my $done = {};
	while($n1){
        my $a = floor($n2*rand())+1;
		next if(exists $done->{$a});
		$done->{$a} = 1 ; 
		push @l , $a ;
		$n1--;
	}
	return @l ;
}
sub QP_GetNRandomNumbersBelowValueSorted{
    my ($n1,$n2) = @_ ; 
	my @l ; 
	my $done = {};
	while($n1){
        my $a = floor($n2*rand())+1;
		next if(exists $done->{$a});
		$done->{$a} = 1 ; 
		push @l , $a ;
		$n1--;
	}
	my @sl = sort {$a <=> $b}  @l;
	return @sl ;
}
