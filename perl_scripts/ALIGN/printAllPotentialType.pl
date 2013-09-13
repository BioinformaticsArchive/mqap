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
my ($ann,$resnum,$config,$type,$p1,$p2,$infile,$outfile,$which_tech,$listfile,$protein);
my $maxdist ;
my $DISTANCEWITHOUTSEQMATCH = 1 ;
my $verbose = 1 ;

my ($all,$radii,$before1,$before2);
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "protein=s"=>\$protein ,
            "all"=>\$all ,
            "p1=s"=>\$p1 ,
            "p2=s"=>\$p2 ,
            "type=s"=>\$type ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "ann=s"=>\$ann ,
            "maxdist=f"=>\$maxdist ,
            "config=s"=>\$config,
            "radii=i"=>\$radii ,
            "resnum=i"=>\$resnum ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
usage( "Need to give a config file name => option -config ") if(!defined $config);
usage( "Need to give a file name => option -protein ") if(!defined $protein);
usage( "Need to give a file name => option -type ") if(!defined $type);


my $ofh = util_write($outfile);
my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC) = util_SetEnvVars();
my $PWD = cwd;

ConfigPDB_Init($config);


my $info = {};
my @resultlines ;
my @proteins ;
push @proteins, $protein; 


my @info = util_ReadPdbs($PDBDIR,$APBSDIR,0,@proteins) ; 
my $info = shift @info ;
my $pdb1 = $info->{PDBOBJ};

my @reslist1 = $pdb1->GetResidues();
foreach my $r (@reslist1){
	my $nm = $r->GetName();
	if($nm =~ /$type/i){
	    my $idx = $r->GetIdx();
	    print "$nm $idx \n";
		system ("printAllPotential.pl -outf $outfile -con $config -pr $protein -res $idx");
	}
}


sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
