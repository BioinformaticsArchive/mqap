#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use POSIX qw(floor);
use ConfigPDB ;
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($cavityfile, $all,$resultfile,$outfile,$or,$silent,$groupinfo);
my ($DIR);
my $howmany = 600000 ; 
my @motifs = (); 
GetOptions(
            "all"=>\$all ,
            "silent"=>\$silent ,
            "resultfile=s"=>\$resultfile ,
            "cavityfile=s"=>\$cavityfile ,
            "dir=s"=>\$DIR ,
            "howmany=i"=>\$howmany ,
            "outfile=s"=>\$outfile 
           );
usage( "Need to give a input file name => option -resultfile ") if(!defined $resultfile);
usage( "Need to give a cavity file name => option -cavityfile ") if(!defined $cavityfile);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
my $ofh = util_write($outfile);

my $CNT = 0 ;
my @results= ConfigPDB_ParseResultsFile($resultfile);
my $cavities =  ConfigPDB_ParseCavityFile($cavityfile);


my ($finalscore,$bestCavityNum,$maxdoesexist,$mindoesntexist) ;
$finalscore = 10000 ;

foreach my $result (@results){
	($finalscore,$bestCavityNum,$maxdoesexist,$mindoesntexist) = ConfigPDB_ScoreSingleResultForCavity($result,$cavities,$ofh,$finalscore);
	print " finalscore,bestCavityNum,maxdoesexist,mindoesntexist $finalscore,$bestCavityNum,$maxdoesexist,$mindoesntexist \n;";
}
print "FINAL $finalscore \n";
  

sub parseSingleLine{
	my ($line) = @_ ; 
	my ($num,$restype,$resnum,$atom,$x,$y,$z) = split " " , $line ; 
	return ($num,$restype,$resnum,$atom,$x,$y,$z);

}
sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
