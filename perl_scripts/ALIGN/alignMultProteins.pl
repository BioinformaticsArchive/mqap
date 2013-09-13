#!/usr/bin/perl -w 
use strict ;
use PDB;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use ConfigPDB;
use MyGeom;
use MyPymol;
use Math::Geometry ;
use Math::VectorReal qw(:all);  # Include O X Y Z axis constant vectors




my $ADDONLYREACTIVE = 0 ; 
my $MATCHREVERSE = 0 ;
my $POTENTIALMATCH = 0 ;
my $DISTANCEMATCH = 1  ;

use Time::HiRes qw( usleep ualarm gettimeofday tv_interval clock_gettime clock_getres  clock);
use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($ann,$config,$p1,$p2,$infile,$outfile,$readpotential,$which_tech,$listfile,$protein);
my $DISTANCEWITHOUTSEQMATCH = 1 ;
my $verbose = 1 ;

my ($verify,$radii,$before1,$before2);
$readpotential = 1 ;
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "protein=s"=>\$protein ,
            "verify"=>\$verify ,
            "p1=s"=>\$p1 ,
            "p2=s"=>\$p2 ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "ann=s"=>\$ann ,
            "config=s"=>\$config,
            "radii=i"=>\$radii ,
            "readpotential=i"=>\$readpotential ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
usage( "Need to give a config file name => option -config ") if(!defined $config);
usage( "Need to give a radii file name => option -radii ") if(!defined $radii);

my $annMap = util_maketablefromfile($ann);


my $ofh = util_write($outfile);
my $ofhclose = util_write("log.close");
my $CNT = 0 ; 
my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC) = util_SetEnvVars();
my $PWD = cwd;

ConfigPDB_Init($config,$ofh);

my ($resultlines,@proteins) = ParseInputFile($infile);

my @info = util_ReadPdbs($PDBDIR,$APBSDIR,$readpotential,@proteins);
my @pdbs ;
my $mapPDBname2Obj = {};
foreach my $i (@info){
	push @pdbs, $i->{PDBOBJ};
	$mapPDBname2Obj->{$i->{PDBNAME}} = $i->{PDBOBJ} ;

}
my @atoms = pymolin_getResultsLineAllFromList($resultlines,\@pdbs);

die "Not ssame size" if(@pdbs ne @atoms);
my $N = @atoms - 1 ; 


### Align all proteins 
my @done;
foreach my $idx (0..$N){
	 my $PPP = $pdbs[$idx];
	 my $atoms1 = $atoms[$idx];
     my ($DD,$RR) = geom_Align3PointsToXYPlane($PPP,$atoms1,$verbose);
	 push @done, $DD ;
}


### turn off when doing penems
if(1){

print STDERR "================Variables=========================================\n";
print STDERR "ADDONLYREACTIVE MATCHREVERSE POTENTIALMATCH DISTANCEMATCH \n";
print STDERR "$ADDONLYREACTIVE $MATCHREVERSE $POTENTIALMATCH $DISTANCEMATCH \n";
print STDERR "====================================================================\n";
foreach my $idx1 (0..$N){
	my @matches ; 
	my @matchedProteins ; 
	my $protein1 = $proteins[$idx1];

    foreach my $idx2 (0..$N){
		 next if($idx1 eq $idx2);

         my $pdb1 = $pdbs[$idx1];
         my $pdb2 = $pdbs[$idx2];

		my $MATCH;
        my $MATCHF = Match2Indices($idx1,$idx2,\@proteins,\@pdbs,\@done,\@info);
		if($MATCHREVERSE){
           my $MATCHR = Match2Indices($idx2,$idx1,\@proteins,\@pdbs,\@done,\@info);
	       $MATCH = Add2Matches($MATCHF,$MATCHR,$pdb1,$pdb2);
		}
		else{
		   $MATCH = $MATCHF;
		}

		 my $protein2 = $proteins[$idx2];
		 push @matches,$MATCH;
		 push @matchedProteins,$protein2;


		 #my $fasta = "FASTA/$protein1.$protein1.ALL.fasta";
         #my $fastafh = util_write($fasta);
		 #util_WriteFastaFromResidueNumbers($pdb1,$listresnum1,$fastafh,$protein1);
		 #close($fastafh);

		 #$fasta = "FASTA/$protein2.$protein1.ALL.fasta";
         #$fastafh = util_write($fasta);
		 #util_WriteFastaFromResidueNumbers($pdb2,$listresnum2,$fastafh,$protein2);
		 #close($fastafh);
    }

	my $aln = "FASTA/$protein1.aln";
    my $alnfh = util_write($aln);
	util_WriteClustalAln($protein1,\@matches,\@matchedProteins,$alnfh,$mapPDBname2Obj,$annMap);
	
	## just do one for now
	last;
}
}


