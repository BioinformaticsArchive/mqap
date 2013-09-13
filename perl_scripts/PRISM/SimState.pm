
package SimState;
use MyUtils;
use PDB;
use Atom;
use Residue;
use MyGeom;
require Exporter;
use ConfigPDB;
use SimNode;
@ISA = qw(Exporter );
#@EXPORT = qw($fields);

use strict ;
use Carp ;
use FileHandle ;
use Getopt::Long;
use vars qw($AUTOLOAD);
use Getopt::Long;
use File::Basename;

my $MINDIST = 1 ; 
my $PRINTTABLE = 0 ; 
my $SIMMAXSTEP = 100 ; 
my $statesseen = {};

my $fields = {
    POTS => undef, 
    PDB => undef, 
    INDICES => undef, 
    SIMNODES => undef, 
    PATH => undef, 
    ATOMIDX => undef, 
    CONFIG => undef, 
    DONORS => undef, 
    CNT => undef, 
};

sub new{
    my $that = shift ; 
    my $class = ref($that) || $that ;
	my ($indices,$simnodes,$pdb,$pqr,$pots,$idx,$config) = @_ ; 

    my $self = {} ; 
    map { $self->{$_} = undef ; } (keys %{$fields});

#################### CAREFUL to add to copy constructor if you add here !!!!!!
	if(defined $indices){
	     $self->{PDB} = $pdb ;
	     $self->{PATH} = [];
	     $self->{INDICES} = $indices;
	     $self->{SIMNODES} = $simnodes;
	     $self->{ATOMIDX} = $idx;
	     $self->{CONFIG} = $config;
	     $self->{CNT} = 0;

	     $self->{POTS} = {};
	     $self->{DONORS} = {};
         vprintheader("Created new SimState object $self");
	     foreach my $idx (keys %{$indices}){
		     my $p = $pdb->GetPotential($pqr,$idx,$pots);
	         my $nm = $pdb->GetAtomIdx($idx)->GetName();
		     vprint("\tSetting potential diff of $nm to $p");
	         $self->{POTS}->{$idx} = $p ;
	         $self->{DONORS}->{$idx} = 1 ; 
	     }
	}
	else{
         vprint("\tCopied new SimState object $self");
	}

    bless $self, $class ; 
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

sub AddSimNode2Path{
	my ($self,$idx,$b) = @_ ; 
	push @{$self->{PATH}}, $idx ;
	push @{$self->{PATH}}, $b ;
}

sub GetPot{
	my ($self,$idx) = @_ ; 
	die "not defined idx" if(!defined $idx);
	die "Potential not found for $idx" if(! exists $self->{POTS}->{$idx});
	return $self->{POTS}->{$idx} ; 
}

sub GetPDB{
	my ($self) = @_ ; 
	return $self->{PDB}; 
}

sub SetPot{
	my ($self,$idx,$pot) = @_ ; 
	$self->{POTS}->{$idx} = $pot ; 
}


sub Step{
	my ($self,$cnt) = @_ ; 

    #print STDERR  "calling step $cnt\n";
	my @newstates ;
	my @endstates ;
	my $retstatus = 0 ; 
	my $validmoves ={} ;
	my $nm = $self->GetAtomName($self->{ATOMIDX});
	my $state = $self->GetState();
	if($statesseen->{$state} || $cnt > $SIMMAXSTEP ){
		if($cnt > $SIMMAXSTEP){
			print "Number of steps crossed SIMMAXSTEP $SIMMAXSTEP \n";
		}
		vprint("Seen state $state");
	    return ($retstatus,\@newstates,\@endstates,$cnt) ;
	}
	$cnt++;

	$statesseen->{$state} = 1 ;
	my $NNodes = keys %{$self->{SIMNODES}} ; 
	vprintheader("Sim Step for $self with state $state and nodes $NNodes");
	$self->PrintPOTS();

	### foreach node, check if there are valid moves possible 
	### it is assumed that the current state is not the final state.
	$self->MoveFromAllSimNodes($validmoves);
	#$self->MoveFromLastSimNode($validmoves);

	if(!keys %{$validmoves}){
	        vSetVerbose(2);
			vprint("no valid moves");
	        vSetVerbose(3);
	}
	else {
		###  for each possible move, make the move - and check whether final state 
		###  has been reached
		###  else this is now a new simtree
	    foreach my $idx (keys %{$validmoves}){
		    my @validmoves = @{$validmoves->{$idx}} ;
	        my $nm = $self->GetAtomName($idx);

	        vSetVerbose(2);
			vprint("moves for $nm");
	        vSetVerbose(3);

			my $sumpot = 0 ; 
			my $CNT  = 0 ;
			print_pdb("red",10000,$self->GetPDB(),$self->{ATOMIDX});
			print_pdb("green",$CNT,$self->GetPDB(),$idx);
			my @resnn  ;
			my @pots  ;
			my @dist  ;
			my @goodones  ;
		    foreach my $v (@validmoves){

				## stop looping
			    my $nn = $self->GetAtomName($v);

				next if($self->IsReverseStep($idx,$v));
				next if($self->Alreadydonated($idx));
				next if($self->AlreadyAccepted($v));

		        my $pa = $self->GetPot($idx);
		        my $pb = $self->GetPot($v);
		        my $diff = $pa - $pb ; 
				$sumpot = $sumpot + $diff ; 
				$CNT++;
				print_pdb("yellow",$CNT,$self->GetPDB(),$v);
	            my $targetnm = $self->GetAtomName($v);

	            my $d1 = util_format_float($self->GetPDB()->DistanceAtomsIdx($idx,$v),1);
				push @resnn , $targetnm ; 
				push @goodones , $v ; 
				push @pots , $diff ; 
				push @dist , $d1 ; 
				
	            my $simnodeA = $self->{SIMNODES}->{$idx};
	            my $water = $simnodeA->IsCloseByWater($v);
				next if(!$self->{CONFIG}->IsProtonMoveValid($idx,$v,$diff,$water));

	            $retstatus = 1 ; 

			    my $newsim = $self->Copy();
	            $newsim->AdjustMove($idx,$v);
	            my @l = @{$self->{PATH}} ;
	            my $N = @{$self->{PATH}} ;
				if($newsim->ReachedFinalState()){
					 vprint("Reached final state -- YAAAAAAAAAAAHOOOOOOOOOOO");
			         push @endstates,$newsim ; 
				}
				elsif($N && $v == $l[0]){
					 vprint("cycled back -- AAARRRGGGGHHH ");
				}
				else{
			         push @newstates,$newsim ; 
				}
		    }


			if($CNT){
			   my $MEAN = $sumpot/$CNT ; 
			   vprint("moves for $nm has mean $MEAN and cnt = $CNT and retstatus = $retstatus, and idx = $idx ");
			   if($PRINTTABLE){
			       $, = " , " ; 
			       print STDERR @resnn , "\n";
			       print STDERR @pots , "\n";
			       print STDERR @dist , "\n";
			   }

			   #if(!$retstatus){
			   if(1){
			   	   if($MEAN > 100 && $idx eq 0 ){
			           my $newsim = $self->Copy();
	                   $newsim->AdjustMoveToMany($idx,@goodones);
	                   my @l = @{$self->{PATH}} ;
	                   my $N = @{$self->{PATH}} ;
				       if($newsim->ReachedFinalState()){
					   		die "Cant reach final state this way";
				       }
				       else{
			                push @newstates,$newsim ; 
				       }
				   }
			   }
			}



		}

	}

	foreach my $s (@newstates){
		my ($a,$b,$c); 
		($a,$b,$c,$cnt) = $s->Step($cnt);
		push @endstates,@{$c}; 
	}

	return ($retstatus,\@newstates,\@endstates,$cnt) ;
}


sub AdjustMove{
	my ($self,$a,$b) = @_ ; 
	my $simnode = $self->{SIMNODES}->{$a};
	my $water = $simnode->IsCloseByWater($b);
	$self->{CONFIG}->AdjustMove($self,$a,$b,$water);

	$self->{DONORS}->{$a} = $self->{DONORS}->{$a} - 1 ;
	$self->{DONORS}->{$b} = $self->{DONORS}->{$b} + 1 ;

	$self->AddSimNode2Path($a,$b);
	$self->PrintPath();
}

sub AdjustMoveToMany{
	my ($self,$a,@goodones) = @_ ; 
	my $water = 0 ;
	my $pa = $self->GetPot($a);
	my @centrecoords = $self->GetPDB()->GetAtomIdx($a)->Coords();
	vprint ("Before : pa = $pa ");
	my $best = 0 ;
	my $maxdiff = 0 ;
	my $minus = 0 ; 
	my @potdiffs = ();
	my @otherpoints = ();
	foreach my $b (@goodones){
	    $self->SetPot($a, $pa);
		my $pb = $self->GetPot($b);
		my $diff = $pa - $pb ; 

		push @potdiffs,$diff ;
	    my @coords = $self->GetPDB()->GetAtomIdx($b)->Coords();
		push @otherpoints, \@coords;

		if($diff > $maxdiff){
			$maxdiff = $diff ; 
			$best = $b ;
		}
		 next if($b eq $self->{ATOMIDX});
	     #$minus = $minus + $self->{CONFIG}->AdjustMove($self,$a,$b,$water);
	     $minus = $minus + int($diff /2) ;

	     $self->SetPot($a, $pa);
	     $self->SetPot($b, $pb);

	     #$self->{DONORS}->{$a} = $self->{DONORS}->{$a} - 1 ;
     
	}
	$self->SetPot($a, $pa - $minus);
	$pa = $self->GetPot($a);
	vprint ("After : pa = $pa ");
	$self->AddSimNode2Path($a,$best);
	$self->PrintPath();
}

sub MakeVectorCentredOnAtom{
	my ($self,$a,@goodones) = @_ ; 
	my $pa = $self->GetPot($a);
	my @centre = $self->GetPDB()->GetAtomIdx($a)->Coords();
	vprint ("Before : pa = $pa ");
	my @potdiffs = ();
	my @otherpoints = ();
	foreach my $b (@goodones){
	    $self->SetPot($a, $pa);
		my $pb = $self->GetPot($b);
		my $diff = $pa - $pb ; 

		push @potdiffs,$diff ;
	    my @coords = $self->GetPDB()->GetAtomIdx($b)->Coords();
		push @otherpoints, \@coords;
	}
	#Now call 
	AddVectorsAboutaCentre(\@centre,\@otherpoints,\@potdiffs);

}

sub SetPath{
	my ($self,$p) = @_ ; 
	$self->{PATH} = $p ;
}

sub SetIndices{
	my ($self,$p) = @_ ; 
	$self->{INDICES} = $p ;
}
sub SetPots{
	my ($self,$p) = @_ ; 
	$self->{POTS} = $p ;
}
sub SetSimnodes{
	my ($self,$p) = @_ ; 
	$self->{SIMNODES} = $p ;
}
sub SetPDB{
	my ($self,$p) = @_ ; 
	$self->{PDB} = $p ;
}


sub SetAtomIdx{
	my ($self,$p) = @_ ; 
	$self->{ATOMIDX} = $p ;
}

sub SetCONFIG{
	my ($self,$p) = @_ ; 
	$self->{CONFIG} = $p ;
}
sub SetDONORS{
	my ($self,$p) = @_ ; 
	$self->{DONORS} = $p ;
}
sub SetCNT{
	my ($self,$p) = @_ ; 
	$self->{CNT} = $p ;
}
sub Copy{
	my ($self) = @_ ; 
	my $newsimstate = new SimState();

	my @path = @{$self->{PATH}};
	$newsimstate->SetPath(\@path);
	$newsimstate->SetIndices($self->{INDICES});
	$newsimstate->SetAtomIdx($self->{ATOMIDX});
	$newsimstate->SetPDB($self->{PDB});
	$newsimstate->SetCONFIG($self->{CONFIG});
	$newsimstate->SetCNT($self->{CNT});

	my $copyPots = util_copy_table($self->{POTS});
	my $copySimnodes = util_copy_table($self->{SIMNODES});
	my $copyDONORS = util_copy_table($self->{DONORS});
	$newsimstate->SetSimnodes($copySimnodes);
	$newsimstate->SetPots($copyPots);
	$newsimstate->SetDONORS($copyDONORS);

	return $newsimstate ;

}


sub ReachedFinalState{
	my ($self) = @_ ; 
	my $ret = $self->{CONFIG}->ReachedFinalState($self->GetPot($self->{ATOMIDX}));
	return $ret ;
}

sub GetAtomName{
	my ($self,$idx) = @_ ; 
	return  $self->GetPDB()->GetAtomIdx($idx)->GetName();

}

sub Alreadydonated{
	my ($self,$idx) = @_ ; 
	my $x = $self->{DONORS}->{$idx} ; 
	return 1 if($x == 0);
	return 0 ; 
}

sub AlreadyAccepted{
	my ($self,$idx) = @_ ; 
	my $x = $self->{DONORS}->{$idx} ; 
	return 1 if($x == 2);
	return 0 ; 
}

sub IsReverseStep{
	my ($self,$x,$y) = @_ ; 
	my $N = @{$self->{PATH}} ;
	my @l = @{$self->{PATH}} ;
	return 0 if(!$N);
	my $b = $l[$N -1];
	my $a = $l[$N -2];
	return 1 if($x == $b && $y == $a);
	return 0 ;
}

sub PrintPath{
	my ($self) = @_ ; 
	my @l = @{$self->{PATH}} ;
	my $N = @{$self->{PATH}} ;
	return 0 if(!$N);
	vprint("\tPrint path for $self");
    my $retstr = "[";
	my $pqr = $self->{CONFIG}->GetPQR();
	my $origpots = $self->{CONFIG}->GetOrigPots();
	while(@l){
		my $a = shift @l ;
		my $b = shift @l ;
	    my $simnodeA = $self->{SIMNODES}->{$a};
	    my $simnodeB = $self->{SIMNODES}->{$b};
	    my $water = $simnodeA->IsCloseByWater($b);
		my $n1 = $self->GetAtomName($a);
		my $n2 = $self->GetAtomName($b);
	    my $d1 = $self->GetPDB()->DistanceAtomsIdx($a,$b);

		my $origpotA = $self->GetPDB()->GetPotential($pqr,$a,$origpots);
		my $origpotB = $self->GetPDB()->GetPotential($pqr,$b,$origpots);
		my $origdiff = $origpotA - $origpotB ;

		vIncrVerbose();
		## dont put spaces here 
		my $str = "$n1-\$>\$$n2," ;
		vprint("\t$str ($d1 - water = $water potA - potB = $origpotA - $origpotB = diff $origdiff )");
		$retstr = $retstr . $str ;
		vDecrVerbose();
	}
		$retstr = $retstr . "]";
	return $retstr ;
}

sub PrintPOTS{
	my ($self) = @_ ; 
	foreach my $idx (keys %{$self->{INDICES}}){
	         my $nm = $self->GetPDB()->GetAtomIdx($idx)->GetName();
	         my $p = $self->{POTS}->{$idx} ;
		     vprint("potential of $nm is $p");
	}
}

sub LastMove{
	my ($self) = @_ ; 
	my @l = @{$self->{PATH}} ;
	my $N = @{$self->{PATH}} ;
	die "Expected at least one move" if(!$N);
	my $b = $l[$N -1];
	my $a = $l[$N -2];
	my $pa = $self->GetPot($a);
	my $pb = $self->GetPot($b);
	my $ret = "$a.$b.$pa.$pb";
	return ($N,$ret);
}

sub GetState{
	my ($self) = @_ ; 
	my @l = @{$self->{PATH}} ;
	my $N = @{$self->{PATH}} ;
	return 0 if(!$N);
	my @indices = (keys %{$self->{SIMNODES}}) ; 
	$N = @indices -1 ;
	my $str = "";
	foreach my $i (0..$N){
		my $ii = $i + 1 ; 
	    foreach my $j ($ii..$N){
		   my $a = $indices[$i];
		   my $b = $indices[$j];
		   my $pa = $self->GetPot($a);
		   my $pb = $self->GetPot($b);
		   my $diff = $pa - $pb ; 
		   if(abs($diff) < 50){
		   	  $str = $str . "0";
		   }
		   elsif ($diff > 50 ){
		   	  $str =  $str ."1";
		   }
		   else{
		   	  $str =  $str ."2";
		   }
		}
	}
	return $str ; 
}

sub MoveFromAllSimNodes{
	my ($self,$validmoves) = @_ ; 
	print STDERR "MoveFromAllSimNodes \n";
	foreach my $idx (keys %{$self->{SIMNODES}}){
	    my $simnode = $self->{SIMNODES}->{$idx};
		
		## foreach node, check the neighbouring nodes where a move is possible
	    my @validmoves =  $simnode->EvaluateMoves($self,$self->{CONFIG});
		if(@validmoves){
		     $validmoves->{$idx} = \@validmoves;
		}
	}
}

sub MoveFromLastSimNode{
	my ($self,$validmoves) = @_ ; 
	#my ($self,$x,$y) = @_ ; 
	my @l = @{$self->{PATH}} ;
	my $N = @{$self->{PATH}} ;
	if(!$N){
		$self->MoveFromAllSimNodes($validmoves);
		return ;
	}

	my $idx = $l[$N-1];
	my $simnode = $self->{SIMNODES}->{$idx};
		
	my @validmoves =  $simnode->EvaluateMoves($self,$self->{CONFIG});
	if(@validmoves){
	    $validmoves->{$idx} = \@validmoves;
	}
}


sub print_pdb{
my ($color,$idx,$pdb,$atomnum) = @_ ; 
my $resnum =  $pdb->GetAtomIdx($atomnum)->GetResNum();
#vprint("select block_query$idx, /target//A/$resnum");
#vprint("color $color, block_query$idx");
#vprint("show spheres, block_query$idx");
}

