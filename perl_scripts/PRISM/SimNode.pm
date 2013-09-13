
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

	my $pseudoatom = new Atom();
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

sub ProcessForces{
    my ($self,$dist) = @_ ; 
    my ($atom) = $self->GetAtom();
	my $nm = $atom->GetName();
	my $pdb = $self->GetPDB();
	my $savedcoords = $pdb->SaveCoords();

	$pdb->MoveOriginToAtom($atom);
 	vprintheader("ProcessForces for atom $nm");
    my ($listofatomsclose,$allatoms) = $self->GetCloseAtoms($atom,$dist,0);
	foreach my $otheratom (@{$listofatomsclose}){
	      my $othernm = $otheratom->GetName();
          my ($a,$b,$c) = $self->ProcessForcesOnAtomIgnoringOne($atom,$otheratom,$dist,$othernm);
          my ($d,$e,$f) = $self->ProcessForcesOnAtomIgnoringOne($otheratom,$atom,$dist,$othernm);
		  my $X = $a - $d ;
		  my $Y = $b - $e ;
		  my $Z = $c - $f ;

	      my $X2 = $X * $X ;
	      my $Y2 = $Y * $Y ;
	      my $Z2 = $Z * $Z ;
	      my $sum = sqrt($X2 + $Y2 + $Z2) ;
	      print STDERR "Final XXX $othernm: $sum \n";
	}
	$pdb->RestoreCoords($savedcoords);
}


sub ProcessForcesOnAtomIgnoringOne{
    my ($self,$centreatom,$ignore,$dist,$othernm) = @_; 
	my $pdb = $self->GetPDB();
	my $p  = $pdb->GetPotential($self->{PQR},$centreatom->GetIdx(),$self->{POTS});
    my ($junk,$allatoms) = $self->GetCloseAtoms($centreatom,$dist,0);
	my $del = 0.5 ;
	my $Radius = 0.5 ;
	my $resignore = $ignore->GetResNum();

	my @validatoms ;
	#foreach my $a (@{$allatoms}){
           #my ($val) = $self->GetPDB()->IsPathClear($centreatom,$a,$allatoms,$pseudoatom,$del,$Radius);
		   #next if(!$val);
		   #push @validatoms,$a;
	#}
	@validatoms = @{$allatoms};
    my ($cx,$cy,$cz) = $centreatom->Coords();


	my ($X,$Y,$Z);
	$X = $Y = $Z = 0 ;
	#$pdb->MoveOriginToAtom($centreatom);
	foreach my $a (@validatoms){
	       my $resnum = $a->GetResNum();
		   #if ($resnum eq $resignore){
			   #next ;
		   #}
		   my $d = $pdb->DistanceAtoms($centreatom,$a);
	       my $p1  = $pdb->GetPotential($self->{PQR},$a->GetIdx(),$self->{POTS});
		   my $diff = $p - $p1 ;
		   my $mult = $diff > 0 ? 1 : -1 ; 
		   my $mag = sqrt(abs($diff/$d)) ;
		   my ($p,$q,$r) = $a->Coords();
		   my $x = $p - $cx ;
		   my $y = $q - $cy ;
		   my $z = $r - $cz ;
		   #print STDERR  "Final : $d $diff $mag $x $y $z \n";
		   $X =  $X + $mult*$mag*($x/sqrt($d));
		   $Y =  $Y + $mult*$mag*($y/sqrt($d));
		   $Z =  $Z + $mult*$mag*($z/sqrt($d));
	}
	my $X2 = $X * $X ;
	my $Y2 = $Y * $Y ;
	my $Z2 = $Z * $Z ;
	my $sum = sqrt($X2 + $Y2 + $Z2) ;
	print STDERR "Final $othernm: $X $Y $Z $sum\n";
	return ($X,$Y,$Z);

}



sub ProcessSingleAtom{
    my ($self,$dist,$wdist,$indices,$choosefromthese) = @_ ; 
    my ($atom) = $self->GetAtom();
	my $nm = $atom->GetName();
	my $pdb = $self->GetPDB();

 	vprintheader("ProcessSingleAtom for atom $nm");
    my ($listofatomsclose,$allatoms) = $self->GetCloseAtoms($atom,$dist,0);
    my ($waters,$junk)           = $self->GetCloseAtoms($atom,$wdist,1);
	my @listofatomsclose = @{$listofatomsclose};
	my @waters = @{$waters};

	#push @listofatomsclose,@waters ;
    
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
	if(1){
    foreach my $water (@waters){
        my ($l,$junk) = $self->GetCloseAtoms($water,$wdist,0);
        foreach my $a (@{$l}){
		   	   my $idx = $a->GetIdx();
			   next if($idx == $self->GetIdx());

			   ### dont give pref to water connection
			   #next if(exists $self->{CLOSE}->{$idx});

		       if(defined $choosefromthese){
		          next if(! exists $choosefromthese->{$idx});	
		       }
		       $indices->{$idx} = 1 ; 
		       $self->{CLOSE}->{$idx} = $water->GetIdx() ; 
        }
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
	my @allatoms ; 
    my $list = util_make_list($atom);
    my ($junk,$neigh)  = $self->GetPDB()->GetNeighbourHoodAtom($list,$dist);
    foreach my $a (@{$neigh}){
        my $num = $a->GetResNum();

		## ignore same residue as the original - this might need to change
		next if($num == $origResnum);

	    my $r1 = $a->GetResName();
		if(ConfigPDB_IsValidAA($r1)){
		    $a->Print();
            push @allatoms , $a ;
		}
	    my $type = $a->GetType();
	    
		my $add = 0 ; 
		if($water && $r1 =~ /HOH/){
			$add = 1 ;
		}
	    if(!$water && $r1 !~ /HOH/){
		  #my ($a,$b) = ConfigPDB_GetAtom($r1) ; 
		    my ($x,$y) = ConfigPDB_GetAtoms($r1) ; 
		    if((defined $x && ($x eq $type)) || (defined $y && ($y eq $type))){
			    $add = 1 ;
		    }
	    }

		#$add = ConfigPDB_IsValidAA($r1);
        if($add){
            push @list , $a ;
        }
    }
	return (\@list,\@allatoms);
}


sub Print{
	my ($self) = @_ ; 
	my $nm = $self->GetAtom()->GetName();
	my $atomidx = $self->GetAtom()->GetIdx();
	my $pdb = $self->GetPDB() ;
	print STDERR  "===========================================\n";
	print STDERR  "Printing info for Simnode for atom: $nm \n";
	print STDERR  "===========================================\n";
	foreach my $idx (keys %{$self->{CLOSE}}){
		my $atom = $self->GetPDB()->GetAtomIdx($idx);
		$nm = $atom->GetName();
		my $water = $self->{CLOSE}->{$idx};
		if($water){
			my $d1 = $pdb->DistanceAtomsIdx($water,$atomidx);
			my $d2 = $pdb->DistanceAtomsIdx($water,$idx);
			print STDERR "\t Atom $nm connected through water $water (d1 = $d1, d2 = $d2)\n";
		}
		else{
			my $dist = $pdb->DistanceAtomsIdx($idx,$atomidx);
			print STDERR  "\t Atom $nm directly connected (dist = $dist)\n";
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
