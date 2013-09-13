#!/usr/bin/perl -w 
use strict ;
use PDB;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use ConfigPDB;
use MyGeom;
use MyPymol;
use Math::Geometry ;
use Math::VectorReal qw(:all);  # Include O X Y Z axis constant vectors




use Time::HiRes qw( usleep ualarm gettimeofday tv_interval clock_gettime clock_getres  clock);
use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($ann,$resnum,$config,$p1,$p2,$infile,$outfile,$which_tech,$listfile,$protein);
my $maxdist ;
my $DISTANCEWITHOUTSEQMATCH = 1 ;
my $verbose = 1 ;

my ($all,$radii,$before1,$before2);
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "protein=s"=>\$protein ,
            "all"=>\$all ,
            "p1=s"=>\$p1 ,
            "p2=s"=>\$p2 ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "ann=s"=>\$ann ,
            "maxdist=f"=>\$maxdist ,
            "config=s"=>\$config,
            "radii=i"=>\$radii ,
            "resnum=i"=>\$resnum ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
usage( "Need to give a config file name => option -config ") if(!defined $config);
usage( "Need to give a file name => option -protein ") if(!defined $protein);
usage( "Need to give a file name => option -resnum ") if(!defined $resnum);


my $ofh = util_append($outfile);
my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC) = util_SetEnvVars();
my $PWD = cwd;

ConfigPDB_Init($config);


my @resultlines ;
my @proteins ;
push @proteins, $protein; 


my @info = util_ReadPdbs($PDBDIR,$APBSDIR,1,@proteins) ; 
my $info = shift @info ;
my $pdb1 = $info->{PDBOBJ};
my $pqr1 = $info->{PQR};
my $pots1 = $info->{POTS};
ConfigPDB_Init($config);




my ($res) = $pqr1->GetResidueIdx($resnum);
my $type = ConfigPDB_GetAtom($res->GetName()) or die;
my $reactiveatom = $pqr1->GetAtomFromResidueAndType($resnum,$type);
my $CAatom = $pqr1->GetAtomFromResidueAndType($resnum,"HG");

#my $d = $reactiveatom->Distance($CAatom) ;
#die "dist = $d\n";

my @atomlist = $res->GetAtoms();
	 my @pots ; 
	 my @names ; 
	 my @charges ; 
	 my $totalcharge = 0 ; 
	 my $totalenergy = 0 ; 
	 my $reactivepot = 0 ; 
	 my $CApot = 0 ; 
	 my $diff ;
	 my $dist ;
	 my $closenm ;
	 foreach my $a (@atomlist){
		my $charge = $a->GetCharge() + 0 ;

		## take only charged atoms, unless all is defined.
		next if(!defined $all && !$charge);

		$totalcharge = $totalcharge + $charge ;
        my $pot = util_GetPotForAtom($a,$pqr1,$pots1) ;
		$pot = util_format_float((100 * $pot)/ 100,1);
		push @pots, $pot ;
		push @charges, $charge ;
		push @names, $a->GetName();
		$totalenergy = $totalenergy + ($charge * $pot );
	 	if($a eq $reactiveatom){
			$reactivepot = $pot ;

		}
	 	if($a eq $CAatom){
			$CApot = $pot ;

		    my ($closestAtom,$mind) = GetClosestAtom($pqr1,$a,"6");
		    $closenm = $closestAtom->GetName();
		    print "CLOSE = $closenm d = $mind\n";
            my $potClose = util_GetPotForAtom($closestAtom,$pqr1,$pots1) ;
			$diff = $reactivepot - $potClose ;
			$dist = $mind ;
		}

	 }
	 die "Expect totalcharge to be zero, got $totalcharge\n" if(!defined $totalcharge);
	 #$diff = $reactivepot - $CApot ;
	 print $ofh "$protein $resnum $totalenergy = energy, diff = $diff, name = $closenm ,dist =$dist\n";

	 #my @dist = @{$pdb1->DistanceInGivenSetOfAtoms(\@atomlist)};
	 #my @pots = @{$pdb1->PotInGivenSetOfAtoms(\@atomlist,$pqr1,$pots1)};
	 #$, = " ";
	 #my $name = join ",",@names ; ;
	 #print $ofh "$name, D " , @dist, "\n";
	 $, = "\n" ;

	 #my $N = @names ;
	 #die if($N ne @pots);
	 #while(@names){
	 	#my $nm = shift @names ;
	 	#my $pot = shift @pots ;
	 	#my $charge = shift @charges ;
	    #print $ofh "$nm $pot $charge \n";
	 #}


sub GetClosestAtom{
	my ($pdb,$atom,$dist) = @_ ; 
	 my $orignum = $atom->GetResNum();
     my $list = util_make_list($atom);
     my ($junk,$neigh)  = $pdb->GetNeighbourHoodAtom($list,$dist);
     my $done ;
     

     my $sort = {} ;
	 my $min = 1000 ;
	 my $minAtom ;
     foreach my $a (@{$neigh}){
         my $d = $pdb->DistanceAtoms($atom,$a);
	     my $num = $a->GetResNum();
		 next if($num eq $orignum);
		 next if($a->GetAtomStr() ne "ATOM");
		 my $atype = $a->GetType();
		 next if($atype =~ /^H/);
		 if($d < $min){
		 	$min = $d ; 
			$minAtom = $a ;
		 }
	 }
	 return ($minAtom,$min) ;
}


sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
