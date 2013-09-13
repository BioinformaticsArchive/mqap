#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use MyUtils;
use ConfigPDB;
use MyGeom;

use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($infile,$outfile,$which_tech,$listfile);
my (@expressions);
my $howmany = 100000 ;
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "expr=s"=>\@expressions,
            "howmany=i"=>\$howmany ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
usage( "Need to give a input file name => option -infile ") if(!defined $infile);
#usage( "Need to give a listfile -option -listfile  ") if(!defined $listfile);
my $CNT = 0 ; 


my ($RESULTDIR,$PDBDIR) = util_SetEnvVars();

my $info = apbs_parsein($infile);

apbs_writein($info,$outfile);

#apbs_parselog("log");
exit ; 


sub apbs_pdb2pqr{
	my ($nm) = @_ ; 
	my $out = "$nm.apbs.in" ; 
	my $pdbfile = $PDBDIR . "/$nm.pdb";
    my $exec = "pdb2pqr.py --apbs-input --ff=parse $pdbfile $out";
    system($exec);
	return $out ; 
}

sub apbs_writein{
	my ($info,$outfile) = @_ ; 
	my $ofh = util_write($outfile);
	my @prelude = @{$info->{PRELUDE}} ;
	print $ofh @prelude, "\n";;

	my $elecs = $info->{ELECS} ;
	my @elecs = @{$elecs};
	my $CNT = 0  ;
	foreach my $elec (@elecs){
	   my @elec = @{$elec};	
	   my $written = 0 ; 
	   foreach my $l (@elec){
	   	   if($l =~ /^\s*write/){
		   	   my $nm = "pot" . $CNT++ ; 
		   	   print $ofh "write pot dx $nm\n";
			   $written = 1 ;
		   }
		   else{
		       if($l =~ /^\s*end/ && !$written){
		   	       my $nm = "pot" . $CNT++ ; 
		   	       print $ofh "write pot dx $nm\n";
		       }
		   	   print $ofh $l ;
		   }
	   }
	}

	my @prologue = @{$info->{PROLOGUE}} ;

	print $ofh @prologue, "\n";;
}


sub apbs_parsein{
	my ($infile) = @_ ; 
	my $ifh = util_read($infile) or die;
	my $info = {};
	my @prelude = ();
    while(<$ifh>){
          next if(/^\s*$/);
		  print "$_ \n";
		  push @prelude,$_ ;  
		  print ;
		  last if(/^\s*end/);

	}
	$info->{PRELUDE} = \@prelude ;

    my @elecs = ();
	my @prologue ; 
	while(1){
		 $_ = <$ifh>;
	     if(/^\s*elec/){
		     my @elec = ();
		     push @elec,$_ ;  
             while(<$ifh>){
                   next if(/^\s*$/);
		           push @elec,$_ ;  
		           last if(/^\s*end/);
	         }
		     push @elecs,\@elec ;
		 }
		 else{
		     push @prologue,$_ ;
			 last ;
		 }
	}

    while(<$ifh>){
		push @prologue,$_ ;
	}


	$info->{PROLOGUE} = \@prologue ;
	$info->{ELECS} = \@elecs ;

	my $len = @elecs ;
	print "there were $len elecs\n";

	#print @prelude ;
	#print @prologue ;

	apbs_parseElecs($info);
	return $info ;
}

sub apbs_parseElecs{
	my ($info) = @_ ;
	my $elecs = $info->{ELECS} ;
	my @elecs = @{$elecs};
	foreach my $elec (@elecs){
	   my @elec = @{$elec};	
	   foreach my $l (@elec){
	   	   if($l =~ /^\s*fglen/){
		   	   print "$l \n"; 
			   my ($fglen,$x,$y,$z) = split " ", $l  ; 
			   print "($fglen,$x,$y,$z) \n";
		   }
	   }
	}
}


sub apbs_parselog{
	my ($infile) = @_ ; 
	my $ifh = util_read($infile);
	my $info = {};
	my @prelude = ();
	my @dimen;
	my @spacing;
	my @length;
	my @centre;
    while(<$ifh>){
          next if(/^\s*$/);
          if(/Grid dimensions/){
		  	  my ($a,$b) = (/(.*):(.*)/);
			  @dimen = split "x", $b ; 
		  } 
          if(/Grid spacings/){
		  	  my ($a,$b) = (/(.*):(.*)/);
			  @spacing = split "x", $b ; 
		  } 
          if(/Grid lengths/){
		  	  my ($a,$b) = (/(.*):(.*)/);
			  @length = split "x", $b ; 
		  } 
          if(/Grid center/){
		  	  s/\(//;
		  	  s/\)//;
		  	  my ($a,$b) = (/(.*):(.*)/);
			  @centre = split ",", $b ; 
		  } 

   }
	print @dimen;
	print @spacing;
	print @length;
	print "center ", @centre, "\n";;
}



chmod 0777, $outfile ;
sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
