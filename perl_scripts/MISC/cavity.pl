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

use AAConfig;

my $aaconfig = new AAConfig("/home/sandeepc/aa.config");



my $padding = 3 ; 
my $DISTSURFACE = 1 ; 
my $DOSURFACE = 0 ; 
my $DISTATOMS   = 1 ; 
my $BOUNDARYDELTA   = 1000 ; 
my $RECALIBRATECOUNT= 100 ; 
my $CNT1000 = 3 ;
my $ADDATOMSCLOSE2 = 0 ;

use Time::HiRes qw( usleep ualarm gettimeofday tv_interval clock_gettime clock_getres  clock);
use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($debugresidue,$ann,$config,$p1,$p2,$infile,$threshPD,$threshsign,$threshDist,$outfile,$readpotential,$which_tech,$listfile,$protein);
my $DISTANCEWITHOUTSEQMATCH = 1 ;
my $verbose = 1 ;

my ($onlypolar,$radii,$before1,$before2);
$readpotential = 1 ;
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "protein=s"=>\$protein ,
            "debugresidue=s"=>\$debugresidue ,
            "onlypolar=i"=>\$onlypolar ,
            "p1=s"=>\$p1 ,
            "p2=s"=>\$p2 ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "ann=s"=>\$ann ,
            "config=s"=>\$config,
            "radii=i"=>\$radii ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
usage( "Need to give a config file name => option -config ") if(!defined $config);
usage( "Need to give a p1 file name => option -p1 ") if(!defined $p1);



my $ofh = util_write($outfile);
my $fhatoms = util_write("coords.atoms");
my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC) = util_SetEnvVars();
my $PWD = cwd;

ConfigPDB_Init($config,$ofh);

my @proteins ;
push @proteins, $p1 ;

my @info = util_ReadPdbs($PDBDIR,$APBSDIR,$readpotential,@proteins);
my $pdb1 = $info[0]->{PDBOBJ};
my $pdb2 = $info[1]->{PDBOBJ};
my $pqr1 = $info[0]->{PQR};

my @atoms1 = $pdb1->GetAtoms();
my ($minx,$miny,$minz);
my ($maxx,$maxy,$maxz);
$minx = $miny = $minz = 100000 ;
$maxx = $maxy = $maxz = -10000 ;
foreach my $a1 (@atoms1){
	my ($x,$y,$z) = $a1->Coords();
	next if(!defined $x);
	$maxx = $x if($x > $maxx); $maxy = $y if($y > $maxy); $maxz = $z if($z > $maxz);
	$minx = $x if($x < $minx); $miny = $y if($y < $miny); $minz = $z if($z < $minz);
}

### round off 
$maxx = int($maxx); $maxy = int($maxy); $maxz = int($maxz);
$minx = int($minx); $miny = int($miny); $minz = int($minz);

### pad 
$maxx = $maxx + $padding ; $maxy = $maxy + $padding ; $maxz = $maxz + $padding ;
$minx = $minx - $padding ; $miny = $miny - $padding ; $minz = $minz - $padding ;

print "maxx maxy maxz\n";
print "$maxx $maxy $maxz\n";
print "minx miny minz\n";
print "$minx $miny $minz\n";
my $diffx = $maxx - $minx ; my $diffy = $maxy - $miny  ; my $diffz = $maxz - $minz  ;
my $CNT = 0 ; 
my $pseudoatom = new Atom();
$pseudoatom->SetIdx(10000);


my $gridresilution = 1 ; 

my $allPointTable = {};
my @allPointList  = ();
my $boundary ={};
my $tablefilled = {};


