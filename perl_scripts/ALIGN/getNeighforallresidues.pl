#ppl!/usr/bin/perl -w 
use strict ;
use PDB;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use Algorithm::Combinatorics qw(combinations) ;
use MyUtils;
use ConfigPDB;
use MyGeom;
use MyPymol;
use Math::Geometry ;
use Math::VectorReal qw(:all);  # Include O X Y Z axis constant vectors




use Time::HiRes qw( usleep ualarm gettimeofday tv_interval clock_gettime clock_getres  clock);
use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($p1,$p2,$infile,$outfile,$dist,$which_tech,$listfile,$protein);
my (@expressions);
my $maxdist = 3 ;
my $verbose = 1 ;
my ($moveZ,$verify,$decaaf,$before1,$before2);
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "protein=s"=>\$protein ,
            "verify"=>\$verify ,
            "p1=s"=>\$p1 ,
            "p2=s"=>\$p2 ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "expr=s"=>\@expressions,
            "maxdist=i"=>\$maxdist ,
            "moveZ=i"=>\$moveZ ,
            "dist=f"=>\$dist ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
my $ofh = util_write($outfile);
my $ofhclose = util_write("log.close");
usage( "Need to give a protein 1 id -option -p1  ") if(!defined $p1);
usage( "Need to give a dist -option -dist  ") if(!defined $dist);
my $CNT = 0 ; 
my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC) = util_SetEnvVars();
my $PWD = cwd;


my $file1 = "$PDBDIR/$p1.pdb";
my $pdb1 = new PDB();
$pdb1->ReadPDB($file1);

my @res = $pdb1->GetResidues();
my $N = @res;
my $cnt = 0 ;
my $sum = 0 ;
my $cntmatch = 0 ; 

my $DB = {};
my $done = {};
foreach my $res (@res){
    $cnt++;
    next if($res->GetAtomStr() ne "ATOM");
	my $resnum = $res->GetResNum();
    my $CAatom = $pdb1->GetAtomFromResidueAndType($resnum,"CA");

	    my @atomlist ;
	    push @atomlist, $CAatom ;
	    my ($results,$combined) = $pdb1->GetNeighbourHoodAtom(\@atomlist,$dist);
	    my $sort ;
		my @goodatoms ; 
		my $residues = {};
		my @Rlist ;
        foreach my $j (@{$combined}){
		    my $atomstr = $j->GetAtomStr();
			next if($atomstr eq "HETATM");
		    my $resnum = $j->GetResNum(); 
			if(!exists $residues->{$resnum}){
			    $residues->{$resnum} = 1 ;
			    my ($res) = $pdb1->GetResidueIdx($resnum);
				push @Rlist, $res ; 
			}
		}

		my $N = @Rlist ; 
		my $iter = combinations(\@Rlist, 3);
		while (my $c = $iter->next) {
		    my @combo = @{$c} ;
		    my @resultssorted = sort { $a->PrintSingleLetter($pdb1) gt $b->PrintSingleLetter($pdb1) } @combo ;
			#print "===============\n";
		    my $nm = "";
		    my $index = "";
			foreach my $r (@resultssorted){
				my $n = $r->GetResNum();
				my $type = $r->PrintSingleLetter($pdb1);
				$nm = $nm . $type ;
				$index = $index . "." . $n ; 
			}
			if(!exists $done->{$index}){
				$done->{$index} = 1 ; 
				if(!exists $DB->{$nm}){
				    $DB->{$nm} = [];	
				}
				push @{$DB->{$nm}}, $index ; 
			}
		}
		print "$cnt has $N resodues \n";
}

foreach my $k (keys %{$DB}){
	my @l = @{$DB->{$k}};
    print $ofh "$k ";
	foreach my $i (@l){
		print $ofh "$i ";
	}
    print $ofh "\n";
}


sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}

