
package PDB;
use MyUtils;
use PDB;
use ConfigPDB;
use Atom;
use Residue;
use MyGeom ;
use Algorithm::Combinatorics qw(combinations) ;
use Math::Geometry ; 
#use Math::Trig;
#use Math::Trig ':radial';
require Exporter;
@ISA = qw(Exporter );
@EXPORT = qw($fields);
use Math::VectorReal qw(:all);  # Include O X Y Z axis constant vectors

my $CHARGE = 1 ;

use strict ;
use Carp ;
use FileHandle ;
use Getopt::Long;
use vars qw($AUTOLOAD);
use Getopt::Long;
use Cwd ;
use File::Basename;

no warnings 'redefine';


my $MAXRESULTS = 100 ;
my $MINDIST = 2 ; 
my @alpha = qw( a b c d e f g h i j k l m n o p  ); 
my $GLOBLOGFILE ;
my $CUTOFF = 24 ; 
my $MAXNUMBEROFRESULTS = 500000 ;
my $ORDERRESIDUES = 0 ;

# how much distance diff will you allow
# my $MAXALLOWEDDISTDEVIATION = 1.6 ;  for protease paper
#my $MAXALLOWEDDISTDEVIATION = 2.6 ; #  for Blase
my $MAXALLOWEDDISTDEVIATIONNEG = 1.5 ; #  for 1NZOX
my $MAXALLOWEDDISTDEVIATIONPOS = 2.5 ; #  for 1NZOX
$MAXALLOWEDDISTDEVIATIONNEG = 3.5 ;
$MAXALLOWEDDISTDEVIATIONPOS = 3.5 ;
my $SCALEFACTOR = 100 ; 

my $_verbose = 0 ;

my $fields = {
    NAME => undef, 
    SEQ => undef, 
    ATOMS => undef ,
    RESIDUES => undef ,
    LINES => undef ,
    ORIGLINES => undef ,
    ADDEDATOMS => undef ,
    PSEUDOATOMCNT => undef ,
    CLOSE2ACTIVESITE => undef ,
    RESIDUESCLOSE2ACTIVESITE => undef ,
    LOGFILE => undef 
};

sub new{
    my $that = shift ; 
    my $class = ref($that) || $that ;

    my $self =  {};

    map { $self->{$_} = undef ; } (keys %{$fields});

    $self->{SEQ} = [];
    $self->{ATOMS} = [];
    $self->{ATOMTABLE} = {};
    $self->{RESIDUES} = [];
    $self->{LINES} = [];
    $self->{ADDEDATOMS} = [];
    $self->{RESTABLE} = {};
    $self->{REPLACENAME} = {};
    $self->{JUSTRESNUM} = 0;
    $self->{READCHARGE} = 0;
    $self->{CLOSE2ACTIVESITE} = 0;
    ##$self->{PSEUDORESIDUE} = new Residue("pse",10000);
    #$self->{PSEUDOATOMCNT} = 10000 ;



	my $fullname ;
	my $threeletter ;
	my $singleletter ;
    my @l = ConfigPDB_AminoAcidCodes();

	while(@l){
		$fullname = shift @l ;
		$threeletter = uc(shift @l) ;
		$singleletter = uc(shift @l) ;
        $self->{SINGLE2THREE}->{$singleletter} = $threeletter ; 
        $self->{THREE2SINGLE}->{$threeletter} = $singleletter ;
        #print "$threeletter} = $singleletter  \n";
        #print " $fullname {THREE2SINGLE}->{$threeletter} = $singleletter  \n";
	}


    bless $self, $class ; 
	#$self->AddResidue($self->{PSEUDORESIDUE}); 
    $self ;
}

sub AUTOLOAD {
    my $self = shift;
    my $attr = $AUTOLOAD;
    $attr =~ s/.*:://;
    return unless $attr =~ /[^A-Z]/;  # skip DESTROY and all-cap methods
    croak "invalid attribute method: ->$attr()" unless exists $fields->{$attr} ; 
    $self->{$attr} = shift if @_;
    return $self->{$attr};
}

sub SetLogFile{
	my $self = shift ; 
    $self->{LOGFILE} = shift ; 
	$GLOBLOGFILE = $self->{LOGFILE} ;
}
sub SetReadCharge{
	my $self = shift ; 
    $self->{READCHARGE} = 1 ; 
}

sub AddAtom{
    my $self = shift ;
    my ($residue,$atom) = @_ ; 
	$residue->AddAtom($atom); 
	push @{$self->{ATOMS}},$atom ; 
	$self->{ATOMTABLE}->{$atom->GetIdx()} = $atom ;
	my $resnum = $atom->GetResNum() ;
	my $resname = $residue->GetName() ;
	$self->{RESTABLE}->{$resnum} = $residue ;
}
sub AddAtomPseudo{
    my $self = shift ;
    my ($residue,$atom) = @_ ; 
	$residue->AddAtom($atom); 
	my $resnum = $atom->GetResNum() ;
	my $resname = $residue->GetName() ;
	$self->{RESTABLE}->{$resnum} = $residue ;
}

sub AddResidue{
    my $self = shift ;
    my ($residue) = @_ ; 
	push @{$self->{RESIDUES}},$residue ; 
}

sub PrintSeq{
    my $self = shift ;
	foreach my $residue (@{$self->{RESIDUES}}){
		my $x  = $residue->PrintSingleLetter($self);
		print "$x" if(defined $x);
	}
	print "\n";
}
sub GetSeq{
    my $self = shift ;
	my @l ;
	foreach my $residue (@{$self->{RESIDUES}}){
		my $x  = $residue->PrintSingleLetter($self);
		next if($x =~ /^\s*$/);
		push @l, $x if(defined $x);
	}
	return @l ; 
}

sub WriteFasta{
    my $self = shift ;
    my $name = shift ;
    my $fh = shift ;
    print $fh "\>$name RecName: Full=Beta-lactamase;\n";
	my $cnt = 0 ; 
	foreach my $residue (@{$self->{RESIDUES}}){
		my $x  = $residue->PrintSingleLetter($self);
		next if($x eq "?");
		$cnt++ ;
		print $fh "$x" if(defined $x);
	}
	print $fh "\n";
	print STDERR "XXX $name = $cnt\n";
}

sub AddSeq{
    my $self = shift ;
    my (@seq) = @_ ; 
	push @{$self->{SEQ}},@seq ; 

}



sub ReadPDB{

   my ($self,$infile) = @_ ; 
   $self->{NAME} = $infile ; 
   croak "No file $infile" if(! -e $infile);
   my $ifh = util_read($infile);
   print "Info: Reading pdb file $infile\n";
   
   my $lastresnum ; 
   my $currresidue ;
   
   my $seqid ;
   my $state = 0 ;
   my $tableCodeforinsertion = {};
   while(<$ifh>){
	    push @{$self->{LINES}},$_ ; 
	    push @{$self->{ORIGLINES}},$_ ; 
        next if(/^\s*$/);
	    if(0 && /^TER/){
   		   chomp ;
		   my $LINE = $_ ; 
	 	   my $atom = new Atom();
		   $atom->SetOrigLine($LINE);
		   $self->AddAtom($currresidue,$atom) ; 
		}
   
	    if(/SEQRES/){
	 	   my @l = split ; 
		   $seqid = $l[2] if(!defined $seqid);
		   next if($seqid ne $l[2]);
		   shift @l ; shift @l ; shift @l ; shift @l ; 
		   $self->AddSeq(@l);
	    }
   
	    if(/^ATOM/ || /^HETATM/ || /^TER/){
   		   chomp ;
		   my $LINE = $_ ; 
		   my $len = length($LINE) ;
		   #print "lenght = $len $LINE \n";
		   my ($atomstr , $serialnum , $atomnm , $alt_loc , $resname , $chainId , $resnum , $codeforinsertion , $x , $y , $z ) = util_ReadLine($LINE);


		   if(0 && $len > 55){
           my $occupancy = util_mysubstr($len,$LINE,55 , 60);
           my $temp = util_mysubstr($len,$LINE,61 , 66);
           my $segid = util_mysubstr($len,$LINE,73 , 76);
           my $element = util_mysubstr($len,$LINE,77 , 78);
           my $charge = util_mysubstr($len,$LINE,79 , 80);
		   }

		   my $charge ;
		   if($self->{READCHARGE} && $len > 55){
           $charge = util_mysubstr($len,$LINE,55 , 60);
		   }

		   if(! exists $tableCodeforinsertion->{$resnum}){
		   	   $tableCodeforinsertion->{$resnum} = $codeforinsertion ; 
		   }

		   my $ignoreDuetoCodeforinserstion = 0 ; 
		   if($tableCodeforinsertion->{$resnum} ne $codeforinsertion){
		       $ignoreDuetoCodeforinserstion = 1 ; 
		   }


		   
		   if($chainId eq "A" && !$ignoreDuetoCodeforinserstion){
             my $GGG = sprintf "%-6s%5s%1s%4s%1s%3s%1s%1s%4s%1s%3s%8s%8s%8s\n",$atomstr,$serialnum," ",$atomnm,$alt_loc,$resname," ",$chainId,$resnum,
                                                              $codeforinsertion,"   ","   TIFRX","   TIFRY","   TIFRZ";
             pop @{$self->{LINES}};
             push @{$self->{LINES}},$GGG ; 
		   	 $state = 1 ;
		   }
		   else{
		   #print "Chain id = $chainId\n";
		   	  next ; 
		   }
		   my @uu = split " ",$atomnm ;
		   if(@uu != 1){
		   	  #print "unknown type atomnm : $atomnm \n";
		   }
		   $atomnm = $uu[0];
		   if(/^TER/){
		   	 $atomnm = "TER";
		   }


	 	   my $atom = new Atom();
		   $atom->SetOrigLine($LINE);
	 	   $atom->SetValues($serialnum,$atomnm,$resname,$resnum,$x,$y,$z);
		   $atom->SetAtomStr($atomstr);
		   if($self->{READCHARGE} && defined $charge){
		   	  $atom->SetCharge($charge);
		   }
   
			  #print "Processing residue number $resnum $resname $atomnm \n";
		   if(!defined $lastresnum || ($resnum != $lastresnum)){
			   $lastresnum = $resnum ; 
			   $currresidue = new Residue($resname,$resnum,$atomstr);
			   #print "Adding residue number $resnum $resname \n";
			   $self->AddResidue($currresidue); 
		   }
   
		   $self->AddAtom($currresidue,$atom) ; 
		   if($atomnm =~ /ca/i){
			   $currresidue->SetCAAtom($atom); 
		   }

	       #if(/^HETATM/){
		   	#$atom->Print();
		   #}

   
	    }
		last if(/^\s*ENDMDL/);
   }

   close($ifh);
   if($_verbose){
       print " There are ", scalar(@{$self->{SEQ}}) , " sequences \n"; 
       print " There are ", scalar(@{$self->{ATOMS}}) , " atoms \n"; 
       print " There are ", scalar(@{$self->{RESIDUES}}) , " residues \n"; 
   }

   die "ERROR $infile No residues, hence quitting. Maybe there was no chain A " if(!@{$self->{RESIDUES}});

   #my $residueRange = $self->GetResidueRange(); 

   ## unlink "TTT.pdb" ;
   ## my $fh = util_write("TTT.pdb") or die;
   ## $self->Print($fh);
   ## close($fh);
   my $cnt = 0 ; 
   foreach my $r (@{$self->{RESIDUES}}){
   	    if(! defined $r->GetAtomType("CA")){
			if($_verbose){
			    $r->Print(1);
			    warn "CA atom not found for residue given above" ;
			}
		}
		my $resnum = $r->GetResNum();
		my $type = $r->GetName();
		#print " $cnt $resnum $type \n";
        $cnt++;
   }



   return $self ; 
}

