#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use MyUtils;
use ConfigPDB;
use BP;

use Bio::Perl;
use Bio::DB::SwissProt;
use Bio::Tools::Run::Alignment::Clustalw;
use Bio::AlignIO;
use Bio::Align::DNAStatistics;
use Bio::Tree::DistanceFactory;
use Bio::TreeIO;
use Bio::Tree::Draw::Cladogram;



use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($infile,$outfile,$id,$listfile);
my (@expressions);
my $howmany = 100000 ;
GetOptions(
            "id=s"=>\$id ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "expr=s"=>\@expressions,
            "howmany=i"=>\$howmany ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);

print "Parsing /home/sandeepc/mapping.txt \n";
my $info = util_read_Mapping_PDB_2_SWISSPROT("/home/sandeepc/mapping.txt");
print "Parsed /home/sandeepc/mapping.txt \n";
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
my $ofh = util_write($outfile);


my $id = "ALL";

my $cnt = 0 ;
foreach my $pdbid (keys %{$info}){

   my $swissid = $info->{$pdbid}->{SWISSID};
   $pdbid = uc($pdbid);
   my $nm = "$pdbid.$id.$swissid.fasta";
   next if($nm =~ /HASH/);
   if(! -e $nm){
   	   print $ofh "getSingleFasta.pl -pdb $pdbid -swis $swissid \n";
	   $cnt++;
   }
}

print "Did not find $cnt number of proteins: written in outfile";





chmod 0777, $outfile ;
sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
