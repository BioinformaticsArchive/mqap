#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use ConfigPDB;
use MyGeom;
use ParsePDB;
use PDB;

use Time::HiRes qw( usleep ualarm gettimeofday tv_interval clock_gettime clock_getres  clock);
use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($infile,$outfile,$which_tech,$chain,$model,$listfile,$protein);
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
            "chain=s"=>\$chain ,
            "model"=>\$model ,
           );
usage( "Need to give a protein pdb id -option -protein  ") if(!defined $protein);
my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC) = util_SetEnvVars();



if(defined $model){
    my $pdb = "$protein.pdb";
    my $PDB = ParsePDB->new (FileName => $pdb);
    $PDB->Parse;
	$PDB->RenumberChains (ChainStart => 'A');
    my @models = $PDB->WriteModels;
}
elsif(defined $chain){
       my $PDB = ParsePDB->new (FileName => $chain);
       $PDB->Parse;
       my $Chain = $PDB->GetChain(ChainLabel => 'A');
	   if(defined $Chain){
	   	  print "Writing Chain A\n";
          $PDB->WriteChains;
	   }
}



sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}



