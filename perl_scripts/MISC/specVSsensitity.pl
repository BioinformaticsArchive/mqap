#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($infile,$outfile,$which_tech,$listfile1,$listfile2);
my (@expressions);
my $cutoff ;
my $tag ;
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "infile=s"=>\$infile ,
            "listfile1=s"=>\$listfile1 ,
            "outfile=s"=>\$outfile ,
            "tag=s"=>\$tag ,
            "expr=s"=>\@expressions,
            "cutoff=i"=>\$cutoff ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a input file name => option -infile ") if(!defined $infile);
usage( "Need to give file containing all scores=> option -listfile ") if(!defined $listfile1);


die "Please define TEST_HOME" if(!defined $ENV{TEST_HOME});

usage( "Need to give a tag name => option -tag ") if(!defined $tag);
my $ofhFprSens = util_write($tag . ".fpr2sens");

   my $class = {};
   my $CNT = 0 ; 
   my $ifh = util_read($infile);
   while(<$ifh>){
        next if(/^\s*$/);
        chomp ;
	    my ($nm,$junk) = split ; 
	    $nm =~ s/.pdb.out//;
	    $nm =~ s/.pdb//;
        $class->{uc($nm)} = 1; 
	    $CNT++;
   }
   print "There were $CNT proteins of given class \n";
   close($ifh);
   
   

   my @listnumbers1 ;
   my @listnumbers2 ;
   my @names1 ;
   my @names2 ;
   
   $CNT = 0 ;
   $ifh = util_read($listfile1);
   while(<$ifh>){
        next if(/^\s*$/);
        chomp ;
	    my ($value,$nm) = split ; 
	    $nm =~ s/.pdb.out//;
	    $nm =~ s/.pdb//;
	    $nm = uc($nm);
        if(exists $class->{$nm}){
		   print "Class protein $nm\n";
           push @listnumbers1 , $value ; 	 	
           push @names1 , $nm ; 	 	
	    }
	    else{
           push @listnumbers2 , $value ; 	 	
           push @names2 , $nm ; 	 	
	    }
	    $CNT++;
   }
   my $n1 = @listnumbers1 ;
   my $n2 = @listnumbers2 ;

   
   print "There were $CNT proteins in all \n";
   print "Of these there were $n1 of class \n";
   print "and there were $n2 of not of class \n";
   close($ifh);



if(!defined $cutoff){
	my @values = qw ( 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 );
	#my @values = qw ( 1 3 5 8 10 13 15 18 20 );
	foreach my $v (@values){
        PrintValues($v);
	}
}
else{
   PrintValues($cutoff);
}
   
sub PrintValues{
   my ($CUTOFF) = @_ ; 


   
   
   my ($l11,$l12,$TP,$FN) = util_split_list_numbers(\@listnumbers1,$CUTOFF);
   my ($l21,$l22,$FP,$TN) = util_split_list_numbers(\@listnumbers2,$CUTOFF);
   return if(! ($TP + $FN));
   return if(! ($FP + $TN));
   my $sensitivity = $TP/($TP + $FN);
   my $specificity = $TN/($FP + $TN);
   my $FPR = 1 - $specificity ;

   #print "sensitivity = tp/(tp + fn ) = $sensitivity \n";
   #print "specificity = tn/(fp + tn ) = $specificity \n";
   #print "FPR = tn/(fp + tn ) = $FPR \n";

   $FPR = $FPR*100 ;
   $sensitivity = $sensitivity*100 ;
   #print $ofh "$CUTOFF $sensitivity $specificity $FPR \n";
   print $ofhFprSens "$FPR $sensitivity \n";
}
   
sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
