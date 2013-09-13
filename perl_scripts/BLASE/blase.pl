#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use MyGeom;
use PDB;
use ConfigPDB;

use Time::HiRes qw( usleep ualarm gettimeofday tv_interval clock_gettime clock_getres  clock);
use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($infile,$outfile,$which_tech,$listfile,$protein);
my (@expressions);
my $howmany = 100000 ;
my $verbose = 1 ;
my $rad1 = 5 ;
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "protein=s"=>\$protein ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "expr=s"=>\@expressions,
            "rad1=i"=>\$rad1 ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
my $ofh = util_write($outfile);
usage( "Need to give a input file name => option -infile ") if(!defined $infile);
my $ifh = util_read($infile);
usage( "Need to give a protein pdb id -option -protein  ") if(!defined $protein);
my $MAXCNT = 0 ; 
my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC) = util_SetEnvVars();
my $PWD = cwd;


my $pdbs = util_maketablefromfile("list.ann");

my $info = {};
my @proteins ;
push @proteins, $protein;
while(<$ifh>){
     next if(/^\s*$/);
     chop ;
	 my (@l) = split ; 
	 my $query = shift @l ;
	 my $ref = shift @l ;
	 my $score = shift @l ;
	 my (@atoms) =  @l ;
	 next if(exists $info->{$query});
	 next if(!exists $pdbs->{$query});

	 ## ignore if the query protein doesnt match - remember this file
	 ## has it all - so you need to filter
	 next if($ref ne $protein);
	 print $ofh "$query $ref $score\n";

     push @proteins, $query;
	 print @atoms, "\n";

	 $info->{$query} = {};

     my $pdb = "$PDBDIR/$query.pdb";
     my $pdb1 = new PDB();
     $pdb1->ReadPDB($pdb);
	 my $allres = {};
	 $info->{$query}->{PDB} = $pdb1 ;




	 my $CNT = 1 ; 
	 foreach my $A (@atoms){
	     my $origatom = $pdb1->ParseAtomLine($A);
	     $origatom->Print();
		 my $resnum = $origatom->GetResNum();
		 my $r1 = $pdb1->GetResidueIdx($resnum);
		 $allres->{$resnum} = $r1 ;

         my $list = util_make_list($origatom);
	     my ($junk,$neigh)  = $pdb1->GetNeighbourHoodAtom($list,$rad1);
		 my @res ; 
		 my $done = {};
	     foreach my $a (@{$neigh}){
	          my $resnum = $a->GetResNum();
		      my $r1 = $pdb1->GetResidueIdx($resnum);
			  my $single = $r1->PrintSingleLetter($pdb1);
			  if($single ne ""){
			       $done->{$resnum} = 1 ;
			  }
		      $allres->{$resnum} = $r1 ;
		 }
		 my $origstr = "ORIG" . $CNT; 
		 $info->{$query}->{$CNT} = $done ;
		 $info->{$query}->{$origstr} = $origatom->GetResNum();
		 $CNT++; 
	 }
	 $MAXCNT = $CNT -1 ;




	 $pdb1->PrintSortedFasta($query,$allres);
}


my $orig = shift @proteins ; 
foreach my $p (@proteins){
	next if($p eq $orig);
	Process2Proteins($orig,$p);
}

sub Process2Proteins{
	my ($X,$Y) = @_; 
	print  "$X $Y $MAXCNT \n";
	my $ai = $info->{$X};
	my $bi = $info->{$Y};
	my $pdbA = $ai->{PDB};
	my $pdbB = $bi->{PDB};

	my $matchingA = {};
	my $matchingB = {};
	foreach my $idx (1..$MAXCNT){
		 my $origstr = "ORIG" . $idx; 
		 my $origA = $ai->{$origstr};
		 my $origB = $bi->{$origstr};
		 $matchingA->{$origA} = $origB;
		 $matchingB->{$origB} = $origA;
	}

	foreach my $idx (1..$MAXCNT){
		 print "====================== $idx ======================= \n";
	     my $resA = $ai->{$idx};
	     my $resB = $bi->{$idx};

		 my @sortedA = sort { $a <=> $b }  keys %{$resA} ;
		 my @sortedB = sort { $a <=> $b }  keys %{$resB} ;

         my $NN = @sortedB ;
		 my $Bidx = 0 ; 
		 foreach my $k (@sortedA){
			print "Matching from A: $k and B index = $Bidx \n";
		 	if(!exists $matchingA->{$k}){
				while($Bidx < $NN){
					my $bres = $sortedB[$Bidx];
					print "\tbres = $bres \n";
					$Bidx++;
		 	        if(!exists $matchingB->{$bres}){
		                my $r1 = $pdbA->GetResidueIdx($k)->GetName();
		                my $r2 = $pdbB->GetResidueIdx($bres)->GetName();
						print "\t\tALIGN $k $bres $r1 $r2 \n";
					}
					else{
						last ;
					}
				}
			}
			else{
				print "\tAlready matched $k \n";
			}
		 }


	}
}

sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
