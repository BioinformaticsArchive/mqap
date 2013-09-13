#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use MyUtils;
use PDB ;
use ConfigPDB;

use POSIX qw(floor);
use Primer;
use Bio::Tools::CodonTable;
my $myCodonTable   = Bio::Tools::CodonTable->new();

my $commandline = util_get_cmdline("",\@ARGV) ;
my ($infile,$outfile,$id,$listfile);
my (@expressions,$ANNDIR);
my $dist ;
GetOptions(
            "id=s"=>\$id ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "anndir=s"=>\$ANNDIR ,
            "expr=s"=>\@expressions,
            "dist=i"=>\$dist ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a listfile -option -listfile  ") if(!defined $listfile);
usage( "Need to give a output file name => option -dist ") if(!defined $dist);
usage( "Need to give a output anndir option -anndir ") if(!defined $ANNDIR);
my ($grpconfig) = $ENV{CONFIGGRP} or die ;
ConfigPDB_Init($grpconfig);


print "Using ANNDIR $ANNDIR \n";




my @list= util_read_list_sentences($listfile);
my $list = {};
map { 
   my $pdb = new PDB();
   my $nm = $_ ; 
   my $annfile = "$ANNDIR/$nm.outconf.annotated";
   my $annfiledist = "$ANNDIR/dist";
   my $annclose = "$ANNDIR/$nm.outconf.annotated.close";
   my $annfasta = "$ANNDIR/$nm.ALL.$dist.fasta";
   if(! -e $annfasta && ! -e $annfiledist && ! -e $annclose && ! -e $annfasta){
        my ($tableResidues,$nresidues,$closeAtoms) =  Config_ReadAnnfile($_,$ANNDIR,$dist,$pdb); 
   }

} @list ;




sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
