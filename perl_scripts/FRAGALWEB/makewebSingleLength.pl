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
my ($title,$infile,$outfile,$which_tech,$listfile,$query);
my (@expressions,$dir,$thresh,$size);
my @threshes ;
my $howmany = 100000 ;
my $verbose = 1 ;
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "dir=s"=>\$dir ,
            "query=s"=>\$query ,
            "infile=s"=>\$infile ,
            "title=s"=>\$title ,
            "outfile=s"=>\$outfile ,
            "expr=s"=>\@expressions,
            "howmany=i"=>\$howmany ,
            "thresh=i"=>\@threshes ,
            "size=i"=>\$size ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
my $ofh = util_write($outfile);
print STDERR "Output written in $outfile\n";


    web_printHtmlHead($ofh,$title);
	print $ofh  "<h1>$title</h1>\n";

	my $link1; 
	my @links ;

while(@threshes){
    my $thresh = shift @threshes ;
	my $fnm = "thresh$thresh.size$size.html";
	$link1 = web_makeLink("threshhold for single alignment=$thresh % similarity, size of fragment =$size",$fnm);
	print $ofh "<h3>$link1</h3>\n";


    my $ofhthresh = util_write($fnm);
    print STDERR "\tOutput written in $fnm\n";

    web_printHtmlHead($ofhthresh,"threshhold for single alignment=$thresh");
	print $ofhthresh  "<h1>threshhold for single alignment=$thresh</h1>\n";

my $s1 ; 
	#my $s1 = "aver.results.thresh$thresh.size$size.doiden0.onlyanno0.html";
	#$link1 = web_makeLink("Sorted based on average for %similarity, even if not annotated",$s1);
	#push @links, $link1 ;

	#$s1 = "aver.results.thresh$thresh.size$size.doiden0.onlyanno1.html";
	#$link1 = web_makeLink("Sorted based on average for %similarity, if annotated",$s1);
	#push @links, $link1 ;

	#$s1 = "aver.results.thresh$thresh.size$size.doiden1.onlyanno0.html";
	#$link1 = web_makeLink("Sorted based on average for FRscore, even if not annotated",$s1);
	#push @links, $link1 ;

	$s1 = "aver.results.thresh$thresh.size$size.doiden1.onlyanno1.html";
	$link1 = web_makeLink("Sorted based on average for FRscore, if annotated",$s1);
	push @links, $link1 ;

	#$s1 = "cumu.results.thresh$thresh.size$size.doiden0.onlyanno0.html";
	#$link1 = web_makeLink("Sorted based on cumulative score for %similarity, even if not annotated",$s1);
	#push @links, $link1 ;

	#$s1 = "cumu.results.thresh$thresh.size$size.doiden0.onlyanno1.html";
	#$link1 = web_makeLink("Sorted based on cumulative score for %similarity, if annotated",$s1);
	#push @links, $link1 ;

	#$s1 = "cumu.results.thresh$thresh.size$size.doiden1.onlyanno0.html";
	#$link1 = web_makeLink("Sorted based on cumulative score for FRscore, even if not annotated",$s1);
	#push @links, $link1 ;


	$s1 = "cumu.results.thresh$thresh.size$size.doiden1.onlyanno1.html";
	$link1 = web_makeLink("Sorted based on cumulative score for FRscore, if annotated",$s1);
	push @links, $link1 ;

    while(@links){
         my $link = shift @links;
	    print $ofhthresh  "<h3>$link</h3>\n";
    }
	web_printHtmlEnd($ofhthresh);
	close($ofhthresh);
}


web_printHtmlEnd($ofh);


chmod 0777, $outfile ;

sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
