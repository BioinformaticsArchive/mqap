#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use MyUtils;
use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($all,$infile,$outfile,$or,$silent,$groupinfo);
my ($DIR);
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
usage( "Need to give a dir => option -dir ") if(!defined $DIR);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
my $ofh = util_write($outfile);


my ($RESULTDIR,$PDBDIR) = util_SetEnvVars();

my @pdbs = util_read_list_words($infile);


   print $ofh "mkdir $DIR \n";
		foreach my $k (@pdbs){
			$k = uc($k);
			print $ofh "cp $PDBDIR/$k.pdb $DIR/ \n";
	}
   
   print $ofh "tar -cvzf $DIR.tgz $DIR  \n";

sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