my @outfiles ; 
foreach my $i (@proteins){
   my $outfile1 = "$i.rotated.pdb";
   push @outfiles, $outfile1 ;
}

foreach my $idx (0..$N){
	my $pdb1 = $pdbs[$idx]; 
	my $outfile1 = $outfiles[$idx];
    $pdb1->WritePDB($outfile1,1);
}


my $outpymol = "XXX.p1m";
my $outpymolfh = util_write($outpymol);
util_PrintPymolWithAllProteins($outpymolfh,\@outfiles,\@atoms);

util_Banner("Wrote pymol file in $outpymol");


print STDERR "Output written in $outfile\n";

################################################### Functions ###############################################


chmod 0777, $outfile ;
sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}




sub Match2Proteins{
    my ($MATCH,$radius,$maxdist,$idx1,$idx2,$pdbs,$done,$allinfo,$potcongruence) = @_ ; 
    my $pdb1 = $pdbs->[$idx1];
    my $pdb2 = $pdbs->[$idx2];
    my $done1 = $done->[$idx1];
    my $done2 = $done->[$idx2];

	my @allinfo = @{$allinfo} ; 


	my ($results,$combined) = $pdb1->GetNeighbourHoodAtom($done1,$radius);
    my $neighatoms ; 	
    foreach my $j (@{$combined}){
		 my $resnum = $j->GetResNum(); 

	     ### ignore residues that are already matched in protein1 
		 next if(exists $MATCH->{$resnum});

	     my ($res) = $pdb1->GetResidueIdx($resnum);
	     my ($type) = $res->PrintSingleLetter($pdb1);
		 next if(!defined $type);
		 my $atomstr = $j->GetAtomStr();
		 next if($atomstr eq "HETATM");

		 my $nm = $res->GetName();
	     my @atoms = ConfigPDB_GetAtoms($nm);
         my ($atom) = $pdb1->GetAtomFromResidueAndType($resnum,$atoms[0]) ;
		 if(!defined $atom){
		 	 next ;
		 }
		 $neighatoms->{$resnum} = $atom ;
	} 

	### ignore residues that are already matched in protein2 
    my $doneResiduesinProt2 = ReverseTable($MATCH);
    my $done2Res = ReverseTable($MATCH);
    foreach my $i (keys %{$doneResiduesinProt2}){
	    $done2Res->{$i} = 1 ;
    }

	my @sortedClose = SortClose($neighatoms,$done1);


	my $info1 = $allinfo[$idx1];
	my $info2 = $allinfo[$idx2];
	my $pqr1 = $info1->{PQR} or die ;
	my $pqr2 = $info2->{PQR} or die ;
	my $pots1 = $info1->{POTS} or die ;
	my $pots2 = $info2->{POTS} or die ;
	my $firstatom1 = $done1->[0];
	my $firstatom2 = $done2->[0];
	my $potatom1  = util_GetPotForAtom($firstatom1,$pqr1,$pots1) ;
	my $potatom2  = util_GetPotForAtom($firstatom2,$pqr2,$pots2) ;


    my ($absscore,$normalizedSum) = $pdb1->ScoreGivenSetOfAtoms($pdb2,$done1,$done2);
    print $ofhclose " ORIGNAL RSMD  : $absscore,$normalizedSum \n";


    
	my $alreadyadded = {};
    print $ofhclose "Doing each neighboring atom\n\n\n";
	my @allresnum ; 
    foreach my $i  (@sortedClose){
		my $NNNNN = $i->GetName();
		my $RESNUMi = $i->GetResNum();
		push @allresnum, $RESNUMi ; 
    
	    my @tmp1 = (@{$done1}, $i);
		#$i->Print();
        my $poti = util_GetPotForAtom($i,$pqr1,$pots1) ;

	    print $ofhclose "neighboring Atom\n";
		print $ofhclose " NEIGH $NNNNN \n";
		PrintMatch($MATCH,$NNNNN,$ofhclose);

	    my @atomlist ;
	    push @atomlist, $i ;
	    my ($results,$combined) = $pdb2->GetNeighbourHoodAtom(\@atomlist,$maxdist);
	    print $ofhclose "Atoms close to this one at distance $maxdist\n";
	    my $sort ;
		my @goodatoms ; 
        foreach my $j (@{$combined}){
		    my $resnum = $j->GetResNum(); 
	        my ($res) = $pdb2->GetResidueIdx($resnum);
		    my $nm = $j->GetName();
		    my $type = $j->GetType();
		    my $atomstr = $j->GetAtomStr();
		    next if($atomstr eq "HETATM");
	        my $a = ConfigPDB_GetAtom($res->GetName());

			## only add atoms with right type
			if(!$ADDONLYREACTIVE || ($a eq $type)){
	            my $d = $i->Distance($j) ;
		        $sort->{$j} = $d ;
				push @goodatoms, $j ;
			}
			else{
			}
	    }

		## sort according to distance
	    my @sorted = sort { $sort->{$a} <=> $sort->{$b} } (@goodatoms);
    
    
	    my $sortrsmd ;
	    my $locallydone = {};
		my @processed ; 
	    foreach my $j (@sorted){
	        next if(exists $done2Res->{$j->GetResNum()});
	        next if(exists $locallydone->{$j->GetResNum()} && $verbose == 0);
			my $atomstr = $j->GetAtomStr();
			next if($atomstr eq "HETATM");

			push @processed, $j ;
    
		    my $resnum = $j->GetResNum(); 
			my $nmj = $j->GetName();
    
		    $locallydone->{$j->GetResNum()} = 1  ; 
	        my @tmp2 = (@{$done2}, $j);
		    print $ofhclose "Atom $nmj at  dist = $sort->{$j} \n";

            my ($absscore,$normalizedSum) = $pdb1->ScoreGivenSetOfAtoms($pdb2,\@tmp1,\@tmp2);
            print $ofhclose " RSMD  : $absscore,$normalizedSum \n";
			$sortrsmd->{$j} = $normalizedSum ;
    
	        print $ofhclose "=============\n\n\n";

	    }

	    my @sortedrsmd = sort { $sortrsmd->{$a} <=> $sortrsmd->{$b} } (@processed);
		my $added = 0 ;
	    foreach my $j (@sortedrsmd){

			my $atomstr = $j->GetAtomStr();
			next if($atomstr eq "HETATM");
	        
			my $RESNUMj = $j->GetResNum();

			my $MATCHCOPY = CopyMatchTable($MATCH);
		    $MATCHCOPY->{$RESNUMi} = $RESNUMj;
			next if(OrderDestroyed($MATCHCOPY));

			my $nmi = $i->GetName();
			my $nmj = $j->GetName();

            my $potj = util_GetPotForAtom($j,$pqr2,$pots2) ;
			my $diff1 = int($potatom1 - $poti );
			my $diff2 = int($potatom2 - $potj );
			my $diff = $diff1 - $diff2 ;
			my $RSMD = $sortrsmd->{$j};
			my $DIST = $sort->{$j};
	        my $DIstancefromfirst=  $firstatom1->Distance($i) ;
			if($potcongruence){
			      if(!$added && !exists $alreadyadded->{$RESNUMj} && abs($diff) < 150){
				              $MATCH->{$RESNUMi} = $RESNUMj;
				              $alreadyadded->{$RESNUMj} = 1 ;
				              $added = 1 ; 
			      }
			}
			else{
			      if(!$added && !exists $alreadyadded->{$RESNUMj}){
				        $MATCH->{$RESNUMi} = $RESNUMj;
				        $alreadyadded->{$RESNUMj} = 1 ;
				        $added = 1 ; 
			      }
			}
			print $ofhclose "Sorted XXX $nmi,$nmj : realdiff =$diff diffi=$diff1  diffj=$diff2  DIstancefromfirst= $DIstancefromfirst DISTfromatom=$DIST RSMD=$RSMD \n";
		}


	    print $ofhclose "=============\n\n\n";
   }

   ### this adds the gaps 
   foreach my $XXX (@allresnum){
			if(!exists $MATCH->{$XXX}){
			    $MATCH->{$XXX} = "-" ;
			}
    }

	return ($MATCH);
}







