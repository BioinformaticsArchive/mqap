
package Atom;
use MyUtils;
use PDB;
use Atom;
use Residue;
use MyGeom;
require Exporter;
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
    TYPE => undef ,
    ORIGLINE => undef ,
    RESNAME => undef ,
    CHARGE => undef ,
    RESNUM => undef ,
    ATOMSTR => undef ,
    x => undef ,
    y => undef ,
    z => undef 
};

sub new{
    my $that = shift ; 
    my $class = ref($that) || $that ;

    my $self = {} ; 
    map { $self->{$_} = undef ; } (keys %{$fields});

    #die "Please define TEST_HOME" if(!defined $ENV{TEST_HOME});

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


sub SetValues{

   my ($self,$idx,$type,$resname,$resnum,$x,$y,$z) = @_ ; 

   $self->{IDX} = $idx ;
   $self->{TYPE} = $type ;
   $self->{RESNAME} = $resname ;
   $self->{RESNUM} = $resnum ;
   $self->{ATOMSTR} = undef ; 
   if($x ne ""){
	$self->{x} =  sprintf("%8.3f", $x);
	$self->{y} =  sprintf("%8.3f", $y);
	$self->{z} =  sprintf("%8.3f", $z);
  }
  else{
  }
      
}

sub Distance{
	my ($self,$a2) = @_ ; 
	my ($x1,$y1,$z1) = ($self->{x},$self->{y},$self->{z}); 
	my ($x2,$y2,$z2) = ($a2->{x},$a2->{y},$a2->{z}); 
	carp " uuu " if(!defined $x2);

	return MyGeom::geom_Distance($x1,$y1,$z1,$x2,$y2,$z2);
}

sub Angle{
	my ($self,$a2) = @_ ; 

	die ; ## this makes no sense to have for the time being 

	my ($x1,$y1,$z1) = ($self->{x},$self->{y},$self->{z}); 
	my ($x2,$y2,$z2) = ($a2->{x},$a2->{y},$a2->{z}); 

	return geom_AngleBetween2Points($x1,$y1,$z1,$x2,$y2,$z2);
}


sub CalcDistance{
	        my ($self,$a2,$cutoff,$has2be_ResType,$ignorelist_ResIndex,$has2beOne_AtomIndex) = @_ ; 

			## if given a list make sure that residues are one of them
			my @keys = (keys %{$has2be_ResType});
			my $klen = @keys ; 
			if($klen == 1){
		         if( !(exists $has2be_ResType->{$self->{RESNAME}}  || exists $has2be_ResType->{$a2->{RESNAME}})){
				     return undef ;
				}
			}
			elsif( $klen  && !(exists $has2be_ResType->{$self->{RESNAME}}  && exists $has2be_ResType->{$a2->{RESNAME}})){
				return undef ;
			}

			## ignore distances between same residues
		    if(( $self->{RESNAME} eq $a2->{RESNAME})){
				return undef ;
			}
			
			## ignore this residues number 
		    if( exists $ignorelist_ResIndex->{$self->{RESNUM}} || exists $ignorelist_ResIndex->{$a2->{RESNUM}}){
				return undef ;
			}

			## one of the residues has to be this 
			if($has2beOne_AtomIndex != -1){
		         return undef if(!(($self->{RESNUM} == $has2beOne_AtomIndex)  ||  ($a2->{RESNUM} == $has2beOne_AtomIndex)));
			}

			my $diff = abs($a2->{RESNUM} - $self->{RESNUM}) ;
			return undef if($diff <= $MINDIST );

			my $s = $self->Distance($a2);
			return undef if($s > $cutoff); 

			my $NMSADDED = $self->{RESNUM} . "_" . $a2->{RESNUM} . "_".  $self->{IDX} . "_" . $a2->{IDX} . "_".  $self->{TYPE} . "_" . $a2->{TYPE}   ;


	       return ($s, $NMSADDED) ; 
}

sub GetResName{
	my ($self) = @_ ; 
	return $self->{RESNAME} ; 
}
sub GetResNum {
	my ($self) = @_ ; 
	return $self->{RESNUM} ; 
}
sub GetAtomStr {
	my ($self) = @_ ; 
	return $self->{ATOMSTR} ; 
}


sub Print{
	my ($self,$str,$ofh) = @_ ; 
	$str = "" if(!defined $str);
	if(defined $ofh){
        print $ofh "$str Atom : index = $self->{IDX} Type = $self->{RESNAME}$self->{RESNUM}  $self->{TYPE} , $self->{x}  $self->{y}  $self->{z}  \n";
	}
	else{
        print STDERR  "$str Atom : index = $self->{IDX} Type = $self->{RESNAME}$self->{RESNUM}  $self->{TYPE} , $self->{x}  $self->{y}  $self->{z}  \n";
	}
	return "$self->{RESNAME}$self->{RESNUM}";
}

sub GetName{
	my ($self) = @_ ; 
	return "$self->{RESNAME}$self->{RESNUM}$self->{TYPE}";
}

sub IsTer{
	my ($self) = @_ ; 
    return 1 if($self->{TYPE} eq "TER");
	return 0 ; 
}
sub GetIdx{
	my ($self) = @_ ; 
	return $self->{IDX} ; 
}
sub SetIdx{
	my ($self,$idx) = @_ ; 
	$self->{IDX} = $idx ;
}
sub GetType{
	my ($self) = @_ ; 
	return $self->{TYPE} ; 
}
sub SetAtomStr{
	my ($self,$str) = @_ ; 
	$self->{ATOMSTR} = $str ;
}
sub SetCharge{
	my ($self,$charge) = @_ ; 
	$self->{CHARGE} = $charge ;
}
sub GetCharge{
	my ($self) = @_ ; 
	return $self->{CHARGE} ; 
}

sub Coords{
	my ($self) = @_ ; 
	return ($self->{x},$self->{y},$self->{z}) ; 
}

sub SetCoords{
	my ($self,$x,$y,$z) = @_ ; 
	#print "Setting $x $y $z \n";
	$self->{x} =  sprintf("%8.3f", $x);
	$self->{y} =  sprintf("%8.3f", $y);
	$self->{z} =  sprintf("%8.3f", $z);
}
sub GetOrigLine{
	my ($self) = @_ ; 
	return $self->{ORIGLINE} ; 
}

sub SetOrigLine{
	my ($self,$line) = @_ ; 
	$self->{ORIGLINE} =$line  ; 
}
