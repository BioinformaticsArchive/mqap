#!/usr/bin/perl -w 
use strict ;
use PDB;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use ConfigPDB;
use MyGeom;
use Math::Geometry ;
use Math::VectorReal qw(:all);  # Include O X Y Z axis constant vectors
use BP;




use Time::HiRes qw( usleep ualarm gettimeofday tv_interval clock_gettime clock_getres  clock);
use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($p1,$p2,$infile,$outfile,$which_tech,$listfile,$protein);
my (@expressions);
my $maxdist = 6 ;
my $verbose = 1 ;
my ($verify,$before1,$before2);
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
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
my $ofh = util_write($outfile);
my $ofhclose = util_write("log.close");
usage( "Need to give a input file name => option -infile ") if(!defined $infile);
usage( "Need to give a protein 1 id -option -p1  ") if(!defined $p1);
usage( "Need to give a protein 2 id -option -p2  ") if(!defined $p2);
my $CNT = 0 ; 
my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC) = util_SetEnvVars();
my $PWD = cwd;


my $file1 = "$PDBDIR/$p1.pdb";
my $file2 = "$PDBDIR/$p2.pdb";
my $pdb1 = new PDB();
$pdb1->ReadPDB($file1);
my $pdb2 = new PDB();
$pdb2->ReadPDB($file2);

my $info = {};

my ($atoms1,$atoms2) = getResultsLine($infile,$pdb1,$pdb2);

#$atoms1 = sortOnResNum($atoms1);

my ($s1) = ProcessAtomsToGetSeq($atoms1,$pdb1);
my ($s2) = ProcessAtomsToGetSeq($atoms2,$pdb2);

print "$s1 $s2 \n";

my $outfileforneedle = "tmp.out.needle";
my $f1 = "/tmp/sandeep.1";
my $f2 = "/tmp/sandeep.2";
unlink $f1 ;
unlink $f2 ;
system("echo $s1 > $f1");
system("echo $s2 > $f2");
BP_Needle($outfileforneedle,"/",$f1,$f2); 

sub ProcessAtomsToGetSeq{
   my ($atoms,$pdb) = @_ ; 
   my $finalStr = "";
   my $neighresidues ;
   foreach my $i (@{$atoms}){
   
	   print "Remaining Atom\n";
	   print "=====================\n";
	   #$i->Print();
	   #$i->Print($ofhclose);
		my $LEN = 1 ;
	    my $atomlist = util_make_list($i);
        my $maxdist = 4 ; 
        my ($results,$combined) = $pdb->GetNeighbourHoodAtom($atomlist,$maxdist);
        foreach my $j (@{$combined}){
            my $resnum = $j->GetResNum();
	        $neighresidues->{$resnum} = $j ; 
        }

	
	    my $LEN = 1 ;
		my ($neighbouringresidues,$neighbouringresiduereplaced) = $pdb->NeighbouringResiduesofAtom($i,$i,$LEN);
		my $str = "";
		foreach my $r (@{$neighbouringresidues}){
			my $x =  $r->PrintSingleLetter($pdb);
			$str = $str . $x ;
		}
		print "$str - existing\n";
		$finalStr = $finalStr . $str ;

	
   }
	print "RES===\n";
    foreach my $k (keys %{$neighresidues}){
	   my $v = $neighresidues->{$k};
	   my $nm = $v->GetResName();
	   next if($nm eq "HOH");
	   next if($nm eq "ZN");
	   print "$nm $k iiiii\n";
    }
	return $finalStr ;
}

sub sortOnResNum{
	my ($atoms) = @_ ; 
	my @sorted = sort { $a->GetResNum() <=> $b->GetResNum() } (@{$atoms});
	return \@sorted ;
}



print STDERR "Output written in $outfile\n";

chmod 0777, $outfile ;
sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}

sub getResultsLine{
    my ($in,$p1,$p2) = @_ ; 
    my $ifh = util_read($in);
    my @l ; 
	my ($a1,$a2);
    while(<$ifh>){
	    next if(/RESULT/);
		print $_ ;
		if(!defined $a1){
		    $a1 = $p1->ParseResultLine($_) ;
		    next ;
		}
		if(!defined $a2){
		    $a2 = $p2->ParseResultLine($_) ;
		     next;
		}
    }
    return ($a1,$a2);
}
