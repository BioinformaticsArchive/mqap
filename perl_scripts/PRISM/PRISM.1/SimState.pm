
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
         vprint("Copied new SimState object $self");
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

	my @newstates ;
	my @endstates ;
	my $retstatus = 0 ; 
	my $validmoves ={} ;
	my $nm = $self->GetAtomName($self->{ATOMIDX});
	my $state = $self->GetState();
	if($statesseen->{$state} || $cnt > 5000 ){
		vprint("Seen state $state");
	    return ($retstatus,\@newstates,\@endstates,$cnt) ;
	}
	$cnt++;

	$statesseen->{$state} = 1 ;
	vprintheader("Sim Step for $self with state $state");
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

		    foreach my $v (@validmoves){
				## stop looping
				next if($self->IsReverseStep($idx,$v));
				next if($self->Alreadydonated($idx));
				next if($self->AlreadyAccepted($v));

		        my $pa = $self->GetPot($idx);
		        my $pb = $self->GetPot($v);
		        my $diff = $pa - $pb ; 
				next if(!$self->{CONFIG}->IsProtonMoveValid($idx,$v,$diff));

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
	vprint("Print path for $self");
    my $retstr = "";
	while(@l){
		my $a = shift @l ;
		my $b = shift @l ;
	    my $simnodeA = $self->{SIMNODES}->{$a};
	    my $simnodeB = $self->{SIMNODES}->{$b};
	    my $water = $simnodeA->IsCloseByWater($b);
		my $n1 = $self->GetAtomName($a);
		my $n2 = $self->GetAtomName($b);
	    my $d1 = $self->GetPDB()->DistanceAtomsIdx($a,$b);

		vIncrVerbose();
		## dont put spaces here 
		my $str = "$n1-->$n2," ;
		vprint("$str ($d1 - water = $water )");
		$retstr = $retstr . $str ;
		vDecrVerbose();
	}
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
	print "MoveFromAllSimNodes \n";
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
