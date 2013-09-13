#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use MyPymol;

use PDB;
use Atom;
use Residue;

use POSIX qw(floor);
use Math::Combinatorics;
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($pdb1,$pdb2,$infile,$outfile,$dontrunPymol,$dontshowsurface);
my ($name1,$name2);
my @expressions ;
my @distances ;
GetOptions(
            "pdb1=s"=>\$pdb1 ,
            "dontrunPymol"=>\$dontrunPymol ,
            "dontshowsurface"=>\$dontshowsurface ,
            "infile=s"=>\$infile ,
            "expr=s"=>\@expressions,
            "dist:s"=>\@distances,
            "outfile=s"=>\$outfile,
            "name1=s"=>\$name1 
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
usage( "Need to give a name1 => option -name1 ") if(!defined $name1);
my $ofh = util_write($outfile);

usage( "Need to give a first protein pdb name => option -pdb1 ") if(!defined $pdb1);



print $ofh "embed $name1, pdb\n";
my $ifh = util_read($pdb1);
while(<$ifh>){
	print $ofh $_ ;
}
print $ofh "embed end\n";


#print $ofh "ray 10000,10000\n";
print $ofh "delete all\n";
print $ofh "load_embedded $name1,name=$pdb1,state=1,discrete=0\n";
print $ofh "hide everything, $pdb1  \n";
print $ofh "select query, $pdb1 \n";
#print $ofh "select query_context, $pdb1 and not query\n";
print $ofh "bg_color white\n";
print $ofh "set specular, 0\n";
print $ofh "color grey, $pdb1\n";
print $ofh "color slate, query\n";
print $ofh "show cartoon, query \n";
print $ofh "zoom query \n";


my @colors = qw ( red yellow orange green purple magenta);
my $residueColorCode = {};

my @atomtypes = ();
if(@distances){
	foreach my $d (@distances){
		my @l = split "/", $d ; 
		push @atomtypes , $l[1];
	}
}

my @residues = ();
my @atoms = ();
my $cnt = 0 ; 

foreach my $x (@expressions){
	my ($i,$name) = ($x =~ /(\d+)(\w+)/);
	my $color ; 
	if(exists $residueColorCode->{$name}){
		$color = $residueColorCode->{$name} ; 
	}
	else{
        $color 	= shift @colors ;
		$residueColorCode->{$name} = $color ;
	    print "STDERR : Color code for residue name $name is $color\n";
	}
    #print $ofh "select res$i, residue $i\n";
	my $resname = "\/$pdb1\/\/A\/$name`$i";
	my $atomname = "\/$pdb1\/\/A\/$name`$i" . "/". $atomtypes[$cnt];
	push @residues, $resname ; 
	push @atoms, $atomname ; 
    print $ofh "select res$i, $resname \n";
    print $ofh "select atom$i, $atomname \n";
    print $ofh "show sticks , res$i \n";
    print $ofh "color $color, res$i\n";
    print $ofh "zoom res$i \n";
	$cnt++ ; 
}



$, = " ";
print $ofh "select allresidues , " ;
print $ofh  @residues ; 
print  $ofh "\n";
print $ofh "zoom allresidues \n";


#if(@distances){
if(@atoms){
  my $combinat = Math::Combinatorics->new(count => 2,
                                          #data => [@distances],
                                          data => [@atoms],
                                         );

  my $cnt = 0 ; 
  print $ofh "set dash_gap, 0\n";
  while(my @combo = $combinat->next_combination){
        print $ofh "distance mydist$cnt, $combo[0], $combo[1] \n";
        print $ofh "color black , mydist$cnt \n";
		$cnt++ ; 
  }
}

#print $ofh "show surface, *\n" if(!defined $dontshowsurface);

#map { print $ofh "label $_ , \"%s-%s\" % (resi,resn) \n"  ; } @atoms ;

system("pymol $outfile") if(!defined $dontrunPymol);

sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
