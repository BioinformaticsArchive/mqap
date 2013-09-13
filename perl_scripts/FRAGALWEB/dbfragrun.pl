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
my ($threshlen,$genscripts,@expressions,$gapopen,$gapex);
my $verbose = 1 ;
my $workdir ;
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "protein=s"=>\$protein ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "genscripts"=>\$genscripts ,
            "workdir=s"=>\$workdir ,
            "expr=s"=>\@expressions,
            "size=i"=>\$size ,
            "threshlen=i"=>\$threshlen ,
            "gapopen=i"=>\$gapopen ,
            "gapex=f"=>\$gapex ,
           );


die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
my $ofh = util_write($outfile);
usage( "Need to give a input file name => option -infile ") if(!defined $infile);
usage( "Need to give a input file name => option -threshlen ") if(!defined $threshlen);
usage( "Need to give a listfile -option -listfile  ") if(!defined $listfile);

my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC,$MATCH3D,$ANNDIR, $UNIPROT) = util_SetEnvVars();
my $arg = "$SRC/BIOPERL/arg.$gapopen-$gapex";
my $CNT = 0 ; 
my $PWD = cwd;


my @list= util_read_list_sentences($listfile);
my $list = {};
map { s/\s*//g ; $list->{$_} = 1 ; } @list ;

my $lastread = util_ProcessReadLastIfExists("last.uniprot");

if(defined $lastread){
  while(@list){
      my $x = shift @list ; 
	  last if($x eq $lastread);
  }
}

my @tmplist = @list ;
@list = ();
print "Filtering above $threshlen \n";
foreach my $f (@tmplist){
	my ($src,$firstline) = util_readfasta("$UNIPROT/$f.fasta");
	my $len = length($src);
	next if($len < 200 );
	if($len < $threshlen){
	    push @list,$f ;
	}
}

die "No files to process, somethign wrong" if(!@list);

my $RUNDIR = "RUN.$size.$gapopen";
system ("mkdir -p $RUNDIR");

while(@list){
	my $a = shift @list ;
	my $doneatleastone = 0 ; 
	foreach my $b (@list){
	    next if($b eq $a);
		($a,$b) = util_SortTwoStrings($a,$b);
		
		my $runfile = "runfrag.csh";
		my $dir = "$RUNDIR/$a.$b";
		my $scrname = "$dir.csh";
		if(defined $genscripts){
           system ("unlink $scrname");
           my $ofhscr = util_write($scrname);
           system ("ls $scrname");
		   print STDERR "Writing $scrname\n";
	       print $ofhscr  "mkdir -p $dir\n";
	       print $ofhscr  "cd $dir\n";
	       print $ofhscr  "ln -s $UNIPROT/$a.fasta . \n ";
	       print $ofhscr  "ln -s $UNIPROT/$b.fasta .  \n";
   
	       print $ofhscr  "unlink $runfile \n";
	       print $ofhscr  "touch $runfile \n";
	       print $ofhscr  "echo setenv FASTADIR \$PWD>> $runfile \n";
	       print $ofhscr  "echo echo FASTADIR set to \$FASTADIR >> $runfile \n";
	       print $ofhscr  "echo \$SRC/FRAGALWEB/fragmentcompare.pl -outfile kkk -in1 $a.fasta -in2 $b.fasta -thresh 1000 -size $size -arg $arg  >> $runfile \n";
	       print $ofhscr  "source $runfile \n";
		   if(!-e "$dir/full.needle"){
                 print $ofhscr  "echo checkIdentity.csh $a $b  full.needle $arg >> kkk \n";
		   }
	       print $ofhscr  "source kkk \n";
	       print $ofhscr  "\$SRC/FRAGALWEB//dbFragPostProcess.pl -out done.uniprot \n";
	       print $ofhscr  "sort.pl -in done.uniprot -out done.uniprot.sort -idx 5 -rever\n";
	       print $ofhscr  "cd - \n";
	       print $ofhscr  "\n\n";
		}
   

		if(!-e "$dir/done.uniprot"){
	       $doneatleastone = 1 ; 
	       print $ofh "source $scrname\n";
		}
	}
	print $ofh "echo $a > ! last.uniprot\n"; 
}


sub util_ProcessReadLastIfExists{
    my ($file) = @_ ; 
	return undef if(!-e $file) ;
    my $ifh = util_read($file);
    while(<$ifh>){
	    chop ; 
	    return $_ ; 
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
