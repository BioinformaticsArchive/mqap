#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use MyGeom;
use PDB;
use ConfigPDB;
use Algorithm::Combinatorics qw(combinations) ;
use Math::NumberCruncher;

use Time::HiRes qw( usleep ualarm gettimeofday tv_interval clock_gettime clock_getres  clock);
use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($infile,$outfile,$which_tech,$listfile,$protein);
my (@expressions);
my $howmany = 100000 ;
my $verbose = 1 ;
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "protein=s"=>\$protein ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "expr=s"=>\@expressions,
            "howmany=i"=>\$howmany ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
my $ofh = util_write($outfile);
usage( "Need to give a input file name => option -infile ") if(!defined $infile);
my $ifh = util_read($infile);
usage( "Need to give a listfile -option -listfile  ") if(!defined $listfile);
usage( "Need to give a protein pdb id -option -protein  ") if(!defined $protein);
my $CNT = 0 ; 
my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC) = util_SetEnvVars();
my $PWD = cwd;

my  ($seconds, $microseconds) = gettimeofday;

my $pdb = "$PDBDIR/$protein.pdb";
my $pdb1 = new PDB();
$pdb1->ReadPDB($pdb);


my @list= util_read_list_words($infile);
my $list = {};
map { s/\s*//g ; $list->{$_} = 1 ; } @list ;


my $N = @list ; 
my $r = 3 ; 
print "$N = MMM \n";

foreach my $i (3..$N){
   print STDERR "Processing for motif length $i\n";
   ProcessOneLength(\@list,$i);
}

sub ProcessOneLength{
   my ($l,$r) = @_ ; 
   $, = " , " ; 
   my $dirname = "dir$r";
   print STDERR "\t created dir $dirname\n";
   `mkdir -p $dirname` ;
   `cp -f $listfile $dirname/list.all` ;
   if(-e "grd"){
       `cp -f grd $dirname/` ;
   }
   my $ofhtop = util_write("$dirname/top");
   print $ofhtop "$protein\n";

   
   my $ofhlist = util_write("$dirname/list.number");
   my @l3 = GetCombinations($l,$r);
   my $cnt = 0 ;
   foreach my $i (@l3){
	   $cnt++;
	   my @l = @{$i};
	   my @nl = DiffLists($l,$i);

	   my $file = "$dirname/$cnt.in";
       my $ofhtemp = util_write($file);
	   print $ofhtemp @l , "\n";
	   close($ofhtemp);

	   $file = "$dirname/$cnt.not";
       $ofhtemp = util_write($file);
	   print $ofhtemp @nl , "\n";
	   close($ofhtemp);
   
	   print $ofhlist "$cnt\n";
   }
   
   close($ofhlist);
}

sub DiffLists{
	my ($l1,$l2) = @_ ; 
    my $table = util_make_table($l2);
	my @ret ; 
	foreach my $i (@{$l1}){
		if(!exists $table->{$i}){
			push @ret, $i ;
		}
	}
	return @ret;
}



sub GetCombinations{
   my ($l,$n) = @_ ; 
   my $iter = combinations($l, $n);
   my @ret ; 
   while (my $c = $iter->next) {
   	  push @ret, $c ;
   }
   return @ret ; 
}



sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
