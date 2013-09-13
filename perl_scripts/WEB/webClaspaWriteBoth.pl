#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use MyWeb;
use ConfigPDB;
use MyGeom;
use PDB;

use Time::HiRes qw( usleep ualarm gettimeofday tv_interval clock_gettime clock_getres  clock);
use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($infile,$outfile,$which_tech,$listfile,$query);
my (@expressions,$dir);
my $howmany = 100000 ;
my $verbose = 1 ;
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "dir=s"=>\$dir ,
            "query=s"=>\$query ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "expr=s"=>\@expressions,
            "howmany=i"=>\$howmany ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
my $ofh = util_write($outfile);
usage( "Need to give a query pdb id -option -query  ") if(!defined $query);
usage( "Need to give a dir id -option -dir  ") if(!defined $dir);
print STDERR "Output written in $outfile\n";


	my $title = " Results for PDB id: $query\n";
    web_printHtmlHead($ofh,$title);
	my $link1 = web_makeLink("Click to get further moonlighting and promiscuous functions in protein with PDB id $query","$query.3.sorted.annotated");
	my $link2 = web_makeLink("Click to see whether the activity of protein with PDB id $query is present in the list of proteins","$query.single.sorted.annotated");
	print $ofh  "<h1>$link1</h1>\n";
	print $ofh  "<h1>$link2</h1>\n";
	web_printHtmlEnd($ofh);


chmod 0777, $outfile ;

sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
