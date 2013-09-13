#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use ConfigPDB;
use MyGeom;
use PDB;
  use Bio::Tools::CodonTable;
 my $myCodonTable   = Bio::Tools::CodonTable->new();
 

use Time::HiRes qw( usleep ualarm gettimeofday tv_interval clock_gettime clock_getres  clock);
use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($infile,$outfile,$which_tech,$listfile,$protein);
my (@expressions);
my ($to,$idx) ;
my $howmany = 100000 ;
my $verbose = 1 ;
my $TEMP = 78 ;
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "to=s"=>\$to ,
            "idx=i"=>\$idx ,
            "protein=s"=>\$protein ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "expr=s"=>\@expressions,
            "howmany=i"=>\$howmany ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
util_CmdLine("to",$to);
util_CmdLine("idx",$idx);
util_CmdLine("outfile",$outfile);
my $ofh = util_write($outfile);
my $ifh = util_read($infile);
my $info = {};
my $line = "";
while(<$ifh>){
	chop ; 
     next if(/^\s*$/);
	 s/\s*//g; 
	$line = $line . $_;
}

die "Expected nucleotide seq " if(IsAA($line));

my @l = ($line =~ /(...)/g);

## make index to start from 1 
my @junk = qw ( JJJ  );
my @origSeq = (  @junk , @l );
@origSeq = Change2Lower(@origSeq);

my $len = @origSeq - 1 ; 
print @origSeq, "\n";


my $aaCodon = $origSeq[$idx];
my  $aaName = $myCodonTable->translate($origSeq[$idx]);
print $ofh "len = $len, AA to replace = $aaName with codon $aaCodon, AA to use = $to\n";


my @codons = $myCodonTable->revtranslate($to);
foreach my $codon (@codons){
	print  $ofh "Target residue $to has codon $codon\n";
}
my $codon2Changes = {};
my $from = $origSeq[$idx];

my $results = {};
my $counter = 0 ; 
foreach my $width (25..35){
foreach my $codon (@codons){
	my $result = {};
	$result->{$codon} = {};
	my $cnt = Change2This($from,$codon);
	my @changedSeq = ReplaceOneCodon($idx,$codon,@origSeq);
	print STDERR "Target residue $to has codon $codon : count = $cnt\n";
	my $window = GetWindowCodon($idx,1,1,@changedSeq);
	print " Window of 1\n";
	print $window, "\n";
	$window =~ s/^..//;
	$window =~ s/..$//;
	print " Window of 1\n";
	print $window, "\n";

	my $l = 10;
	my $r = $width - 10 ;
	while($l < ($width - 10)){
		 $counter++;
	     my ($window,$pre,$mid,$post) = GetWindowNucleotide($idx,$l,$r,@changedSeq);
		 if(defined $window){
		     if($pre =~ /^(a|t)/i || $pre =~ /^.(a|t)/i || $post =~ /(a|t)$/i || $post =~ /^(a|t).$/i  ){
			 	print "Ignored due to at in begining or end\n";
			 }
			 else{
		        my $GCCount_percent = GetGCCountPercent($window,$width); 
		        my $mismatchpercent = ($cnt * 100)/$width ;
		        my $temp  = GetTemp($GCCount_percent,$mismatchpercent,$width);
				if($temp > $TEMP){

				     my $beginwith = GetHowManyToBeginWith($pre);
				     my $revpost = reverse($post);
				     my $endwith = GetHowManyToBeginWith($revpost);
	                 print "\t\t $pre $mid $post temp = $temp begin = $beginwith end = $endwith rev post $revpost  \n";
     
					 my $full = $pre . $mid . $post ;
					 my $rev = reverse($full);
	                 $codon2Changes->{$counter}->{WIDTH} = $width;
	                 $codon2Changes->{$counter}->{CODON} = $codon;
	                 $codon2Changes->{$counter}->{SCORE} = $cnt;
	                 $codon2Changes->{$counter}->{TEMP} = $temp;
	                 $codon2Changes->{$counter}->{GCCOUNT} = $GCCount_percent;
	                 $codon2Changes->{$counter}->{MISMATCHPERCENT} = $mismatchpercent;
	                 $codon2Changes->{$counter}->{PRE} = $pre;
	                 $codon2Changes->{$counter}->{MID} = $mid;
	                 $codon2Changes->{$counter}->{POST} = $post;
	                 $codon2Changes->{$counter}->{GCBEGIN} = $beginwith;
	                 $codon2Changes->{$counter}->{GCEND} = $endwith;
	                 $codon2Changes->{$counter}->{REV} = $rev;
				}
				else{
			 	  print "Ignored due to temp $temp which is less than $TEMP\n";
				}


			 }
		 }
		 $l++;
		 $r--;
	}
	print "===============\n";
}
}

foreach my $counter (sort  { $a <=> $b } keys %{$codon2Changes}){

	print $ofh "$codon2Changes->{$counter}->{WIDTH},  $codon2Changes->{$counter}->{CODON} , $codon2Changes->{$counter}->{SCORE} , $codon2Changes->{$counter}->{TEMP} , $codon2Changes->{$counter}->{GCCOUNT} , $codon2Changes->{$counter}->{MISMATCHPERCENT} , $codon2Changes->{$counter}->{PRE} ,  $codon2Changes->{$counter}->{MID},  $codon2Changes->{$counter}->{POST} , $codon2Changes->{$counter}->{GCBEGIN} , $codon2Changes->{$counter}->{GCEND},  $codon2Changes->{$counter}->{REV}  \n";

}




sub IsAA{
	my ($line) = @_ ; 
	my @l = split "" , $line;
	my $nucleotide = 1 ;
	foreach my $s (@l){
	    if($s !~ /(A|T|G|C|U)/){
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

	return ($complete,$pre,$CC,$post) ; 
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
 
sub GetTemp{
	my ($GCCount_percent,$mismatchpercent,$width) = @_ ; 
	#print " ($GCCount_percent,$mismatchpercent,$width) \n";
    my $temp = 81.5 + 0.41 * $GCCount_percent - 675/$width - $mismatchpercent;
	return $temp ;
}

sub GetGCCountPercent{
	my ($line,$len) = @_ ; 
	my $gcount = CountNucleotide("g",$line);
	my $ccount = CountNucleotide("c",$line);
	my ($ret) = (($gcount + $ccount)*100)/$len ;
	# print "gcount = $gcount ccount = $ccount len = $len ret - $ret \n";
	return $ret ;
}


sub GetHowManyToBeginWith{
	my ($line) = @_ ; 
	print $line , "\n";
	my ($gc) = ($line =~ /^((g|c)*)/g);
	return 0 if(!defined $gc);
	return length($gc) ;
}