##############################################################
### Accumulate all the grid points and mark the boundaries ###
##############################################################
foreach my $p (0..$diffx){
	my $X = $gridresilution * $p + $minx ; 
    foreach my $q (0..$diffy){
	    my $Y = $gridresilution * $q + $miny ; 
        foreach my $r (0..$diffz){
	        my $Z = $gridresilution * $r + $minz ; 
	        my $str = geom_MakeKeyFromCoord($X,$Y,$Z);
			$allPointTable->{$str} = {};
			push @allPointList,$str;
			$CNT++ ;

			## Mark the boundaries
			if ($p eq 0 || $q eq 0 || $r eq 0 || $p eq $diffx || $q eq $diffy || $r eq $diffz){
			    $boundary->{$str} = 1 ;
			}
        }
    }
}


my $natoms = @atoms1 ;
my $ngridpoints = @allPointList ;
print "Assigning $ngridpoints grid points to $natoms atoms - distance is $DISTATOMS\n";
foreach my $a1 (@atoms1){
	my ($x,$y,$z) = $a1->Coords();
	my $NM = $a1->GetName();

	next if(!defined $x); ## why would this ever happen?

    $x = int($x); $y = int($y); $z = int($z);

	my $Sx  = $x- 1 ; my $Ex  = $x + 1 ;
	my $Sy  = $y- 1 ; my $Ey  = $y + 1 ;
	my $Sz  = $z- 1 ; my $Ez  = $z + 1 ;
	my $found = 0 ;

	my $distable = {};
    foreach my $p ($Sx..$Ex){
        foreach my $q ($Sy..$Ey){
            foreach my $r ($Sz..$Ez){
                  $pseudoatom->SetCoords($p,$q,$r);
				   my $d = $pseudoatom->Distance($a1) ;
	               my $str = geom_MakeKeyFromCoord($p,$q,$r);
				   die if(!defined $allPointTable->{$str});
				   $distable->{$d} = $str ; 
            }
        }
    }

	my $CCC = 0 ; 
	foreach my $k (sort {$a <=> $b} keys  %{$distable}){
		my $str = $distable->{$k} ;
		if($k < $DISTATOMS){
			if(!defined $allPointTable->{$str}->{ATOMLIST}){
					   	   $allPointTable->{$str}->{ATOMLIST} = [];
			}
			push @{$allPointTable->{$str}->{ATOMLIST}}, $a1 ;
			if(exists $tablefilled->{$str}){
				print "ALREADY \n";
				next ;
			}

			$tablefilled->{$str} = $a1 ;
			print $fhatoms "$NM $str\n";
			$CCC++;
		}
		last if($CCC eq 1);
	}
}


my $tablesurface  = {};
if($DOSURFACE){
    $tablesurface  = GetSurface($tablefilled,$DISTSURFACE) ; 
}
my $staticvalues = {};


print "Computing static distances to boundary/atoms for each point\n";
foreach my $k (@allPointList){
	if(! exists $tablefilled->{$k} && ! exists $boundary->{$k}){
	    my ($x,$y,$z) = geom_MakeCoordFromKey($k);
	    my $list = util_make_list($x,$y,$z);
		my @ret ; 
	    #params for MoveInOnedirection  --> ($k,$list,$idx,$dir,$ret) = @_ ; 
		my $north = MoveInOnedirection($k,$list,0,0,\@ret);
		my $south = MoveInOnedirection($k,$list,0,1,\@ret);
		my $east = MoveInOnedirection($k,$list,1,1,\@ret);
		my $west = MoveInOnedirection($k,$list,1,0,\@ret);
		my $up = MoveInOnedirection($k,$list,2,1,\@ret);
		my $down = MoveInOnedirection($k,$list,2,0,\@ret);
		$staticvalues->{$k} = \@ret ; 
		#print "$x $y $z $north $south $east $west $up $down \n";
	}
}

print "recalibrating\n";
my $recalibrated = {};
foreach my $k (@allPointList){
	if(! exists $tablefilled->{$k} && ! exists $boundary->{$k}){
	    my ($x,$y,$z) = geom_MakeCoordFromKey($k);
	    my $list = util_make_list($x,$y,$z);
		## todo remove values
		my $north = RecalibrateValues($k,$list,0,0,1);
		my $south = RecalibrateValues($k,$list,0,1,0);
		my $east = RecalibrateValues($k,$list,1,1,3);
		my $west = RecalibrateValues($k,$list,1,0,2);
		my $up =   RecalibrateValues($k,$list,2,1,5);
		my $down = RecalibrateValues($k,$list,2,0,4);
	}
}

