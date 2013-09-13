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

use Math::Trig;




use Time::HiRes qw( usleep ualarm gettimeofday tv_interval clock_gettime clock_getres  clock);
use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($score,$ann,$config,$p1,$p2,$infile,$ignorepro,$outfile,$which_tech,$listfile,$protein);
my $maxdist ;
my $DISTANCEWITHOUTSEQMATCH = 1 ;
my $verbose = 1 ;
my $DB = {};

my $MINSAMPLE = 30 ;
my $NUMBEROFNTERMINALIGNORE = 1 ; 
my $NUMBEROFCTERMINALIGNORE = 5 ; 

my ($verify,$radii,$before1,$before2);
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "verify"=>\$verify ,
            "p1=s"=>\$p1 ,
            "p2=s"=>\$p2 ,
            "score=s"=>\$score,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "ann=s"=>\$ann ,
            "maxdist=f"=>\$maxdist ,
            "config=s"=>\$config,
            "ignorepro"=>\$ignorepro,
            "radii=i"=>\$radii ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
usage( "Need to give a config file name => option -config ") if(!defined $config);
usage( "Need to give a listfile -option -list  ") if(!defined $listfile);
my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC) = util_SetEnvVars();
my $ofh= util_write("$outfile");

my @list= util_read_list_sentences($listfile);
my $list = {};
map { s/\s*//g ; $list->{$_} = 1 ; } @list ;



my $prevnorm ; 
foreach my $protein (@list){
     #my $ofhangle = util_write("angle.$protein");
    my $PWD = cwd;
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
	foreach my $i (1..$NUMBEROFNTERMINALIGNORE){
	    shift @res ; 
	}
    while(@res > $NUMBEROFCTERMINALIGNORE ){
		
		my $res1 = shift @res ;
		my $res2 = $res[0];
		my $res3 = $res[1];
		my $res4 = $res[2];
		if(defined $ignorepro && util_IsPro($res1) || util_IsPro($res2) || util_IsPro($res3)){
			next ; 
		}

        my $what = "CB";
		my $CA1 = $pdb1->GetAtomFromResidueAndType($res1->GetResNum(),$what);
		my $CA2 = $pdb1->GetAtomFromResidueAndType($res2->GetResNum(),$what);
		my $CA3 = $pdb1->GetAtomFromResidueAndType($res3->GetResNum(),$what);
		my $CA4 = $pdb1->GetAtomFromResidueAndType($res4->GetResNum(),$what);
		next if(!defined $CA1 || !defined $CA2 || !defined $CA3 || !defined $CA4 );



  
       next if(!util_AreResiduesContinuous($pdb1,$res1,$res2));
       next if(!util_AreResiduesContinuous($pdb1,$res2,$res3));
       next if(!util_AreResiduesContinuous($pdb1,$res3,$res4));


		my $nm1 = $res1->PrintSingleLetter($pdb1);
		my $nm2 = $res2->PrintSingleLetter($pdb1);
		my $nm3 = $res3->PrintSingleLetter($pdb1);
		my $nm4 = $res4->PrintSingleLetter($pdb1);
		my $NM = $nm1 . $nm2 . $nm3 . $nm4 ; 
		my $NM1 = $nm1 . $nm2 . $nm3 ; 
		my $NM1X = $nm1 .  $nm3 ; 
		my $NM2 = $nm2 . $nm3 . $nm4 ; 

		my $angle1 = $pdb1->AngleBetweenThreeAtoms($CA1,$CA2,$CA3);
		my $angle2 = $pdb1->AngleBetweenThreeAtoms($CA2,$CA3,$CA4);


	    my $v1 = $pdb1->MakeVector($CA1);
	    my $v2 = $pdb1->MakeVector($CA2);
	    my $v3 = $pdb1->MakeVector($CA3);
	    my $v4 = $pdb1->MakeVector($CA4);

		my ($norm1,$dd1) = plane( $v1, $v2 , $v3  );
		my ($norm2,$dd2) = plane( $v2 , $v3, $v4  );

	    my $c = $norm1 . $norm2 ; 
		my $anglebetweenplanes = acos($c);
		$anglebetweenplanes = rad2deg($anglebetweenplanes);


        my $sortNM = util_sortsingleString($NM1X);
		my $multfactor = 1 ; 
		$multfactor = -1 if($sortNM ne $NM1X); 

		my $pddiff = util_GetPotDiffForResidues($pdb1,$pqr1,$pots1,$res1,$res3,$what) * $multfactor;
        my $distCB = util_format_float($pdb1->DistanceAtoms($CA1,$CA3),1);

		push @{$DB->{$sortNM}}, $distCB ;
    }
    
}

if(!defined $score){
    foreach my $k (keys %{$DB}){
	    my $N = @{$DB->{$k}} ;
	    #next if ($N < $MINSAMPLE );
        my ($mean,$sd) = util_GetMeanSD($DB->{$k});
	    #my $absmean = abs ($mean);
	    #if($absmean > $sd + 10 && $sd < 50 ){
             print $ofh "$k $mean $sd $N \n";
	    #}
	    #else{
		    #print $ofhignored "$k $mean $sd $N \n"; 
	    #}
    }
}

    

sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
