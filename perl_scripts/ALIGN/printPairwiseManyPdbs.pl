#!/usr/bin/perl -w 
use strict ;
use PDB;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use ConfigPDB;
use MyGeom;
use MyPymol;
use Math::Geometry ;
use Math::VectorReal qw(:all);  # Include O X Y Z axis constant vectors




use Time::HiRes qw( usleep ualarm gettimeofday tv_interval clock_gettime clock_getres  clock);
use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($ann,$config,$p1,$p2,$infile,$statfile,$outfile,$which_tech,$listfile,$protein);
my $maxdist ;
my $DISTANCEWITHOUTSEQMATCH = 1 ;
my $verbose = 1 ;

my ($verify,$radii,$before1,$before2);
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "protein=s"=>\$protein ,
            "verify"=>\$verify ,
            "p1=s"=>\$p1 ,
            "p2=s"=>\$p2 ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "statfile=s"=>\$statfile ,
            "outfile=s"=>\$outfile ,
            "ann=s"=>\$ann ,
            "maxdist=f"=>\$maxdist ,
            "config=s"=>\$config,
            "radii=i"=>\$radii ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
usage( "Need to give a config file name => option -config ") if(!defined $config);
usage( "Need to give a listfile -option -listfile  ") if(!defined $listfile);
usage( "Need to give a iinput file name => option -infile ") if(!defined $infile);


my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC) = util_SetEnvVars();
my $PWD = cwd;

ConfigPDB_Init($config);

my @list= util_read_list_sentences($listfile);
my $list = {};
map { s/\s*//g ; $list->{$_} = 1 ; } @list ;

my @M ; 
my @SD ; 
if(defined $statfile){
my @stats= util_read_list_sentences($statfile);
foreach my $s (@stats){
   $s =~ s/,/ /;
   my ($m, $sd) = split " ", $s ; 
   my $SDhalf = $sd/2 ; 
   my $SDQuarter = $SDhalf/2 ; 
   $sd = $sd + $SDQuarter  ;
   push @M, $m;
   push @SD, $sd;
}
}

$, = " ";
my $ifh = util_read($infile);
my $myline ;
while(<$ifh>){
   next if(/^\s*$/);
   next if(/RESULT/);
   chop ;
   $myline = $_ ;
   last ;
}

my $ofh0 = util_write("$outfile.0");
my $ofh1 = util_write("$outfile.1");
my $ofh2 = util_write("$outfile.2");
my $ofh3 = util_write("$outfile.3");

my $cnt = 0 ; 
my @p0 ;
my @p1 ;
my @p2 ;
my @p3 ;
my $N ; 
my $goodcnt  = 0 ; 
my $badcnt  = 0 ; 
foreach my $i (@list){

    my $info = {};
    my @resultlines ;
    my @proteins ;
    push @proteins, $i; 
    
    
	next if( ! -e "$APBSDIR/$i/$i.pqr");
	next if( ! -e "$APBSDIR/$i/pot1.dx.atompot" && ! -e "$APBSDIR/$i/pot1.dx.atompot");
    my @info = util_ReadPdbs($PDBDIR,$APBSDIR,1,@proteins) ; 
    my $info = shift @info ;
    my $pdb1 = $info->{PDBOBJ};
    my $pqr1 = $info->{PQR};
    my $pots1 = $info->{POTS};


    
	my ($dist,$pots,$name) = util_ProcessSingleLine($pdb1,$pqr1,$pots1,$myline);
	my @dist = @{$dist}; 
	my @pots = @{$pots}; 
	$N = @pots ;
    
	#print $ofh "$name, D " , @dist, "\n";
	$cnt++;
	print $ofh0 "$cnt $pots[0] \n";
	print $ofh1 "$cnt $pots[1] \n";
	print $ofh2 "$cnt $pots[2] \n";
	print $ofh3 "$cnt $pots[3] \n" if($N > 3);


	push @p0, $pots[0] ;
	push @p1, $pots[1] ;
	push @p2, $pots[2] ;
	push @p3, $pots[3] if ($N > 3);

    my $good = 1 ;
	if($statfile){
	     my $d0 = abs ($pots[0] - $M[0]);
	     my $d1 = abs ($pots[1] - $M[1]);
	     my $d2 = abs ($pots[2] - $M[2]);
	     my $d3  = 0 ; 
	     $d3 = abs ($pots[3] - $M[3]) if ($N > 3);

		 if($N > 3 ){
		     $good = 0  if(!($d0 < $SD[0] && $d1 < $SD[1] && $d2 < $SD[2] && $d3 < $SD[3])) ; 
		 }
		 else{
		     $good = 0 if(!($d0 < $SD[0] && $d1 < $SD[1] && $d2 < $SD[2] ));
		     #$good = 0 if(!($d0 < $SD[0] ));
		 }
	}

	if($good){
	     $goodcnt++ ;
	}
	else{
		$badcnt++ ; 
	}
}

my ($m0,$sd0) = util_GetMeanSD(\@p0);
my ($m1,$sd1) = util_GetMeanSD(\@p1);
my ($m2,$sd2) = util_GetMeanSD(\@p2);
my ($m3,$sd3) = util_GetMeanSD(\@p3) if($N > 3);


print " $m0,$sd0 \n";
print " $m1,$sd1 \n";
print " $m2,$sd2 \n";
print " $m3,$sd3 \n" if($N > 3);

print " good = $goodcnt,bad = $badcnt, total = $cnt \n" ;

sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
