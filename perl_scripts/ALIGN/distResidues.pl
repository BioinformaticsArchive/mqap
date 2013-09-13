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
#usage( "Need to give a config file name => option -config ") if(!defined $config);
usage( "Need to give a listfile -option -list  ") if(!defined $listfile);
my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC) = util_SetEnvVars();
my $ofh= util_write("$outfile");

my @list= util_read_list_sentences($listfile);
my $list = {};
map { s/\s*//g ; $list->{$_} = 1 ; } @list ;

my $prevnorm ; 
my $proteincnt = 0 ; 
my @alldistances ; 
foreach my $protein (@list){
    my $finalscoreCA = 0 ; 
    my $finalscoreCB = 0 ; 
    my $finalscoreCN = 0 ; 
    my $pdCAscore = 0 ; 
    my $pdCBscore = 0 ; 
    my $finalscorestr = "";
    #ConfigPDB_Init($config);
    my $i = $protein ;
    my @proteins ; 
    push @proteins, $i ; 

    my $PWD = cwd;

    my $pdb = "$PDBDIR/$protein.pdb";
    my $pdb1 = new PDB();
    $pdb1->ReadPDB($pdb);
    
    
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
		if(abs($num1 - $num2) ne 1){
			next ;
		}


		my $CA1 = $pdb1->GetAtomFromResidueAndType($res1->GetResNum(),"CA");
		my $CA2 = $pdb1->GetAtomFromResidueAndType($res2->GetResNum(),"CA");
		next if(!defined $CA1 || !defined $CA2 );

		my $C1 = $pdb1->GetAtomFromResidueAndType($res1->GetResNum(),"C");
		my $C2 = $pdb1->GetAtomFromResidueAndType($res2->GetResNum(),"C");
		next if(!defined $C1 || !defined $C2 );

		my $N1 = $pdb1->GetAtomFromResidueAndType($res1->GetResNum(),"N");
		my $N2 = $pdb1->GetAtomFromResidueAndType($res2->GetResNum(),"N");
		next if(!defined $N1 || !defined $N2 );


		my $NM = $nm1 . $nm2 ;
        my $sortNM = util_sortsingleString($NM);
		my $multfactor = 1 ; 
		$multfactor = -1 if($sortNM ne $NM); 



       my ($val, $DD1, $diffdistCA) = util_AreResiduesContinuous($pdb1,$res1,$res2);
	   $scoreDistCA = $scoreDistCA + $diffdistCA * $diffdistCA ;
	   if($diffdistCA){
	       $numberScoreDistCA++ ;
		   if($diffdistCA > 1 ){
		       print "$nm1 $nm2 $num1 $num2 $DD1 $diffdistCA\n";
		   }
	   }

	   if($diffdistCA > $maxscoreDistCA){
	   	  $maxscoreDistCA = $diffdistCA ;
	   }
	   

  
		$NM = $sortNM ;

        my $distCA = util_format_float($pdb1->DistanceAtoms($CA1,$CA2),1);
        my $distCN = util_format_float($pdb1->DistanceAtoms($C1,$N2),1);
		push @alldistances, $distCA;



		$cnt++ ;

    }
	if(!$cnt){
		print $ofh "BAD cnt = 0 $protein\n";
		next ;
	}


my $averageCAist = util_format_float(sqrt($scoreDistCA/($cnt*$cnt))) + 0 ;
my $averageCAist1000 =  $averageCAist ; 
print $ofh "$protein averageCAist1000 = $averageCAist1000 \n";
    
}

my $ofhstat = util_append("stat.CA");
my $cnt = 0 ; 
foreach my $i (@alldistances){
	$cnt++;
	print $ofhstat "$cnt $i\n";
}



sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}


