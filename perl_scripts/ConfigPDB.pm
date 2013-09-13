package ConfigPDB;
use MyUtils;
use Atom;
use Residue;
use MyGeom ;
require Exporter;
@ISA = qw(Exporter );
@EXPORT = qw(
            ConfigPDB_Groups 
            ConfigPDB_GetAtoms 
            ConfigPDB_GetAtom
			ConfigPDB_Init 
			ConfigPDB_Verify 
			ConfigPDB_IsValidAminoAcid
			Config_ReadAnnfile
			Config_ReadAnnfileClose
			ConfigPDB_ParseResultsFile
			ConfigPDB_ParseCavityFileFPocket
			ConfigPDB_GetCavities_FPocket
			ConfigPDB_ParseCavityFileCASTP
			ConfigPDB_GetGrpNameForRes
			ConfigPDB_ScoreSingleResultForCavity
			ConfigPDB_PrintOutConf
			ConfigPDB_IsValidAA
			ConfigPDB_GetOnlyGrpNameForRes
			ConfigPDB_AminoAcidCodes);

use strict ;
use Carp ;
use FileHandle ;
use Getopt::Long;
use vars qw($AUTOLOAD);
use Getopt::Long;
use File::Basename;

my $verbose = 0 ;
my @l = qw(
			   alanine ala A 
	           arginine arg R 
			   asparagine asn N 
			   aspartic asp D 
			   asparagine asx B 
			   cysteine cys C 
			   glutamic glu E 
			   glutamine gln Q 
			   glutamine glx Z 
			   glycine gly G 
			   histidine his H 
			   isoleucine ile I 
			   leucine leu L 
			   lysinex kcx O 
			   lysine lys K 
			   methionine met M 
			   phenylalanine phe F 
			   proline pro P 
			   serine ser S 
			   threonine thr T 
			   tryptophan trp W 
			   tyrosine tyr Y 
			   valine val V
			   ) ; 
my $l ; 

sub ConfigPDB_IsValidAminoAcid{
	my ($nm) = @_ ; 
	$nm = uc($nm);
	if(!defined $l){
		$l = {};
		my @tmp = @l ;
		while(@tmp){
			my $a = shift @tmp ;
			my $b = shift @tmp ;
			my $c = shift @tmp ;
		    $b = uc($b);
		    $l->{$b} = 1 ; 
		}
	}
	if(exists $l->{$nm}){
		return 1 ; 
	}
	else{
		return 0 ; 
	}

}

sub ConfigPDB_AminoAcidCodes{

	return @l ;
}


my $initialized ;
my $GROUPS = {} ;
my $ATOMCONFIG = {} ;
my $ATOMCONFIGS = {} ;
my $RES2GROUP = {} ; ##might be multiple - we just choose the last 

