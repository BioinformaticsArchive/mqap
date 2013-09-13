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
my ($infile,$outfile,$which_tech,$listfile,$protein);
my (@expressions);
my $thresh ;
my $verbose = 1 ;
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "protein=s"=>\$protein ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "expr=s"=>\@expressions,
            "thresh=i"=>\$thresh ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
usage( "Need to give a input file name => option -infile ") if(!defined $infile);
usage( "Need to give a input file name => option -thresh ") if(!defined $thresh);
my $ifh = util_read($infile);
my $info = {};

my @commands ; 
while(<$ifh>){
	chomp;
	push @commands ,$_ ;
}

while(@commands){
   my $loadstr = ` cat /proc/loadavg `;
   my ($x,$y,$z) =  split " ", $loadstr ;
   my $load = $x ; 
   if($load < $thresh){
   	   print "$load = load \n";
   	   my $command = shift @commands ;
	   $command = $command . " > & ! /dev/null ";
       my $ofh = util_write($outfile);
   	   print $ofh "#\!/bin/csh -f \n";
   	   print $ofh "$command \n";
	   close($ofh);
       chmod 0777, $outfile ;
	   print "Scheduling command $command \n";
	   system("./$outfile &");
       sleep 2 ;
   }
   else{
      sleep 5 ; 
   }
  
}

sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