###################################################################3
### Match 2 proteins from the list in @pdbs of indices idx1 and idx2
###################################################################3
sub Match2Indices{
		 my ($idx1,$idx2,$proteins,$pdbs,$done,$info) = @_; 
	     my $protein1 = $proteins->[$idx1];
		 my $protein2 = $proteins->[$idx2];
         my $pdb1 = $pdbs->[$idx1];
         my $pdb2 = $pdbs->[$idx2];
         my $done1 = $done->[$idx1];
         my $done2 = $done->[$idx2];
		 print STDERR "Matching $protein1 $protein2 in Match2Indices\n";
		 print $ofhclose "Matching $protein1 $protein2 in Match2Indices\n";

		 ### potential match
	     my $ORIGMATCH = MakeMatch($done1,$done2);

		 if($POTENTIALMATCH){
		     my $r = 1 ; 
		     while($r <= $radii){
		            my $maxdist = 3 ; 
                    ($ORIGMATCH) = Match2Proteins($ORIGMATCH,$r,$maxdist,$idx1,$idx2,$pdbs,$done,$info,1);
			        $r = $r + 0.5 ;
		     }
		     PrintMatch($ORIGMATCH,"0",$ofhclose);
		 }

         #### this does the distance matching
		 if($DISTANCEMATCH){
		     my $r = 1 ; 
		     while($r <= $radii){
		         my $maxdist = 4 ; 
                 ($ORIGMATCH) = Match2Proteins($ORIGMATCH,$r,$maxdist,$idx1,$idx2,$pdbs,$done,$info,0);
			     $r = $r + 0.5 ;
		     }
		 }

		PrintMatch($ORIGMATCH,"1",$ofhclose);
		return $ORIGMATCH ;
}


