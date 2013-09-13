#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($infile,$pdb,$outfile,$which_tech);
GetOptions(
            "pdb=s"=>\$pdb ,
            "infile=s"=>\$infile ,
            "outfile=s"=>\$outfile 
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
usage( "Need to give a  pdb name => option -pdb ") if(!defined $pdb);
my $ofh = util_write($outfile);
usage( "Need to give a input file name => option -infile ") if(!defined $infile);
my $ifh = util_read($infile);

print "HEE $infile \n";
sleep (1);
my $found = 0 ; 
while(<$ifh>){
     next if(/^\s*$/);
	 if(/http.*dx.doi.org/){
	 print ;
	 	#my ($num) = (/http.*dx.doi.org\/.*\/(bi\d+)/);
	    #print $ofh  "wget \"http://pubs.acs.org/doi/pdf/10.1021/$num\" -O $pdb.pdf\n";
	 	my ($num) = (/href=\"(.*)\" /);
		print "NUM = $num\n";
	    #print $ofh  "wget \"$num\" -O $pdb.final.html\n";
	    print $ofh  "firefox \"http://nist.rcsb.org/pdb/explore/pubmedArticle.do?structureId=$pdb\" \n";
	    print $ofh  "firefox \"$num\" \n";
		$found = 1 ;
		last; 
	 }
}
$ifh = util_read($infile);
while(<$ifh>){
     last if($found);
	 if(/href/){
	    print ;
	 	my ($num) = (/href=\"(.*)\" /);
		print "NUM = $num\n";
	    #print $ofh  "wget \"$num\" -O $pdb.final.html\n";
	    print $ofh  "firefox \"http://nist.rcsb.org/pdb/explore/pubmedArticle.do?structureId=$pdb\" \n";
	    print $ofh  "firefox \"$num\" \n";
		$found = 1 ;
		last; 
	 }
}
chmod 0777, $outfile ;
sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
