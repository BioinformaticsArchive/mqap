#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use MyGeom;
use PDB;
use ConfigPDB;
use Algorithm::Combinatorics qw(combinations) ;

use Time::HiRes qw( usleep ualarm gettimeofday tv_interval clock_gettime clock_getres  clock);
use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($config,$infile,$outfile,$which_tech,$listfile,$protein);
my (@expressions);
my $howmany = 100000 ;
my $verbose = 1 ;
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "protein=s"=>\$protein ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "config=s"=>\$config,
            "expr=s"=>\@expressions,
            "howmany=i"=>\$howmany ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a config file name => option -config ") if(!defined $config);
#usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
#usage( "Need to give a input file name => option -infile ") if(!defined $infile);
#my $ifh = util_read($infile);
#usage( "Need to give a listfile -option -listfile  ") if(!defined $listfile);
usage( "Need to give a protein pdb id -option -protein  ") if(!defined $protein);
my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC) = util_SetEnvVars();
my $PWD = cwd;
$outfile = "$protein.cinp";
my $ofh = util_write($outfile);


my $libinfo = ReadLibConfigfile($config);

### Read PDB and Potential files
my $file1 = "$PDBDIR/$protein.pdb";
my $pdb1 = new PDB();
$pdb1->ReadPDB($file1);

sub util_readAPBSPotentialFromStart{
	my ($protein,$apbsdir) = @_ ; 
    my $pqrfile = "$APBSDIR/$protein/$protein.pqr";
    my $pqr = new PDB();
    $pqr->ReadPDB($pqrfile);
    my @pots = ();
    my $potential = "$APBSDIR/$protein/pot1.dx.atompot";
    util_readAPBSPotential(\@pots,$potential);
	return ($pqr,\@pots);
}

PreprocessForC($file1,$pdb1,$pqr,\@pots,$libinfo);



sub PreprocessForC{
   my ($infile,$pdb1,$pqr,$pots,$libinfo) = @_ ; 
   print "$infile,$pdb1,$pqr,$pots \n";
   my $ifh = util_read($infile);
   my @pots = @{$pots};
   print "Info: Reading pdb file $infile for preprocessing\n";
   
   my $CNT = 0; 
   while(<$ifh>){
	    if(/^ATOM/){
		   my $LINE = $_ ; 
		   my $len = length($LINE) ;
		   #print "lenght = $len $LINE \n";
		   my ($atomstr , $serialnum , $atomnm , $alt_loc , $resname , $chainId , $resnum , $codeforinsertion , $x , $y , $z ) = util_ReadLine($LINE);
		   next if($resname =~ /HOH/);
		   next if($chainId !~ /A/);
		   $resname =~ s/\s//g;
		   $atomnm =~ s/\s//g;
		   my $newtype = $resname.$atomnm ; 
		   next if(! exists $libinfo->{Type}->{$newtype}); 
		   my $index = $libinfo->{Type}->{$newtype};

		   my $pot = $pdb1->GetPotential($pqr,$resnum,$atomnm);

		   {
               my ($x,$y,$z) = $a->Coords();
               my ($x1,$y1,$z1) = $aPqr->Coords();
               if(!util_IsZero($x-$x1+$y -$y1+$z-$z1)){
			   	  print "dod not match \n";
				  $CNT++;
				  next ;
			   }
		   }
           
           
		   print $ofh "$resname $atomnm $index $resnum $serialnum  $x $y $z $pot \n";
		 }
	}
}

sub ReadLibConfigfile{
   my ($infile) = @_ ; 
   my $ifh = util_read($infile);
   print "Info: Reading lib config file $infile \n";
   
   my $CNT = 0; 
   my $libinfo = {};
   while(<$ifh>){
   		next if(/^\s*#/);
	    if(/^Type/){
			my (@l) = split ; 
			shift @l ;
			$libinfo->{Type}->{$l[0]} = $l[1];
		}
	}
	return $libinfo;
}


sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
