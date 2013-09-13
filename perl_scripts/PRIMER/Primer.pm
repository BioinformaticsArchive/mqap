
package Primer;
use Carp ;
use POSIX ;
require Exporter;
use Algorithm::Combinatorics qw(combinations) ;
use Math::NumberCruncher;
use Math::MatrixReal;  # Not required for pure vector math as above
use Math::Geometry ; 
use MyUtils;
#use Math::Trig;
#use Math::Trig ':radial';
no warnings 'redefine';
my $EPSILON = 0.01;
 use Bio::Tools::CodonTable;


  local $SIG{__WARN__} = sub {};

@ISA = qw(Exporter);
@EXPORT = qw(
ReadSeq
IsAA
SplitCodonIntoNucleotides
Change2This
ReplaceOneCodon
GetWindowCodon
GetWindowNucleotide
Change2Lower
CountNucleotide
GetTemp
GetGCCountPercent
GetHowManyToBeginWith
ReplaceSingleAA
GetTemperature
PrintInfo
GetComplementary
           );

sub ReadSeq{
    my ($infile,$proteinseq,$change2lower) = @_ ; 
	die if(!defined $proteinseq);
    my $ifh = util_read($infile);
    my $line = "";
    while(<$ifh>){
	    chomp ; 
         next if(/^\s*$/);
         next if(/^\s*>/);
	     s/\s*//g; 
	    $line = $line . $_;
    }
    
	if($change2lower){
        my @l = Change2Lower($line);
        $line = $l[0];
	}
    my $width = length($line);
	my @ll = ($line =~ /(...)/g);
	close($ifh);
    die "Expected nucleotide seq $line " if(!$proteinseq && !IsAA($line));

    return ($line,$width,@ll);
}

sub ReplaceSingleAA{
	  my ($idx, $from, $to, $seq,$score,$len,$myCodonTable,$ofh) = @_ ; 
      my  $aaName = $myCodonTable->translate($from);
      my @codons = $myCodonTable->revtranslate($to);

	  my @seqs  ;
      foreach my $codon (@codons){
	      my $cnt = Change2This($from,$codon);
		  my $newscore = $cnt+$score;
	      my @changedSeq = ReplaceOneCodon($idx,$codon,@{$seq});
		  push @seqs, \@changedSeq;
		  push @seqs, $newscore ;
	 }
	 return @seqs ;

}

sub PrintInfo{
	  my ($idx, $from, $to, $seq,$len,$myCodonTable,$ofh) = @_ ; 
	  $len--;
      my  $aaName = $myCodonTable->translate($from);
      print $ofh "len = $len, replace = $aaName at $idx( $from), use = $to\n";
      my @codons = $myCodonTable->revtranslate($to);

	  my @seqs  ;
      foreach my $codon (@codons){
          print $ofh "$to codon $codon for from $from \n";
	 }
}





sub IsAA{
	my ($line) = @_ ; 
	my @l = split "" , $line;
	my $nucleotide = 1 ;
	foreach my $s (@l){
	    if($s !~ /(A|T|G|C|U)/i){
		print "NOT NUCLEOTIDE $s\n";
			$nucleotide = 0 ; 
			last ;
	    }
	}
	return (!$nucleotide) ;
}

sub SplitCodonIntoNucleotides{
	my ($line) = @_ ; 
    my @f = ($line =~ /(.)/g);
    my $len = @f ; 
    die "Expected length 3, got $len for $line" if($len ne 3);
	return @f ;
}

sub Change2This{
	my ($from,$to) = @_ ; 
	print "STDERR Change2This from = $from to = $to \n";
    my @f = SplitCodonIntoNucleotides($from);
    my @t = SplitCodonIntoNucleotides($to);
	my $cnt = 0 ; 
	foreach my $i (0..2){
		my $a = $f[$i];
		my $b = $t[$i];
		$cnt++ if($a ne $b);
	}
	return $cnt ;

}