sub Get3Letter{
	my ($pdb,$resnum) = @_ ; 
	my ($res) = $pdb->GetResidueIdx($resnum);
	my ($type) = $res->PrintSingleLetter($pdb);
	$type = "" if(!defined $type);
	return $type ;
}


sub OrderDestroyed{
	my ($M) = @_ ;
	my $last ;
	foreach my $i (sort {$a <=> $b} keys %{$M}){
		my $v = $M->{$i} ; 
		next if($v eq "-");
		if(!defined $last){
		    $last = $v ;
		}
		else{
			return 1 if($v < $last);
		    $last = $v ;
		}
     }	
	 return 0 ; 
}

sub ReverseTable{
	my ($M2) = @_;
	my $revM2 ; 
	foreach my $i (sort {$a <=> $b} keys %{$M2}){
		my $v2 = $M2->{$i} ; 
		next if($v2 eq "-");
		$revM2->{$v2} = $i ;
	}
	return $revM2;
}

sub Add2Matches{
	my ($M1,$M2,$pdb1,$pdb2) = @_ ; 

	## first reverse the reverse match
	## revbM2 cant have a "-"
	my $revM2 = ReverseTable($M2); ; 
	my $doneresidues = ReverseTable($M1); ; 

	## now in the forward match, add the match if it does not exist and does not destroy the ordering
	foreach my $i (sort {$a <=> $b} keys %{$revM2}){
		my $v = $revM2->{$i} ; 
		next if(exists $doneresidues->{$v});

		if(! exists $M1->{$i}){
		    $M1->{$i} = $v ;
		    if(OrderDestroyed($M1)){
			    delete $M1->{$i};
			}
		 }
		else{
			my $v1 = $M1->{$i} ; 
			## now the problem - merge 
		    if($v1 eq "-"){
		       $M1->{$i} = $v ;
		       if(OrderDestroyed($M1)){
			       delete $M1->{$i};
			   }
			}
			else{
				my $b3 = Get3Letter($pdb2,$v);
				my $orig = Get3Letter($pdb1,$i);
				if($b3 eq $orig){
		            $M1->{$i} = $v ;
			    }
		     }
		}
	}
	#PrintMatch($M1,"DDD",$ofhclose);
	#die ;
	return $M1; 
}
sub PrintMatch{
   my ($MATCH,$str,$OFH) = @_ ; 
   my @a ;
   my @b ;
   $, = " , ";
   print $OFH "==========Printing match $str===================\n";
   my $cnt = 0 ; 
   my $CNT = 0 ; 
   foreach my $i (sort {$a <=> $b} keys %{$MATCH}){
   	   my $j = $MATCH->{$i} ; 
	   $CNT++ ;
	   $cnt++ if($j ne "-");
	   push @a , $i ;
	   push @b , $j ;
	   print $OFH "$str $i = $j\n";
   }
   print $OFH "There were $cnt real matches out of $CNT \n";
   print $OFH "=============================\n";
}

