#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use MyUtils;
use ConfigPDB;
use MyGeom;

use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($infile,$outfile,$which_tech,$listfile);
my (@expressions);
my $howmany = 100000 ;
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "expr=s"=>\@expressions,
            "howmany=i"=>\$howmany ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
my $ofh = util_write($outfile);
usage( "Need to give a listfile -option -listfile  ") if(!defined $listfile);
my $ofh = util_write($outfile);
my $CNT = 0 ; 
my ($RESULTDIR,$PDBDIR,$FASTADIR) = util_SetEnvVars();


my @list= util_read_list_words($listfile);
my $list = {};
map { $list->{$_} = 1 ; } @list ;

my $done = 0 ;
my $ign = 0 ;
foreach my $i (@list){
   my $resultsfile = "$i.dir/results.cons";
   if(! -e $resultsfile){
   	warn "$resultsfile doesnt exist\n";
	$ign++;
	next;
   }
   my $infile = $i;
   my $ifh = util_read($infile);
   my $saved ;
   while(<$ifh>){
   		if(/^ATOM/){
	       my (@l) = split ;
	       my $v1 = $l[7];
	       my $v2 = $l[8];
		   $saved = "$v1 $v2 ";
	   }
   }
   close($ifh);
   $ifh = util_read($resultsfile);
   my $written = 0 ;
   while(<$ifh>){
        if(/\*\*\*/){
          s/\*\*\*//g;
	      my (@l) = split ;
	      my $v1 = ($l[4]);
	      my $v2 = ($l[9]);
		  #print "pot = $v1 $v2\n";
		  my $d = $v2 - $v1 ;
		  print $ofh "$saved $d \n"; 
          $written = 1 ;
		}
   }
   if($written){
        $done++;
  }
  else{
      $ign++;
  }
      
   close($ifh);
}

print STDERR "Output written in $outfile\n";
print STDERR "done = $done , ignored = $ign \n";

chmod 0777, $outfile ;
sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
