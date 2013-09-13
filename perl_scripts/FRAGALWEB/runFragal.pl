#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use MyGeom;
use PDB;
use ConfigPDB;

use Time::HiRes qw( usleep ualarm gettimeofday tv_interval clock_gettime clock_getres  clock);
use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($arg,$size,$infile,$outfile,$which_tech,$listfile,$protein);
my (@expressions,$gapopen,$gapex);
my $verbose = 1 ;
my $workdir ;
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "protein=s"=>\$protein ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "workdir=s"=>\$workdir ,
            "expr=s"=>\@expressions,
            "size=i"=>\$size ,
            "gapopen=i"=>\$gapopen ,
            "gapex=f"=>\$gapex ,
           );
my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC) = util_SetEnvVars();
$arg = "$SRC/BIOPERL/arg.$gapopen-$gapex";
die "$arg file does not exist" if(! -e $arg);
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
my $ofh = util_write($outfile);
usage( "Need to give a input file name => option -infile ") if(!defined $infile);
usage( "Need to give a workdir => option -workdir ") if(!defined $workdir);
my $ifh = util_read($infile);
my @l ;
while(<$ifh>){
     next if(/^\s*$/);
     next if(/^\s*#/);
	 my ($nm,$junk) = split ; 
	 push @l, $nm ;
	 $junk = "1" if(!defined $junk);
	 if(! -e "$nm.fasta") {
	      system ("wget http://www.uniprot.org/uniprot/$nm.fasta");
	 }
	 push @l, $junk ;
}

while(@l){
	my $nm = shift @l ;
	my $junk = shift @l ;
	my @tmp = @l ;
	while(@tmp){
	    my $a = shift @tmp ;
	    my $b = shift @tmp ;
		my $runfile = "runfrag.csh";
		my $dir = "$junk.$nm.$b.$a.gap.$gapopen.size$size";
		my $Aname = "$junk.$nm";
		my $Bname = "$b.$a";
		my $scrname = "$dir.csh";
        my $ofhscr = util_write($scrname);
		print STDERR "Writing $scrname\n";
	    print $ofhscr  "mkdir -p $dir\n";
	    print $ofhscr  "cd $dir\n";
	    print $ofhscr  "\\cp -f $workdir/$a.fasta . \n ";
	    print $ofhscr  "\\cp -f $workdir/$nm.fasta .  \n";

	    print $ofhscr  "\\cp -f $workdir/$nm.ann A.ann \n ";
	    print $ofhscr  "\\cp -f $workdir/$a.ann  B.ann  \n";

	    print $ofhscr  "\\rm $runfile A.name B.name \n";
	    print $ofhscr  "echo $Aname > A.name \n";
	    print $ofhscr  "echo $Bname > B.name \n";
	    print $ofhscr  "\\cp -f $workdir/$nm.fasta .  \n";
	    print $ofhscr  "touch $runfile \n";
	    print $ofhscr  "echo setenv FASTADIR \$PWD>> $runfile \n";
	    print $ofhscr  "echo echo FASTADIR set to \$FASTADIR >> $runfile \n";
	    print $ofhscr  "echo sleep 1 >> $runfile \n";
	    print $ofhscr  "echo \$SRC/SHELLSCRIPTS/fragmentcompare.csh $nm.fasta $a.fasta 25 $size $arg >> $runfile \n";
	    print $ofhscr  "echo \$SRC/SHELLSCRIPTS/fragmentcompare.csh $nm.fasta $a.fasta 30 $size $arg >> $runfile \n";
	    print $ofhscr  "echo \$SRC/SHELLSCRIPTS/fragmentcompare.csh $nm.fasta $a.fasta 35 $size $arg >> $runfile \n";
	    print $ofhscr  "source $runfile \n";
	    print $ofhscr  "source \$SRC/FRAGALWEB//makewebMainLevelhtml.csh $size \n";
	    print $ofhscr  "cd - \n";
	    print $ofhscr  "\n\n";


	    print $ofh "source $scrname\n";
	}
}

sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
