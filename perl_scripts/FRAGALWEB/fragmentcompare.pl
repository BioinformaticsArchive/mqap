#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use ConfigPDB;
use MyGeom;
use PDB;
use Primer;
use BP;
use Bio::Tools::CodonTable;
use Carp ;
 my $myCodonTable   = Bio::Tools::CodonTable->new();
 

use Time::HiRes qw( usleep ualarm gettimeofday tv_interval clock_gettime clock_getres  clock);
use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($onlyanno,$processout,$FFF,$RRR,$forward,$reverse,$infile,$outfile,$which_tech,$listfile,$protein,$junk);
my (@expressions,@indices,$in1,$in2,@towhichresidue,@junk,$arg);
my $howmany = 100000 ;
my $verbose = 1 ;
my $incr = 10 ; 
my $SIZE = 50 ; 
my $DOIDEN ;
my $incrsteps = $SIZE/$incr ;
my $THRESH ;
GetOptions(
            "which_tech=s"=>\$which_tech ,
			"onlyanno=i"=>\$onlyanno ,
            "towhichresidue=s"=>\@towhichresidue ,
            #"idx=i"=>\$idx ,
            "protein=s"=>\$protein ,
            "in1=s"=>\$in1 ,
            "in2=s"=>\$in2 ,
            "arg=s"=>\$arg ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "indices=i"=>\@indices,
            "howmany=i"=>\$howmany ,
            "thresh=i"=>\$THRESH ,
            "size=i"=>\$SIZE ,
            "doiden=i"=>\$DOIDEN ,
            "forward=s"=>\$forward ,
            "reverse=s"=>\$reverse ,
            "processout"=>\$processout ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
util_CmdLine("size",$SIZE);
util_CmdLine("outfile",$outfile);
util_CmdLine("arg",$arg);

my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC) = util_SetEnvVars();

if(defined $processout){
    util_CmdLine("thresh",$THRESH);
    util_CmdLine("onlyanno",$onlyanno);
    util_CmdLine("doiden",$DOIDEN);
}


print STDERR "Writing needle script to $outfile\n";
my $ofh = util_write($outfile);
my ($infoA,$cntA,$annoinfoA) = ProcessSingleSeq($in1,"A",$SIZE,"A.ann");
my ($infoB,$cntB,$annoinfoB) = ProcessSingleSeq($in2,"B",$SIZE,"B.ann");

die if(! -e "$FASTADIR/A1.ALL.fasta");

print STDERR "KKKKKKKKKKKK\n";
foreach my $idxA (1..$cntA){
	my $r1 = $infoA->{$idxA}->{JUSTNAME};
    foreach my $idxB (1..$cntB){
	   my $r2 = $infoB->{$idxB}->{JUSTNAME};
	   my $nm = "$r1.$r2.out";
       print $ofh "checkIdentity.csh $r1 $r2  $nm $arg\n" if(!defined $processout && ! -e $nm);
	}
}
print $ofh "touch done\n" if(!defined $processout);


my @MATCHES;
if(defined $processout){
    my $SSS = "thresh$THRESH.size$SIZE.doiden$DOIDEN.onlyanno$onlyanno";
    foreach my $idxA (1..$cntA){
		my $r1 = $infoA->{$idxA}->{JUSTNAME};
        foreach my $idxB (1..$cntB){
		    my $r2 = $infoB->{$idxB}->{JUSTNAME};
		    my $nm = "$r1.$r2.out";
			print "running needle on $nm\n";
           my ($iden,$simi) = BP_Needle_parseout($nm);
		   print "$nm $iden $simi ....................\n";
	    }
    }

	## to ensure not reading needle file twice 
    my $CACHE ;
    StartMatch($infoA,$infoB,$cntA,$cntB,$CACHE,$annoinfoA,$annoinfoB);
    my @resultssorted = sort { $b->{TOTAL} <=> $a->{TOTAL} } @MATCHES;
    my @resultssortedAV = sort { $b->{AVERAGE} <=> $a->{AVERAGE} } @MATCHES;
    my $ofhcumu = util_write("cumu.results.$SSS");
	my $counter = 0 ; 
	my $matchingstr = "";
    foreach my $SAVEDMATCH (@resultssorted){
		$counter++;
        my $seq = $SAVEDMATCH->{SEQ} ;
		next if($matchingstr =~ /$seq/);
		$matchingstr = $matchingstr . $seq ; 
	    my $total = $SAVEDMATCH->{TOTAL} ;
	    my $average = util_format_float($SAVEDMATCH->{AVERAGE},1) ;
	    my $annofound = $SAVEDMATCH->{ANNOFOUND} ;
		if(!$onlyanno || $annofound){
	         print $ofh "$total $average $seq \n";
	         print $ofhcumu "$counter $total $seq \n";
		}
    }
	print $ofh "=================\n";
    my $ofhaver = util_write("aver.results.$SSS");
	$counter = 0 ; 
    foreach my $SAVEDMATCH (@resultssortedAV){
		$counter++;
        my $seq = $SAVEDMATCH->{SEQ} ;
	    my $total = $SAVEDMATCH->{TOTAL} ;
	    my $average = util_format_float($SAVEDMATCH->{AVERAGE},1) ;
	    my $annofound = $SAVEDMATCH->{ANNOFOUND} ;
		if(!$onlyanno || $annofound){
	         print $ofh "$total $average $seq \n";
	         print $ofhaver "$counter $average $seq \n";
		}
    }

}