sub WritePDB{
	my ($self,$outfile,$onlychainA,$ignorewater) = @_ ; 
	die if(!defined $onlychainA) ;
    my $fh = util_write($outfile);
	print STDERR "Info: Writing PDB file to $outfile\n";

	foreach my $line (@{$self->{LINES}}){
	    if(defined $ignorewater){
		    if($line =~ /^HETATM/ && $line =~ /HOH/){
			    next ; 
		    }
	    }


		my $print = 1 ; 
	    $print = 0 if($self->{JUSTRESNUM});
	    if($line =~ /^ATOM/ || $line =~ /^HETATM/ || $line =~ /^TER/){
		    if($line =~ /TIFR/){
		        my $len = length($line) ;
                my $atomstr = util_mysubstr($len,$line,1 ,  6);
                my $idx = util_mysubstr($len,$line,7 , 11);

                my $resname = util_mysubstr($len,$line,18 , 20);
                my $resnum = util_mysubstr($len,$line,23 , 26);
				if(exists $self->{REPLACENAME}->{$resnum}){
					my $newnm = $self->{REPLACENAME}->{$resnum} ;
			        $line =~ s/$resname/$newnm/;
				}

				if($self->{JUSTRESNUM}){
				    $print = 1 if($self->{JUSTRESNUM} == $resnum);
				}

				if($self->{READCHARGE} && $self->{READCHARGE} == $resnum){
                     my $charge = util_mysubstr($len,$line,55 , 60);
			         $line =~ s/$charge/0.0000/;
				}

				#print "$resname $resnum" if($resnum == 73);

				#print "$line\n";
			    my $atom = $self->GetAtomIdx($idx) or die "could not parse line $line\n";;
			    my ($x,$y,$z) = $atom->Coords();
				$atom->Print() if(!defined $x);
			    $line =~ s/   TIFRX/$x/;
			    $line =~ s/   TIFRY/$y/;
			    $line =~ s/   TIFRZ/$z/;
		    }
		    elsif($onlychainA){
			    next ;
		    }
		}
		print $fh $line if($print);
	}
	
}

sub WritePQR{
	my ($self,$outfile) = @_ ; 
    my $fh = util_write($outfile);
	print STDERR "Info: Writing PQR file to $outfile\n";

	my $once = 0 ; 
	foreach my $line (@{$self->{ORIGLINES}}){
		if($line =~ /^\s*TER\s*$/){
			foreach my $lll (@{$self->{ADDEDATOMS}}){
			      if(!$once){
		             print $fh $lll; 
				     $once = 1 ;
				  }
			}
		}
		print $fh $line ; 
	}
	
}

sub DistanceAtoms{
    my ($self,$a1,$a2) = @_ ; 
	return util_format_float($a1->Distance($a2),3);
}

sub DistanceAtomsIdx{
    my ($self,$a1,$a2) = @_ ; 
	my $A1 = $self->GetAtomIdx($a1);
	my $A2 = $self->GetAtomIdx($a2);
	return $A1->Distance($A2); 
}

sub GetAtomIdx{
    my ($self,$idx) = @_ ; 
	if(!defined $idx){
	     carp " undefined idx " ; 
		 return undef ;
	}

	my $atom = $self->{ATOMTABLE}->{$idx} ;
	croak "No atom found for index $idx" if(!defined $atom);

	return $atom ;

  
  	## NOT USED 
	if($idx > scalar(@{$self->{ATOMS}})){
		print "Incorrect index number $idx for atom, since there are only ", scalar(@{$self->{ATOMS}}), " atoms\n";
		return undef ; 
	}
	## adjust
	$idx--; 
	## todo - idx 
	my @atoms = @{$self->{ATOMS}} ; 
	#$atoms[$idx]->Print(); 
	return $atoms[$idx]; 
}

sub GetResidueIndices{
    my ($self,@indices) = @_ ; 
	my @out = ();
	foreach my $r (@indices){
		my $i ;
	    if(defined $r){
		   $i = $self->GetResidueIdx($r);
	       carp "$i $r lllllll \n" if(! defined $i);
		   push @out,$i ;
		}
		else{
		   push @out,$i ;
		}
	}
	return @out ; 
}

sub GetResidueIndicesFromResidueObjects{
    my ($self,@residues) = @_ ; 
	my @out = ();
	foreach my $r (@residues){
		my $i = $r->GetResNum();
		push @out,$i ;
	}
	return @out ; 
}

sub GetResidueIdx{
    my ($self,$idx) = @_ ; 
	#print "JJJ $self $self->{RESTABLE} \n";
	if(!exists $self->{RESTABLE}->{$idx}){
		#my @ll = keys %{$self->{RESTABLE}};
	    #my @l = sort { $a <=> $b} @ll ; 
		#map { print "iiiiiiiii = $_ \n"; } @l ;
		print STDERR "Incorrect index number $idx for residue, \n";
		return undef ; 
	}
	return $self->{RESTABLE}->{$idx} ; 
}


sub PrintResults{
	my($self) = shift ;
	my ($msg) = @_ ; 
	my $ofh = $self->{LOGFILE}  ;
	print $ofh "$msg\n";
	print "$msg\n";
}

sub QueryResidueType{
	my ($self,$name,$print) = @_ ; 
    my @residues = @{$self->{RESIDUES}} ; 

	$self->PrintResults("residue number            name") if($print);
	my $cnt =0 ; 
	my @resNums = ();
	foreach my $r (@residues){
		my $nm = $r->{RESNAME}; 
		my $num = $r->{RESNUM}; 
		if($nm =~ /$name/ || uc($name) eq "X"){
			$cnt++;
			$self->PrintResults("$num\t\t\t$nm") if($print);
			push @resNums,$num ; 
		}
	}
	$self->PrintResults("Summary: There are $cnt numbers of $name residues\n") if($print);
	return @resNums ;
}

sub ConvertResidue2ThreeLetter{
	my ($self,$name) = @_ ; 
	if(length($name) == 1){
	    $name = uc($name);
		if(! exists  $self->{SINGLE2THREE}->{$name}){
			print "Error: Residue code $name doesnt exist\n";
			return undef ;
		}
		my $v = $self->{SINGLE2THREE}->{$name} ;
		return uc($v) ;
	}
	elsif(length($name) == 3){
	    $name = lc($name);
		if(! exists  $self->{THREE2SINGLE}->{$name}){
			print "Error: Residue code $name doesnt exist\n";
			return undef ;
		}
		return uc($name) ; 
	}
	else{
		print "Error: Residue code must be either 3 letter or 1 letter \n";
		die ; 
	}
}

sub GetAtoms{
	my ($self) = @_ ; 
	return  @{$self->{ATOMS}}  ;
}
sub GetResidues{
	my ($self) = @_ ; 
	return  @{$self->{RESIDUES}}  ;
}


sub MinDistanceBetweenResidues{
	my ($self,$n1,$n2) = @_ ; 

	my $r1 = $self->GetResidueIdx($n1);
	my $r2 = $self->GetResidueIdx($n2);
	
	my $rname1 = $r1->GetName();
	my $rname2 = $r2->GetName();
	my $key = $rname1 . $rname2 ;


	my $minDist = 10000 ;
	my $minA ; 
	my $minB ; 
	if(defined $r1 and defined $r2){
		my @atoms1 = $r1->GetAtoms();
		my @atoms2 = $r2->GetAtoms();
		foreach my $a1 (@atoms1){
		     foreach my $a2 (@atoms2){
				   my $connType = $a1->{TYPE} . $a2->{TYPE} ;
		           my $d = $self->DistanceAtoms($a1,$a2); 
				   if($d < $minDist){
				   	   $minDist = $d ; 
					   $minA = $a1 ; 
					   $minB = $a2 ; 
				   }
		     }
		}

		warn "Did not find min dist between residues $n1 and $n2 with resnames $rname1 and $rname2" if(!defined $minA);
		return ($minDist,$minA,$minB); 
	}
	return 0 ; 
}

