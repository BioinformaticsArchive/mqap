#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use MyUtils;
use ConfigPDB;
use BP;

use Bio::Perl;
use Bio::DB::SwissProt;
use Bio::Tools::Run::Alignment::Clustalw;
use Bio::AlignIO;
use Bio::Align::DNAStatistics;
use Bio::Tree::DistanceFactory;
use Bio::TreeIO;
use Bio::Tree::Draw::Cladogram;



my $VALUE = 10 ;
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
usage( "Need to give a listfile -option -listfile  ") if(!defined $listfile);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
#usage( "Need to give a howmany") if(!defined $howmany);
my $ofh = util_write($outfile);



my ($mappingfile) = $ENV{MAPPINGFILE} or die;
print "Parsing $mappingfile\n";
my ($info,$uniqueEC,$uniqueSP) = util_read_Mapping_PDB_2_SWISSPROT($mappingfile);
my $ECNUM = (keys %{$uniqueEC}) ;
print "Parsed $mappingfile \n";

my @list= util_read_list_sentences($listfile);
my $list = {};
map { s/\s*//g ; $list->{$_} = 1 ; } @list ;
my $N = @list  ;

my ($ecdone,$spdone,$pdbTable,$cnt)= util_filter_basedon_EC($info,$uniqueEC,$uniqueSP,\@list,undef,1); 



	my $count = {};
	my $pdbs = {};
    foreach my $ec (sort keys %{$ecdone}){
		my @ecs = @{$ecdone->{$ec}} ;

	    $ec =~ s/\./YYY/g;
        my @l = split "YYY", $ec ;
	    my $top = $l[0] ; 
		$count->{$top} = 0 if(!defined $count->{$top}); 
		$pdbs->{$top} = [] if(!defined $pdbs->{$top}); 
		$count->{$top} =  $count->{$top} + 1 ; 
		push @{$pdbs->{$top}}, @ecs ;
    }


    foreach my $c (sort keys %{$count}){
    #foreach my $c (6){
		my @pdbs = @{$pdbs->{$c}} ; 
		my $fnm = "EC".$c ; 
		my $fnm1 = "list.$howmany.EC$c" ; 
        my $lfh = util_write($fnm);
        my $lfh1 = util_write($fnm1);
		print " wrote to file name $fnm \n ";
		foreach my $p (@pdbs){
			$p = uc ($p);
			print $ofh  "$p\n";
			print $lfh  "$p\n";
		}
		if(defined $howmany){
		my $l = util_pick_n_random_from_list(\@pdbs,$howmany);
		foreach my $i (@{$l}){
			print $lfh1 "$i\n";
		}
		}
	}
	system("wc -l EC*");

print "Wrote to file $outfile. Started with $N, ended with $cnt. There are $ECNUM of unqiue ECS\n";

			



chmod 0777, $outfile ;
sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
