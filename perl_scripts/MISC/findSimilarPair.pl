#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use PDB;
use Cwd ;
use MyUtils;
use ConfigPDB;
use MyGeom;

use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($infile,$outfile,$which_tech,$listfile);
my (@expressions);
my $howmany = 100000 ;
my $verify ;
my ($a1,$a2,$protein);
my ($config,$nslices,$potential,$npoints,$ncircles,$dist);

GetOptions(
            "protein=s"=>\$protein ,
            "dist=i"=>\$dist ,
            "npoints=i"=>\$npoints ,
            "ncircles=i"=>\$ncircles ,
            "nslices=i"=>\$nslices ,
            "outfile=s"=>\$outfile ,
            "a1=s"=>\$a1 ,
            "config=s"=>\$config,
            "potential"=>\$potential ,
            "a2=s"=>\$a2 ,
            "listfile=s"=>\$listfile ,
            "verify"=>\$verify ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);

usage( "Need to give a pdb id => option proteinpdb") if(!defined $protein);
usage( "Need to give a output option -out") if(!defined $outfile);
usage( "Need to give a config file name => option -config ") if(!defined $config);
usage( "amino acid type 1 ") if(!defined $a1);
usage( "amino acid type 2 ") if(!defined $a2);
usage( "distance") if(!defined $dist);

my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC) = util_SetEnvVars();

my $pdb = "$PDBDIR/$protein.pdb";
my $ofh = util_append($outfile);

ConfigPDB_Init($config);

my $pdbfile = $pdb ;
my $PDB = new PDB();
$PDB->ReadPDB($pdbfile);
my @n1 = $PDB->QueryResidueType($a1,0);
my @n2 = $PDB->QueryResidueType($a2,0);

my $tab1 = util_make_table(\@n1);
my $tab2 = util_make_table(\@n2);

my @pots ;
my $pqr = new PDB();
if(defined $potential){
    $potential = "$APBSDIR/$protein/pot1.dx.atompot";

    my $pqrfile = "$APBSDIR/$protein/$protein.pqr";
    
   util_readAPBSPotential(\@pots,$potential) ;
   $pqr->ReadPDB($pqrfile);
}

my $done = {};
foreach my $n (@n1){
			my $a1type = ConfigPDB_GetAtom($a1);
			my $a2type = ConfigPDB_GetAtom($a2);
				my $x = $pqr->GetAtomFromResidueAndType($n,$a1type);
			    my ($i1) = $x->GetIdx();

				my $list = util_make_list($x);
				my ($neigh,$atoms) = $pqr->GetNeighbourHoodAtom($list,$dist,$a2);
				foreach my $y (@{$atoms}){
				    next if($a2type ne $y->GetType());
					$y->Print();
			        my ($i2) = $y->GetIdx();
			        my $pot1 = $pots[$i1-1] or die "Expected to find potential";
			        my $pot2 = $pots[$i2-1] or die "Expected to find potential";
                    my $diff = $pot1 - $pot2 ;
					my $d = $y->GetResNum();
			        print $ofh "$pdb $a1=$n $a2=$d  $diff  $i1 $i2 $pot1 - $pot2  \n";
				}



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