print "Figuring out which are cavities - cnt1000 should be greater than $CNT1000\n";
my $cavity = {};
foreach my $k (@allPointList){
	if(! exists $tablefilled->{$k} && ! exists $boundary->{$k}){
	   my @values = @{$recalibrated->{$k}};
	   my $cnt1000 = 0 ; 
	   foreach my $i (@values){
	   	    $cnt1000++ if($i < 1000);
	   }

	   if($cnt1000 > $CNT1000){
		   $cavity->{$k} = 1  ;
	   }
	   else{
		   	$, = " " ;
		   	print $ofh " not cavity @values \n";
		}
	}
}
my $ncavity = (keys %{$cavity});
print "There were $ncavity cavity points \n";

if(1){
my @Addtocavity = Add2Cavity($cavity);
my $naddtocavity = @Addtocavity ; 
print "Adding $naddtocavity points to cavity\n";
foreach my $k (@Addtocavity){
	$cavity->{$k} = 1 ; 
}
}

if(defined $debugresidue){
    my @points1 ; 
	my $points = {};
    my $IFH = util_read($debugresidue);
    my $OFH = util_write("$debugresidue.out");
    while(<$IFH>){
         next if(/^\s*$/);
	     my ($nm,$key) = split ; 
	     push @points1, $key ;
		 $points->{$key} = 1 ;
    }
	foreach my $p (@points1){
	    my @l = geom_GetPointsAroundOnePoint($p,1);
		foreach my $k (@l){
		     if(exists $recalibrated->{$k}){
	             my @values = @{$recalibrated->{$k}};
	             my @origvalues = @{$staticvalues->{$k}};
			     my $iscavity = exists $cavity->{$k} ? 1 : 0 ; 
			     print $OFH "$k @values $iscavity\n";
			     print $OFH "$k @origvalues $iscavity\n";
		     }
		}
	}
	die "debugresidue $debugresidue done \n";
}


print "Assigning cavities\n";
my $numcavities = 0 ; 
my $CAVITIES = {};
foreach my $k (keys %{$cavity}){
	if($cavity->{$k} eq 1 ){
		my @atoms ;
		my @ret ; 
  
        RecurseCreateCavity($k,\@ret,\@atoms);

		$numcavities++ ; 

		my $N  = @ret ; 
		$CAVITIES->{$numcavities} = {};
		$CAVITIES->{$numcavities}->{POINTS} = \@ret ; 
		$CAVITIES->{$numcavities}->{ATOMS} = \@atoms ; 
		$CAVITIES->{$numcavities}->{NUM} = $N ; 
	}
}



my @sorted = sort { $CAVITIES->{$a}->{NUM} <=> $CAVITIES->{$b}->{NUM} } (keys %{$CAVITIES});
foreach my $numcavities (@sorted){    
	my $N = $CAVITIES->{$numcavities}->{NUM} ;
	my $atoms = $CAVITIES->{$numcavities}->{ATOMS} ;
	my $points = $CAVITIES->{$numcavities}->{POINTS} ;
    my $fhcavityatoms = util_write("atoms.$numcavities");
    my $fhcavitycoords = util_write("coords.$numcavities");
	my $done = {};
	my $doneatom = {};
	my $str = "";
	my $numres = 0 ; 
	my $natomsincavity = 0 ; 

	foreach my $k (@{$points}){
		print $fhcavitycoords "$k\n";
	}

	foreach my $a (@{$atoms}){
	    my $NM = $a->GetName();
		if(! exists $doneatom->{$NM}){
			$natomsincavity++ ; 
			print $fhcavityatoms "$NM\n";
		}
	    my $nm = $a->GetResName();
	    my $number = $a->GetResNum();
		my $num = "$nm.$number";
		 if(! exists $done->{$num}){
	          $str = $str . " $num "  ;
			  $numres++;
		 }
	     $done->{$num} = 1 ;
        #$pseudoatom->SetCoords($x,$y,$z);
		#my $list = util_make_list($pseudoatom);
		#my ($junk,$neigh)  = $pdb1->GetNeighbourHoodAtom($list,2);
		#foreach my $a (@{$neigh}){
		    #my $num = $a->GetResNum();
		#}
	}
	close($fhcavityatoms);
	close($fhcavitycoords);
	print $ofh "$numcavities has size $N, and $numres residues, and $natomsincavity atoms - $str \n";
}

