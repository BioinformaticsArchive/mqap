#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use ConfigPDB;
use MyGeom;
use PDB;

use Time::HiRes qw( usleep ualarm gettimeofday tv_interval clock_gettime clock_getres  clock);
use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($scale,$population,$infile,$learn,$fastadir,$outfile,$id,$dist,$which_tech,$listfile,$protein);
my (@expressions,$stats);
my $howmany = 100000 ;
my $verbose = 1 ;
my $pepinfo = {};
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "scale"=>\$scale ,
            "protein=s"=>\$protein ,
            "id=s"=>\$id ,
            "population=s"=>\$population ,
            "infile=s"=>\$infile ,
            "stats=i"=>\$stats ,
            "learn=s"=>\$learn ,
            "listfile=s"=>\$listfile ,
            "fastadir=s"=>\$fastadir ,
            "outfile=s"=>\$outfile ,
            "expr=s"=>\@expressions,
            "howmany=i"=>\$howmany ,
            "dist=i"=>\$dist ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a input file name => option -infile ") if(!defined $infile);

if(defined $scale){
	ScaleIndices($infile);
	exit ; 
}
elsif(defined $stats){
    usage( "Need to give a outfule ") if(!defined $outfile);
	Stats($infile,$outfile);
	exit ;
}
elsif(defined $learn){
    usage( "Need to dist => option -dist ") if(!defined $dist);
    usage( "Need to give a fastadir -option -fastadir  ") if(!defined $fastadir);
	Learning($infile,$learn,$pepinfo);
	exit ;
}
usage( "Need to dist => option -dist ") if(!defined $dist);
usage( "Need to give a fastadir -option -fastadir  ") if(!defined $fastadir);
my $CNT = 0 ; 
my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC) = util_SetEnvVars();
my $PWD = cwd;


#my @list= util_read_list_sentences($listfile);
#my $list = {};
#map { s/\s*//g ; $list->{$_} = 1 ; } @list ;
#
#foreach my $i (@list){
	#print "$i\n";
#}


my @ecs = qw ( 1 2 3 4 5 6 );
my @fhs ; 
my $fhs = {};

foreach my $ec (@ecs){
   my $fnm = "list.dist$dist.ec$ec";
   my $fh = util_write($fnm);
   push @fhs,$fh ; 
   $fhs->{$ec} = $fh ; 
}

#ProcessSingle($infile,$pepinfo,"Molecular");
ProcessSingle($infile,$pepinfo,"Acidic");
ProcessSingle($infile,$pepinfo,"Basic");
ProcessSingle($infile,$pepinfo,"Polar");
ProcessSingle($infile,$pepinfo,"AcidBasic");
ProcessSingle($infile,$pepinfo,"PAB");
ProcessSingle($infile,$pepinfo,"CHARGE");

sub Learning{
   my ($infile,$outfile,$pepinfo) = @_ ; 
   my $ifh = util_read($infile);
   my $cnt = 0 ;
   my $positive = {};
   my $negative = {};
   while(<$ifh>){
        chomp ;
        next if(/^\s*$/);
	    next if(/0, 0, 0, 0 , 0 ,/);
	    next if(!/PROM score for/);
		$cnt++;
	    my ($pdb,$ec) = (/PROM score for (.*) with EC (.*)/);
	    s/PROM score for (.*) with EC (.*)//;
	    my $level = util_getECID($ec,1);
	    my ($threshhold, $ANNFILEDIST, $promIndex, $moonIndex, $TOTALMATCHES , $CNTOFMATCHES , $CNTOFNOTMATCHES, $COUNT ,$LEN) = split "," , $_ ; 
	    #next if($promIndex < 1);
		die "Dist $dist is not equal to $ANNFILEDIST" if($dist != $ANNFILEDIST);
   
	    #util_readPeptideInfo($pepinfo,$pdb,"/home/sandeepc/FASTA/$pdb.peptideinfo") if(!defined $pepinfo->{$pdb});
		#print "Reading $fastadir/$pdb.peptideinfo \n";
	    util_readPeptideInfo($pepinfo,$pdb,"$fastadir/$pdb.peptideinfo") if(!defined $pepinfo->{$pdb});
   
	    my $Molecular = $pepinfo->{$pdb}->{"Molecular"} or die;
	    my $Acidic = $pepinfo->{$pdb}->{"Acidic"} or die;
	    my $Basic = $pepinfo->{$pdb}->{"Basic"} or die;
	    my $Polar = $pepinfo->{$pdb}->{"Polar"} or die;
	    my $Tiny = $pepinfo->{$pdb}->{"Tiny"} or die;
	    my $Small = $pepinfo->{$pdb}->{"Small"} or die;
	    my $Aliphatic = $pepinfo->{$pdb}->{"Aliphatic"} or die;
	    my $Aromatic = $pepinfo->{$pdb}->{"Aromatic"} or die;

	    
		if($cnt < 10 || $cnt > 320){
			my $table = {};
			$table = $cnt > 320 ? $positive : $negative ;

		    #$table->{$pdb}->{1} = int($Molecular) ; 
		    #$table->{$pdb}->{2} = int($Acidic) ; 
		    #$table->{$pdb}->{3} = int($Basic) ; 
		    $table->{$pdb}->{4} = int($Polar) ; 
		    #$table->{$pdb}->{5} = int($Acidic + $Basic) ; 
		    #$table->{$pdb}->{6} = int($Tiny);
		    #$table->{$pdb}->{7} = int($Small);
		    #$table->{$pdb}->{8} = int($Aliphatic);
		    #$table->{$pdb}->{9} = int($Aromatic);
		}

   }

   SVMWrite($outfile,$positive,$negative);

   close($ifh);
}

