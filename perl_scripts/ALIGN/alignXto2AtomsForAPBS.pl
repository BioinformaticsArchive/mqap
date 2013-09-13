#!/usr/bin/perl -w 
local $SIG{__WARN__} = sub {};
use strict ;
use FileHandle ;
use Getopt::Long;
use MyUtils;
use MyGeom;

use PDB;
use Atom;
use Residue;
use ConfigPDB;

use Math::NumberCruncher;
use Algorithm::Combinatorics qw(combinations) ;



use POSIX qw(floor);
use Math::Combinatorics;
my $before ;
my $commandline = util_get_cmdline("",\@ARGV) ;
my $onatom ;
my ($pdb1,$pdb2,$infile,$outfile,$weightfile,$dontrunpymol,$svm,$single);
my ($interactive,$annotate,$positive,$negative,$maxresults,$inconf,$outconf,$train,$check,$meanfile);
my ($grpconfig) = $ENV{CONFIGGRP} or die ;
my ($pdb,$score,$listfile) ;
my ($howmanycircles) ;
my ($howmanypoints); 
my ($writeinsertpoints); 
my $MINDIST = 2 ;
$, = "  ";


my ($RESULTDIR,$PDBDIR) = util_SetEnvVars();
my $verify ;
my ($atom1,$atom2);
my ($nslices,$npoints,$ncircles,$extend);

GetOptions(
            "pdb=s"=>\$pdb ,
            "writeinsertpoints"=>\$writeinsertpoints ,
            "extend=i"=>\$extend ,
            "npoints=i"=>\$npoints ,
            "ncircles=i"=>\$ncircles ,
            "nslices=i"=>\$nslices ,
            "outfile=s"=>\$outfile ,
            "atom1=s"=>\$atom1 ,
            "atom2=s"=>\$atom2 ,
            "listfile=s"=>\$listfile ,
            "verify"=>\$verify ,
            "onatom"=>\$onatom 
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);

usage( "Need to give a pdb id => option -pdb") if(!defined $pdb);
usage( "Need to give a output option -out") if(!defined $outfile);

usage( "Need to give a atom1 ") if(!defined $atom1);
usage( "Need to give a atom2 ") if(!defined $atom2);

my $ofh ; 
if(defined $writeinsertpoints){
usage( "Need to give a output list file -list") if(!defined $listfile);
usage( "Need to give a ncircles ") if(!defined $ncircles);
usage( "Need to give a npoints ") if(!defined $npoints);
usage( "Need to give a nslices ") if(!defined $nslices);
$ofh = util_write($listfile);
}


ProcessOne($pdb);


sub ProcessOne{
      my ($proteinName) = @_ ; 

       my $pdbfile = $PDBDIR . uc($proteinName) . ".pdb";
       my $pdb = new PDB();
       $pdb->ReadPDB($pdbfile);

	   $before = $pdb->DistanceMatrix() if(defined $verify);
	   my $lc = lc($proteinName); 
	   my $uc = uc($proteinName); 
				my $a0 = $pdb->ParseAtomLine($atom1);
				my $a1 = $pdb->ParseAtomLine($atom2);
    
				print STDERR "Info : To start with \n";
				$a0->Print() ;
				$a1->Print();
				$pdb->AlignXto2Atoms($a0,$a1);

				print STDERR "Info : after aligning X axis along these two points\n";
				$a0 = $pdb->ParseAtomLine($atom1);
				$a1 = $pdb->ParseAtomLine($atom2);
				$a0->Print() ;
				$a1->Print();

                my ($x,$y,$z) = geom_MidPointAtoms($a0,$a1);
				$pdb->MoveOriginToPoint($x,$y,$z);
				print STDERR "Info : after moving centre to the midpoint of these 2 points\n";

				$a0 = $pdb->ParseAtomLine($atom1);
				$a1 = $pdb->ParseAtomLine($atom2);
				$a0->Print() ;
				$a1->Print();


           if(defined $writeinsertpoints){

				my ($minX) = $a0->Coords();
				my ($maxX) = $a1->Coords();
				my $dist = $maxX -$minX;
				my $delta = $dist/$nslices;

				my $atomlist = util_make_list($a0,$a1);
				my ($results,$combined) = $pdb->GetNeighbourHoodAtom($atomlist,"15");
				#map { print " kkkk " ; $_->Print();} @{$combined};


				$nslices = $nslices + $extend  if(defined $extend);
				my @Xs = ();
				push @Xs, 0 ;
			    my $cnt = 1 ;
				while($cnt < $nslices){
					my $v = $cnt * $delta ; 
					my $negv = -$v ;
				    push @Xs, util_format_float($v) ;
				    push @Xs, util_format_float($negv) ;
					$cnt++ ;
				}
				@Xs = sort {$a <=> $b}   @Xs ;
				print @Xs, "\n";


				my $slice = 0 ; 
				foreach my $X (@Xs){
					$slice++ ; 
					my $slicenm = "SLICE$slice";
					my $tag = $X >= 0 ? "pos" : "neg" ;
					$X =~ s/\s*//g;
					my $dirnm = "INSERT.$slicenm.$tag.$X";
					print STDERR "$dirnm \n";
					#`mkdir -p $dirnm` ;
					my $POINT = {};
			        foreach my $r (1..$ncircles){
			             my $points = geom_PointsOnACircle($r,0,0,$npoints);
					     my $n = 0 ; 
					     foreach my $p  (@{$points}){
					 	     $n++ ;
					 	     my ($y,$z) = @{$p};
						     $X = util_format_float($X);
						     $y = util_format_float($y);
						     $z = util_format_float($z);

							 my ($mindist,$minatom) = geom_Closest2($X,$y,$z,$combined);
							 #print "$mindist = mindist\n";
							 if($mindist < .7 && !defined $POINT->{$n}) {
							 	 $POINT->{$n} = $r."/".$slice ;
							 }

						     my $nm = "$dirnm.insert.radius$r.$n";
						     my $ofhfile = util_write($nm);
					         print $ofhfile "ATOM  20000  Na  ION A  26     $X  $y  $z +1.00   1.6800\n";
						     close($ofhfile);

				             print $ofh "$nm\n";
					     }
			        }

					foreach my $key (keys %{$POINT}){
						print "$key $POINT->{$key} kkkkkkkkkkkkk\n";
					}
				}



        print STDERR "Wrote list of insert points in $listfile\n";
	}
	$pdb->WritePDB($outfile,1);
}
			if(defined $verify){
			    my $after = $pdb->DistanceMatrix();
			    print STDERR "Verifying distances \n";
			    if(! $pdb->VerifyDistanceMatices($after,$before)){
				    die "PDBS are different \n";
			    }
			}


    
sub usage{
my ($msg) = @_ ;
print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
   die ;
}