exit ; 
###############  END ################################


### this is quite a complicated function - so pay attention ### 
### As we go up, we dont want to go down - just east, west , north and south
sub RecalibrateValues{
	my ($k,$list,$idx,$dir,$otherdir) = @_ ; 
	my @l = @{$list} ; 
	my @origvalues = @{$staticvalues->{$k}};
	my $cnt = 0 ; 
	
	## this might as well have been while 1
	while($cnt < $RECALIBRATECOUNT){
		$cnt++ ; 
		if($dir eq 0){
	          $l[$idx] = $l[$idx] -1 ; 
		 }
		 else{
	          $l[$idx] = $l[$idx] + 1 ; 
		 }
	     my ($x,$y,$z) = @l ;
	     my $newkey = geom_MakeKeyFromCoord($x,$y,$z);
		 if(exists $boundary->{$newkey} || exists $tablefilled->{$newkey}){
		     $recalibrated->{$k} = \@origvalues;
		 	return ; 
		 }
		 my $values = $staticvalues->{$newkey};
		 my @values = @{$values};
		 foreach my $IDX (0..5){
		 	next if($IDX eq $idx || $IDX eq $otherdir);
			my $newval = $values[$IDX];
			$origvalues[$IDX] = $origvalues[$IDX] + int($newval/($cnt)) ; 
		 }
	}
}

sub MoveInOnedirection{
	my ($k,$list,$idx,$dir,$ret) = @_ ; 
	my @l = @{$list} ; 
	my $cnt = 0 ; 
	while(1){
		if($dir eq 0){
	          $l[$idx] = $l[$idx] -1 ; 
		 }
		 else{
	          $l[$idx] = $l[$idx] + 1 ; 
		 }

	     my ($x,$y,$z) = @l ;
		 #print "$x $y $z \n";
	     my $newkey = geom_MakeKeyFromCoord($x,$y,$z);
		 if(exists $boundary->{$newkey}){
		 	$cnt = $cnt+ $BOUNDARYDELTA ; 
			push @{$ret}, $cnt ; 
			return $cnt; 
		 }
		 elsif(exists $tablesurface->{$newkey} || exists $tablefilled->{$newkey}){
			push @{$ret}, $cnt ; 
		    return $cnt ; 
		 }
		 ## could make a move 
		 $cnt++ ; 
	}
}







sub usage{
my ($msg) = @_ ;
print $msg , "\n" ;
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
die ;
}


sub GetSurface{
	my ($tf,$distsurface) = @_ ; 
	my $ts = {};
    foreach my $pointfilled (keys %{$tf}){
		my @l = geom_GetPointsAroundOnePoint($pointfilled,$distsurface);
		my $atom = $tf->{$pointfilled} ; 
		foreach my $k (@l){
	        $ts->{$k} = $atom if(! exists $tf->{$k});
		}
    }
    
    #foreach my $k (keys %{$ts}){
	    #print "surface $k \n";
    #}
	return $ts ; 
}



