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
my ($infile,$outfile,$which_tech,$listfile,$protein);
my (@expressions,$config);
my $howmany ;
my $verbose = 1 ;
my $LARGESTDISTALLOWED = 30 ;
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "protein=s"=>\$protein ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "expr=s"=>\@expressions,
            "config=s"=>\$config,
            "howmany=i"=>\$howmany ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
usage( "Need to give a config file name => option -config ") if(!defined $config);
usage( "Need to give a listfile -option -listfile  ") if(!defined $listfile);
#usage( "Need to give a howmany -option -howmany  ") if(!defined $howmany);
usage( "Need to give a protein pdb id -option -protein  ") if(!defined $protein);
my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC) = util_SetEnvVars();
my $PWD = cwd;

my  ($seconds, $microseconds) = gettimeofday;

my $file1 = "$PDBDIR/$protein.pdb";
my $pdb1 = new PDB();
$pdb1->ReadPDB($file1);
ConfigPDB_Init($config);

my @list= util_read_list_sentences($listfile);
my $list = {};
my @reallist ; 
#map {my @j = split ; push @reallist, @j;  } @list ;
map { s/,/ /g ; my @j = split ; push @reallist, @j;  } @list ;
map { s/\s*//g ; $list->{$_} = 1 ; } @reallist ;

#my $size = @reallist ;
my @chain;
my @atoms ; 
my $done ;
my $original ;
my $CNT = 0 ; 
foreach my $i (@reallist){
	print "$i\n";
	$CNT++ ;
	$i =~ s/,//g;
	my ($name,$number) = ($i =~ /([a-zA-Z]+)([0-9]+)/);
	$name = uc($name);
	#print "$name,$number \n";
	my $len = length($name); 
	die "Wrong length $len" if($len != 1 && $len != 3);
	if($len == 1){
	      $name = $pdb1->GetThreeLetter($name);
	}
	#print "$name,$number \n";

	my ($res) = $pdb1->GetResidueIdx($number);
	my $type = ConfigPDB_GetAtom($res->GetName()) or die;
	print "$name,$number,$type \n";
	my ($atom1) = $pdb1->GetAtomFromResidueAndType($number,$type);
	$atom1->Print();
	push @atoms, $atom1 ;
	$done->{$number} = 1 ; 
	$original->{$number} = 1 ; 


	push @chain,$name;
	push @chain,$number;
	if(defined $howmany && $howmany && $CNT eq $howmany){
		last ; 
	}
}

my $DIFF = $howmany - $CNT ;


if($howmany && $DIFF){
    my $dist = 1; 
	my $CCC = 0 ; 
    while($dist < 7){
	    print "Need $DIFF more atoms for dist $dist\n";
        foreach my $atom1 (@atoms){
	        my $list = util_make_list($atom1);
	        my ($junk,$neigh)  = $pdb1->GetNeighbourHoodAtom($list,$dist);
        
	        foreach my $a (@{$neigh}){
	            my $number = $a->GetResNum();
	            $done->{$number} = 1 ; 
	        }
        }
	    $dist++ ; 
	    my $nkeys = keys %{$done}; 
	    my @keys = (keys %{$done}); 
	    if($nkeys >= $howmany){
		    ## Choose $howmany 
			 my $added = 0 ; 
			 while($CCC < $DIFF && @keys){
			 	my $key = shift @keys ; 
				next if(! defined $key);
				print "key = $key\n";
				if(!exists $original->{$key}){

					print "\t adding number $key\n";
	                my ($res) = $pdb1->GetResidueIdx($key);
				    my $name = $res->GetName();
	                my $type = ConfigPDB_GetAtom($res->GetName()) ;

    
					if(defined $type){
	                   my ($atom1) = $pdb1->GetAtomFromResidueAndType($key,$type);
	                   push @atoms, $atom1 ;
					    $CCC++;
	                    push @chain,$name;
	                    push @chain,$key;
					}

				}
			 }

		     last if($CCC eq $DIFF); 
	    }
    }
}

my @distlist = sort @{$pdb1->DistanceInGivenSetOfAtoms(\@atoms)};
my $N = @distlist - 1 ;
my $largestdist = $distlist[$N];
if($largestdist > $LARGESTDISTALLOWED){
	$, = " , " ;
	print "Distances are @distlist \n";
    die "Error: $protein: Largest distance = $largestdist  more than $LARGESTDISTALLOWED"  ;
}


my $size = @chain /2 ;
ConfigPDB_PrintOutConf($outfile,$protein,$size,\@chain,1);

sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
