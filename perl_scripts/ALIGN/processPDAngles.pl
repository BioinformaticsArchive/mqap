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
	my @tmp ; 
	foreach my $i (1..$NUMBEROFNTERMINALIGNORE){
	    shift @res ; 
	}
    while(@res > $NUMBEROFCTERMINALIGNORE ){
		my $res1 = shift @res ;
		push @tmp, $res1 ;
	}
	@res = @tmp ; 
		

	while(@res){
		my $res1 = shift @res ;
	    my $IDX = @res ;
		next if(defined $ignorepro && util_IsPro($res1));
		next if(!defined $res1);
		next if(util_IsHetWater($res1));
		my $cnt = 0 ; 
		foreach my $idx (0..$IDX){
			$cnt++ ; 
		
		    my $res2 = $res[$idx];
		    next if(!defined $res2);
		    next if(util_IsHetWater($res2));
		    if(defined $ignorepro  && util_IsPro($res2)){
			    next ; 
		    }

		    my $nm1 = $res1->PrintSingleLetter($pdb1);
		    my $nm2 = $res2->PrintSingleLetter($pdb1);
		    my $NM = $nm1 . $nm2 ;

            my $sortNM = util_sortsingleString($NM);
		    my $multfactor = 1 ; 
		    $multfactor = -1 if($sortNM ne $NM); 

			my $what = "CB";
			my $CB1 = $pdb1->GetAtomFromResidueAndType($res1->GetResNum(),$what);
			my $CB2 = $pdb1->GetAtomFromResidueAndType($res2->GetResNum(),$what);
			next if(!defined $CB1 || !defined $CB2);

		    my $pddiff = util_GetPotDiffForResidues($pdb1,$pqr1,$pots1,$res1,$res2,$what) * $multfactor;
            #my $distCB = util_format_float($pdb1->DistanceAtoms($CA1,$CA3),1);

		    push @{$DB->{$cnt}->{$sortNM}}, $pddiff ;
         }
    }
    
}

if(!defined $score){
    foreach my $i (keys %{$DB}){
        foreach my $k (keys %{$DB->{$i}}){
	        my $N = @{$DB->{$i}->{$k}} ;
	        #next if ($N < $MINSAMPLE );
            my ($mean,$sd) = util_GetMeanSD($DB->{$i}->{$k});
            print $ofh "$k $mean $sd $N $i \n";
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

sub util_IsHetWater{
	my ($res) = @_ ;
	return 1 if($res->GetAtomStr() eq "HETATM");
	return 1 if($res->GetName() eq "HOH");
	return 0 ; 
}	