sub ConfigPDB_Init{
    $initialized = 1 ;
	my ($infile,$ofh) = @_; 
    my $ifh = util_read($infile);
	my $done ; 
    while(<$ifh>){
         next if(/^\s*$/);
         next if(/^#/);
         chomp ;
		 if(/^GROUP/){
             my @l = split ; 
		     my $junk = shift @l ; 
		     my $grpname = shift @l ; 
		     my $table = {};
		     my $cnt = @l ;
		     while(@l){
		         my $res = shift @l ; 
				 $RES2GROUP->{$res} = $grpname ; 
		         my $atom = ConfigPDB_GetAtom($res);
			     $table->{$res} = $atom ; 
			     #print "$res = $atom \n";
		     }
		     $table->{SIZE} = $cnt ; 
		     $GROUPS->{$grpname} = $table ; 
			 #print "$cnt = $grpname \n";
		 }
		 if(/^ATOMCONFIG/){
		     my ($junk,$res,$atom) = split ;
		     $ATOMCONFIGS->{$res} = [] if(!defined $ATOMCONFIGS->{$res});
			 if(! exists $done->{$res.$atom}){
			 	$done->{$res.$atom} = 1 ; 
			    push @{$ATOMCONFIGS->{$res}}, $atom;
			 }
			 $ATOMCONFIG->{$res} =  $atom;
		 }
	}

	if(defined $ofh){
		my $cnt = 1 ;
		print $ofh "### ATOMTYPES \n";
		foreach my $k (%{$ATOMCONFIGS}){
			my $l = $ATOMCONFIGS->{$k};
			foreach my $atom (@{$l}){
				print $ofh "Type $k$atom $cnt\n"; 
				$cnt++;
			}
		}
		print $ofh "### ATOMTYPES END \n\n\n";
	}



}


sub ConfigPDB_Groups{
	my ($nm) = @_; 
	die "need to initialize" if(! $initialized);
	die "group $nm doesnt exist" if(! exists $GROUPS->{$nm}) ; 
	return $GROUPS->{$nm} ; 

}

sub ConfigPDB_Verify{
	my (@l) = @_; 
	die "need to initialize" if(! $initialized);
	foreach my $nm (@l){
	   die "group $nm doesnt exist" if(! exists $GROUPS->{$nm}) ; 
	}

}

sub ConfigPDB_IsValidAA{
	my ($nm) = @_; 
	die "need to initialize" if(! $initialized);
	if(! exists $ATOMCONFIG->{$nm}){
		return 0 ;
	}
	else{
		return 1 ;
	}
}

sub ConfigPDB_GetAtom{
	my ($nm) = @_; 
	die "need to initialize" if(! $initialized);
	carp "group $nm doesnt exist" if(! exists $ATOMCONFIG->{$nm}) ; 
	return $ATOMCONFIG->{$nm};
}
sub ConfigPDB_GetAtoms{
	my ($nm) = @_; 
	die "need to initialize" if(! $initialized);
	if(! exists $ATOMCONFIGS->{$nm}){
	    carp "group $nm doesnt exist"  ;
		return undef ;
	}
	return @{$ATOMCONFIGS->{$nm}};
}



# this divides the score with the number of residues
sub ConfigPDB_ParseResultsFile{
	my ($infile,$num) = @_; 
	croak if(! -e $infile);
    my $ifh = util_read($infile);

	my @results ; 
	my $cnt = 0 ; 
    while(<$ifh>){
         next if(/^\s*$/);
	     if(/#RESULT/){
		 	my $result = {};
		 	my @l = split ; 
			my $len = @l ;
			my $absscore = $l[$len -3];
			my $score = $l[$len -1];

			$score = 0  if(util_IsZero($score));
			$score = util_format_float($score);

			$result->{ABSSCORE} = $absscore ; 
			$result->{SCORE} = $score ; 
			$result->{CNT} = $cnt ; 

			push @results,$result ;

			my $nextline = <$ifh>;
			$nextline =~ s/#//;
			$nextline =~ s/-//g;
			my @atoms = split " ",$nextline ; 

			my $natoms = @atoms ;
			#$result->{SCORE} = $score/$natoms ; 

			$result->{ATOMS} = \@atoms ;

		    $cnt++;
		 }
		 last if(defined $num && $cnt == $num) ;
   }
   close($ifh);
   return @results ; 
}

sub ConfigPDB_GetGrpNameForRes{
	my ($nm) = @_; 
	warn "group $nm doesnt exist" if(! exists $RES2GROUP->{$nm}) ; 
	return $RES2GROUP->{$nm} ; 
}

sub ConfigPDB_GetOnlyGrpNameForRes{
	my ($nm) = @_; 
	return $nm . "ONLY";
}


sub ConfigPDB_ParseCavityFileFPocket{
	my ($cavityfiles) = @_; 
    my $cavities = {};
	my $cavityNum = 1 ;
foreach my $cavityfile (@{$cavityfiles}){
    print STDERR "Info: parsing file $cavityfile \n";
    my $ifh = util_read($cavityfile);
    while(<$ifh>){
	    if(/^ATOM/){
   		   chomp ;
		   my $LINE = $_ ; 
		   my $len = length($LINE) ;
		   my $chainId = util_mysubstr($len,$LINE,22,1);
		   next if($chainId ne "A");
           my $resnum = util_mysubstr($len,$LINE,23 , 26);

			#print " cavityNum = $cavityNum \n";
			$cavities->{$cavityNum} = {} if(!defined  $cavities->{$cavityNum} );
			$cavities->{$cavityNum}->{$resnum} = 1 ; 
			$cavityNum++;
			#print "$resnum \n";
		}
   }
   close($ifh);
}
   return $cavities ;
}
sub ConfigPDB_ParseCavityFileCASTP{
	my ($cavityfile) = @_; 
    print STDERR "Info: parsing file $cavityfile \n";
    my $cavities = {};
    my $ifh = util_read($cavityfile);
    while(<$ifh>){
            next if(/^\s*$/);
	        my @l = split ; 
			my $len = @l ; 
			my $flag = 1 ; 
			my $aa ;
			my $cnt = 0; 
			while($flag && $cnt < $len){
				my ($junk,$l) = ( $l[$cnt] =~ /(.*)(...)/) ;
				if(ConfigPDB_IsValidAminoAcid($l)){
					$flag = 0 ;
					$aa = $l;
				}
				$cnt++;
			}

			die "did not see amino acid" if($flag);
			#print "Saw amino acid $aa \n";
			my $resnum ; 
			if(util_is_integer($l[$cnt])){
                 $resnum = $l[$cnt ] ;
			}
			else{
				if(!util_is_integer($l[$cnt+1])){
				   my $j ;
				   ($j,$resnum) = ($l[$cnt] =~ /([A-Z]+)(\d+)/);
				   if(!util_is_integer($resnum)){
					   warn "still not an integer $resnum";
					   print  ;
					   next ;
				   }
				   #next if($j ne "A");
				   my $t = $l[$cnt+1] ; 
				   warn "$resnum =num $t is not an integer - expecting one";
				   warn "full line $_ ";
				}
				#next if($j ne "A");
                 $resnum = $l[$cnt + 1 ] ;
			}
			my $cavityNum = $l[$len -2]; 
			#print " cavityNum = $cavityNum \n";
			$cavities->{$cavityNum} = {} if(!defined  $cavities->{$cavityNum} );
			$cavities->{$cavityNum}->{$resnum} = 1 ; 
			#print "$resnum \n";
   }
   return $cavities ;
}

sub ConfigPDB_ScoreSingleResultForCavity{
	my ($result,$cavities,$ofh,$finalscore) = @_ ; 

    my @factors = qw ( 1 1 2 4 8 32 64 128 256 );

	my $origscore = $result->{SCORE} ;

	if(!defined $cavities){
	    return ($origscore,0,0,0);
	}

	my $bestscore = 10000 ;

	my $maxdoesexist = 0 ; 
	my $mindoesntexist = 10000 ; 
	my $bestCavityNum = -1 ;

	my $globalexists = {} ;
	foreach my $cavityNum (sort {$a <=> $b}  keys %{$cavities}){


		my $allexists  = 1 ;
		my $doesexist  = 0 ;
		my $doesnotexist  = 0 ;
	    foreach my $k (keys %{$result}){
			next if($k eq "SCORE");
			next if($k eq "CNT");

			my @atoms = @{$result->{$k}};
		    foreach my $atom (@atoms){
			    my ($res,$num,$atom) = split "/", $atom ;
    
			    if( exists $cavities->{$cavityNum}->{$num}){
					 $globalexists->{$num} = 1 ; 
		            $doesexist++;
			    }
				elsif( exists $globalexists->{$num}){
		            $doesexist++;
				}
			    else{
				    $allexists = 0 ; 
		            $doesnotexist++;
			    }
		    }
		}

		if($allexists){
			$result->{VOLUME} =  0 ;
			print " Result number $result->{CNT} matches completely with score $result->{SCORE} and cavity number $cavityNum \n" if($verbose);
			$bestscore = $origscore ; 

	        $maxdoesexist = $doesexist ; 
	        $mindoesntexist = 0 ; 
			$bestCavityNum = $cavityNum ;

		    last ;
		}
		else{
			
			 my $factor = $factors[$doesnotexist];
			 my $tmpscore = $result->{SCORE} * $factor ; 
			 $bestscore = $tmpscore if($tmpscore < $bestscore);
			print  " Result number $result->{CNT} partially matches : exists = $doesexist , doesnt exist = $doesnotexist with score $result->{SCORE} and cavity number $cavityNum \n" if($verbose);
			if($maxdoesexist < $doesexist){
	            $maxdoesexist = $doesexist ; 
	            $mindoesntexist = $doesnotexist ; 
				$bestCavityNum = $cavityNum ;
			}
		}

	}

	print "orig = $origscore best = $bestscore\n";
	$finalscore = $bestscore if($bestscore < $finalscore);
	return ($finalscore,$bestCavityNum,$maxdoesexist,$mindoesntexist) ;

}


sub ConfigPDB_GetCavities_FPocket{
	 my ($protein) = @_ ;
	 my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC) = util_SetEnvVars();
     my $pocketdir = "$FPOCKET/$protein". "_out/pockets/";
     my @cavityfiles = <$pocketdir/pocket*pdb>;
     my $cavities =  ConfigPDB_ParseCavityFileFPocket(\@cavityfiles);
#
     my @nn =  (keys %{$cavities});
     die "Something wrong - no cavities found" if(!@nn);
	 return $cavities ;
}