sub GetResidueRange{
	my $self = shift ; 
	my $first = 1 ;
	while(! exists $self->{RESTABLE}->{$first}){
		$first++;
	}

	my $last = 5000 ; 
	while(! exists $self->{RESTABLE}->{$last}){
		$last--
	}

    my $idx = $first ; 
	while($idx < $last){
	    if(! exists $self->{RESTABLE}->{$idx}){
			warn "some residues are missing: at index $idx for example \n" if($_verbose);
			last ; 
		}
		$idx++ ; 
	}
	

	print " range = $first-$last \n" if($_verbose);
	return "$first-$last";

}

sub CalcDistance{
	my ($self,$r1,$r2,$cutoff,$ignorelist_ResIndex,$has2beOne_ResIndex) = @_ ; 

	my $has2be_ResType = {};
	$has2be_ResType->{$r1} = 1 if(uc($r1) ne "X");
	$has2be_ResType->{$r2} = 1 if(uc($r2) ne "X");

	
	my $key = $r1 . $r2 ;
	my $a1 ; 
    my @atoms = $self->GetAtoms();
	my $info = {} ;

	## iterating over all atoms 
    while($a1 = shift @atoms){
		foreach my $a2 (@atoms){
		    my $connType = $a1->{TYPE} . $a2->{TYPE} ;
	        my ($s,$NMSADDED) = $a1->CalcDistance($a2,$cutoff,$has2be_ResType,$ignorelist_ResIndex,$has2beOne_ResIndex);
			if(defined $s){
			  	$info->{$s} = $NMSADDED ;
			}
		}
	}
	return $info;
}

sub ClosestResiduePair{
	my ($self,$r1,$r2,$cutoff,$ignorelist,$has2be) = @_ ;
	my $info = $self->CalcDistance($r1,$r2,$cutoff,$ignorelist,$has2be);
	my @results = ();
	my $cnt = 0; 
	my $seen = {};

    foreach my $key (sort  { $a <=> $b } keys %{$info}){
		  # print " $key = $info->{$key} \n";
		  
          my $result = {};
		  my @f = split "_",  $info->{$key} ;
		  my $dist = $key ; 
	      my ($res1,$res2,$atom1,$atom2,$t1,$t2) = @f ; 

		  my $respair = $res1 . "_" . $res2 ; 
		  my $atompair = $atom1 . "_" . $atom2 ; 
		  my $atomtypepair = $t1 . "_" . $t2 ; 

		  ## ignore residue pairs already seen 
		  next if($seen->{$respair});
		  $seen->{$respair} = 1 ; 

		  $result->{RESPAIR} = $respair ;
		  $result->{ATOMPAIR} = $atompair ;
		  $result->{ATOMTYPEPAIR} = $atomtypepair;

		  $result->{DIST} = $dist;
		  $result->{RESNUM} = [];
		  $result->{ATOM} = [] ;

		  $self->AddResults($result,$atom1,$atom2);
          push @results,$result ;

		  $cnt++;
		  last if($cnt >= $MAXRESULTS);
    }


	return @results ;
}

sub AddResults{
	      my ($self,$result,$atom1,$atom2) = @_ ; 
		  push @{$result->{ATOM}} , $atom1 ;
		  push @{$result->{ATOM}} , $atom2 ;


		  my $atomobj1 = $self->GetAtomIdx($atom1);
		  my $atomobj2 = $self->GetAtomIdx($atom2);

		  my $res1 = $atomobj1->GetResNum();
		  my $res2 = $atomobj2->GetResNum();
		  push @{$result->{RESNUM}} , $res1 ;
		  push @{$result->{RESNUM}} , $res2 ;

		  my $respair = $res1 . "_" . $res2 ; 

}


sub AngleBetweenThreeAtoms{
	my ($self,$a1,$a2,$a3) = @_ ; 
	croak " Atoms not defined " if(!defined $a1);
	croak " Atoms not defined " if(!defined $a2);
	croak " Atoms not defined " if(!defined $a3);
	return geom_AngleBetweenThreePoints($a1->Coords(),$a2->Coords(),$a3->Coords());
}


sub GetNeighbourHoodAtom{
	my ($self,$atoms,$cutoff,$onlythistype) = @_;
	my $junk ;
	
	my ($residues,$combined);
	($residues,$combined,$residues) = $self->GetNeighbourHoodAtomInSet($atoms,$self->{ATOMS},$cutoff,$onlythistype) ; 
	return ($junk,$combined,$residues) ;
}

sub GetNeighbourHoodAtomInSet{
	my ($self,$atoms,$searchset,$cutoff,$onlythistype) = @_;
	my $results ; 
	my @combined ;
	my $residues ; 
	#print STDERR " llllllllll GetNeighbourHoodAtomInSet $cutoff \n";
	croak "Expected some atoms: $cutoff " if(!defined $cutoff);
	foreach my $atom2 (@{$searchset}){
		next if($atom2->IsTer());
	    foreach my $atom1 (@{$atoms}){

		   my $d = $atom2->Distance($atom1) ;
		   if($d < $cutoff){
		   		if(defined $onlythistype){
					my $r = $atom2->GetResName();
					next if($r ne $onlythistype);
					print "$r $onlythistype\n";
				}
					my $rnum = $atom2->GetResNum();
					$residues->{$rnum} = 1; 
		            if(defined $atom1->GetIdx()){
					   $results->{$atom1->GetIdx()} = [] if(!defined $results->{$atom1->GetIdx()});
					   push @{$results->{$atom1->GetIdx()}}, $atom2 ; 
					}
					push @combined, $atom2 ; 

		    }
	    }
	}
	return ($results,\@combined,$residues) ;
}

sub GetNeighboutHood{
	my ($self,$grptable,@reslist1) = @_ ; 
	my $groups = {};
	foreach my $p (@reslist1){
		if(exists $grptable->{$p->GetName()}){
		    $groups->{$p->GetResNum()} = [] ;	
	        foreach my $x (@reslist1){
				next if($x == $p || $x->GetResNum() == $p->GetResNum());
				my ($a,$b)  = util_Sort($p->GetResNum,$x->GetResNum());
				my $str = "$a.$b";
		        if(exists $self->{DISTTABLE}->{$str}){
					push @{$groups->{$p->GetResNum()}}, $x;
		        }
		        #my ($atom1) = $self->GetAtomFromResidueAndType($x->GetResNum(),"CA");
		        #my ($atom2) = $self->GetAtomFromResidueAndType($p->GetResNum(),"CA");
		        #next if(!defined ($atom1 && $atom2));
		        #my $d = $atom1->Distance($atom2) ;
		        #if($d < $CUTOFF){
					#push @{$groups->{$p->GetResNum()}}, $x;
				#}
			}
		}
	}
	return $groups ;
}


sub util_Sort{
	my ($x,$y) = @_ ; 
	return ($x,$y) if($x >= $y );
	return ($y,$x) if($x < $y );
}

sub CreateDistTable{
	my ($self) = @_ ; 
	my @reslist1 = $self->GetResidues();
	#my $n = @reslist1 ;
	my $info = {};
	while (my $p = shift @reslist1){
	#my $n = @reslist1 ;
	        foreach my $x (@reslist1){
				next if($x == $p);
		        my ($atom1) = $self->GetAtomFromResidueAndType($x->GetResNum(),"CA");
		        my ($atom2) = $self->GetAtomFromResidueAndType($p->GetResNum(),"CA");
		        next if(!defined ($atom1 && $atom2));
		        my $d = $atom1->Distance($atom2) ;
		        if($d < $CUTOFF){
					my ($a,$b)  = util_Sort($p->GetResNum,$x->GetResNum());
					my $str = "$a.$b";
					$info->{$str} = $d ;
				}
			}
	}
	return $self->{DISTTABLE} = $info ;
}

sub GetAllResiduesOrSubset{
	my ($self,$a,$b,$c) = @_ ; 
	if(!defined $self->{RESIDUESCLOSE2ACTIVESITE}){
	    my @reslist1 = $self->GetResidues();
		return @reslist1 ; 
	}
	else{
	    my @resnumbers = (keys %{$self->{RESIDUESCLOSE2ACTIVESITE}});
	    my @reslist1 ;
		foreach my $resnum (@resnumbers){
	        my ($res) = $self->GetResidueIdx($resnum);
			push @reslist1,$res ;
		}
		return @reslist1 ; 
	}
}

sub GetTrio{
	my ($self,$a,$b,$c) = @_ ; 
	my @reslist1 = $self->GetAllResiduesOrSubset();

	my @retlist = ();
	my $done = {};
	foreach my $s (@reslist1){
		if(exists $a->{$s->GetName()}){
	        foreach my $l (@reslist1){
		        if(exists $b->{$l->GetName()}){
	                  foreach my $t (@reslist1){
		                  if(exists $c->{$t->GetName()}){
							#next if(util_ignoreIfDistanceIsLessthan(3,$t->GetResNum(),$l->GetResNum(),$s->GetResNum()));
							next if(util_ignoreIfAnyAreEqual($t->GetResNum(),$l->GetResNum(),$s->GetResNum()));
							my $SS = $t->GetResNum() . $l->GetResNum(). $s->GetResNum();
							next if($done->{$SS});
							$done->{$SS} = 1 ;

							my @l = ();
						  	push @l, $s->GetResNum() ;
						  	push @l, $l->GetResNum() ;
						  	push @l, $t->GetResNum() ;
						  	push @retlist, \@l ;
						  }
	                  }
				}
	        }
		}
	}
	return @retlist ; 
}