sub SVMWrite{
   my ($outfile,$positive,$negative) = @_ ; 
   my $svmofh = util_write($outfile);
   SVMWriteTable($svmofh,$positive,"1");
   SVMWriteTable($svmofh,$negative,"-1");
}


sub SVMWriteTable{
   my ($svmofh,$table,$val) = @_ ; 
   my $cnt =0 ;
   foreach my $pdb (keys %{$table}){
   	  my $t = $table->{$pdb} ; 
      print $svmofh "$val ";
      foreach my $key (sort keys %{$t}){
   	      my $val = $t->{$key}; 
          print $svmofh " $key:$val ";
      }
      print $svmofh "\n";
      #print $svmofh "$pdb \n ";
      $cnt++;
   }

   print "Added $cnt for $val\n";
}

sub ProcessSingle{
   my ($infile,$pepinfo,$WHAT) = @_ ; 
   my $ifh = util_read($infile);
   my $ofnm = "output.$dist.$id.$WHAT.csv";
   my $FH = util_write($ofnm);
   print "processing $WHAT - output in $ofnm\n";
   while(<$ifh>){
        chomp ;
        next if(/^\s*$/);
	    next if(/0, 0, 0, 0 , 0 ,/);
	    next if(!/PROM score for/);
	    my ($pdb,$ec) = (/PROM score for (.*) with EC (.*)/);
	    s/PROM score for (.*) with EC (.*)//;
	    my $level = util_getECID($ec,1);
	    my $fh = $fhs->{$level} or die ; 
		#print $fh "$pdb \n";
	    my ($threshhold, $ANNFILEDIST, $promIndex, $moonIndex, $TOTALMATCHES , $CNTOFMATCHES , $CNTOFNOTMATCHES, $cnt ,$LEN) = split "," , $_ ; 
	    #next if($promIndex < 1);
		die "Dist $dist is not equal to $ANNFILEDIST" if($dist != $ANNFILEDIST);
   
	    #util_readPeptideInfo($pepinfo,$pdb,"/home/sandeepc/FASTA/$pdb.peptideinfo") if(!defined $pepinfo->{$pdb});
		#print "Reading $fastadir/$pdb.peptideinfo \n";
	    util_readPeptideInfo($pepinfo,$pdb,"$fastadir/$pdb.peptideinfo") if(!defined $pepinfo->{$pdb});
   
	    my $val = $pepinfo->{$pdb}->{$WHAT};

	    print2Both($fh,$FH,$promIndex,$val);

   }
   close($ifh);
   close($FH);
}

