package NamdConfig;
require Exporter;
@ISA = qw(Exporter );
use strict ;
use Carp ;
use FileHandle ;
use MyUtils ;
use Getopt::Long;
use vars qw($AUTOLOAD);
use Getopt::Long;
use File::Basename;
my $MINDIST = 1 ; 
my $fields = {
PDBNoH => undef,
PARAMFILE => undef,
PDBALIAS => undef,
PDBPSF => undef,
PDB => undef,
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

sub Read{
    my $self = shift;
    my $infile = shift;
    my $ifh = util_read($infile);
    while(<$ifh>){
         next if(/^\s*$/);
         next if(/#^\s*#/);
	     s/=//g;
         chop ;
	     my ($nm,$junk) = split ; 
         $self->{$nm} = $junk ;
    }
}
sub GetPDBNoH{ my $self = shift; return $self->{PDBNoH}; } 
sub GetPARAMFILE{ my $self = shift; return $self->{PARAMFILE}; } 
sub GetPDBALIAS{ my $self = shift; return $self->{PDBALIAS}; } 
sub GetPDBPSF{ my $self = shift; return $self->{PDBPSF}; } 
sub GetPDB{ my $self = shift; return $self->{PDB}; } 
