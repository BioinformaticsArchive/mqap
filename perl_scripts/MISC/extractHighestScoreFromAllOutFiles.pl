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
my $verbose ;
#$single = 1 ;
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "infile=s"=>\$infile ,
            "single"=>\$single,
            "list=s"=>\$list ,
            "verbose"=>\$verbose ,
            "outfile=s"=>\$outfile 
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
my $ofh = util_write($outfile);
my $ofhlist = util_write($outfile . ".list");

my $info = {};
if(defined $list){
    my $ifh = util_read($list);
    while(<$ifh>){
         next if(/^\s*$/);
         chop ;
	     my ($nm,$junk) = split ; 
	     if(!defined $info->{$nm}){
		    $info->{$nm} = 1;
	    }
    }
    close($ifh);
}

my @list = <*.out> ; 


my $CNT = 0 ;
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
	#print "$tmp \n";
    #next if(!defined $info->{$tmp});

	my @results = ConfigPDB_ParseResultsFile($l,1);
	my $nresults = @results ;
	print "There were $nresults results for $tmp \n" if(defined $verbose);
	$l = $tmp; 

	my $result = shift @results;
	if(defined ($result && $result->{SCORE})){
	#print "$l lllllllllll\n";
	    print $ofhlist  "$l\n" ;
	    print $ofh "$result->{SCORE} $l \n";
		$CNT++;
	}
}

print STDERR "extractHighestScoreFromAllOutFiles wrote in $outfile. Processed $CNT proteins\n";

sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
