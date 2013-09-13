#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use MyGeom;
use PDB;
use Bio::SeqIO;
use Bio::Tools::CodonTable;
use Bio::SeqUtils;
use ConfigPDB;

use Time::HiRes qw( usleep ualarm gettimeofday tv_interval clock_gettime clock_getres  clock);
use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($infile,$outfile,$which_tech,$listfile,$protein);
my (@expressions,$config);
my $howmany = 100000 ;
my $verbose = 1 ;
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "protein=s"=>\$protein ,
            "config=s"=>\$config ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "expr=s"=>\@expressions,
            "howmany=i"=>\$howmany ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
my $ofh = util_append($outfile);
usage( "Need to give a input file name => option -infile ") if(!defined $infile);
my $ifh = util_read($infile);
usage( "Need to give a protein pdb id -option -protein  ") if(!defined $protein);
usage( "Need to give a config file name => option -config ") if(!defined $config);

my $CNT = 0 ; 
my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC) = util_SetEnvVars();
my $PWD = cwd;


ConfigPDB_Init($config);
my $pdb1 = new PDB();



my $seqio = Bio::SeqIO->new(-file => $infile, '-format' => 'Fasta');
while(my $seq = $seqio->next_seq) {
  my $string = $seq->seq;
  my @ALL = ($string =~ /./g);
  my $LEN = @ALL;
  #my @l = qw (Asp Glu Gly Ala Pro Leu Val );
  my @l = qw (Trp Phe Tyr );
  my $sum = 0; 
  foreach my $i (@l){
  	my $one = $pdb1->GetSingleLetter($i);
    my @M = ($string =~ /$one/g);
    my $N = @M ; 
	$sum = $sum + $N ; 
    print "$i $one $LEN $N \n";
  } 
  my $percent = (100 * $sum )/$LEN ; 
  print $ofh "$protein $percent\n";

  # do stuff with $string
}

sub usage{
    my ($msg) = @_ ;
	    print $msg , "\n" ;
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
		    die ;
			}
