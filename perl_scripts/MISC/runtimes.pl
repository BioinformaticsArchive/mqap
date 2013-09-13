#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;
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
usage( "Need to give a listfile -option -listfile  ") if(!defined $listfile);
my $CNT = 0 ; 
my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET) = util_SetEnvVars();
my $PWD = cwd;


my @list= util_read_list_sentences($listfile);
my $list = {};
map { s/\s*//g ;$list->{$_} = 1 ; } @list ;
my $ofh1 = util_write("A");
my $ofh2 = util_write("B");
my $ofh3 = util_write("C");
my $ofh4 = util_write("LIST");

my $cnt = 1 ; 
my @l1 ; 
foreach my $i (@list){
	my $clasp = "$i.log";
	my $pqr = "$i.pdb2pqr.log";
	my $apbs = "$i.apbs.log";
	next if(!-e $clasp);
	next if(!-e $pqr);
	next if(!-e $apbs);

	my $a = parseAndWrite($clasp);
	my $b = parseAndWrite($pqr);
	my $c = parseAndWrite($apbs);

	if($c > 1 ){
	    if($a > 10){
		   print "$i $a \n";
		   next ;
	   }

       push @l1, $c ;

	   print $ofh1 "$cnt $a\n";
	   print $ofh2 "$cnt $b\n";
	   print $ofh3 "$cnt $c\n";
	   print $ofh4 "$cnt $i\n";

	   $cnt++;
	}
}

#@l1 = sort {$a <=> $b} @l1 ; 
#$cnt = 0 ; 
#map { $cnt++ ; print $ofh1 "$cnt $_ \n"; } @l1 ;

sub parseAndWrite{
	my ($infile,$outfile,$cnt) = @_ ; 
    my $info ;
    my $ifh = util_read($infile);
    while(<$ifh>){
	    $info = $_  ;
    }
	close($ifh);
    my ($t) = util_get_time_from_string($info);
	($t) = $t/60 ;
	return $t ;

}



chmod 0777, $outfile ;
sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
