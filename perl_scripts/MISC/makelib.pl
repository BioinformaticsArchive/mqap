#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use MyGeom;
use PDB;
use ConfigPDB;
use Algorithm::Combinatorics qw(combinations) ;

use Time::HiRes qw( usleep ualarm gettimeofday tv_interval clock_gettime clock_getres  clock);
use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($config,$infile,$outfile,$which_tech,$listfile,$protein);
my (@expressions);
my $howmany = 100000 ;
my $verbose = 1 ;
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "protein=s"=>\$protein ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "config=s"=>\$config,
            "expr=s"=>\@expressions,
            "howmany=i"=>\$howmany ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a config file name => option -config ") if(!defined $config);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
my $ofh = util_write($outfile);
usage( "Need to give a input file name => option -infile ") if(!defined $infile);
my $ifh = util_read($infile);
usage( "Need to give a listfile -option -listfile  ") if(!defined $listfile);
usage( "Need to give a protein pdb id -option -protein  ") if(!defined $protein);
my $CNT = 0 ; 
my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC) = util_SetEnvVars();
my $PWD = cwd;


my $seqres = "/home/sandeepc/pdb_seqres.txt";


my @list= util_read_list_sentences($listfile);
my $list = {};
map { s/\s*//g ; $list->{$_} = 1 ; } @list ;

foreach my $i (@list){
	print "$i\n";
}

ConfigPDB_Init($config,$ofh);


my $proteininfo = util_parsePDBSEQRES($seqres,0);


my $info = {};
while(<$ifh>){
     next if(/^\s*$/);
     next if(/^\s*#/);
	 my ($protein,@res) = split ; 
     my $file1 = "$PDBDIR/$protein.pdb";
     my $pdb1 = new PDB();

	 ### Read PDB and Potential files
     $pdb1->ReadPDB($file1);
	 my $pqrfile = "$APBSDIR/$protein/$protein.pqr";
	 my $pqr = new PDB();
	 $pqr->ReadPDB($pqrfile);
	 my @pots = ();
	 my $potential = "$APBSDIR/$protein/pot1.dx.atompot";
	 util_readAPBSPotential(\@pots,$potential);

     my @atomobjs ; 
     my @potentials ; 

	 my $lc = lc($protein);


	 ## foreach residue 
	 my $failed = 0 ; 
     foreach my $i (@res){
	     $i =~ s/,//g;
	     my ($name,$number) = ($i =~ /([a-zA-Z]+)([0-9]+)/);
	     $name = uc($name);
	     my $len = length($name); 
		 if($len != 1 && $len != 3){
	        warn "Warning: Ignoring protein $protein as wrong length $len of amino acid" ;
			$failed = 1 ;
			last ; 
		 }
	     if($len == 1){
	           $name = $pdb1->GetThreeLetter($name);
	     }

		 ## each residue might have multiple atoms 
		 my @atoms = ConfigPDB_GetAtoms($name);
		 foreach my $atomnm (@atoms){
		      my ($a) = $pdb1->GetAtomFromResidueAndType($number,$atomnm);
			  $a->Print() if($verbose);
              my ($aPqr) = $pqr->GetAtomFromResidueAndType($number,$atomnm) or die ;

              my ($x,$y,$z) = $a->Coords();
              my ($x1,$y1,$z1) = $aPqr->Coords();
			  if(0 && !util_IsZero($x-$x1+$y -$y1+$z-$z1)){
                 warn "Warning: $x,$y,$z $x1,$y1,$z1 do not match" ;
			  }

              my ($i1) = $a->GetIdx();
              my ($i2) = $aPqr->GetIdx();

              #imp -1 
              my $pot = $pots[$i2-1] or die "Expected to find potential";

			  push @atomobjs, $a ;
			  push @potentials, $pot ;

		 }
    }
	next if($failed);

    my $iter = combinations(\@atomobjs, 2);
	my @ddiff ;
	my @pdiff ;
    while (my $c = $iter->next) {
            my @combo = @{$c} ; 
			my ($a,$b) = @combo ; 
			my $d = $pdb1->DistanceAtoms($a,$b);
		    push @ddiff, $d ;
		    print "DIST $d \n" if($verbose);
	}
    $iter = combinations(\@potentials, 2);
    while (my $c = $iter->next) {
            my @combo = @{$c} ; 
			my ($a,$b) = @combo ; 
			my $d = int($a-$b);
		    push @pdiff, $d ;
		    print "POT $d \n" if($verbose);
	}
	$, = " , ";
	print $ofh "NAME $protein\n";
	print $ofh "DDIFF ", @ddiff, "\n";
	print $ofh "PDIFF ", @pdiff, "\n";
	print $ofh "NAMEALL $protein ", @res, " " ,  @ddiff, " " , @pdiff,  "\n";
	print $ofh "DESC $proteininfo->{$lc}->{FULLNM}\n";
	print $ofh "\n\n\n";
}

close($ifh);

foreach my $k (keys %{$info}){
     $k = uc($k);
	 my $val = $info->{$k} ; 
	 print $ofh "$k\n";
}

sub parseSingleLine{
	my ($line) = @_ ; 
	my ($num,$restype,$resnum,$atom,$x,$y,$z) = split " " , $line ; 
	return ($num,$restype,$resnum,$atom,$x,$y,$z);
}
print STDERR "Output written in $outfile\n";

chmod 0777, $outfile ;

sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