sub GetQuad{
	my ($self,$a,$b,$c,$d) = @_ ; 
	my @reslist1 = $self->GetAllResiduesOrSubset();

	my @retlist = ();
	my $groups = $self->GetNeighboutHood($a,@reslist1);

    my $cnt = 0 ; 
	foreach my $resnum (keys %{$groups}){
	        my @residues = @{$groups->{$resnum}};  
	        foreach my $s (@residues){
		        if(exists $b->{$s->GetName()}){
	                foreach my $l (@residues){
		                if(exists $c->{$l->GetName()}){
	                          foreach my $t (@residues){
		                          if(exists $d->{$t->GetName()}){
							        #next if(util_ignoreIfDistanceIsLessthan(3,$resnum,$t->GetResNum(),$l->GetResNum(),$s->GetResNum()));
							        next if(util_ignoreIfAnyAreEqual($resnum,$t->GetResNum(),$l->GetResNum(),$s->GetResNum()));
        
							        my @l = ();
						  	        push @l, $resnum ; 
						  	        push @l, $s->GetResNum() ;
						  	        push @l, $l->GetResNum() ;
						  	        push @l, $t->GetResNum() ;  ##### IIIIIMMMMPPPP to add it in order 
						  	        push @retlist, \@l ;
									$cnt++;
						          }
	                          }
							  last if($cnt eq $MAXNUMBEROFRESULTS);
				        }
	                }
					last if($cnt eq $MAXNUMBEROFRESULTS);
		        }
	        }
			last if($cnt eq $MAXNUMBEROFRESULTS);
	}
	return @retlist ; 
}

sub GetPent{
	my ($self,$a,$b,$c,$d,$e) = @_ ; 
	my @reslist1 = $self->GetAllResiduesOrSubset();

	my @retlist = ();
	my $groups = $self->GetNeighboutHood($a,@reslist1);

	my $cnt = 0 ; 
	foreach my $resnum (keys %{$groups}){
			#my $nm = $s->GetName();
	        my @residues = @{$groups->{$resnum}};  
	        foreach my $s (@residues){
			#my $nm = $s->GetName();
		        if(exists $b->{$s->GetName()}){
	                foreach my $l (@residues){
		                if(exists $c->{$l->GetName()}){
	                          foreach my $t (@residues){
		                          if(exists $d->{$t->GetName()}){
	                                  foreach my $r (@residues){
		                                  if(exists $e->{$r->GetName()}){
							                  #next if(util_ignoreIfDistanceIsLessthan(3,$resnum,$t->GetResNum(),$l->GetResNum(),$s->GetResNum(),$r->GetResNum()));
							                  next if(util_ignoreIfAnyAreEqual($resnum,$t->GetResNum(),$l->GetResNum(),$s->GetResNum(),$r->GetResNum()));
                  
							                  my @l = ();
						  	                  push @l, $resnum ; 
						  	                  push @l, $s->GetResNum() ;
						  	                  push @l, $l->GetResNum() ;
						  	                  push @l, $t->GetResNum() ;  ##### IIIIIMMMMPPPP to add it in order 
						  	                  push @l, $r->GetResNum() ;  ##### IIIIIMMMMPPPP to add it in order 
						  	                  push @retlist, \@l ;
											  $cnt++ ; 
										 }
							              last if($cnt eq $MAXNUMBEROFRESULTS);
									 }
						          }
							      last if($cnt eq $MAXNUMBEROFRESULTS);
	                          }
				        }
						last if($cnt eq $MAXNUMBEROFRESULTS);
	                }
		        }
				last if($cnt eq $MAXNUMBEROFRESULTS);
	        }		
		last if($cnt eq $MAXNUMBEROFRESULTS);
	}

	my $num = @retlist;
	die "No matches found - hence quiting " if(!$num);
	return @retlist ; 
}
sub GetHex{
	my ($self,$a,$b,$c,$d,$e,$f) = @_ ; 
	my @reslist1 = $self->GetAllResiduesOrSubset();

	my @retlist = ();
	my $groups = $self->GetNeighboutHood($a,@reslist1);

	foreach my $resnum (keys %{$groups}){
	        my @residues = @{$groups->{$resnum}};  
	        foreach my $s (@residues){
		        if(exists $b->{$s->GetName()}){
	                foreach my $l (@residues){
		                if(exists $c->{$l->GetName()}){
	                          foreach my $t (@residues){
		                          if(exists $d->{$t->GetName()}){
	                                  foreach my $r (@residues){
		                                  if(exists $e->{$r->GetName()}){
	                                           foreach my $u (@residues){
		                                           if(exists $f->{$u->GetName()}){

							                             next if(util_ignoreIfAnyAreEqual($resnum,$t->GetResNum(),$l->GetResNum(),$s->GetResNum(),
											             $r->GetResNum(),$u->GetResNum()));

							                             my @l = ();
						  	                             push @l, $resnum ; 
						  	                             push @l, $s->GetResNum() ;
						  	                             push @l, $l->GetResNum() ;
						  	                             push @l, $t->GetResNum() ;  ##### IIIIIMMMMPPPP to add it in order 
						  	                             push @l, $r->GetResNum() ;  ##### IIIIIMMMMPPPP to add it in order 
						  	                             push @l, $u->GetResNum() ;  ##### IIIIIMMMMPPPP to add it in order 
						  	                             push @retlist, \@l ;


											     }
										     } 
										 }
									 }
						          }
	                          }
				        }
	                }
		        }
	        }
	}

	my $num = @retlist;
	die "No matches found - hence quiting " if(!$num);
	return @retlist ; 
}

sub GetNine{
	my ($self,$a,$b,$c,$d,$e,$f,$g,$h,$i) = @_ ; 
	my @reslist1 = $self->GetAllResiduesOrSubset();

	my @retlist = ();
	my $groups = $self->GetNeighboutHood($a,@reslist1);

	foreach my $resnum (keys %{$groups}){
	        my @residues = @{$groups->{$resnum}};  
	        foreach my $s (@residues){
		        if(exists $b->{$s->GetName()}){
	                foreach my $l (@residues){
		                if(exists $c->{$l->GetName()}){
	                          foreach my $t (@residues){
		                          if(exists $d->{$t->GetName()}){
	                                  foreach my $r (@residues){
		                                  if(exists $e->{$r->GetName()}){
	                                           foreach my $u (@residues){
		                                           if(exists $f->{$u->GetName()}){
	                                                  foreach my $v (@residues){
		                                                  if(exists $g->{$v->GetName()}){
	                                                          foreach my $w (@residues){
		                                                          if(exists $h->{$w->GetName()}){
	                                                                  foreach my $x (@residues){
		                                                                  if(exists $i->{$x->GetName()}){



							                             next if(util_ignoreIfAnyAreEqual($resnum,$t->GetResNum(),$l->GetResNum(),$s->GetResNum(),
											             $r->GetResNum(),$u->GetResNum(),
											             $v->GetResNum(),$w->GetResNum(),$x->GetResNum()
														 ));

							                             my @l = ();
						  	                             push @l, $resnum ; 
						  	                             push @l, $s->GetResNum() ;
						  	                             push @l, $l->GetResNum() ;
						  	                             push @l, $t->GetResNum() ;  ##### IIIIIMMMMPPPP to add it in order 
						  	                             push @l, $r->GetResNum() ;  ##### IIIIIMMMMPPPP to add it in order 
						  	                             push @l, $u->GetResNum() ;  ##### IIIIIMMMMPPPP to add it in order 
						  	                             push @l, $v->GetResNum() ;  ##### IIIIIMMMMPPPP to add it in order 
						  	                             push @l, $w->GetResNum() ;  ##### IIIIIMMMMPPPP to add it in order 
						  	                             push @l, $x->GetResNum() ;  ##### IIIIIMMMMPPPP to add it in order 
						  	                             push @retlist, \@l ;


												    }
													}}}
												   }
												  }
											     }
										     } 
										 }
									 }
						          }
	                          }
				        }
	                }
		        }
	        }
	}

	my $num = @retlist;
	die "No matches found - hence quiting " if(!$num);
	return @retlist ; 
}




sub AngleBetweenThreeResiduesWithGivenAtomsPermuted{
	my ($self,$a,$b,$c,$t1,$t2,$t3) = @_ ; 
	#print "$t1 $t2 $t3\n";
	my $a1 = $self->AngleBetweenThreeResiduesWithGivenAtoms($a,$b,$c,$t1,$t2,$t3);
	my $a2 = $self->AngleBetweenThreeResiduesWithGivenAtoms($b,$a,$c,$t2,$t1,$t3);
	my $a3 = $self->AngleBetweenThreeResiduesWithGivenAtoms($b,$c,$a,$t2,$t3,$t1);
	return ($a1,$a2,$a3); 
}

sub AngleBetweenThreeGivenAtomsPermuted{
	my ($self,$a,$b,$c) = @_ ; 
	#print "$t1 $t2 $t3\n";
	my $a1 = $self->AngleBetweenThreeAtoms($a,$b,$c);
	my $a2 = $self->AngleBetweenThreeAtoms($b,$a,$c);
	my $a3 = $self->AngleBetweenThreeAtoms($b,$c,$a);
	return ($a1,$a2,$a3); 
}

sub AngleBetweenThreeResiduesWithGivenAtoms{
	my ($self,$a,$b,$c,$t1,$t2,$t3) = @_ ; 
    my ($res0,$res1,$res2) = $self->GetResidueIndices($a,$b,$c);
	
	my $CA0 = $res0->GetAtomType($t1);
	my $CA1 = $res1->GetAtomType($t2);
	my $CA2 = $res2->GetAtomType($t3);
	return undef if(!defined ($CA0 && $CA1 && $CA2)) ; 

	my $angle = $self->AngleBetweenThreeAtoms($CA0,$CA1,$CA2);
	$self->PrintResults( "Angle between residues $a $b $c is $angle");

	return $angle ; 
		
}

