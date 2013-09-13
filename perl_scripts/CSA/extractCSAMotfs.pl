#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use ConfigPDB;

use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($infile,$outfile,$which_tech,$listproteins,$listmotifs);
my (@expressions);
my $howmany = 100000 ;
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "infile=s"=>\$infile ,
            "listmotifs=s"=>\$listmotifs ,
            "listproteins=s"=>\$listproteins ,
            "outfile=s"=>\$outfile ,
            "expr=s"=>\@expressions,
            "howmany=i"=>\$howmany ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
my $ofh = util_write($outfile);
#usage( "Need to give a input file name => option -infile ") if(!defined $infile);
#my $ifh = util_read($infile);
my $CNT = 0 ; 

my @listproteins = util_read_list_sentences($listproteins);
my @listmotifs = util_read_list_sentences($listmotifs);

my $lists = {};
foreach my $m (@listmotifs){
     foreach my $p (@listproteins){
	 	 $lists->{$p} = [] if(! defined $lists->{$p});
	 	 my $infile = "$m.CSA.ANN.outconf.dir/$p.pdb.out";
		 print "$infile \n";
         my $ifh = util_read($infile);
         my @r= ConfigPDB_ParseResultsFile($infile,1);
	     foreach my $result (@r){
		 	print "$result->{SCORE} \n";
			my $score = int(10* $result->{SCORE}); 
			$score = $score/10.0 ;
			push @{$lists->{$p}}, $score ;
         }
	  }
}

#print $ofh "\\begin{subtables} \n";
print $ofh "\\begin{table*} \n";
print $ofh "\\rowcolors{1}{tableShade}{white} \n";

#print $ofh "\\subfloat[Output from learning - mean distance between each pair of residues, and a weight associated with that parameter ] { \n";
print $ofh "\\begin{tabular}{ ";

foreach my $m (@listmotifs){
     print $ofh "l " ; 
}
print $ofh " l } \n " ; 

print $ofh "\\hline \n";



my @type = qw(
 hexokinase
 kinase
 racemase
 synthase
 proteinase
 reductase 
 hydrolase
 hydrolase
 lipase
 ligase

 );
#SEDOLISIN

foreach my $m (@listmotifs){
     print $ofh "& $m  " ; 
}
print $ofh  "\\\\ \n";
foreach my $m (@type){
     print $ofh " & {\\small $m }  " ; 
}
print $ofh  "\\\\ \n";
print $ofh "\\hline \n";


foreach my $p (@listproteins){
	 	  my @l = @{$lists->{$p}} ; 
		  my $what = "  ";
		  print $ofh  "$p & ";
		  foreach my $x (@l){
		     print $ofh "$what $x ";
			 $what = " & " ;
		  }
		  print $ofh  "\\\\ \n";
          print $ofh "\\hline \n";
}

print $ofh "\\end{tabular} \\label{table:pdbgrid} \n";

# print $ofh "} \\\\ \n";

print $ofh "\\caption{Here we tabulate the scores of 10 motifs from the CSA DB on a few proteins chosen from the non redundant protein set in the PDB DB. The number of residues in the motifs vary from 3 to 5. It is to be noted that lesser the number of residues in the motifs, the more the number of false positives we should expect. Also, these runs were highly constrained in terms of stereo-chemically equivalent residues} \n"; 
print $ofh "\\end{table*} \n";
#print $ofh "\\end{subtables} \n";



chmod 0777, $outfile ;
sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
