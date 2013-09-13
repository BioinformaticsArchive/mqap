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
use Math::VectorReal qw(:all);  # Include O X Y Z axis constant vectors
use Scalar::Util qw(looks_like_number);


use Math::Trig;




use Time::HiRes qw( usleep ualarm gettimeofday tv_interval clock_gettime clock_getres  clock);
use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($cutoff,$exception,$ann,$config,$p1,$p2,$infile,$score,$ignorepro,$outfile,$which_tech,$listfile,$protein);
my $maxdist ;
my $DISTANCEWITHOUTSEQMATCH = 1 ;
my $verbose = 1 ;
my $DBCA ;
my $DBCB ;
my $DBCN ;

$cutoff = 0.012 ;
my $MINSAMPLE = 1 ;
my $NUMBEROFCTERMINALIGNORE = 1 ; 
my $NUMBEROFNTERMINALIGNORE = 1 ; 

my ($verify,$radii,$before1,$before2);
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "verify"=>\$verify ,
            "p1=s"=>\$p1 ,
            "p2=s"=>\$p2 ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "ann=s"=>\$ann ,
            "maxdist=f"=>\$maxdist ,
            "cutoff=f"=>\$cutoff ,
            "config=s"=>\$config,
            "score=s"=>\$score,
            "ignorepro"=>\$ignorepro,
            "radii=i"=>\$radii ,
            "exception=s"=>\$exception ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
usage( "Need to give a config file name => option -config ") if(!defined $config);
usage( "Need to give a listfile -option -list  ") if(!defined $listfile);
my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC) = util_SetEnvVars();
my $ofh= util_write("$outfile");
my $ofhescapist= util_write("escapist.out");
my $ofhCA= util_write("pd.CA");
my $ofhCB= util_write("pd.CB");
my $ofhCN= util_write("pd.CN");

my $ofhCAdist= util_write("dist.CA");
my $ofhCBdist= util_write("dist.CB");
my $ofhCNdist= util_write("dist.CN");

my $ofhCAABS= util_write("pd.CAabs");
my $ofhCBABS= util_write("pd.CBabs");
my $ofhignored= util_write("ignored");