sub GetAtomFromResidueAndType{
	my ($self,$a1,$t1) = @_ ; 
	#print "GET RESIDUE INDEx $a1\n";
	#print " NAME = $self->{NAME} \n";
    my ($res1) = $self->GetResidueIndices($a1);
	die "Error :did not get residue for number $a1 and $t1 $self->{NAME} " if(!defined $res1);
	my $atom = $res1->GetAtomType($t1) ;
	if(!defined $atom ){
	    #$res1->Print();
	    #warn "did not get residue for type $t1 " ; 
	}
	return $atom;

}

sub DistanceBetweenThreeResiduesWithGivenAtoms{
	my ($self,$a,$b,$c,$t1,$t2,$t3) = @_ ; 
    my ($res0,$res1,$res2) = $self->GetResidueIndices($a,$b,$c);
	my $CA0 = $res0->GetAtomType($t1);
	my $CA1 = $res1->GetAtomType($t2);
	my $CA2 = $res2->GetAtomType($t3);
	return undef if(!defined ($CA0 && $CA1 && $CA2)) ; 

	my $d1 = $CA0->Distance($CA1) ;
	my $d2 = $CA1->Distance($CA2) ;
	my $d3 = $CA2->Distance($CA0) ;
	$self->PrintResults( "Distance between residues are  $d1 $d2 $d3");
	
	return ($d1,$d2,$d3);
		
}




sub GetGroups{
    my ($self,$infile) = @_ ; 
    my $ifh = util_read($infile);
    
    while(<$ifh>){
         next if(/^\s*$/);
         chomp ;
	     if(/^GROUPS/){
	 	    my (@groups) = split ; 
		    shift @groups ; ## get rid of points 
			print "Info:Found " , scalar(@groups) , " groups - ie the same number of atoms \n";
			print "Info: The groups are ", @groups , " \n";
	        close($ifh);
			my $num = @groups ; 
			die "Cant handle $num number of groups" if($num != 3 && $num != 4 && $num != 5 && $num != 6 && $num != 9);
			return @groups ; 
		}
	}
	close($ifh);
}

sub GetResidueNames{
    my ($self,@resObjs) = @_ ; 
	my @ret = (); 
	map { 
	    my $y = defined $_ ? $_->GetName() : $_ ; 
	    push @ret , $y ; 
	    } @resObjs ; 
	return @ret ; 
}

sub GetTypesFromTable{
    my ($self,$nameList,$tableList) = @_ ; 
	my @ret = (); 
	my @l1  = @{$nameList} ; 
	my @l2  = @{$tableList} ; 
	my $cnt = @l1 ; 
	my $cnt1 = @l2 ; 
	die "sizes mismatch $cnt and $cnt1 "  if(scalar(@l1) != scalar(@l2)); 
	my $idx = 0 ;
	while($idx < $cnt){
		my $name = $l1[$idx];
		my $table = $l2[$idx];
		my $t = $table->{$name} or die "type $name not found for cnt $idx and table $table " ;
		push @ret ,  $t;
		$idx++ ;
	}
	return @ret ; 
}
sub GetAtomFromResidueAndTypeList{
    my ($self,$resList,$typeList) = @_ ; 
	my @ret = (); 
	my @l1  = @{$resList} ; 
	my @l2  = @{$typeList} ; 
	my $cnt = @l1 ; 
	die if(scalar(@l1) != scalar(@l2)); 
	my $idx = 0 ;
	while($idx < $cnt){
		my $res = $l1[$idx];
		my $type = $l2[$idx];
		my ($atom) = $self->GetAtomFromResidueAndType($res,$type);
		if(!defined $atom){
			my @l = ();
			return @l ;
		}
		push @ret ,  $atom;
		$idx++ ;
	}
	return @ret ; 
}

sub MatchConfig{
    my ($self,$origname,$anndir,$infile,$grpconfig,$close2activesite) = @_ ; 

	my $residuesclose2activesite = {};
	if($close2activesite){
		 my $annfile = "$anndir/$origname.outconf.annotated";
		 die "$annfile annotate file does not exist" if(! -e $annfile);
		 my (@resnumbers) =  util_Ann2Simple($annfile);
		 foreach my $n (@resnumbers){
		 	print "$n $close2activesite-------- \n";
			my ($resobj,$atom) = $self->GetResidueObjAndCAAtom($n);
			my $list = util_make_list($atom);
			my ($junk,$neigh) = $self->GetNeighbourHoodAtom($list,$close2activesite);
			my $done ; 
			my $doneatoms ; 
			foreach my $a (@{$neigh}){
				my $num = $a->GetResNum();
	            #my ($resobj) = $self->GetResidueIdx($num);
				$residuesclose2activesite->{$num} = 1 ;
			}
		 }
		 $self->{RESIDUESCLOSE2ACTIVESITE} = $residuesclose2activesite ; 
	}

	my $finddistorangle = 0 ; 
    my $ifh = util_read($infile);
    while(<$ifh>){
         if(/^DIST/){
		 	$finddistorangle = 1 ;
	     }
         if(/^ANGLE/){
		 	$finddistorangle = 1 ;
	     }
    }
	close($ifh);
	die "Error: Expected to see DIST or ANGLE in conf file" if(!$finddistorangle);

    ConfigPDB_Init($grpconfig);
	my @groups = $self->GetGroups($infile);
	my @tables = ();
    map { push @tables,  ConfigPDB_Groups($_); } @groups ; 
	my @results = (); 
	my $numIgnored = 0 ; 
	print " Creating dist table with cutoff $CUTOFF\n";
	$self->CreateDistTable();
	if(1){
	     my @trios  = (); 
		 print "Info: Getting the sets of residues which match given groups \n";
		 my $specific = 0 ; 
		 if(@groups == 3){
	          @trios = $self->GetTrio(@tables);
		 }
	     elsif (@groups == 4){
		      @trios = $self->GetQuad(@tables);
		 }
	     elsif (@groups == 5){
		      @trios = $self->GetPent(@tables);
		 }
	     elsif (@groups == 6){
		      @trios = $self->GetHex(@tables);
		 }
	     elsif (@groups == 9){
		      @trios = $self->GetNine(@tables);
		 }
		 else{
		 	die ;
		 }

		 my $numberofresults = @trios ;
		 print "Info : Found $numberofresults number of residues with the given types\n";

         #my $sss = util_write("sss");
		 my $COUNTER = 0 ; 
		 while(@trios){
		 	$COUNTER++ ;
		 	my $result = {};
		     my $l = shift @trios ; 
			 ($result->{A} , $result->{B}, $result->{C} , $result->{D} , $result->{E}, $result->{F} ,  $result->{G} , $result->{H}, $result->{I} ) = @{$l} ;
			 #print $sss "blue 0 $result->{A}  $result->{B} $result->{C} $result->{D} \n";
			 

			 ## do a quick elimination 
			 if($self->IgnoreIfAnyAreFurtherThanCutoff($CUTOFF,$result->{A} , $result->{B}, $result->{C} )){
			 	 $numIgnored++;
				 next ;
			 }

	         my (@resObjs) = $self->GetResidueIndices(@{$l});
	         my (@names) = $self->GetResidueNames(@resObjs);
	         my (@types) = $self->GetTypesFromTable(\@names,\@tables);
		     my (@atoms) = $self->GetAtomFromResidueAndTypeList($l,\@types);
	         next if(!@atoms);
		     my ($score,$absscore) = $self->ScoreGivenSet($infile,@atoms,$result);
			 ($result->{TA} , $result->{TB}, $result->{TC} , $result->{TD} , $result->{TE}, $result->{TF} ,  $result->{TG} , $result->{TH}, $result->{TI} ) = @types ; 
	         $result->{SCORE} = $score ;
	         $result->{ABSSCORE} = $absscore;
			 push @results, $result ;
			 if($COUNTER > $MAXNUMBEROFRESULTS){
		          print "Stopping after $MAXNUMBEROFRESULTS, " ;
				  last ;
			 }
		 }
		 print "\n";
	}
	print "Ignored $numIgnored residues as they were greater than cutoff $CUTOFF\n";

	my $number = 0 ; 
	print "\n\n ===== printing $MAXRESULTS results \n";
	my @resultssorted = sort { $a->{SCORE} <=> $b->{SCORE} } @results ; 
	my $done = {};
	foreach my $result (@resultssorted){
	    my (@residueIndices) = ($result->{A},$result->{B},$result->{C},$result->{D},$result->{E},$result->{F},$result->{G},$result->{H},$result->{I});

		my $XXX = "";
		$XXX = $XXX . $result->{A} if(defined $result->{A});
		$XXX = $XXX . $result->{B} if(defined $result->{B});
		$XXX = $XXX . $result->{C} if(defined $result->{C});
		$XXX = $XXX . $result->{D} if(defined $result->{D});
		$XXX = $XXX . $result->{E} if(defined $result->{E});
		$XXX = $XXX . $result->{F} if(defined $result->{F});
		$XXX = $XXX . $result->{G} if(defined $result->{G});
		$XXX = $XXX . $result->{H} if(defined $result->{H});
		$XXX = $XXX . $result->{I} if(defined $result->{I});

		next if(exists $done->{$XXX});
		$done->{$XXX} = 1 ; 

	    my (@residues) = $self->GetResidueIndices($result->{A},$result->{B},$result->{C},$result->{D},$result->{E},$result->{F},
		                                                    $result->{G},$result->{H},$result->{I});


		### make it 1 when you want ordered -  just like for MBL and SBL
		## ensure that the input query is ordered too..
		if($ORDERRESIDUES){
		my $previous;
		my $ignore = 0 ;
        foreach my $r (@residues){
			next if(!defined $r);
			my $idx = $r->GetIdx();
			$previous = $idx if(!defined $previous);
			if($previous > $idx){
				$ignore = 1 ;
				last ;
			}
			else{
				$previous = $idx ;
			}
		}
		next if($ignore);
		}

	    my (@types) = ($result->{TA},$result->{TB},$result->{TC},$result->{TD},$result->{TE},$result->{TF},$result->{TG} , $result->{TH}, $result->{TI});
		$self->PrintResults("\n#RESULT $number  SCORE - ABSSCORE = $result->{ABSSCORE} , $result->{SCORE}   ");
		#map { print " dist diff :$_ \n"; } @{$result->{DISTDIFF}

        my @distances ;
        my @printinfo ; 
		my $count = @residues ;
	    my (@names)   = $self->GetResidueNames(@residues);
	    my $cnt = 0 ; 
		while($cnt < $count){
			my $r = $residueIndices[$cnt];
			my $t = $types[$cnt];
			my $nm = $names[$cnt];
			push @distances, "$r/$t" if(defined $r);
			push @printinfo, "$nm/$r/$t" if(defined $r);
		 	$cnt++ ;
		}
        my $diststr = util_AddBeforeEach("-dist",@distances);


        my @res ;
	    $cnt = 0 ; 
		while($cnt < $count){
			my $r = $residueIndices[$cnt];
			my $nm = $names[$cnt];
			push @res, "$r$nm" if(defined $r);
			$cnt++ ;
		}
        my $resstr = util_AddBeforeEach("-expr",@res);
        my $printstr = "#" . util_AddBeforeEach(" ",@printinfo);
		$self->PrintResults($printstr);

		my $pymolnm = "pymol.p1m";
	    my $exec = "pymol.residues.pl -out $pymolnm -pdb1 ".  $self->{NAME} . " $diststr $resstr\n";
	    $self->RunPymol($exec,0);

		$number++;
		last if($number >= $MAXRESULTS);
	}
}
	


