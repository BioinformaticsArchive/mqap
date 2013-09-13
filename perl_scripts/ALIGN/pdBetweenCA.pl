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
my ($ann,$config,$p1,$p2,$infile,$ignorepro,$outfile,$which_tech,$listfile,$protein);
my $maxdist ;
my $DISTANCEWITHOUTSEQMATCH = 1 ;
my $verbose = 1 ;

my ($verify,$radii,$before1,$before2);
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "protein=s"=>\$protein ,
            "verify"=>\$verify ,
            "p1=s"=>\$p1 ,
            "p2=s"=>\$p2 ,
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
usage( "Need to give a listfile -option -protein  ") if(!defined $protein);

my $ofhpot = util_write("pot.$protein");
my $ofhrmsd = util_write("rmsd.$protein");
my $ofhNext = util_write("next.$protein");
my $ofhabs = util_write("absolute.$protein");

my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC) = util_SetEnvVars();
my $PWD = cwd;

ConfigPDB_Init($config);

my $i = $protein ;
my @proteins ; 
push @proteins, $i ; 
die if( ! -e "$APBSDIR/$i/$i.pqr");
die if( ! -e "$APBSDIR/$i/pot1.dx.atompot" && ! -e "$APBSDIR/$i/pot1.dx.atompot");
my @info = util_ReadPdbs($PDBDIR,$APBSDIR,1,@proteins) ; 
my $info = shift @info ;
my $pdb1 = $info->{PDBOBJ};
my $pqr1 = $info->{PQR};
my $pots1 = $info->{POTS};

#push @pots, $pot ;
my @res = $pdb1->GetResidues();
my $N = @res;
my $cnt = 0 ; 
my $prevres ; 
my $prevpd = 0  ; 
foreach my $res (@res){
    $cnt++;
    next if($res->GetAtomStr() ne "ATOM");
    next if($cnt < 2 );
	my $resnum = $res->GetResNum();
	my $name = $res->GetName();
	next if(defined $ignorepro && $name eq "PRO");
	next if(defined $ignorepro && defined $prevres && $prevres->GetName() eq "PRO");
    
    my $CA = $pdb1->GetAtomFromResidueAndType($resnum,"CA");
    my $N = $pdb1->GetAtomFromResidueAndType($resnum,"N");
    my $C = $pdb1->GetAtomFromResidueAndType($resnum,"C");
	if(!defined $CA || !defined $N || !defined $C ){
	 	undef $prevres ;	
		next ;
	}

    my $potCA = util_GetPotForAtom($CA,$pqr1,$pots1) *1  ;
    my $potN = util_GetPotForAtom($N,$pqr1,$pots1)  *1 ;
    my $potC = util_GetPotForAtom($C,$pqr1,$pots1) *1  ;

	$potCA = $potCA * 1;

	print $ofhabs "$resnum $potCA\n";
	#print $ofhabs "$resnum $potN\n";
	#print $ofhabs "$resnum $potC\n";

	if(!defined $prevres){
		$prevres = $res ; 
	}
	else{

		my $prevatomCA = $pdb1->GetAtomFromResidueAndType($prevres->GetResNum(),"CA");
		my $prevatomC = $pdb1->GetAtomFromResidueAndType($prevres->GetResNum(),"C");
		my $prevatomN = $pdb1->GetAtomFromResidueAndType($prevres->GetResNum(),"N");

        my $prevpotCA = util_GetPotForAtom($prevatomCA,$pqr1,$pots1) *1  ;
        my $prevpotN = util_GetPotForAtom($prevatomN,$pqr1,$pots1) *1  ;
        my $prevpotC = util_GetPotForAtom($prevatomC,$pqr1,$pots1) *1  ;

		my $pd = $potN - $prevpotC ; 
		my $pdCA = util_format_float($potCA - $prevpotCA);
		my $d = util_format_float($pdb1->DistanceAtoms($N,$prevatomC),1);
		print "$pdCA $pd $d = CN \n";

		my $abspd = abs($pd);
		#next if($abspd < 60 ); 

		print $ofhpot "$resnum $pd \n";
		


		print $ofhrmsd "$resnum $d \n";
		#print $ofhNext "$resnum $pdAndNext \n";

		$prevres = $res ; 
		$prevpd = $pd ; 
	}
}


    

sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
