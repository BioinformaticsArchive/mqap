#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use PDB;
use ConfigPDB;
use MyGeom;
# just test

use Time::HiRes qw( usleep ualarm gettimeofday tv_interval clock_gettime clock_getres  clock);
use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($infile,$outfile,$which_tech,$rad1,$threshold,$mutatefile,$listfile,$protein,$rad2);
my (@expressions,$resultsfile,$config);
my $howmany = 100000 ;
my $LARGESTDISTALLOWED = 15 ;
my $verbose = 1 ;

GetOptions(
            "which_tech=s"=>\$which_tech ,
            "protein=s"=>\$protein ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "resultsfile=s"=>\$resultsfile ,
            "mutatefile=s"=>\$mutatefile ,
            "outfile=s"=>\$outfile ,
            "expr=s"=>\@expressions,
            "config=s"=>\$config,
            "rad2=i"=>\$rad2 ,
            "rad1=i"=>\$rad1 ,
            "threshold=f"=>\$threshold ,
            "howmany=i"=>\$howmany ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
usage( "Need to give a config file name => option -config ") if(!defined $config);
my $ofh = util_write($outfile);
usage( "Need to give a config file name => option -mutate ") if(!defined $mutatefile);
my $ofhmut = util_write($mutatefile);
usage( "Need to give a listfile -option -listfile  ") if(!defined $listfile);
usage( "Need to give a protein pdb id -option -protein  ") if(!defined $protein);
my $CNT = 0 ; 
my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC) = util_SetEnvVars();
my $PWD = cwd;

my  ($seconds, $microseconds) = gettimeofday;


my $numlessthan = 0 ;
my $firststr ; 
my $table ;
if(defined $resultsfile &&  -e $resultsfile){
   my @results= ConfigPDB_ParseResultsFile($resultsfile);
   print STDERR "Reading $resultsfile \n";

   foreach my $result (@results){
       my $score = $result->{SCORE}; 
	   next if($score > $threshold);
       my @atoms = @{$result->{ATOMS}}; 
	   my $NUM = @atoms ;

	   my @l ; 
       foreach my $atom (@atoms){
       		   my ($res,$num,$type) = split "/", $atom ;
			   push @l, $num ;
       }
	   my @sl = sort {$a <=> $b}  @l ; 
	   my $str = join ",", @sl ; 



	   if(!defined $firststr){
	        $firststr = $str ;
			#print "firststr $str \n";
	        $table = util_make_table(\@sl);
	   }
	   else{

	   		### after the first, which always has score 0, you should see at least one 
			### of the residues 
	   		my $seenone = 0 ; 
            foreach my $num (@l){
				$seenone = 1 if(exists $table->{$num});
			}
			if(!$seenone){
				#print "did not see one $str \n";
				next ; 
			}
	   }

	   #next if($str eq $firststr);
	   $threshold = $threshold + 0 ;
	   if($score < $threshold){
	       #print "$score \n";
	       #$numlessthan = $numlessthan + 1/$score ; 
	       #$numlessthan++  ;
	       $numlessthan = $numlessthan + (1 - ($score*4)/$NUM) ; 
	       print "SSS $str \n";
	   }
   }
}

my $file1 = "$PDBDIR/$protein.pdb";
my $pdb1 = new PDB();
$pdb1->ReadPDB($file1);
ConfigPDB_Init($config);

