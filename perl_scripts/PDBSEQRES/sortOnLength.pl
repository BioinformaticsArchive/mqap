#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($all,$infile,$outfile,$or,$silent,$groupinfo);
my ($DIR,$listfile);
my $howmany = 600000 ; 
my $cutofflength = 0 ; 
my @types = (); 
my @ntypes = (); 
my @motifs = (); 
GetOptions(
            "all"=>\$all ,
            "groupinfo"=>\$groupinfo ,
            "silent"=>\$silent ,
            "infile=s"=>\$infile ,
            "dir=s"=>\$DIR ,
            "listfile=s"=>\$listfile ,
            "howmany=i"=>\$howmany ,
            "or=i"=>\$or ,
            "cutofflength=i"=>\$cutofflength ,
            "type=s"=>\@types,
            "ntype=s"=>\@ntypes,
            "motif=s"=>\@motifs,
            "outfile=s"=>\$outfile 
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a input file name => option -infile ") if(!defined $infile);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
usage( "Need to give a listfile -option -listfile  ") if(!defined $listfile);
my $ofh = util_write($outfile);

my @list= util_read_list_sentences($listfile);
my $list = {};
map { $list->{lc($_)} = 1 ; } @list ;


    print STDERR "Info: parsing file $infile - might take some time\n";

	my $info = util_parsePDBSEQRES($infile,0);
	my @p ;
    map { 
		push @p, $info->{$_};
	} (keys %{$list}) ;

	my @resultssorted = sort { $a->{LEN} <=> $b->{LEN} } @p ;

	map {
	    if($cutofflength){
		    if( $_->{LEN} > $cutofflength){
		        print STDERR  "$_->{NM} $_->{LEN} .... \n";
		        my $uc = uc($_->{NM});
		        print $ofh  "$uc\n";
	        }
		}
	}@resultssorted;

print STDERR "Output written in $outfile\n";


sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
