
package MyBlock;
use Image::Magick;
use MyGeom;
use MyUtils;
@ISA = qw(Exporter );
@EXPORT = qw($fields);


use strict ;
use Carp ;
use FileHandle ;
use Getopt::Long;
use vars qw($AUTOLOAD);
use Getopt::Long;
use Cwd ;
use File::Basename;

no warnings 'redefine';

my $verbose = 0 ;

my $fields = {
    BLKCNT => undef, 
    ORIGBLKCNT => undef, 
    POINTSTABLE => undef, 
    POINTSLIST => undef, 
    TOUCHED => undef, 
};

sub new{
    my $that = shift ; 
    my $class = ref($that) || $that ;

	my ($cnt) = @_ ; 

    my $self =  {};

    map { $self->{$_} = undef ; } (keys %{$fields});

    $self->{BLKCNT} = $cnt;
    $self->{ORIGBLKCNT} = $cnt;
    $self->{POINTSTABLE} = {};
    $self->{POINTSLIST} = [];

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

sub Add {
    my ($self,$x,$y,$globalblockinfo) = @_ ;
	my $str = "$x.$y";
	print "Adding $str to  $self->{BLKCNT}\n" if($verbose);
	$globalblockinfo->{$str} = $self->{BLKCNT} ; 
	push @{$self->{POINTSLIST}}, $x ;
	push @{$self->{POINTSLIST}}, $y ;
}

sub GetPoints {
    my ($self,$x,$y) = @_ ;
	return  @{$self->{POINTSLIST}} ; 
}

sub GetBlkCnt {
    my ($self,$x,$y) = @_ ;
	return  $self->{BLKCNT} ; 
}

sub SetBlock {
    my ($self,$block,$globalblockinfo) = @_ ;
	if($self->{TOUCHED}){
		$block->{TOUCHED} = 0 ; 
		$block->SetBlock($self,$globalblockinfo);
		return  $self->{BLKCNT} ;
	}
	$self->{TOUCHED} = 1 ;
	$self->{BLKCNT}  = $block->GetBlkCnt();
    my @points = $self->GetPoints();	
	while(@points){
	 	my $x = shift @points ;
	 	my $y = shift @points ;
	    my $str = "$x.$y";
	    $globalblockinfo->{$str} = $self->{BLKCNT} ; 
	}
	return  $self->{BLKCNT} ;

}

sub GetSize {
    my ($self) = @_ ;
	my $size = @{$self->{POINTSLIST}} ;
	return $size/2  ; 
}