sub ReplaceOneCodon{
	my ($idx,$to,@line) = @_ ; 
	$line[$idx] = $to ; 
	return @line ; 
}


 

sub GetWindowCodon{
    my ($idx,$l,$r,@line) = @_ ; 
	my $len = @line ; 
	my $start = $idx -$l ;
	my $end = $idx + $r ;
	if($start < 0 || $end >= $len){
		print STDERR " Out of bounds for $idx,$l,$r, $len\n";
		return undef ;
	}
	my $retline = "";
	foreach my $i ($start..$end){
		$retline = $retline . $line[$i];
	}
	return $retline ; 
}


sub GetWindowNucleotide{
    my ($idx,$l,$r,@line) = @_ ; 
	my $CC = $line[$idx];
	my $str = join "", @line ; 
    my @single = split "", $str ;	
	my $len = @single ; 
	my $retline = "";
	my $start = ($idx)  * 3; 
	my $mid = ($start)  + 1 ;
	my $end = ($mid) + 1 ; 

	my $testCC = $single[$start]  . $single[$mid]  . $single[$end] ;
	die if($testCC ne $CC);

	my $L = $start - $l ;
	my $R = $end   +  $r ;

	my $pre = "";
	my $post = "";
	foreach my $i ($L..$start){
		$pre = $pre . $single[$i];
	}
	$pre =~ s/.$//;

	foreach my $i ($end..$R){
		$post = $post . $single[$i];
	}
	$post =~ s/^.//;


	my $complete = $pre . $CC . $post ;
	#print "full = $complete start = $start len $len actual cod  = $CC pre = $pre post = $post \n";

	return ($complete,$pre,$CC,$post,$L,$R) ; 
}
 
sub Change2Lower{
    my (@line) = @_ ; 
	my $len = @line ; 
	foreach my $i (0..$len){
		$line[$i] = lc($line[$i]);
	}
	return @line ; 
}
 
sub CountNucleotide{
    my ($what,@line) = @_ ; 
	my $len = @line -1 ; 
	my $cnt = 0 ; 
	foreach my $i (0..$len){
        my @f = ($line[$i] =~ /(.)/g);
	    foreach my $j (@f){
		$cnt++ if($j eq $what);
		}
	}
	return $cnt++;
}
 
sub GetTemperature{
	my ($GCCount_percent,$mismatchpercent,$width) = @_ ; 
	#print " ($GCCount_percent,$mismatchpercent,$width) \n";
    my $temp = 81.5 + 0.41 * $GCCount_percent - 675/$width - $mismatchpercent;
	return util_format_float($temp,3) ;
}

sub GetGCCountPercent{
	my ($line,$len) = @_ ; 
	my $gcount = CountNucleotide("g",$line);
	my $ccount = CountNucleotide("c",$line);
	my ($ret) = (($gcount + $ccount)*100)/$len ;
	# print "gcount = $gcount ccount = $ccount len = $len ret - $ret \n";
	return util_format_float($ret) ;
}


sub GetHowManyToBeginWith{
	my ($line) = @_ ; 
	print $line , "\n";
	my ($gc) = ($line =~ /^((g|c)*)/g);
	return 0 if(!defined $gc);
	return length($gc) ;
}

sub uniq2 {
	my ($l) = @_;
    my %seen = ();
    my @r = ();
    foreach my $a (@{$l}) {
        unless ($seen{$a}) {
            push @r, $a;
            $seen{$a} = 1;
        }
    }
    return @r;
}

sub GetComplementary{
	my ($line) = @_ ; 
	$line = lc($line);
	my @f = ($line =~ /(.)/g);
	my $len = @f ;


	my @ret ;
	my $s = "";
	foreach my $i (@f){
		$s = $s . "a" if($i eq "t");
		$s = $s . "t" if($i eq "a");
		$s = $s . "g" if($i eq "c");
		$s = $s . "c" if($i eq "g");
	}
	return $s ; 
	
}
