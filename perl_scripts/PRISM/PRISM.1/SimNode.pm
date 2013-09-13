
package SimNode;
use MyUtils;
use PDB;
use Atom;
use Residue;
use MyGeom;
require Exporter;
use ConfigPDB;
use SimState;
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

my $fields = {
    IDX => undef, 
    PDB => undef ,
    PQR => undef ,
    POTS => undef ,
    POT => undef ,
    ATOM => undef, 
    ATOMIDXS => undef ,
};

sub new{
    my $that = shift ; 
    my $class = ref($that) || $that ;
	my ($idx,$pdb,$pqr,$pots) = @_ ; 

    my $self = {} ; 
    map { $self->{$_} = undef ; } (keys %{$fields});

	$self->{IDX} = $idx ;
	$self->{PDB} = $pdb ;
	$self->{PQR} = $pqr ;
	$self->{POTS} = $pots ;
	$self->{ATOM} = $pdb->GetAtomIdx($idx);
	$self->{CLOSE} = {};
	$self->{POT} = $pdb->GetPotential($pqr,$idx,$pots);


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
sub GetPOTS{
	my ($self) = @_ ; 
	return $self->{POTS} ; 
}
sub GetPQR{
	my ($self) = @_ ; 
	return $self->{PQR} ; 
}

sub GetIdx{
	my ($self) = @_ ; 
	return $self->{IDX} ; 
}
sub GetAtom{
	my ($self) = @_ ; 
	return $self->{ATOM} ; 
}
sub GetPDB{
	my ($self) = @_ ; 
	return $self->{PDB} ; 
}

sub ProcessSingleAtom{
    my ($self,$dist,$wdist,$indices,$choosefromthese) = @_ ; 
    my ($atom) = $self->GetAtom();
	my $nm = $atom->GetName();
	my $pdb = $self->GetPDB();

 	vprintheader("ProcessSingleAtom for atom $nm");
    my @listofatomsclose = $self->GetCloseAtoms($atom,$dist,0);
    my @waters           = $self->GetCloseAtoms($atom,$wdist,1);
    
    foreach my $a (@listofatomsclose){
		my $idx = $a->GetIdx();
		next if($idx == $self->GetIdx());
		if(defined $choosefromthese){
		     next if(! exists $choosefromthese->{$idx});	
		}
		$indices->{$idx} = 1 ; 
		$self->{CLOSE}->{$idx} = 0 ; 
    }
    
    # =========== Now add close atoms close to atom through water =================
    foreach my $water (@waters){
        my @l = $self->GetCloseAtoms($water,$wdist,0);
        foreach my $a (@l){
		   	   my $idx = $a->GetIdx();
			   next if($idx == $self->GetIdx());

			   ### give pref to water connection
			   #next if(exists $self->{CLOSE}->{$idx});

		       if(defined $choosefromthese){
		          next if(! exists $choosefromthese->{$idx});	
		       }
		       $indices->{$idx} = 1 ; 
		       $self->{CLOSE}->{$idx} = $water->GetIdx() ; 
        }
    }
	$self->Print() ;
}

sub IsCloseByWater{
	my ($self,$idx) = @_ ; 
	return $self->{CLOSE}->{$idx} ; 
}

sub GetCloseAtoms{
	my ($self,$atom,$dist,$water) = @_ ; 
	my $origResnum = $atom->GetResNum();
	my @list ; 
    my $list = util_make_list($atom);
    my ($junk,$neigh)  = $self->GetPDB()->GetNeighbourHoodAtom($list,$dist);
    foreach my $a (@{$neigh}){
        my $num = $a->GetResNum();

		## ignore same residue as the original - this might need to change
		next if($num == $origResnum);

	    my $r1 = $a->GetResName();
	    my $type = $a->GetType();
	    
		my $add = 0 ; 
		if($water && $r1 =~ /HOH/){
			$add = 1 ;
		}
	    if(!$water && $r1 !~ /HOH/ &&  (ConfigPDB_GetAtom($r1) eq $type)){
			$add = 1 ;
	    }
        if($add){
            push @list , $a ;
        }
    }
	return @list ; 
}


sub Print{
	my ($self) = @_ ; 
	my $nm = $self->GetAtom()->GetName();
	my $atomidx = $self->GetAtom()->GetIdx();
	my $pdb = $self->GetPDB() ;
	print "===========================================\n";
	print "Printing info for Simnode for atom: $nm \n";
	print "===========================================\n";
	foreach my $idx (keys %{$self->{CLOSE}}){
		my $atom = $self->GetPDB()->GetAtomIdx($idx);
		$nm = $atom->GetName();
		my $water = $self->{CLOSE}->{$idx};
		if($water){
			my $d1 = $pdb->DistanceAtomsIdx($water,$atomidx);
			my $d2 = $pdb->DistanceAtomsIdx($water,$idx);
			print "\t Atom $nm connected through water $water (d1 = $d1, d2 = $d2)\n";
		}
		else{
			my $dist = $pdb->DistanceAtomsIdx($idx,$atomidx);
			print "\t Atom $nm directly connected (dist = $dist)\n";
		}
	}
}


###########################################################################
## return indices of atoms that have the desired direction of potential diff
###########################################################################
sub EvaluateMoves{
	my ($self,$simstate,$simconfig) = @_ ; 
	my $P = $simstate->GetPot($self->GetIdx());
	my @validmoves ;
	foreach my $idx (keys %{$self->{CLOSE}}){
		    my $p = $simstate->GetPot($idx);
		    my $diff = $P - $p ;
			push @validmoves,$idx ;
	}
	return @validmoves ;
}
