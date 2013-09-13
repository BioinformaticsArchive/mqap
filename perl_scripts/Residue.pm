
package Residue;
use MyUtils;
use PDB;
use Atom;
use Residue;
require Exporter;
@ISA = qw(Exporter );
#@EXPORT = qw($fields);

use strict ;
use Carp ;
use FileHandle ;
use Getopt::Long;
use vars qw($AUTOLOAD);
use Getopt::Long;
use Cwd ;
use File::Basename;

my $VERBOSE = 0 ;

my $fields = {
    RESNAME => undef, 
    RESNUM => undef ,
    CA => undef ,
    WARNED => undef ,
    ATOMTYPE => undef ,
    ATOMSTR => undef ,
    ATOMS => undef 
};


sub new{
    my $that = shift ; 
	my ($resname,$resnum,$atomstr) = @_ ;
    my $class = ref($that) || $that ;

    my $self =  {}; 
    map { $self->{$_} = undef ; } (keys %{$fields});
    $self->{RESNAME} = $resname ; 
	$self->{RESNUM} = $resnum ;
	$self->{ATOMSTR} = $atomstr ;
	$self->{ATOMS} = [];
	$self->{ATOMTYPE} = {};
	$self->{WARNED} = {};

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

sub AddAtom{
    my $self = shift ;
    my ($atom) = @_ ; 
	push @{$self->{ATOMS}},$atom ; 
	$self->{ATOMTYPE}->{$atom->{TYPE}} = $atom ; 

}
sub SetCAAtom{
    my $self = shift ;
    my ($atom) = @_ ; 
	$self->{CA} = $atom ; 
}

sub Print{
	my ($self,$short) = @_ ; 
	my @atoms = @{$self->{ATOMS}};
	print "Residue has number $self->{RESNUM} and type $self->{RESNAME} and ", scalar(@atoms), " atoms \n";
	return if(defined $short);
	map { $_->Print(); } @atoms ; 

}
sub PrintSingleLetter{
	my ($self,$pdb) = @_ ; 
	die if(!defined $pdb);
	my $name = uc($self->{RESNAME});
	my $x = $pdb->{THREE2SINGLE}->{$name} ;
	if(!defined $x){
		print STDERR "Undefined for $name\n" if($VERBOSE);
		return "";
	}
	return $x;
}

sub GetCAAtom{
    my $self = shift ;
	return $self->{CA} ;
}

sub GetAtoms{
    my $self = shift ;
	return  @{$self->{ATOMS}}; 
}
sub GetName{
    my $self = shift ;
	return  $self->{RESNAME}; 
}
sub SetName{
    my $self = shift ;
    my $nm = shift ;
	$self->{RESNAME} = $nm ; 
}
sub GetResNum{
    my $self = shift ;
	return  $self->{RESNUM}; 
}
sub GetIdx{
    my $self = shift ;
	return  $self->{RESNUM}; 
}
sub GetAtomStr{
    my $self = shift ;
	return  $self->{ATOMSTR}; 
}
sub GetAtomType{
    my $self = shift ;
    my $type = shift ;
	if(!exists $self->{ATOMTYPE}->{$type}){
	   my $str =  "type of atom $type does exist for residue with name $self->{RESNAME} and number $self->{RESNUM} "  ;
	   if(!exists $self->{WARNED}->{$str}){
	   		#print "$str \n";
			$self->{WARNED}->{$str} = 1 ; 
	   }
	   return undef ; 
	}

	return $self->{ATOMTYPE}->{$type} ;
}