sub StartMatch{
	my ($iA,$iB,$maxA,$maxB,$cache,$AnnoinfoA,$AnnoinfoB) = @_ ; 
	my $ifoneseen = 0 ;
	foreach my $i (1..$maxA){
        my $matches ; 
		print "Doing A $i\n";
		if($ifoneseen){
			$ifoneseen--;
			next ;
		}
	    foreach my $j (1..$maxB){
	          my ($iden,$simi) =  GetValues($iA,$iB,$i,$j,$cache) ;
			  if($simi > $THRESH){
			  	  $matches->{$i} = {};
			  	  $matches->{$i}->{OTHER} = $j ; 
			  	  $matches->{$i}->{IDEN} = $iden ; 
			  	  $matches->{$i}->{SIMI} = $simi ; 
		          print "\tDoing B since simi $simi > $THRESH $j\n";
	              ScoreFromOnePoint($iA,$iB,$i,$j,$maxA,$maxB,$matches,$cache,1,$AnnoinfoA,$AnnoinfoB);
				  $ifoneseen = 1 ; 
			  }
		}
		ProcessMatches($matches,$AnnoinfoA,$AnnoinfoB);
	}
}


sub ScoreFromOnePoint{
	my ($iA,$iB,$startA,$startB,$maxA,$maxB,$matches,$cache,$lastwasmatched,$AnnoinfoA,$AnnoinfoB) = @_ ; 
	print "\tDoing ScoreFromOnePoint for startA = $startA,startB = $startB \n";
	my $nextA = $lastwasmatched? $startA + $incrsteps : $startA + 1  ; 
	my $nextB = $lastwasmatched? $startB + $incrsteps : $startB + 1  ; 
	if($nextA > $maxA || $nextB > $maxB){
		ProcessMatches($matches,$AnnoinfoA,$AnnoinfoB);
		print "\t Exceeded length. returning\n";
		return 1 ;
	}
	my $i = $nextA ;
	my $j = $nextB ;
	my ($iden,$simi) =  GetValues($iA,$iB,$i,$j,$cache) ;
	if($simi > $THRESH){
			$matches->{$i} = {};
			$matches->{$i}->{OTHER} = $j ; 
			$matches->{$i}->{IDEN} = $iden ; 
			$matches->{$i}->{SIMI} = $simi ; 
	        return ScoreFromOnePoint($iA,$iB,$i,$j,$maxA,$maxB,$matches,$cache,1,$AnnoinfoA,$AnnoinfoB);
	}
	print "\tFELL Thru\n";
	return ScoreFromOnePoint($iA,$iB,$nextA,$nextB,$maxA,$maxB,$matches,$cache,0,$AnnoinfoA,$AnnoinfoB);
	#ProcessMatches($matches);
	#return 0 ;
}

