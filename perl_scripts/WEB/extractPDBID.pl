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
my $found = 0 ; 
while(<$ifh>){
     next if(/^\s*$/);
	 if(/list_uids/){
	 	my ($num) = (/list_uids=(\d+)/) or die "$_\n";
	    print $ofh "#$num  \n";
	    print $ofh  "wget \"http://www.ncbi.nlm.nih.gov/pubmed/$num\?dopt=Abstract\" -O $pdb.abstract.html \n";
		$found = 1 ; 
	 }
	 elsif(/Not in PubMed/){
		$found = 1 ; 
	    print $ofh  "echo Not in PubMed > ! $pdb.abstract.html \n";
	 }
}
die "Did not find number in pdb $pdb \n" if(!$found);
chmod 0777, $outfile ;
sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