sub ConfigPDB_PrintOutConf{
        my ($outfile,$protein,$length,$chain,$specific) = @_ ;
		my @chain = @{$chain};
		my $groupdir = {};
		if(-e "grd"){
             my $ifh = util_read("grd");
             while(<$ifh>){
                  next if(/^\s*$/);
                  chop ;
	              my ($nm,$grpname) = split ; 
				  $nm = uc($nm);
				  $groupdir->{$nm} = $grpname ;
			 }
		}
        #my $outconf = "$protein.$length.$specific.outconf.annotated";
        my $outconffh = util_write($outfile);
		my @groups ; 
	    print $outconffh "POINTS ";
		my $cnt = 0 ;
		while(@chain){
			last if($cnt == 10);
			$cnt++;
			my $a = shift @chain ;
			my $b = shift @chain ;

			my $fullname = "$a$b";
			$fullname = uc($fullname);
			if(exists $groupdir->{$fullname}){
				print STDERR "---------------------\n";
				print STDERR "Warning: using grd file \n";
				print STDERR "---------------------\n";
			    push @groups,  $groupdir->{$fullname} ;
			}
			elsif($specific == 1){
			    push @groups,  ConfigPDB_GetOnlyGrpNameForRes($a);
			}
			else{
			    push @groups,  ConfigPDB_GetGrpNameForRes($a);
			}
			print $outconffh "\t\t $b/$a ";
		}
	    print $outconffh "\n";
		$, = "  " ; 
	    print $outconffh "GROUPS " , @groups , "\n";
		close($outconffh);
		print "Wrote to outfile $outfile\n";
}