### list file has all the active site atoms
my @list= util_read_list_sentences($listfile);
my $list = {};
my @reallist ; 
#map {my @j = split ; push @reallist, @j;  } @list ;
map { s/,/ /g ; my @j = split ; push @reallist, @j;  } @list ;
map { s/\s*//g ; $list->{$_} = 1 ; } @reallist ;

my $size = @reallist ;
my @atomobjs;
foreach my $i (@reallist){
	print STDERR "$i\n";
	$i =~ s/,//g;
	my ($name,$resnum) = ($i =~ /([a-zA-Z]+)([0-9]+)/);
	$name = uc($name);
	#print "$name,$resnum \n";
	my $len = length($name); 
	die "Wrong length $len" if($len != 1 && $len != 3);
	if($len == 1){
	      $name = $pdb1->GetThreeLetter($name);
	}
	#print "$name,$resnum \n";
	my ($res) = $pdb1->GetResidueIdx($resnum);
	my $type = ConfigPDB_GetAtom($res->GetName()) or die;
	my $atom = $pdb1->GetAtomFromResidueAndType($resnum,$type);
	push @atomobjs,$atom;
	print STDERR "$name,$resnum,$type \n";
}


### dont consider active site motifs that are wider than LARGESTDISTALLOWED
my @distlist = sort @{$pdb1->DistanceInGivenSetOfAtoms(\@atomobjs)};
$, = " ";
my $N = @distlist - 1 ;
my $largestdist = $distlist[$N];
die "Largest distance = $largestdist  more than $LARGESTDISTALLOWED" if($largestdist > $LARGESTDISTALLOWED);
if(!defined $rad1){
   die ; ## dont allow this for the time being
   $rad1 = $distlist[$N]/2;
}


######################################################
### this is the mutational part  - turn off or on
######################################################
my $cnt = 0 ;
if(0){

    ## now get the residues of the active site
    my $residues = {};
    foreach my $atom (@atomobjs){
         my $list = util_make_list($atom);
         my ($junk,$neigh)  = $pdb1->GetNeighbourHoodAtom($list,$rad1);
         foreach my $a (@{$neigh}){
             my $num = $a->GetResNum();
             my $atomstr = $a->GetAtomStr();
	         next if($atomstr ne "ATOM");
		     $residues->{$num} = 1 ;
	    }
    }
    
    my $res2closeatom  = {};
    my $donedeal = {};
    foreach my $resnum (sort {$a <=> $b}  keys %{$residues}){
    
	    ## get residues close to each residue 
	    my ($res) = $pdb1->GetResidueIdx($resnum);
	    my $type = ConfigPDB_GetAtom($res->GetName()) or die;
	    my $atom = $pdb1->GetAtomFromResidueAndType($resnum,$type);
         my $list = util_make_list($atom);
         my ($junk,$neigh)  = $pdb1->GetNeighbourHoodAtom($list,$rad2);
    
	     print STDERR "R = $resnum \n";
	     my $done = {};
         foreach my $a (@{$neigh}){
    
		 	     my $anm1 = $a->GetName();
		 	     my $anm2 = $atom->GetName();
	         next if($anm1 eq $anm2);
             my $atomstr = $a->GetAtomStr();
	         next if($atomstr ne "ATOM");
    
	         my ($num,$resobj,$origtype,$reactiveatom,$reactivetype) = $pdb1->GetReactiveAtomFromAtom($a);
		     next if(!($origtype eq $reactivetype));
    
		 	     my $nm1 = $res->GetName();
		 	     my $nm2 = $resobj->GetName();
			     my $idx1 = $res->GetResNum();
			     my $idx2 = $resobj->GetResNum();
			     my $k1 = $nm1 . $idx1 ;
			     my $k2 = $nm2 . $idx2 ;
			     my $key = $idx1 > $idx2 ? $k1 . "x". $k2 : $k2 . "x". $k1 ;
			     next if(exists $donedeal->{$key});
			     $donedeal->{$key} = 1 ;
    
		     next if($done->{$num});
		     $done->{$num} = 1 ;
    
             my $d = $a->Distance($atom) ;
		     my $str = "$d \t";
		     if($res->GetName() ne $resobj->GetName()){
			     if($d < 4.5){
                     print $ofhmut "Mutate residue $k2 to type $k1. Dist between both = $d , key = $key \n"; 		 	
			     }
		     }
		     else{
	             $reactiveatom->Print($str);
		         $cnt++;
		     }
	    }
    }
    $cnt = $cnt*$numlessthan;
}
else{
    $cnt = $numlessthan;
    #$cnt = $numlessthan*$largestdist;
}
#print STDERR "$protein $cnt $rad1 $rad2 n=$size largestdist=$largestdist\n";
print $ofh  "$protein $cnt $rad1 $rad2 n=$size largestdist=$largestdist\n";


sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
