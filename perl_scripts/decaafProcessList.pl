#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use MyGeom;
use PDB;
use ConfigPDB;

use Time::HiRes qw( usleep ualarm gettimeofday tv_interval clock_gettime clock_getres  clock);
use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($infile,$outfile,$which_tech,$listfile,$protein);
my (@expressions);
my $cutoff ;
my $verbose = 1 ;


my $CUTOFFFORNUMER = 6 ;
my $IGNOREBADMATCHES = 1 ;

GetOptions(
            "which_tech=s"=>\$which_tech ,
            "protein=s"=>\$protein ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "expr=s"=>\@expressions,
            "cutoff=i"=>\$cutoff ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
my $ofh = util_write($outfile);
usage( "Need to give a input file name => option -cutoff ") if(!defined $cutoff);
usage( "Need to give a listfile -option -listfile  ") if(!defined $listfile);
my $CNT = 0 ; 
my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC) = util_SetEnvVars();
my $PWD = cwd;


my @list= util_read_list_sentences($listfile);

my $info = {};
foreach my $i (@list){
	ProcessSingleFile($i);
}

my @results ; 
foreach my $k (keys %{$info}){
	 my $score = $info->{$k}->{SCORES} ; 
	 my $num = $info->{$k}->{NUM} ; 
	 my $r = {};
	 $r->{ORIGNUM} = $num ;
	 $r->{ORIGSCORE} = $score ;
	 $num = 1 if($num eq 0);
	 my $modified = util_format_float($score/($num),3) ; 
	 print "$k $modified $score $num\n";
	 $r->{NAME} = $k ;
	 $r->{SCORE} = $modified ;
	 push @results, $r ; 
}

print STDERR "final list written in $outfile \n";
my @resultssorted = sort { $a->{SCORE} <=> $b->{SCORE} } @results ; 
foreach my $r (@resultssorted){
	next if($r->{ORIGNUM} < $CUTOFFFORNUMER);
	print $ofh "$r->{NAME} $r->{SCORE}  $r->{ORIGSCORE} $r->{ORIGNUM} \n";
}


sub ProcessSingleFile{
    my ($filenm) = @_ ; 
	print STDERR "Processing file $filenm \n";
    my $ifh = util_read($filenm);
    while(<$ifh>){
         next if(/^\s*$/);
         chop ;
	     my @l = split ; 
		 my $N = @l - 1 ;
		 my $pdb = $l[0];
		 my $score = $l[$N];
		 if ($score > $cutoff){
		 	next if($IGNOREBADMATCHES);
		 	$score = 2 ; 
		 }
		 $info->{$pdb} = {} if(!defined $info->{$pdb});
		 $info->{$pdb}->{SCORES} = 0 if(!defined $info->{$pdb}->{SCORES});
		 $info->{$pdb}->{NUM} = 0 if(!defined $info->{$pdb}->{NUM});

		 $info->{$pdb}->{SCORES} = $info->{$pdb}->{SCORES} + $score ; 

		 if ($score <= $cutoff){
		       $info->{$pdb}->{NUM} = $info->{$pdb}->{NUM} + 1 ; 
		 }
    }
    close($ifh);
}


sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