### this read the ANNOTATE file
### if closeatoms are give it writes a file "dist", the close residues, and also the fasta
sub Config_ReadAnnfile{

 			my ($nm,$ANNDIR,$closeatoms,$pdb)  = @_ ;
			my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC) = util_SetEnvVars();

			my $annfile = "$ANNDIR/$nm.outconf.annotated";
			my $annfiledist = "$ANNDIR/dist";
			my $annclose = "$ANNDIR/$nm.outconf.annotated.close";
			my $annfasta = "$ANNDIR/$nm.ALL.$closeatoms.fasta";

			my $ofh ;
			my $fhfasta ;
			if($closeatoms){
			    $ofh = util_write($annclose) ;
			    $fhfasta = util_write($annfasta) ;
			    my $ofhdist = util_write($annfiledist) ;
				print STDERR "wrote to file $annfiledist , $annfasta and $annclose\n";

				print $ofhdist "$closeatoms\n";
			}
			my $residues = "";
		    my $nresidues = 0 ; 
			my $tableResidues = {};
            my $closeAtoms ;
			my $pdb1 = "$PDBDIR/$nm.pdb";
			if($closeatoms){
			   $pdb->SetLogFile($ofh);
			   $pdb->ReadPDB($pdb1);
			}

			if( -e $annfile){
				my @ss = `head -1 $annfile` ;
				#print @ss ; 
				$residues = $ss[0] ;
				die "Could not read $annfile" if(!defined $residues);
				$residues =~ s/POINTS//;
				$residues =~ s/\s\s*/ /;

				$residues =~ s/\t*/ /;
				my @ll = split " ",$residues ;
				my @list = ();
				foreach my $a (@ll){
					my ($n,$r) = split "/",$a;
					$tableResidues->{"$r.$n"} = 1 ; 
					if($closeatoms){
					    print $ofh  "$r.$n\n";
					    my $type = ConfigPDB_GetAtom($r);
					    my ($a) = $pdb->GetAtomFromResidueAndType($n,$type) or die ;
					    push @list, $a ; 
					}

				}

				if($closeatoms){
				     my $dist = $closeatoms;
                     my ($j1,$neigh,$j2) = $pdb->GetNeighbourHoodAtom(\@list,$dist);
                     foreach my $a (@{$neigh}){
                         my $num = $a->GetResNum();
                         my $res = $a->GetResName();
					     if(!defined $closeAtoms->{"$res.$num"}){
                            $closeAtoms->{"$res.$num"} = 1 ;
					        print $ofh "$res.$num \n";
					     }
                     }
                     print $fhfasta "\>AMPC_ENTCL RecName: Full=Beta-lactamase;\n";
                     foreach my $a (keys %{$closeAtoms}){
	                     my ($aa) = ($a =~ (/(...)/));
	                     my $aaa = $pdb->GetSingleLetter($aa);
	                     next if($aaa eq "?");
	                     print $fhfasta "$aaa";
                     }
                     print $fhfasta "\n";
				}

			    $nresidues = @ll ;
			}
			return ($tableResidues,$nresidues,$closeAtoms);
}

sub Config_ReadAnnfileClose{
   my ($nm,$ANNDIR)  = @_ ;
   my $list = {};
   my $dist ;
   if(! defined $nm){
       return ($list,$dist) ;
   }
   my $annclose = "$ANNDIR/$nm.outconf.annotated.close";
   my $annfiledist = "$ANNDIR/dist";
   if(-e $annclose){
       my @list= util_read_list_sentences($annclose);
       map { s/\s*//g ; $list->{$_} = 1 ; } @list ;
   }

   my @dist= util_read_list_sentences($annfiledist);
   $dist = $dist[0];
   return ($list,$dist) ;
}
