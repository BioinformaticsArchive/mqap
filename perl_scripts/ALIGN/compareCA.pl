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
my ($p1,$p2,$infile,$outfile,$dist,$which_tech,$listfile,$protein);
my (@expressions);
my $maxdist = 3 ;
my $verbose = 1 ;
my ($moveZ,$verify,$decaaf,$before1,$before2);
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "protein=s"=>\$protein ,
            "verify"=>\$verify ,
            "p1=s"=>\$p1 ,
            "p2=s"=>\$p2 ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "expr=s"=>\@expressions,
            "maxdist=i"=>\$maxdist ,
            "moveZ=i"=>\$moveZ ,
            "dist=f"=>\$dist ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
my $ofh = util_append($outfile);
my $ofhclose = util_write("log.close");
usage( "Need to give a protein 1 id -option -p1  ") if(!defined $p1);
usage( "Need to give a protein 2 id -option -p2  ") if(!defined $p2);
usage( "Need to give a dist -option -dist  ") if(!defined $dist);
my $CNT = 0 ; 
my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC) = util_SetEnvVars();
my $PWD = cwd;


my $file1 = "$p1.pdb";
my $file2 = "$p2.pdb";
my $pdb1 = new PDB();
$pdb1->ReadPDB($file1);
my $pdb2 = new PDB();
$pdb2->ReadPDB($file2);

my @res = $pdb1->GetResidues();
my $N = @res;
my $cnt = 0 ;
my $sum = 0 ;
my $cntmatch = 0 ; 
foreach my $res (@res){
    $cnt++;
    next if($res->GetAtomStr() ne "ATOM");
	my $resnum = $res->GetResNum();
    my $CAatom = $pdb1->GetAtomFromResidueAndType($resnum,"CA");
	$CAatom->Print();

	    my @atomlist ;
	    push @atomlist, $CAatom ;
		my $maxdist = 2 ; 
	    my ($results,$combined) = $pdb2->GetNeighbourHoodAtom(\@atomlist,$maxdist);
	    my $sort ;
		my @goodatoms ; 
        foreach my $j (@{$combined}){
		    my $resnum = $j->GetResNum(); 
	        my ($res) = $pdb2->GetResidueIdx($resnum);
		    my $nm = $j->GetName();
		    my $type = $j->GetType();
		    next if($type ne "CA");
		    my $atomstr = $j->GetAtomStr();
		    next if($atomstr eq "HETATM");
            my $CAatom2 = $pdb2->GetAtomFromResidueAndType($j->GetResNum(),"CA");
			my $d = util_format_float($pdb1->DistanceAtoms($CAatom2,$CAatom),1);
			next if($d > $dist);
			print "$d =\n";
			$cntmatch++;
			$sum = $sum + $d * $d ; 
		}
}

my $rmsd = util_format_float(sqrt($sum/$cntmatch),3) ; 
print $ofh " $p2 $rmsd $cntmatch\n";


sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}