sub RecurseCreateCavity{
	my ($k,$ret,$atoms) = @_ ; 
    die "Did not expect to get to the boundary $k" if(exists $boundary->{$k});
	if(defined $cavity->{$k}){
	   if($cavity->{$k} eq 1 ){
	      $cavity->{$k} = 0 ; 
		  push @{$ret}, $k ;
	      my ($x,$y,$z) = geom_MakeCoordFromKey($k);
		  my $k1 = geom_MakeKeyFromCoord($x+1,$y,$z);
		  RecurseCreateCavity($k1,$ret,$atoms) if(!defined $cavity->{$k1} || $cavity->{$k1} eq 1);
		  $k1 = geom_MakeKeyFromCoord($x-1,$y,$z);
		  RecurseCreateCavity($k1,$ret,$atoms) if(!defined $cavity->{$k1} || $cavity->{$k1} eq 1);
		  $k1 = geom_MakeKeyFromCoord($x,$y+1,$z);
		  RecurseCreateCavity($k1,$ret,$atoms) if(!defined $cavity->{$k1} || $cavity->{$k1} eq 1);
		  $k1 = geom_MakeKeyFromCoord($x,$y-1,$z);
		  RecurseCreateCavity($k1,$ret,$atoms) if(!defined $cavity->{$k1} || $cavity->{$k1} eq 1);
		  $k1 = geom_MakeKeyFromCoord($x,$y,$z+1);
		  RecurseCreateCavity($k1,$ret,$atoms) if(!defined $cavity->{$k1} || $cavity->{$k1} eq 1);
		  $k1 = geom_MakeKeyFromCoord($x,$y,$z-1);
		  RecurseCreateCavity($k1,$ret,$atoms) if(!defined $cavity->{$k1} || $cavity->{$k1} eq 1);

	    }
    }		
	else{
		  if($ADDATOMSCLOSE2){
	           my ($x,$y,$z) = geom_MakeCoordFromKey($k);
               $pseudoatom->SetCoords($x,$y,$z);
		       my $list = util_make_list($pseudoatom);
		       my ($junk,$neigh)  = $pdb1->GetNeighbourHoodAtom($list,$ADDATOMSCLOSE2);
		       foreach my $a (@{$neigh}){
		           push @{$atoms} ,$a ;
		       }
		  }

		 if( exists $tablesurface->{$k}){
		 	push @{$atoms} ,$tablesurface->{$k}; 
		 }
		 elsif (exists $tablefilled->{$k}){
		 	push @{$atoms} ,$tablefilled->{$k} if($tablefilled->{$k});
		 }
		return ;
	}
}
sub Add2Cavity{
	my ($CAV) = @_ ; 
    my @addtocavity ; 
    foreach my $k (keys %{$CAV}){
	    my ($x,$y,$z) = geom_MakeCoordFromKey($k);
		  my @l ; 
	      my $newkey = geom_MakeKeyFromCoord($x-1,$y,$z);
		  push @l, $newkey ;
	      $newkey = geom_MakeKeyFromCoord($x+1,$y,$z);
		  push @l, $newkey ;
	      $newkey = geom_MakeKeyFromCoord($x,$y-1,$z);
		  push @l, $newkey ;
	      $newkey = geom_MakeKeyFromCoord($x,$y+1,$z);
		  push @l, $newkey ;
	      $newkey = geom_MakeKeyFromCoord($x,$y,$z-1);
		  push @l, $newkey ;
	      $newkey = geom_MakeKeyFromCoord($x,$y,$z+1);
		  push @l, $newkey ;
          foreach my $newkey (@l){
		       if(exists $staticvalues->{$newkey}){
	                my @values = @{$staticvalues->{$newkey}};
	                my $cnt1000 = 0 ; 
	                my $cntX = 0 ; 
	                foreach my $i (@values){
	   	                 $cnt1000++ if($i < 1000);
	   	                 $cntX++ if($i < 20);
	                }
             
	                if($cnt1000 > $CNT1000 && $cntX > 4){
		                if(!exists $boundary->{$newkey} && ! exists $tablefilled->{$newkey} && ! exists $CAV->{$newkey}){
				           push @addtocavity, $newkey ;
				        }
	                }
			   }
         }
    }
	return @addtocavity ; 
}
