#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use ConfigPDB;
use MyGeom;
use PDB;

use Time::HiRes qw( usleep ualarm gettimeofday tv_interval clock_gettime clock_getres  clock);
use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($infile,$outfile,$which_tech,$listfile,$protein);
my (@expressions);
my $howmany = 100000 ;
my $verbose = 1 ;
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "protein=s"=>\$protein ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "expr=s"=>\@expressions,
            "howmany=i"=>\$howmany ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
my $ofh = util_append($outfile);
usage( "Need to give a input file name => option -infile ") if(!defined $infile);
my $ifh = util_read($infile);

my $dist = 1 ;
my @colors = qw (red green blue yellow orange magenta purple cyan violet brown gray
xxx1 xxx2 xxx3 xxx4 xxx5);
my $tikz ; 
while(<$ifh>){
     next if(/^\s*$/);
	 my ($C,$M,$nm) = split ; 
	 #$name =~ s/\./,/g;
	 #my @l = split ",", $name ;
	 #my $nm = $l[3] ;
	 print $ofh "\$learnt->{$nm}->{$dist}->{M} = $M ; \n";
	 print $ofh "\$learnt->{$nm}->{$dist}->{C} = $C ; \n";

	 my $fnm = "$nm.$dist";
     my $fh = util_write($fnm);
	 if(! defined $tikz){
	 	$tikz = util_write("tikz.$nm");
	 }
	 my $del = 0.1;
	 my $x = 0 ; 
	 while($x <= 1){
	 	#my $x = ($y - $C)/$M ; 
	 	my $y = ($M*$x + $C);
		print $fh "$x $y\n";
		$x = $x + $del ; 
	 }
	print $tikz "\\addplot[smooth,$colors[$dist]] file {$fnm} ;\n";
	print $tikz "\\addlegendentry{dist = $dist A}\n";

	 $dist++;

}

sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