my @list= util_read_list_sentences($listfile);
my $list = {};
map { s/\s*//g ; $list->{$_} = 1 ; } @list ;

my $exceptiontable = {};
if(defined $exception){
    my @exception= util_read_list_sentences($exception);
    map { s/\s*//g ; $exceptiontable->{$_} = 1 ; } @exception ;
}

my $dbinfoCA = {};
my $dbinfoCB = {};
my $dbinfoCN = {};
if(defined $score){
   my $ifh ;
   $ifh = util_read($score);
   while(<$ifh>){
        next if(/^\s*$/);
	    my ($a,$b,$c,$d) = split ; 
	    $dbinfoCB->{$a} = {};
		if($b > 0){
	        $dbinfoCB->{$a}->{MEAN} = $b ;
	        $dbinfoCB->{$a}->{START} = $b - $c ; 
	        $dbinfoCB->{$a}->{END} = $b + 2*$c ; 
		}
		else{
	        $dbinfoCB->{$a}->{MEAN} = $b ;
	        $dbinfoCB->{$a}->{START} = $b - 2*$c ; 
	        $dbinfoCB->{$a}->{END} = $b + $c ; 
		}
   }
   close($ifh);
   $ifh = util_read("pd.CA.score");
   while(<$ifh>){
        next if(/^\s*$/);
	    my ($a,$b,$c,$d) = split ; 
	    $dbinfoCA->{$a} = {};
		if($b > 0){
	        $dbinfoCA->{$a}->{MEAN} = $b ;
	        $dbinfoCA->{$a}->{START} = $b - $c ; 
	        $dbinfoCA->{$a}->{END} = $b + 2*$c ; 
		}
		else{
	        $dbinfoCA->{$a}->{MEAN} = $b ;
	        $dbinfoCA->{$a}->{START} = $b - 2*$c ; 
	        $dbinfoCA->{$a}->{END} = $b + $c ; 
		}
   }
   if(1){
   close($ifh);
   $ifh = util_read("pd.CN.score");
   while(<$ifh>){
        next if(/^\s*$/);
	    my ($a,$b,$c,$d) = split ; 
	    $dbinfoCN->{$a} = {};
		if($b > 0){
	        $dbinfoCN->{$a}->{MEAN} = $b ;
	        $dbinfoCN->{$a}->{START} = $b - $c ; 
	        $dbinfoCN->{$a}->{END} = $b + 2*$c ; 
		}
		else{
	        $dbinfoCN->{$a}->{MEAN} = $b ;
	        $dbinfoCN->{$a}->{START} = $b - 2*$c ; 
	        $dbinfoCN->{$a}->{END} = $b + $c ; 
		}
   }
   }
}



my $prevnorm ; 
my $proteincnt = 0 ; 
foreach my $protein (@list){
    my $finalscoreCA = 0 ; 
    my $finalscoreCB = 0 ; 
    my $finalscoreCN = 0 ; 
    my $pdCAscore = 0 ; 
    my $pdCBscore = 0 ; 
    my $finalscorestr = "";
    ConfigPDB_Init($config);
    my $i = $protein ;
    my @proteins ; 
    push @proteins, $i ; 
    next if( ! -e "$APBSDIR/$i/$i.pqr");
    next  if( ! -e "$APBSDIR/$i/pot1.dx.atompot" && ! -e "$APBSDIR/$i/pot1.dx.atompot");
    my @info = util_ReadPdbs($PDBDIR,$APBSDIR,1,@proteins) ; 
    my $info = shift @info ;
    my $pdb1 = $info->{PDBOBJ};
    my $pqr1 = $info->{PQR};
    my $pots1 = $info->{POTS};
    #my $ofhangle = util_write("pd.$protein");
    my $PWD = cwd;

    #my $pdb = "$PDBDIR/$protein.pdb";
    #my $pdb1 = new PDB();
    #$pdb1->ReadPDB($pdb);
    
    
    #push @pots, $pot ;
    my @res = $pdb1->GetResidues();
    my $N = @res;
    my $prevres ; 
    my $prevpd = 0  ; 
    my @potCA ; 
	my $bad = 0 ; 
	my $N = @res ; 

	my $cnt = 0 ;
	my $numbercomparedCA = 0 ;
	my $numbercomparedCB = 0 ;
	my $numbercomparedCN = 1 ;
	my @pdCA ; 
	my @pdCB ; 
	my @pdCN ; 
	my @NM ; 
	my $good = 1 ; 
	$proteincnt++;

	foreach my $i (1..$NUMBEROFNTERMINALIGNORE){
	    shift @res ; 
	}
	my $scoreDistCA = 0 ;
	my $maxscoreDistCA = 0 ;
	my $numberScoreDistCA = 0 ;
    while(@res > $NUMBEROFCTERMINALIGNORE ){
		
		my $res1 = shift @res ;
		my $res2 = $res[0];
		next if($res1->GetAtomStr() eq "HETATM");
		next if($res2->GetAtomStr() eq "HETATM");
		next if($res1->GetName() eq "HOH");
		next if($res2->GetName() eq "HOH");

		if(defined $ignorepro && util_IsPro($res1) || util_IsPro($res2)){
			next ; 
		}

		my $resnum =  $res1->GetResNum();
		my $nm1 = $res1->PrintSingleLetter($pdb1);
		my $nm2 = $res2->PrintSingleLetter($pdb1);
		my $num1 = $res1->GetResNum();
		my $num2 = $res2->GetResNum();


		my $CA1 = $pdb1->GetAtomFromResidueAndType($res1->GetResNum(),"CA");
		my $CA2 = $pdb1->GetAtomFromResidueAndType($res2->GetResNum(),"CA");
		next if(!defined $CA1 || !defined $CA2 );

		my $C1 = $pdb1->GetAtomFromResidueAndType($res1->GetResNum(),"C");
		my $C2 = $pdb1->GetAtomFromResidueAndType($res2->GetResNum(),"C");
		next if(!defined $C1 || !defined $C2 );

		my $N1 = $pdb1->GetAtomFromResidueAndType($res1->GetResNum(),"N");
		my $N2 = $pdb1->GetAtomFromResidueAndType($res2->GetResNum(),"N");
		next if(!defined $N1 || !defined $N2 );


		## will ignore all Gly 
		my $CB1 = $pdb1->GetAtomFromResidueAndType($res1->GetResNum(),"CB");
		my $CB2 = $pdb1->GetAtomFromResidueAndType($res2->GetResNum(),"CB");
		if(!defined $CB1){
		    print STDERR "Expect only Gly, found $nm1 $num1, nexting\n" if($nm1 ne "G");	
		    next if($nm1 ne "G");	
			$CB1 = $CA1 ;
		}
		if(!defined $CB2){
		    print STDERR "Expect only Gly, found $nm2 $num2, nexting\n" if($nm2 ne "G");	
		    next if($nm2 ne "G");	
			$CB2 = $CA2 ;
		}

#print "$nm1 $nm2 .......\n";
#$CB1->Print();
#$CB2->Print();



		my $NM = $nm1 . $nm2 ;
        my $sortNM = util_sortsingleString($NM);
		my $multfactor = 1 ; 
		$multfactor = -1 if($sortNM ne $NM); 



       my ($val, $diffdistCA) = util_AreResiduesContinuous($pdb1,$res1,$res2);
	   $scoreDistCA = $scoreDistCA + $diffdistCA * $diffdistCA ;
	   $numberScoreDistCA++ if($diffdistCA);

	   if($diffdistCA > $maxscoreDistCA){
	   	  $maxscoreDistCA = $diffdistCA ;
	   }
	   

  
       my $potCA1 = util_GetPotForAtom($CA1,$pqr1,$pots1) *1  ;
       my $potN1 = util_GetPotForAtom($N1,$pqr1,$pots1)  *1 ;
       my $potC1 = util_GetPotForAtom($C1,$pqr1,$pots1) *1  ;
       my $potCB1 = util_GetPotForAtom($CB1,$pqr1,$pots1) *1  ;

       my $potCA2 = util_GetPotForAtom($CA2,$pqr1,$pots1) *1  ;
       my $potN2 = util_GetPotForAtom($N2,$pqr1,$pots1)  *1 ;
       my $potC2 = util_GetPotForAtom($C2,$pqr1,$pots1) *1  ;
       my $potCB2 = util_GetPotForAtom($CB2,$pqr1,$pots1) *1  ;

		my $pdCN = $potC1 - $potN2 ;
		my $pdCBs = $multfactor *($potCB1 - $potCB2) ;
		my $pdCAs = $multfactor *($potCA1 - $potCA2) ;
		my $pdCAsabs = abs ($pdCAs);
		my $pdCBsabs = abs ($pdCBs);


	    #next if(!looks_like_number($pdCBs));
		next if($pdCBs =~ /nan/i);


		$NM = $sortNM ;

		### sometimes the CN potential is negative, happens when the residue is 
		### something that APBS does not recognize
		if($pdCN < 1  ){ 
		    $good = 0 ; 
		}


        my $distCA = util_format_float($pdb1->DistanceAtoms($CA1,$CA2),1);
        my $distCB = util_format_float($pdb1->DistanceAtoms($CB1,$CB2),1);
        my $distCN = util_format_float($pdb1->DistanceAtoms($C1,$N2),1);
		print $ofhCAdist "$NM $distCA\n";
		print $ofhCBdist "$NM $distCB\n";
		print $ofhCNdist "$NM $distCN\n";



		$cnt++ ;

		$pdCAscore = $pdCAscore + $pdCAsabs ;
	    if(!defined $score){
		    push @pdCA, $pdCAs ;
		    push @pdCB, $pdCBs ;
		    push @pdCN, $pdCN ;
		    push @NM, $NM ;
		}
		else{
			#if(! exists $exceptiontable->{$NM}){
			    if(0 || defined $dbinfoCA->{$NM}){
				   $numbercomparedCA++ ;
				   my $diffCA = abs($pdCAs - $dbinfoCA->{$NM}->{MEAN});	
				   $finalscoreCA = $finalscoreCA + $diffCA ; 
			    }
			    if(0 || defined $dbinfoCB->{$NM}){
				   $numbercomparedCB++ ;
				   die if(!defined $pdCBs);
				   die "$NM $dbinfoCB->{$NM}" if(!defined $dbinfoCB->{$NM}->{MEAN} );
				   my $diffCB = abs($pdCBs - $dbinfoCB->{$NM}->{MEAN});	
				   $finalscoreCB = $finalscoreCB + $diffCB ; 
			    }
			    if(0 || defined $dbinfoCN->{$NM}){
				   $numbercomparedCN++ ;
				   my $diffCN = abs($pdCN - $dbinfoCN->{$NM}->{MEAN});	
				   $finalscoreCN = $finalscoreCN + $diffCN ; 
				 }
			#}
		}
    }
	if(!$cnt){
		print $ofh "BAD cnt = 0 $protein\n";
		next ;
	}


	if(!defined $score){
	    if($good){
			$DBCA = ProcessOne (\@pdCA, \@NM,$DBCA);
			$DBCB = ProcessOne (\@pdCB, \@NM,$DBCB);
			$DBCN = ProcessOne (\@pdCN, \@NM,$DBCN);

	    }
	    else{
		    print $ofh "BAD = $protein\n";
    
	    }
	}
	else{
		if($numbercomparedCB){
	        my $averagePDCAABS = util_format_float($pdCAscore/$cnt,1)+ 0  ;

			my $averageCA = util_format_float($finalscoreCA/$numbercomparedCA, 1)+ 0;
			my $averageCB = util_format_float($finalscoreCB/$numbercomparedCB, 1)+ 0;
			my $averageCN = util_format_float($finalscoreCN/$numbercomparedCN, 1)+ 0;

			my $averageCAist = util_format_float(sqrt($scoreDistCA/($cnt*$cnt))) + 0 ;
			my $averageCAist1000 =  $averageCAist * 1000 ; 
			$averageCAist1000 = 0  if($averageCAist < $cutoff) ;
			my $newscore = $averageCB + 2* $averageCAist1000;


			my $total = util_format_float($averageCA + $averageCB + $averageCN , 1)+ 0;

		    print $ofh "CA = $averageCA  CB = $averageCB CN = $averageCN PDCAABS = $averagePDCAABS  t = $total CAdist = $averageCAist  newscore = $newscore $protein nCA = $numbercomparedCA, nCB = $numbercomparedCB cnt = $cnt good=$good number=$N \n";
			print $ofhescapist "$protein $averageCB\n";
		}
	}
    
}


if(!defined $score){
	PrintOneDB($DBCA,$ofhCA,1,"CA") ; 
	PrintOneDB($DBCB,$ofhCB,1,"CB") ; 
	PrintOneDB($DBCN,$ofhCN,1,"CN") ; 
}

sub ProcessOne{
	my ($lpd,$lNM,$DB) = @_ ; 
	my @pd = @{$lpd} ; 
	my @NM = @{$lNM} ; 
	while(@pd){
		my $pd = shift @pd ;
		my $NM = shift @NM ;
		die "$NM not defied $NM" if(!defined $pd);
		$DB->{$NM} = [] if(!defined $DB->{$NM});
		push @{$DB->{$NM}}, $pd ;
	}
	return $DB ;
}
    
sub PrintOneDB{
	my ($DB,$OFH,$printOneStat,$what) = @_ ; 
	my $cnt= 0 ; 
    foreach my $k (keys %{$DB}){
	    my $N = @{$DB->{$k}} ;
	    next if ($N < $MINSAMPLE);
		$cnt++ ;
		if($printOneStat && $cnt < 1000){
            my $ofhstat = util_write("pd.single.$what.$k");
			my @l = @{$DB->{$k}};
			my $Nminus = $N - 1 ;
			foreach my $i (0..$Nminus){
				print  $ofhstat "$i $l[$i]\n";
			}
		}
        my ($mean,$sd) = util_GetMeanSD($DB->{$k});
	    my $absmean = abs ($mean);
        print $OFH "$k $mean $sd $N \n";
    }
}

sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}