sub ProcessMatches{
    my ($matches,$AnnoinfoA,$AnnoinfoB) =@_ ; 

	my $total = 0  ; 
	my $sequence = "";
	print "ProcessMatchea============================\n" ;
	my $N = 0 ; 
	my $annofound = 0 ; 
	foreach my $i ( sort  { $a <=> $b } keys %{$matches}){
		$N++ ;
		my $j = $matches->{$i}->{OTHER} ;
		my $simi = $matches->{$i}->{SIMI} ;
		my $iden = $matches->{$i}->{IDEN} ;
		$sequence = $sequence . "A$i-B$j," ;
		$total = $total + $simi ; 
		if($DOIDEN){
		    # $total = $total + $iden ; 
		    my $onlysimi = $simi - $iden ;
		    my $addto = 0.333 * $onlysimi + 0.666 * $iden ; 
		    $total = $total + $addto ;
		}
		$annofound = 1 if(exists $AnnoinfoB->{$j} && ! exists $AnnoinfoA->{$i});
		print "\tFound $i $j $simi \n";
		delete $matches->{$i};
	}
	print "ProcessMatchea============================\n";
	return if(!$N);
	my $SAVEDMATCH = {};
	my $average = $total / $N  ; 
	$SAVEDMATCH->{SEQ} =  $sequence;
	$SAVEDMATCH->{TOTAL} =  $total;
	$SAVEDMATCH->{AVERAGE} = $average;
	$SAVEDMATCH->{ANNOFOUND} = $annofound;
	push @MATCHES, $SAVEDMATCH ;
}

sub GetValues{
	my ($iA,$iB,$startA,$startB,$cache) = @_ ; 
	die if(!defined $iA->{$startA});
	carp "Not defined startb $startB" if(!defined $iB->{$startB});
	my $nm = $startA ."-". $startB;
	if(defined $cache->{$nm}){
	    my $iden = $cache->{$nm}->{IDEN} ;
	    my $simi = $cache->{$nm}->{SIMI} ;
        return ($iden,$simi);
	}
	my $r1 = $iA->{$startA}->{JUSTNAME};
	my $r2 = $iB->{$startB}->{JUSTNAME};
	my $nm = "$r1.$r2.out";
    my ($iden,$simi) = BP_Needle_parseout($nm);
	$cache->{$nm}->{IDEN} = $iden ;
	$cache->{$nm}->{SIMI} = $simi ;
	#print "GetValues $startA,$startB $iden,$simi \n";
    return ($iden,$simi);
}


sub ProcessSingleSeq{
	  my ($infile,$tag,$size,$annofile) = @_ ; 
      my ($line,$len,@l) = ReadSeq($infile,1,0);
      my $FH = util_write("$tag.sequences");
	  print STDERR "Writing sequence and id info to $tag.sequences\n";
      
      print "$len = Length\n";

      my $Annoinfo ;
	  if(defined $onlyanno && defined $annofile){
	  	  $Annoinfo =  util_ReadAnnotateFile($annofile);
	  }
      
      my $do = 1 ; 
      my $start = 0 ; 
      my $cnt = 0 ; 
	  my @ret ;
	  my $info ={};
	  my $annotatedinfo ={};
      while($do){
	       my $x = abs($start - $len) ;
		   ## process last one
	       if($x < $size){
	           $size = $x  ;
		       $do = 0 ; 
	       }
		   else{
	            $cnt++ ; 
                my $s =  substr($line,$start,$size);
	            print $FH "$cnt -> $s \n";

				if(defined $onlyanno && defined $annofile){
					my $end = $start + $size ; 
					foreach my $x (keys %{$Annoinfo}){
						if($x > $start && $x < $end){
						   my $commentsinfile = $Annoinfo->{$x}  ;
						   $annotatedinfo->{$cnt} = $commentsinfile ;
						}
					}
					
				}
                
	            $start = $start + $incr ;
	            
		        my $nm = "$tag"."$cnt";
		        my $filenm = "$nm.ALL.fasta";
                my $fastafh = util_write($filenm);
	            print $fastafh "\>$nm;\n";
	            print $fastafh "$s\n";
	            push @ret , $nm ;
		        $info->{$cnt} = {};
		        $info->{$cnt}->{JUSTNAME} = $nm; ## need for fasta prog which works off the PDB name
		        $info->{$cnt}->{FASTANAME} = $filenm;
		        $info->{$cnt}->{STR} = $s;
		   }
      }
      
      print $FH "orig = $line \n";
	  close($FH);
	  return ($info,$cnt,$annotatedinfo);
}
