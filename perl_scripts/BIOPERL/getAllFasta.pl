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

## remove this file before you start running this script in a loop
my $outfile = "/tmp/kkkkk";
system("touch $outfile");

my @ignore = ();
my $ifh = util_read($outfile);
my $last = <$ifh>;
chop $last ;
$last =~ s/\s*//g;
$last = lc($last);
print "last = $last \n";
close $ifh ;

my $id = "ALL";
my $arr ; 
my $ignore = {};
map { $ignore->{$_} = 1 ; } @ignore ; 

my $start = 1 ; 
$start = 0 if($last =~ /^\s*$/);

my $cnt = 0 ;
foreach my $pdbid (keys %{$info}){

   my $swissid = $info->{$pdbid};
   if($start && !($pdbid =~ /$last/)){
   	   $cnt++ ;
       next ;
   }
   elsif( $pdbid =~/$last/){
   	 $start = 0 ; 
	 print "Ignored $cnt \n";
	 sleep(1);
	 next ;
   }

   next if($ignore->{$swissid});

   $pdbid = uc($pdbid);
   my $nm = "$pdbid.$id.$swissid.fasta";
   next if($nm =~ /HASH/);
   print "$nm \n";
   
   my $ofh = util_write($outfile);
   print $ofh "$pdbid\n";
   close $ofh ;

   (BP_GetSequence($id,$done,$arr,$pdbid,$swissid,1));
}





chmod 0777, $outfile ;
sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
