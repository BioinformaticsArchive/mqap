#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use MyUtils;
use ConfigPDB;

use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($infile,$outfile,$id,$listfile);
my (@expressions);
my $howmany = 100000 ;
GetOptions(
            "id=s"=>\$id ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "expr=s"=>\@expressions,
            "howmany=i"=>\$howmany ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
my $ofh = util_write($outfile);
#usage( "Need to give id => option -id ") if(!defined $id);
usage( "Need to give a input file name => option -infile ") if(!defined $infile);
my $ifh = util_read($infile);
my $CNT = 0 ; 

die "Please define TEST_HOME" if(!defined $ENV{TEST_HOME});
my $TEST_HOME = $ENV{TEST_HOME} ;

$infile =~ s/fasta//;

my $info = {};
while(<$ifh>){
	s/./>$infile /;
	print $ofh $_ ;
	last ;
}
while(<$ifh>){
	print $ofh $_ ;
}

close($ifh);


chmod 0777, $outfile ;
sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
