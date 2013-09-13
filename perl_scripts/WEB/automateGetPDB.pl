#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($infile,$outfile,$which_tech);
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "infile=s"=>\$infile ,
            "outfile=s"=>\$outfile 
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
my $ofh = util_write($outfile);
usage( "Need to give a input file name => option -infile ") if(!defined $infile);
my $ifh = util_read($infile);
while(<$ifh>){
     next if(/^\s*$/);
     chop ;
	 s/\s*//g;
	 my $i = $_ ; 
	 print $ofh "wget \"http://nist.rcsb.org/pdb/explore/pubmedArticle.do\?structureId=$i\" -O $i.html  \n";
	 print $ofh "extractPDBID.pl -in $i.html -out $i.out.csh -pdb $i \n";
	 print $ofh "source $i.out.csh\n";
}

chmod 0777, $outfile ;
sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
