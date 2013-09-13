#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use ConfigPDB ;
use MyUtils;
use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($infile,$outfile,$which_tech,$list,$single);
#$single = 1 ;
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "infile=s"=>\$infile ,
            "single"=>\$single,
            "list=s"=>\$list ,
            "outfile=s"=>\$outfile 
           );
#die "Dont recognize command line arg @ARGV " if(@ARGV);

my $info = {};
my  @list ;
if(@ARGV){ @list = @ARGV ; }
else{ @list = <*.out> ; }

my $PWD = cwd; 



my $CNT ;
my $INIT ;
foreach my $l (@list){
	my $tmp = $l ;
	$tmp =~ s/.outconf//;
	$tmp =~ s/.annotated//;
	$tmp =~ s/.out//;
	$tmp =~ s/.pdb//;
	if($tmp =~ /\./){
		if(defined $single){
	        $tmp =~ s/.....$//; 
		}
		else{
	        $tmp =~ s/^.....//; 
		}
	}

	my @results = ConfigPDB_ParseResultsFile($l,1);
	my $result = shift @results;
	if(defined ($result && $result->{SCORE})){
	    my @atoms = @{$result->{ATOMS}};
		my $N = @atoms ; 
		if(!defined $CNT){
		   $CNT = $N ;
		   $INIT = $l ;
		}
		die "Size $N is different from rest $CNT (file $INIT) in $PWD for file $l" if($N ne $CNT);
	}
}


sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
