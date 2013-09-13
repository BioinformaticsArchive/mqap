#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($infile,$outfile,$which_tech);
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "infile=s"=>\$infile ,
            "outfile=s"=>\$outfile 
           );
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);

### This takes a amino acid sequence - and writes it down with the residues
### with the residue number on its side.

my $ofh = util_write($outfile);
my @residues = ();
if(defined $infile){
    my $ifh = util_read($infile);
    while(<$ifh>){
         next if(/^\s*$/);
	     s/\s*//g;
         my @l1 = split "", $_ ;
	     push @residues,@l1 ; 
    }
}
else{
	my $l = $ARGV[0] or die; 
    my @l1 = split "", $l ;
	push @residues,@l1 ; 
}

my $cnt = 1; 
foreach my $r (@residues){
	print $ofh "$cnt $r\n";
	$cnt++;
}
print $ofh "\n";

sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
