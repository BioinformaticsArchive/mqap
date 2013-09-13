#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($infile,$outfile,$negate,$superset,$subset);
my (@expressions);
my $howmany = 100000 ;
GetOptions(
            "negate"=>\$negate ,
            "infile=s"=>\$infile ,
            "outfile=s"=>\$outfile ,
            "superset=s"=>\$superset ,
            "subset=s"=>\$subset ,
            "expr=s"=>\@expressions,
            "howmany=i"=>\$howmany ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
my $ofh = util_write($outfile);
usage( "Need to give a super set => option -superset ") if(!defined $superset);
usage( "Need to give a subset name => option -subset ") if(!defined $subset);
my $ifh = util_read($superset);
my $CNT = 0 ; 

my $info = {};
while(<$ifh>){
     next if(/^\s*$/);
     chomp ;
	 my ($nm,$junk) = split ; 
	 if(!defined $info->{$nm}){
		$CNT++ ;
		$info->{$nm} = {} ;
	}
}
close($ifh);

$ifh = util_read($subset);
my $info1 = {};
while(<$ifh>){
     next if(/^\s*$/);
     chomp ;
	 my ($nm,$junk) = split ; 
	 if(!defined $info1->{$nm}){
		$CNT++ ;
		$info1->{$nm} = {} ;
	 }
}

foreach my $nm (keys %{$info}){
	 if(defined $info1->{$nm}){
         #print $ofh "$nm\n" ;
	}
	else{
         print $ofh "$nm\n" ;
    }
}

chmod 0777, $outfile ;
sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
