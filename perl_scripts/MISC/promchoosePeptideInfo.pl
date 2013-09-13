#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use ConfigPDB;
use MyGeom;
use PDB;

use Time::HiRes qw( usleep ualarm gettimeofday tv_interval clock_gettime clock_getres  clock);
use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($number,$scale,$population,$infile,$scores,$fastadir,$peptideinfo,$outfile,$id,$dist,$which_tech,$listfile,$protein);
my (@expressions,$stats);
my $howmany = 100000 ;
my $verbose = 1 ;
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "scale"=>\$scale ,
            #"protein=s"=>\$protein ,
            "scores=s"=>\$scores ,
            "peptideinfo=s"=>\$peptideinfo ,
            "id=s"=>\$id ,
            "population=s"=>\$population ,
            "infile=s"=>\$infile ,
            "stats=i"=>\$stats ,
            "number=i"=>\$number ,
            "listfile=s"=>\$listfile ,
            "fastadir=s"=>\$fastadir ,
            "outfile=s"=>\$outfile ,
            "expr=s"=>\@expressions,
            "howmany=i"=>\$howmany ,
            "dist=i"=>\$dist ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output dir name=> option -outfile ") if(!defined $outfile);
usage( "Need to number file=> option -number ") if(!defined $number);
usage( "Need to give a listfile -option -listfile  ") if(!defined $listfile);
my $CNT = 0 ; 
my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC) = util_SetEnvVars();
my $PWD = cwd;

system("mkdir -p $outfile");


my @list= util_read_list_sentences($listfile);
my $list = {};
map { s/\s*//g ; $list->{$_} = 1 ; } @list ;


foreach my $protein (@list){
    GetPeptideInfo($protein,$number);
    
}



sub GetPeptideInfo{
   my ($protein,$number) = @_ ; 
   foreach my $dist (1..15){
	  my $peptideinfo = "$protein/$protein.$dist.peptideinfo";
	  my $pepinfo = {};
      util_readPeptideInfo($pepinfo,$protein,$peptideinfo);
	  my $nres = $pepinfo->{$protein}->{NRES};
	  my $diff = abs ($nres - $number);
	  if($nres >= $number){
	  #if($diff < 1){
	  	  system("cp -rf $peptideinfo $outfile/$protein.peptideinfo");
	  	  system("cp -rf $peptideinfo $outfile/ ");
		  return ; 
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
