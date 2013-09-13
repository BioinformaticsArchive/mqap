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
while(<$ifh>){
     next if(/^\s*$/);
	 s/\s*//g;
	 my $name = $_ . ".abstract";
     my $input = util_read($name);
	 print "\n\n\n<p>                  <\/p>\n";
	 print "<p>                  <\/p>\n";
	 print "<p>                  <\/p>\n";
	 print "<p> $_                 <\/p>\n";
     while(<$input>){
		if(/^\s*\<title/){
	       print $_ ; 
		}

	 	if(/abstract_label/){
	       print $_ ; 
		}
		elsif(/Not in PubMed/){
	       print $_ ; 
			
		}
	 }
	 close($input); 
}
chmod 0777, $outfile ;
sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