sub Stats{
   my ($infile,$ofnm) = @_ ; 
   my $ifh = util_read($infile);
   my $FH = util_write($ofnm);
   print "processing $infile output in $ofnm\n";
   my $info ; 


   my $popinfo = {};
   my $popoutfh ; 
   if(defined $population){
      my $popfh = util_read($population);
      while(<$popfh>){
        chomp ;
        next if(/^\s*$/);
	    next if(/0, 0, 0, 0 , 0 ,/);
	    next if(!/PROM score for/);
	    my ($pdb,$ec) = (/PROM score for (.*) with EC (.*)/);
	    s/PROM score for (.*) with EC (.*)//;
	    my ($threshhold, $ANNFILEDIST, $promIndex, $moonIndex, $TOTALMATCHES , $CNTOFMATCHES , $CNTOFNOTMATCHES, $cnt ,$LEN) = split "," , $_ ; 
		$popinfo->{$pdb}= $promIndex ; 
	  }
      $popoutfh = util_write("Ttest.csv");
   }

   while(<$ifh>){
        chomp ;
        next if(/^\s*$/);
	    next if(/0, 0, 0, 0 , 0 ,/);
	    next if(!/PROM score for/);
	    my ($pdb,$ec) = (/PROM score for (.*) with EC (.*)/);
	    s/PROM score for (.*) with EC (.*)//;
	    my $level = util_getECID($ec,1);
		#print $fh "$pdb \n";
	    my ($threshhold, $ANNFILEDIST, $promIndex, $moonIndex, $TOTALMATCHES , $CNTOFMATCHES , $CNTOFNOTMATCHES, $cnt ,$LEN) = split "," , $_ ; 
		print "$promIndex $pdb \n";
		$info->{$pdb} = [] if(!defined $info->{$pdb});
		push @{$info->{$pdb}}, $promIndex ; 
   }

   my $cnt = 0 ; 
   #my $FFF = util_write("$k.dat");
   my $FFF = util_write("data.csv");
   foreach my $k (keys %{$info}){
   	  my @l = @{$info->{$k}}; 
	  my $N = @l ; 
	  if($N > $stats){
		 $cnt++;
		 my $mean = util_format_float(Math::NumberCruncher::Mean(\@l) or warn "Mean not found",3) ;
		 my $median = util_format_float(Math::NumberCruncher::Median(\@l) or warn "Mean not found",3) ;
		 my $sd = util_format_float(Math::NumberCruncher::StandardDeviation(\@l) or warn "sd not found",3) ;
	     print $FH "pdb $k has $N $mean $median $sd  \n";
		 $, = ",";
		 if(!exists $popinfo->{$k}){
		 print STDERR "Expect population valu $k\n"   ;
		 next ;
		 }
		 print $FFF "$k,$mean,$median,$sd,$popinfo->{$k}, ", @l, "\n";
		 if(defined $popoutfh && exists $popinfo->{$k}){
		 	print $popoutfh "$k,$mean,$popinfo->{$k} \n";
		 	
		 }

	  }
   }
   print "cnt = $cnt \n";

   close($ifh);
   close($FH);
}

sub ScaleIndices{
   my ($infile) = @_ ; 
   my $ifh = util_read($infile);
   my $outfile = "$infile.scaled";
   my $ofh = util_write($outfile);
   my $maxProm = 0 ;
   my $maxMoon = 0 ;
   print "Wrote $infile to scaled filr $outfile\n";
   while(<$ifh>){
        chomp ;
        next if(/^\s*$/);
	    next if(/0, 0, 0, 0 , 0 ,/);
	    next if(!/PROM score for/);
	    my ($pdb,$ec) = (/PROM score for (.*) with EC (.*)/);
	    s/PROM score for (.*) with EC (.*)//;
	    my $level = util_getECID($ec,1);
	    my ($threshhold, $ANNFILEDIST, $promIndex, $moonIndex, $TOTALMATCHES , $CNTOFMATCHES , $CNTOFNOTMATCHES, $cnt ,$LEN) = split "," , $_ ; 
	    next if($promIndex < 1);



		$maxProm = $promIndex if($maxProm < $promIndex);
		$maxMoon = $moonIndex if($maxMoon < $moonIndex);
   }


   $ifh = util_read($infile);
   while(<$ifh>){
        chomp ;
        next if(/^\s*$/);
	    next if(/0, 0, 0, 0 , 0 ,/);
	    next if(!/PROM score for/);
	    my ($pdb,$ec) = (/PROM score for (.*) with EC (.*)/);
	    s/PROM score for (.*) with EC (.*)//;
	    my $level = util_getECID($ec,1);
	    my ($threshhold, $ANNFILEDIST, $promIndex, $moonIndex, $TOTALMATCHES , $CNTOFMATCHES , $CNTOFNOTMATCHES, $cnt ,$LEN) = split "," , $_ ; 


		my $pidx = (1* $promIndex) / $maxProm ;
		my $midx = (1* $moonIndex) / $maxMoon ;
		#$pidx = $pidx - 1 ;
		#next if($pidx > 1.5);
	    print $ofh "$threshhold, $ANNFILEDIST, $pidx, $midx, $TOTALMATCHES , $CNTOFMATCHES , $CNTOFNOTMATCHES, $cnt ,$LEN PROM score for $pdb with EC $ec \n";
   }

}


sub print2Both{
	 my ($fh,$FH,$a,$b) = @_ ;
	 return if(!defined $b);
	 print $fh "$a,$b \n";
	 print $FH "$a,$b \n";
}



sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