sub MakeMatch{
	my ($l1,$l2) = @_ ; 
	my $match = {};
	my @l1 = @{$l1};
	my @l2 = @{$l2};
	my $cnt = 0 ;
	while($cnt < 3){
	    $cnt++;
		my $a = shift @l1 ;
		my $b = shift @l2 ;
		my $na = $a->GetResNum(); 
		my $nb = $b->GetResNum(); 
		$match->{$na} = $nb;
	}
	return $match ;

}

###########################################################################
### sort the atoms in $atoms such that the closer one to $refatoms come firs 
###########################################################################
sub SortClose{
	my ($atoms,$refatoms) = @_ ; 

	my $sss = {};
	foreach my $a (values %{$atoms}){
		my $min = 1000 ; 
		foreach my $r (@{$refatoms}){
	        my $d = $a->Distance($r) ;
			$min = $d if($d < $min);
		}
		$sss->{$min} = $a ;
	}
	my @ret ; 
	foreach my $i (sort {$a <=> $b} keys %{$sss}){
		push @ret, $sss->{$i} ;
	}
	return @ret ;
	
}


sub CopyMatchTable{
    my ($MATCH) = @_ ; 
	my $ret = {};
	foreach my $k (keys %{$MATCH}){
		 my $v = $MATCH->{$k};
		 $ret->{$k} = $v ;
	}
	return $ret ;
}

sub ParseInputFile{
	my ($fname) = @_ ; 
    my @resultlines ;
    my $ifh = util_read($fname);
    my @Proteins ; 
	my $Info = {};
    while(<$ifh>){
         next if(/^\s*$/);
         next if(/^\s*#/);
         chop ;
	     my (@l) = split ; 
	     my $query = shift @l ;
	     my $ref = shift @l ;
	     my $score = shift @l ;
	     my (@atoms) =  @l ;
	     next if(exists $Info->{$query});
		 $Info->{$query} = 1 ; 
    
	     push @resultlines, \@atoms ;
         push @Proteins, $query;
    }
	return (\@resultlines,@Proteins);
}
