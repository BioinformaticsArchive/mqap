
package SimConfig;
use MyUtils;
use PDB;
use Atom;
use Residue;
use MyGeom;
require Exporter;
use ConfigPDB;
use AAConfig;
use SimNode;
use SimState;

@ISA = qw(Exporter );

use strict ;
use Carp ;
use FileHandle ;
use Getopt::Long;
use vars qw($AUTOLOAD);
use Getopt::Long;
use File::Basename;

my $MINDIST = 1 ; 
my $statesseen = {};

my $SIGDIFFERENCEINPOT = 50 ; 
my $DIFFFORMOVE = 150 ; 
my $DIFFFORMOVETOBASIC = 100 ; 
my $DIFFFORMOVEFROMBASIC = 300 ; 

my $fields = {
    POT => undef, 
    ORIGPOTS => undef, 
    PDB => undef, 
    PQR => undef, 
    INDICES => undef, 
    AACONFIG => undef, 
    SIMNODES => undef, 
    ATOMIDX => undef, 
    MOVETABLE => undef, 
    ALLATOMS => undef, 
    SAVEDCOORDS => undef, 
    PSEUDOATOM => undef, 
};

sub new{
    my $that = shift ; 
    my $class = ref($that) || $that ;
	my ($indices,$simnodes,$pdb,$pqr,$pots,$idx,$delforpot,$allatoms) = @_ ; 

    my $self = {} ; 
    map { $self->{$_} = undef ; } (keys %{$fields});

    my $table = {};
	$table->{"1a2b"} = 50 - $delforpot ;
	$table->{"1b2a"} = 250 - $delforpot ; 
	$table->{"1a2a"} = 150 - $delforpot ; 
	$table->{"1b2b"} = 130 - $delforpot ; 
	$table->{"1x2b"} = 100 - $delforpot ; 
	$table->{"1b2p"} = 251 - $delforpot ; 
	$table->{"1m2x"} = 252 - $delforpot ; 
	$table->{"1x2m"} = 400 - $delforpot ; 
	$table->{"1n2b"} = 401 - $delforpot ; 

	$self->{PDB} = $pdb ;
	$self->{ORIGPOTS} = $pots ;
	$self->{PQR} = $pqr ;
	$self->{INDICES} = $indices;
	$self->{SIMNODES} = $simnodes;
	$self->{ATOMIDX} = $idx;
	$self->{AACONFIG} = new AAConfig("/home/sandeepc/aa.config");
	$self->{MOVETABLE} = $table ;
	$self->{ALLATOMS} = $allatoms ;
	$self->{SAVEDCOORDS} = $pdb->SaveCoords($allatoms);
	my $pseudoatom = new Atom();
	$pseudoatom->SetIdx(10000);
	$self->{PSEUDOATOM} = $pseudoatom;



    vprintheader("Created new SimConfig object $self");
	my $p = $pdb->GetPotential($pqr,$idx,$pots);
	my $nm = $pdb->GetAtomIdx($idx)->GetName();
	vprint("\tSetting potential diff of $nm to $p");
	$self->{POT} = $p;

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


sub GetPDB{
	my ($self) = @_ ; 
	return $self->{PDB}; 
}
sub GetAllAtoms{
	my ($self) = @_ ; 
	return $self->{ALLATOMS}; 
}

sub GetPQR{
	my ($self) = @_ ; 
	return $self->{PQR}; 
}

sub GetOrigPots{
	my ($self) = @_ ; 
	return $self->{ORIGPOTS}; 
}

sub GetPseudoAtom{
	my ($self) = @_ ; 
	return $self->{PSEUDOATOM}; 
}

sub ReachedFinalState{
	my ($self,$v) = @_ ; 
	my $diff = $v - $self->{POT} ;
	return 1 if($diff < -$SIGDIFFERENCEINPOT);
	return 0 ; 
}

sub IsProtonMoveValid{
	my ($self,$a,$b,$diff,$water) = @_ ; 
	my $required = $DIFFFORMOVE ;

	my $A = $self->GetPDB()->GetAtomIdx($a);
	my $B = $self->GetPDB()->GetAtomIdx($b);
    my $d1 = $self->GetPDB()->DistanceAtomsIdx($a,$b);




	## if target is basic, make pot required smaller
	my $resnameB = $B->GetResName();
	my $resnameA = $A->GetResName();
	my $nmA = $A->GetName();
	my $nmB = $B->GetName();

	if($b eq $self->{ATOMIDX}){
        vprint("*Not* Allowed - for $a $b $nmA $nmB diff=$diff required=$required, water = $water, distance = $d1 as its target nucleophile ");
		return 0 ; 
	}

	#if($nmA =~ /HOH/ || $nmB =~ /HOH/){
	    #vprint("Allowed  for WATER $a $b :$nmA $nmB  ");
		#return 1 ;
	#}
	

	my $aIsPolar = $self->{AACONFIG}->IsPolar($resnameA) ;
	my $aIsBasic = $self->{AACONFIG}->IsBasic($resnameA) ;
	my $aIsAcidic = $self->{AACONFIG}->IsAcidic($resnameA) ;
	my $aIsAmide = $self->{AACONFIG}->IsAmide($resnameA) ;

	my $bIsPolar = $self->{AACONFIG}->IsPolar($resnameB) ;
	my $bIsBasic = $self->{AACONFIG}->IsBasic($resnameB) ;
	my $bIsAcidic = $self->{AACONFIG}->IsAcidic($resnameB) ;
	my $bIsAmide = $self->{AACONFIG}->IsAmide($resnameB) ;

	return 0 if(!$aIsPolar || !$bIsPolar);

    my $what = ""; 
	if($aIsAcidic && $bIsBasic){
		$what = "1a2b";
	}
	elsif($bIsAcidic && $aIsBasic){
		$what = "1b2a";
	}
	elsif($aIsAcidic && $bIsAcidic){
		$what = "1a2a";
	}
	elsif($aIsBasic && $bIsBasic){
		$what = "1b2b";
	}
	elsif($bIsBasic && !$aIsPolar){
		$what = "1n2b";
	}
	elsif($bIsBasic){
		$what = "1x2b";
	}
	elsif($bIsAmide){
		$what = "1x2m";
	}
	elsif($aIsBasic && $bIsPolar){
		$what = "1b2p";
	}
	if($what ne ""){
	     $required = $self->{MOVETABLE}->{$what} or die "$what is not there" ;
	}

	if($diff > $required){
	    my $pseudoatom = $self->{PSEUDOATOM};
	    my $allatoms = $self->{ALLATOMS};
	    my $del = 0.5 ;
	    my $Radius = 0.5 ;
	    my $pdb = $self->GetPDB();
	    my $savedcoords = $self->{SAVEDCOORDS};
        my ($val,$atom,$point,$DIST) = $pdb->IsPathClear($A,$B,$allatoms,$pseudoatom,$del,$Radius);
		## if through water, then consider always possible
	    if(!$water && !$val){
			$atom->Print();
		    vprint( "Cant move since above atom is in the path in dist $Radius at distance $DIST from the point $point");
            vprint("*Not* Allowed  for $a $b $nmA $nmB diff=$diff required=$required, water = $water, distance = $d1 ");
		    return 0 ;
		}

		vprint("Allowed  for $a $b $nmA $nmB diff=$diff required=$required, water = $water, distance = $d1 ");
		return 1 ;
	}
    vprint("*Not* Allowed  for $a $b $nmA $nmB diff=$diff required=$required, water = $water, distance = $d1 ");
	return 0 ;
}


sub AdjustMove{
	my ($self,$simstate,$a,$b,$water)  = @_ ;
	my $pA = $simstate->GetPot($a) ;
	my $pB = $simstate->GetPot($b) ;

	my $a1 = $simstate->GetPDB()->GetAtomIdx($a);
	my $b1 = $simstate->GetPDB()->GetAtomIdx($b);
	my $n1 = $a1->GetName();
	my $n2 = $b1->GetName();

	my $DD = $a1->Distance($b1);
	my $idiff = $pA - $pB ;
	#my $del  = $idiff > 400 ? 300 : int($idiff/2) + 2; 
	my $half  = int($idiff/2) ;
	my $quarter  = int($half/2) ;
	my $del  = $idiff ;
	my $delminus  = 3*$quarter ; 
	my $delplus  = $quarter ;

	$simstate->SetPot($a, $simstate->GetPot($a) - $delminus );
	$simstate->SetPot($b, $simstate->GetPot($b) + $delplus );

	$pA = $simstate->GetPot($a) ;
	$pB = $simstate->GetPot($b) ;
	my $fdiff = $pA - $pB ;
	vprint("\tAdjusting move for $n1 to $n2 ( through water $water) - intial = $idiff final diff = ($pA - $pB) = $fdiff, dist = $DD");

	return $delminus ; 
}