sub ReadConfigAndThenWriteValues{
    my ($self,$infile,$outfile,$grpconfig) = @_ ; 
    ConfigPDB_Init($grpconfig);
    my $ifh = util_read($infile);
    my $ofh = util_write($outfile);
	my @groups = $self->GetGroups($infile);
    ConfigPDB_Verify(@groups);

	my @retatoms ;
    
    my $IDS = {} ; 
    my @distances ;
    my @residues ;
	my $ndist = 0;
	my $npoints = 0 ; 
    while(<$ifh>){
         next if(/^\s*$/);
	     next if(/^\s*#/); 
         chomp ;
	     if(/^POINTS/){
	 	    my (@points) = split ; 
		    shift @points ; ## get rid of points 
			$npoints = @points ; 
		    my $cnt = 0 ; 
		    foreach my $point (@points){
			    my ($resnum,$checkResname) = split "/", $point;
				my ($res) = $self->GetResidueIdx($resnum);
				my $nm = $res->GetName();
				die " Check for resname failed for resnum $resnum for $checkResname : got $nm " if($checkResname ne $res->GetName());
				my $type = ConfigPDB_GetAtom($res->GetName()) or die;
			    my ($atom) = $self->GetAtomFromResidueAndType($resnum,$type);
			    die "Could not find residue and type $resnum and $type" if(!defined $atom); 
				push @retatoms ,$atom ;
			    my $id = $alpha[$cnt++]; 
			    $IDS->{$id} = $atom ; 
			    push @distances, "$resnum/$type" ;
			    push @residues, "$resnum$type";
		    }
		    print $ofh "$_ \n"; ; 
	     }
         elsif(/^DIST/){
		 		$ndist++;
			    my ($junk,$a,$b,$weight) = split ;
			    my $a1 = $IDS->{$a} or die ;
			    my $a2 = $IDS->{$b} or die ;
			    my $d = $self->DistanceAtoms($a1,$a2);
		        print $ofh "DIST $a $b $weight $d \n";
	     }
         elsif(/^ANGLE/){
		 		$ndist++;
			    my ($junk,$a,$b,$c,$weight) = split ;
			    my $a1 = $IDS->{$a} or die ;
			    my $a2 = $IDS->{$b} or die ;
			    my $a3 = $IDS->{$c} or die ;
	            my $angle = $self->AngleBetweenThreeAtoms($a1,$a2,$a3);
		        print $ofh "ANGLE $a $b $c $weight $angle \n";
	     }
		 else{
		    print $ofh "$_ \n"; ; 
		 }
    }

	if(!$ndist){
		my $nPointsIndexed2zero = $npoints -1 ;
		my @l = ();
		foreach my $i (0..$nPointsIndexed2zero){
			push @l, $alpha[$i];
		}
        my $iter = combinations(\@l, 2);
        while (my $c = $iter->next) {
            my @combo = @{$c} ; 
			my ($a,$b) = @combo ; 
			my $weight = 1 ; 

			my $a1 = $IDS->{$a} or die ;
			my $a2 = $IDS->{$b} or die ;
			my $d = $self->DistanceAtoms($a1,$a2);
		    print $ofh "DIST $a $b $weight $d \n";
		}
	}

	close($ifh);
	close($ofh);

    my $diststr = util_AddBeforeEach("-dist",@distances);
    my $resstr = util_AddBeforeEach("-expr",@residues);
	my $pymolnm = "pymol.p1m";
	my $exec = "pymol.residues.pl -out $pymolnm -pdb1 ".  $self->{NAME} . " $diststr $resstr\n";
	$self->RunPymol($exec,0);
	return \@retatoms ;
}

sub ScoreGivenSet{
    my ($self,$infile,@atoms,$result) = @_ ; 
    my $ifh = util_read($infile);

	my $size = @atoms ; 
	#print "SSSSSSSSSSS $size \n";
    
    my $IDS = {} ; 
	my $cnt = 0 ; 
	foreach my $atom (@atoms){
	    my $id = $alpha[$cnt++]; 
	    $IDS->{$id} = $atom ; 
	}

	my $score = 0 ; 
	my $absscore = 0 ; 
	$result->{DISTDIFF} = [];
	$result->{ANGLEDIFF} = [];
    while(<$ifh>){
         next if(/^\s*$/);
         chomp ;
	     next if(/^POINTS/); 
	     next if(/^\s*#/); 

         if(/^DIST/){
			    my ($junk,$a,$b,$weight,$dist) = split ;
			    my $a1 = $IDS->{$a} or die ;
			    my $a2 = $IDS->{$b} or die  "$b not found in IDS \n" ;
			    my $d = $self->DistanceAtoms($a1,$a2);

				my $signeddiff = ($d - $dist) ;
				my $absdiff = abs($d - $dist) ;
				$absscore+=$absdiff ;
				##my $absdiffnormalized = 10*$absdiff/($dist*$size) ;
				my $absdiffnormalized = $absdiff/($dist*$size) ;
				#my $absdiffnormalized = $absdiff;
				my $scalefactor = 1 ;

				my $whichone = $signeddiff > 0 ? $MAXALLOWEDDISTDEVIATIONPOS : $MAXALLOWEDDISTDEVIATIONNEG ; 
				$scalefactor = $SCALEFACTOR if($absdiff > $whichone);


		        my $diff = $weight*$absdiffnormalized*$scalefactor ;

				#print " for $a $b doing  $weight*(abs($d - $dist)) \n";
		        my $str = "$diff = $weight*(($d - $dist)) ";
	            push @{$result->{DISTDIFF}},$str ; 
				#print " dist = $diff \n";
				$score+=$diff ;
	     }
         if(/^ANGLE/){
			    my ($junk,$a,$b,$c,$weight,$angle) = split ;
			    my $a1 = $IDS->{$a} or die ;
			    my $a2 = $IDS->{$b} or die ;
			    my $a3 = $IDS->{$c} or die ;
	            my $angleCurrent = $self->AngleBetweenThreeAtoms($a1,$a2,$a3);
		        my $diff = $weight*(abs($angleCurrent - $angle));
		        my $str = "$weight*(($angleCurrent - $angle)) ";
	            push @{$result->{ANGLEDIFF}},$str ; 
				#print " angle = $diff \n";
				$score+=$diff ;
	     }
    }
	#print " Score = $score \n";

	close($ifh);
	$result->{SCORE} = $score ; 
	$result->{ABSSCORE} = $absscore ; 
	return ($score,$absscore) ;
}

sub GetWeights{
    my ($self,$infile) = @_ ; 
    my $ifh = util_read($infile);

	my @weights ;
    while(<$ifh>){
         next if(/^\s*$/);
         chomp ;
	     next if(/^POINTS/); 
	     next if(/^\s*#/); 

         if(/^DIST/){
			    my ($junk,$a,$b,$weight,$dist) = split ;
				push @weights,$weight;
	     }
    }
	return (@weights);
}

sub GetActiveResidues{
    my ($self,$infile) = @_ ; 
    my $ifh = util_read($infile);

	my @retatoms ;
    while(<$ifh>){
         next if(/^\s*$/);
         chomp ;
	     if(/^POINTS/){
	 	    my (@points) = split ; 
		    shift @points ; ## get rid of points 
			my $npoints = @points ; 
		    my $cnt = 0 ; 
		    foreach my $point (@points){
			    my ($resnum,$checkResname) = split "/", $point;
				my ($res) = $self->GetResidueIdx($resnum);
				my $nm = $res->GetName();
				die " Check for resname failed for resnum $resnum for $checkResname : got $nm " if($checkResname ne $res->GetName());
				my $type = ConfigPDB_GetAtom($res->GetName()) or die;
			    my ($atom) = $self->GetAtomFromResidueAndType($resnum,$type);
			    die "Could not find residue and type $resnum and $type" if(!defined $atom); 
				push @retatoms ,$atom ;
		    }
	     }
	}
	return \@retatoms ;
}


sub ScoreGivenSetOfAtom{
    my ($self,$atoms1,$threshold) = @_ ; 
	my @atoms1 = @{$atoms1};
	my $size1 = @atoms1 ;
    my $iter1 = combinations(\@atoms1, 2);

    my @l ; 
    while (my $c1 = $iter1->next) {
        my @combo1 = @{$c1} ; 
		my ($a11) = $combo1[0];
		my ($a12) = $combo1[1];
 
	    my $d1 = $self->DistanceAtoms($a11,$a12);
		if(defined $threshold){
			my @jj ; 
		    return @jj if($d1 > $threshold);
		}
	 	push @l, $d1 ;

	}

	return @l ;
}

sub ScoreGivenSetOfAtoms{
    my ($self,$pdb2,$atoms1,$atoms2) = @_ ; 
	my @atoms1 = @{$atoms1};
	my $size1 = @atoms1 ;
    my $iter1 = combinations(\@atoms1, 2);
	my @atoms2 = @{$atoms2};
	my $size2 = @atoms2 ;
    my $iter2 = combinations(\@atoms2, 2);
	my $absscore = 0 ; 
	my $normalizedSum = 0 ; 

	die if($size1 != $size2);
    while (my $c1 = $iter1->next) {
        my @combo1 = @{$c1} ; 
		my ($a11) = $combo1[0];
		my ($a12) = $combo1[1];
 
        my $c2 = $iter2->next;
        my @combo2 = @{$c2} ; 
		my ($a21) = $combo2[0];
		my ($a22) = $combo2[1];


	    my $d1 = $self->DistanceAtoms($a11,$a12);
	    my $d2 = $pdb2->DistanceAtoms($a21,$a22);

	    my $absdiff = abs($d1 - $d2) ;
		$absscore+=$absdiff ;
	}

	return ($absscore,$absscore/$size1);
}


sub RunPymol{
    my ($self,$exec,$dontrunpymol) = @_ ; 
	#print "$exec \n";

	print $GLOBLOGFILE "$exec \n" if(!defined $dontrunpymol);
	print $GLOBLOGFILE "set ttttt=\$\<\n" if(!defined $dontrunpymol);

	my @l = `$exec` if(!defined $dontrunpymol) ;
	print @l  if(!defined $dontrunpymol) ;

}

sub IgnoreIfAnyAreFurtherThanCutoff{
	my ($self,$cutoff,@l) = @_ ; 
    my $iter = combinations(\@l, 2);
    while (my $c = $iter->next) {
        my @combo = @{$c} ; 
		my ($atom1) = $self->GetAtomFromResidueAndType($combo[0],"CA");
		my ($atom2) = $self->GetAtomFromResidueAndType($combo[1],"CA");
		if(!defined ($atom1 && $atom2)){
			warn " CA not defined for either $combo[0] or $combo[1] \n";
			return 1 ; 
		}
		my $d = $atom1->Distance($atom2) ;
		if($d > $cutoff){
			#print " will ignore as dist $d greater than $cutoff \n";
			return 1 ; 
		}
	}
	return 0 ;
}

sub MoveAtomsAlongAxis{
	my ($self,$which,$amount,$atoms) =@_ ; 
	my @l ; 
	if(defined $atoms){
		@l = @{$atoms} ;
	}
	else{
	    @l = @{$self->{ATOMS}} ;
	}
	die if($which ne "X" && $which ne "Y" && $which ne "Z");

	foreach my $a (@l){
	    my ($p,$q,$r) = $a->Coords();
		$p = $p + $amount  if($which eq "X");
		$q = $q + $amount  if($which eq "Y");
		$r = $p + $amount  if($which eq "Z");
	    $a->SetCoords($p ,$q,$r);
	}
}


############################
#### Geom Transforms starts #######
############################

sub MoveOriginToAtom{
	my ($self,$atom,$atoms) =@_ ; 
	my ($x,$y,$z) = $atom->Coords();
	$self->MoveOriginToPoint($x,$y,$z,$atoms);
}


sub MoveOriginToPoint{
	my ($self,$x,$y,$z,$atoms) =@_ ; 
	my @l ; 
	if(defined $atoms){
		@l = @{$atoms} ;
	}
	else{
	    @l = @{$self->{ATOMS}} ;
	}
	foreach my $a (@l){
	    my ($p,$q,$r) = $a->Coords();
		if(!defined $p){
		    die if(! $a->IsTer());
			$p = $q = $r = 0 ;
		}
	    $a->SetCoords($p -$x ,$q - $y,$r -$z);
	}
}

sub MakeVector{
	my ($self,$a1) =@_ ; 
	my ($x,$y,$z) = $a1->Coords();
	#print "coord = $x $y $z \n";
	my $v1 = vector($x,$y,$z);
	#print 'length     => ', $v1->length, "\n";
	return $v1 ;
}

sub MakePlane{
	my ($self,$a1,$a2,$a3) =@_ ; 

	my $v1 = $self->MakeVector($a1);
	my $v2 = $self->MakeVector($a2);
	my $v3 = $self->MakeVector($a3);

	my ($newX,$d) = plane( $v1, $v2 , $v3  );
	my ($newY) = $v2->norm ;
	my ($newZ) = $newX x $newY  ;

}


sub ApplyRotationMatrix{
	my ($self,$R,$list) = @_ ; 
	croak "Expected some atoms: $R " if(!defined $list);
	my $N = @{$list};
	croak "Expected some atoms: got $N" if(!$N);
	foreach my $a (@{$list}){
	    my $v = $self->MakeVector($a);
		my $newA = $v * $R ;
	    $a->SetCoords($newA->x(),$newA->y(),$newA->z());
	}
}

sub AlignXto2Atoms{
	my ($self,$a,$b) = @_ ; 
    my ($newX,$newY,$newZ) = $self->AlignXto2AtomsInSet($a,$b,$self->{ATOMS});
	return ($newX,$newY,$newZ);
}

sub AlignXto2AtomsInSet{
	my ($self,$a,$b,$list) = @_ ; 
	croak "Expected some atoms: " if(!defined $list);
	$self->MoveOriginToAtom($a);
	my $vector = $self->MakeVector($b);
    my ($newvec,$R,$rotMatrix1,$rotMatrix2,$newX,$newY,$newZ)= MyGeom::geom_AlignXaxis2Vector($vector);

    $self->ApplyRotationMatrix($R,$list);
	return ($newX,$newY,$newZ);
}

sub ParseResultLine{
	my ($self,$line) = @_ ; 
    #print "Parse line $line\n";
	$line =~ s/#//g;
	$line =~ s/-//g;
	my @atomnames = split " ",$line ;
	my @atoms ; 
	#shift @atomnames ;
	#shift @atomnames ;
	#shift @atomnames ;
	foreach my $a (@atomnames){
		push @atoms, $self->ParseAtomLine($a);
	}
	return \@atoms ;

}

sub ParseAtomLine{
	my ($self,$atom) = @_ ; 
    my ($res,$num,$type) = split "/", $atom ;
	#print "$res,$num,$type\n";
	my ($a) = $self->GetAtomFromResidueAndType($num,$type) or die ;
	die "could not find atom with num $num and type $type " if(!defined $a);
	#$a->Print();
	return $a ;
}
						

sub DistanceMatrix{
	my ($self) = @_ ;
	print "Making Distance Matrix \n";
	my @atoms = @{$self->{ATOMS}} ;
	my @rows ;
	while(@atoms){
		my $a = shift @atoms ;
		next if($a->IsTer());
		my @row = ();
	    foreach my $b (@atoms){
		    next if($b->IsTer());
	        my $dist = $self->DistanceAtoms($a,$b);
			push @row , $dist ;
	    }
		push @rows, \@row ;
	}
	return \@rows ;
}

sub VerifyDistanceMatices{
	my ($self,$row1,$row2) = @_ ;
	my @rows1 = @{$row1} ;
	my @rows2 = @{$row2} ;
	my $equal = 1 ;
	while(@rows1){
		my $r1 = shift @rows1 ;
		my $r2 = shift @rows2 ;

		my @r1 = @{$r1};
		my @r2 = @{$r2};
	    while(@r1){
		    my $a = shift @r1 ;
		    my $b = shift @r2 ;
			if(! geom_IsZero($a-$b)){
				print "Different $a $b \n";
				die "PDBS are different \n";
				return 0 ;
			}
	    }
	}
	return 1 ;
}

############################
#### Geom Transforms ends #######
############################

## done only on pqr 
sub InsertAtom{
	my ($self,$line) = @_ ;
	$line = $line . "\n";
	push @{$self->{ADDEDATOMS}},$line ;
}

sub NeighbouringResiduesofAtom{
	my ($self,$atom,$atomorig,$n) = @_ ;
	my $resnum = $atom->GetResNum();
	return $self->NeighbouringResiduesofResidue($resnum,$n);
}

sub NeighbouringResiduesofResidue{
	my ($self,$resnum,$n) = @_ ;
	my $found = 0 ; 
	my $cnt = 0 ; 
	my @l = 0 ; 
	my @origl = 0 ; 
	my @results ; 
	foreach my $residue (@{$self->{RESIDUES}}){
		if($resnum == $residue->GetResNum()){
			$found = 1 ; 
			my $len = @l ; 
			my $d = $len - $n ; 
			while($d--){
				shift @l ; 
				shift @origl ; 
			}
			my $remlen = @l ; 
			#print "Nrw thtere are $remlen \n";

		}

		push @l, $residue ;
		push @origl, $residue ;
		if($found){
		   $cnt++;
		}
		last if($cnt > $n);
	}
	my $remlen = @l ; 
	#print "last thtere are $remlen \n";
	return \@l ;
}

sub GetSingleLetter{
    my ($self,$name) = @_ ;
	$name = uc($name);
    my $x = $self->{THREE2SINGLE}->{$name} ;
    if(!defined $x){
        print STDERR "Undefined for $name\n";
        return "?";
    }
    return $x;
}
sub GetThreeLetter{
    my ($self,$name) = @_ ;
    my $x = $self->{SINGLE2THREE}->{$name} ;
    if(!defined $x){
        print STDERR "Undefined for $name\n";
        return "?";
    }
    return $x;
}


sub DistanceInGivenSetOfAtoms{
    my ($self,$atoms1) = @_ ; 
	my @atoms1 = @{$atoms1};
	my $size1 = @atoms1 ;
    my $iter1 = combinations(\@atoms1, 2);
	my @l ; 
    while (my $c1 = $iter1->next) {
        my @combo1 = @{$c1} ; 
		my ($a11) = $combo1[0];
		my ($a12) = $combo1[1];
 
	    my $d1 = $self->DistanceAtoms($a11,$a12);
		push @l, $d1 ;
	}

	return \@l ;
}

sub PotInGivenSetOfAtoms{
    my ($self,$atoms1,$pqr1,$pots1) = @_ ; 
	my @atoms1 = @{$atoms1};
	my $size1 = @atoms1 ;
    my $iter1 = combinations(\@atoms1, 2);
	my @l ; 
    while (my $c1 = $iter1->next) {
        my @combo1 = @{$c1} ; 
		my ($a11) = $combo1[0];
		my ($a12) = $combo1[1];
 
        my $pot1 = util_GetPotForAtom($a11,$pqr1,$pots1) ;
        my $pot2 = util_GetPotForAtom($a12,$pqr1,$pots1) ;
		my $d1 = util_format_float($pot1 - $pot2,1);
		push @l, $d1 ;
	}

	return \@l ;
}

sub ParseResultsFile{
   my ($self,$resultfile,$n) = @_;
   return ConfigPDB_ParseResultsFile ($resultfile,$n);
}

sub ProcessMetalIon{
   my ($self,$metal,$cutoff) = @_;
   	my @typeofatom = ();
	my $return = {};
	foreach my $r (@{$self->{RESIDUES}}){
		my $type = $r->GetName();
		if($type =~ /$metal/i){
	        print "=================================\n";
			my @listofatomsclose; 
			my $origNum = $r->GetResNum();
			my @atoms = $r->GetAtoms();

			## there is only atom for metals
			my $atom = shift @atoms ;
			$r->Print();
			$atom->Print();

			my $list = util_make_list($atom);
			my ($junk,$neigh) = $self->GetNeighbourHoodAtom($list,$cutoff);
			my $done ; 
			my $doneatoms ; 
			foreach my $a (@{$neigh}){
				my $num = $a->GetResNum();
				my $nm = $a->GetName();
				#next if($nm =~ /HOH/);
				next if ($num eq $origNum);
				if(! exists $done->{$num}) {
				    push @listofatomsclose , $num ;
				    $a->Print();
				    my $d = $self->DistanceAtoms($atom,$a);
				    $done->{$num} = $d ;
				    $doneatoms->{$a->GetIdx()} = $d ;
				    print " $num dist =$d \n";
				}
			}
			my $str = join ",", @listofatomsclose;
			print " select active1, (resi  $str and chain A) \n";

			$return->{$r} = $doneatoms ;


		}
	}
	return $return ;
}

sub ReplaceType{
   my ($self,$resnum,$newtype) = @_;
   $self->{REPLACENAME}->{$resnum} = $newtype ;
   my $r1 = $self->GetResidueIdx($resnum);
   $r1->SetName($newtype);
}
sub JustResNum{
   my ($self,$resnum) = @_;
   $self->{JUSTRESNUM}= $resnum ;
}
sub ChargeZero{
   my ($self,$resnum) = @_;
   $self->{READCHARGE}= $resnum ;
}
sub util_getECID{
	my ($ec,$level) = @_ ; 
	$ec =~ s/\./YYY/g ; 
	my @l = split "YYY",$ec ; 
	my $str = "";
	my $first = 1 ; 
	foreach my $i (1..$level){
		if(!$first){
			$str = $str . ".";
		}
		$str = $str . $l[$i -1];
		$first = 0 ; 
	}
	return $str ; 
}

sub GetPotential{
	my ($self,$pqr,$idx,$pots) = @_ ; 
	my $a = $self->GetAtomIdx($idx);
	my $resnum = $a->GetResNum();
	my $atomnm = $a->GetType();
	my @pots = @{$pots};
    ($a) = $self->GetAtomFromResidueAndType($resnum,$atomnm);
    my ($aPqr) = $pqr->GetAtomFromResidueAndType($resnum,$atomnm) or croak "pqr did not get atomnm" ;
	die "Did not find aPqr " if(! defined $aPqr);
    my ($i1) = $a->GetIdx();
    my ($i2) = $aPqr->GetIdx();
    #imp -1 
    my $pot = $pots[$i2-1] or die "Expected to find potential";
	$pot = int($pot);
	return $pot ; 
           
}

sub SaveCoords{
	my ($self,$atoms) = @_ ; 
	my @l ; 
	if(defined $atoms){
		@l = @{$atoms} ;
	}
	else{
	    @l = @{$self->{ATOMS}} ;
	}
	my $table = {};
    foreach my $a (@l){
	   my @coord = $a->Coords();
	   $table->{$a} = \@coord ;
    }
	return $table ; 
}

sub RestoreCoords{
	my ($self,$table,$atoms) = @_ ; 
	my @l ; 
	if(defined $atoms){
		@l = @{$atoms} ;
	}
	else{
	    @l = @{$self->{ATOMS}} ;
	}
    foreach my $a (@l){
	   if(!exists $table->{$a}){
	   		$a->Print();
	        die "Died since $a does not exist" ;
	   }
	   my $c = $table->{$a} ; 
	   $a->SetCoords(@{$c});
    }
}

sub IsPathClear{
	my ($self,$A,$B,$allatoms,$pseudoatom,$del,$D) = @_ ; 
	my $savedcoords = $self->SaveCoords($allatoms);
	$self->AlignXto2AtomsInSet($A,$B,$allatoms);
	#$A->Print();
	#$B->Print();
	my ($BX,$BY,$BZ) = $B->Coords();

	while($del < $BX){
	     $pseudoatom->SetCoords($del,0,0);
	     my @list ;
	     my $list = util_make_list($pseudoatom);
	     my ($junk,$neigh)  = $self->GetNeighbourHoodAtomInSet($list,$allatoms,$D);
		 my @l = @{$neigh};
		 #my $N = @l ;
		 #print STDERR "There are $N atoms close by \n";
	     foreach my $a (@{$neigh}){
		 	 next if($a eq $A || $a eq $B);
			 my $DIST = $self->DistanceAtoms($pseudoatom,$a);
	         $self->RestoreCoords($savedcoords,$allatoms);
	         #print "Close to dist $D for atom $a at del = $del\n" ;
			 return (0,$a,$del,$DIST);
		 }
		 $del = $del + $del ; 
	}
		 

	$self->RestoreCoords($savedcoords,$allatoms);
	#$A->Print();
	#$B->Print();
	return (1,0,0);
}


sub GetPseudoAtom{
	my ($self) = @_; 
	my $atom = new Atom();
	my $res = $self->{PSEUDORESIDUE} ; 
	my $atomnm = "YYY";
	my $serialnum = $self->{PSEUDOATOMCNT} ; 
	$self->{PSEUDOATOMCNT}  =  $self->{PSEUDOATOMCNT} + 1 ; 
	$atom->SetValues($serialnum,$atomnm,$res->GetName(),$res->GetIdx(),0,0,0);
	$self->AddAtom($res,$atom) ; 
	return $atom ;
}

sub GetReactiveAtomFromAtom{
	my ($self,$a) = @_; 
    my $num = $a->GetResNum();
	my ($res) = $self->GetResidueIdx($num);
	my $reactivetype = ConfigPDB_GetAtom($res->GetName()) or die;
	my $reactiveatom = $self->GetAtomFromResidueAndType($num,$reactivetype);
	my $origtype = $a->GetType();
	return ($num,$res,$origtype,$reactiveatom,$reactivetype);
}



sub Mutate{
	my ($self,$mutatefile) = @_; 
    my $ifh = util_read($mutatefile);
    while(<$ifh>){
         next if(/^\s*$/);
		 my ($a,$b) = split ;
		 my ($ra) = ($a =~ /(...)/);
		 my ($rb,$n) = ($b =~ /(...)(\d*)/);
		 print "$ra $rb $n \n";
	     my ($res) = $self->GetResidueIdx($n);
		 my $nm = $res->GetName();
		 die "Expect $nm and $rb to be the same" if(!($nm eq $rb));
		 $res->SetName($ra);
	}
}

sub PrintSortedFasta{
      my ($self,$origpdb,$allres) = @_ ;
      my $fastafh = util_write("$origpdb.fasta");
      my $s2 = "";
      my $s1 = "";
	  my $N  = 0 ; 
      foreach my $i (sort  { $a <=> $b }  keys %{$allres}){
	      my $r = $allres->{$i} ; 
	      my $s = $r->PrintSingleLetter($self);
		  $N++ if($s ne "");
	      $s1 = $s1 .  "$s$i," ;
	      $s2 = $s2 . "$s" ;
      }
      print $fastafh "\>$origpdb.$s1; number=$N\n";
      print $fastafh "$s2\n";
}


sub GetResidueObjAndCAAtom{
	my ($self,$resnum) = @_ ;
	my ($res) = $self->GetResidueIdx($resnum);
	my $atom = $res->GetAtomType("CA");
	die "Could not find residue and type $resnum " if(!defined $atom); 
	return ($res,$atom);
}
