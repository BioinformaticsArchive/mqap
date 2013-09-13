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
my ($infile,$outfile,$which_tech,$removefile,$protein);
my (@expressions);
my $howmany = 100000 ;
my $verbose = 1 ;
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "protein=s"=>\$protein ,
            "infile=s"=>\$infile ,
            "removefile=s"=>\$removefile ,
            "outfile=s"=>\$outfile ,
            "expr=s"=>\@expressions,
            "howmany=i"=>\$howmany ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
my $ofh = util_write($outfile);
usage( "Need to give a input file name => option -infile ") if(!defined $infile);
my $ifh = util_read($infile);

my $remove = {};
if(defined $removefile && -e $removefile){
    my @list= util_read_list_sentences($removefile);
	$remove = util_make_table(\@list);
}

$, = ",";
my $info = {};
my @b1 ;
my @r1 ;
my @o1 ;

my @b2 ;
my @r2 ;
my @o2 ;

my @sb1 ;
my @rb1 ;
my @ob1 ;
my @sb2 ;
my @rb2 ;
my @ob2 ;
	 foreach my $i (1..5){
	 	push @b1 , [];
	 	push @r1 , [];
	 	push @o1 , [];
	 	push @b2 , [];
	 	push @r2 , [];
	 	push @o2 , [];
	 }

my @nm ; 
push @nm , " " ;
my @numbers = qw (1 2 3 4 5 );
my $TOTAL = 0 ;
while(<$ifh>){
     chomp; 
	 s/,//g;
     next if(/^\s*Name/);

	 my @l1 = split ;
	 $_ = <$ifh> ;
     chomp; 
	 s/,//g;
	 my @l2 = split ;


     my $nm1 = shift @l1 ; 
     my $nm2 = shift @l2 ; 
	 next if ($nm1 ne $nm2);

	 my $N1 = @l1 ;
	 my $N2 = @l2 ;
	 next if ($N1 ne $N2);

     my $nm1removedjpg = $nm1 ; 
	 $nm1removedjpg =~ s/.jpg//;
	 $nm1removedjpg =~ s/.png//;
	 if(exists $remove->{$nm1removedjpg}){
	 	print "REMOVEd $nm1\n";
		next ;
	 }

	 push @nm , $nm1 ; 

     my $sb1 = 0 ;
     my $rb1 = 0 ;
     my $ob1 = 0 ;
     my $sb2 = 0 ;
     my $rb2 = 0 ;
     my $ob2 = 0 ;
	 $TOTAL++;
	 foreach my $i (@numbers){
	     my ($b1,$r1,$o1) = GetBRO(\@l1);
	     my ($b2,$r2,$o2) = GetBRO(\@l2);
		 push @{$b1[$i-1]}, $b1 ;
		 push @{$r1[$i-1]}, $r1 ;
		 push @{$o1[$i-1]}, $o1 ;
		 push @{$b2[$i-1]}, $b2 ;
		 push @{$r2[$i-1]}, $r2 ;
		 push @{$o2[$i-1]}, $o2 ;
		 $sb1 = $sb1 + $b1 ;
		 $rb1 = $rb1 + $r1 ;
		 $ob1 = $ob1 + $o1 ;
		 $sb2 = $sb2 + $b2 ;
		 $rb2 = $rb2 + $r2 ;
		 $ob2 = $ob2 + $o2 ;
	 }
	 push @sb1, $sb1 ;
	 push @rb1, $rb1 ;
	 push @ob1, $ob1 ;
	 push @sb2, $sb2 ;
	 push @rb2, $rb2 ;
	 push @ob2, $ob2 ;
	 die if(@l1);
	 die if(@l2);

}

push @nm, "SD";
push @nm, "SQRTN";
push @nm, "SEM";
push @nm, "Shellmean";
push @nm, " (shellMeanForAll/Totalmean)*100";

my $SBT1 = 0 ; 
my $RBT1 = 0 ; 
my $OBT1 = 0 ; 
my $SBT2 = 0 ; 
my $RBT2 = 0 ; 
my $OBT2 = 0 ; 
my $SQRT = sqrt($TOTAL) ;
foreach my $i (@numbers){
         my $mean = Math::NumberCruncher::Mean($b1[$i-1]) or warn "Mean not found" ;
         my $sd = Math::NumberCruncher::StandardDeviation($b1[$i-1]) or warn "Mean not found" ;
		 my $sem = $sd / $SQRT;
		 push @{$b1[$i-1]}, $sd ;
		 push @{$b1[$i-1]}, $SQRT ;
		 push @{$b1[$i-1]}, $sem ;
		 push @{$b1[$i-1]}, $mean ;
		 $SBT1 = $SBT1 + $mean ; 
         $mean = Math::NumberCruncher::Mean($r1[$i-1]) or warn "Mean not found" ;
         $sd = Math::NumberCruncher::StandardDeviation($r1[$i-1]) or warn "Mean not found" ;
		 $sem = $sd / $SQRT;
		 push @{$r1[$i-1]}, $sd ;
		 push @{$r1[$i-1]}, $SQRT ;
		 push @{$r1[$i-1]}, $sem ;
		 push @{$r1[$i-1]}, $mean ;
		 $RBT1 = $RBT1 + $mean ; 
         $mean = Math::NumberCruncher::Mean($o1[$i-1]) or warn "Mean not found" ;
         $sd = Math::NumberCruncher::StandardDeviation($o1[$i-1]) or warn "Mean not found" ;
		 $sem = $sd / $SQRT;
		 push @{$o1[$i-1]}, $sd ;
		 push @{$o1[$i-1]}, $SQRT ;
		 push @{$o1[$i-1]}, $sem ;
		 push @{$o1[$i-1]}, $mean ;
		 $OBT1 = $OBT1 + $mean ; 

         my $mean = Math::NumberCruncher::Mean($b2[$i-1]) or warn "Mean not found" ;
         $sd = Math::NumberCruncher::StandardDeviation($b2[$i-1]) or warn "Mean not found" ;
		 $sem = $sd / $SQRT;
		 push @{$b2[$i-1]}, $sd ;
		 push @{$b2[$i-1]}, $SQRT ;
		 push @{$b2[$i-1]}, $sem ;
		 push @{$b2[$i-1]}, $mean ;
		 $SBT2 = $SBT2 + $mean ; 
         $mean = Math::NumberCruncher::Mean($r2[$i-1]) or warn "Mean not found" ;
         $sd = Math::NumberCruncher::StandardDeviation($r2[$i-1]) or warn "Mean not found" ;
		 $sem = $sd / $SQRT;
		 push @{$r2[$i-1]}, $sd ;
		 push @{$r2[$i-1]}, $SQRT ;
		 push @{$r2[$i-1]}, $sem ;
		 push @{$r2[$i-1]}, $mean ;
		 $RBT2 = $RBT2 + $mean ; 
         $mean = Math::NumberCruncher::Mean($o2[$i-1]) or warn "Mean not found" ;
         $sd = Math::NumberCruncher::StandardDeviation($o2[$i-1]) or warn "Mean not found" ;
		 $sem = $sd / $SQRT;
		 push @{$o2[$i-1]}, $sd ;
		 push @{$o2[$i-1]}, $SQRT ;
		 push @{$o2[$i-1]}, $sem ;
		 push @{$o2[$i-1]}, $mean ;
		 $OBT2 = $OBT2 + $mean ; 
}

PUSH3space(\@sb1); push @sb1 , $SBT1 ;  
PUSH3space(\@rb1); push @rb1 , $RBT1 ;  
PUSH3space(\@ob1); push @ob1 , $OBT1 ;  
PUSH3space(\@sb2); push @sb2 , $SBT2 ;  
PUSH3space(\@rb2); push @rb2 , $RBT2 ;  
PUSH3space(\@ob2); push @ob2 , $OBT2 ;  

foreach my $i (@numbers){
         my $NNN = @{$b1[$i-1]} - 1  ; 
         my $mean = $b1[$i-1]->[$NNN]; 
		 push @{$b1[$i-1]}, ($mean/$SBT1)*100 ;

         $NNN = @{$r1[$i-1]} - 1  ; 
         $mean = $r1[$i-1]->[$NNN]; 
		 push @{$r1[$i-1]}, ($mean/$RBT1)*100 ;

         $NNN = @{$o1[$i-1]} - 1  ; 
         $mean = $o1[$i-1]->[$NNN]; 
		 push @{$o1[$i-1]}, ($mean/$OBT1)*100 ;

         $NNN = @{$b2[$i-1]} - 1  ; 
         my $mean = $b2[$i-1]->[$NNN]; 
		 push @{$b2[$i-1]}, ($mean/$SBT2)*100 ;

         $NNN = @{$r2[$i-1]} - 1  ; 
         $mean = $r2[$i-1]->[$NNN]; 
		 push @{$r2[$i-1]}, ($mean/$RBT2)*100 ;

         $NNN = @{$o2[$i-1]} - 1  ; 
         $mean = $o2[$i-1]->[$NNN]; 
		 push @{$o2[$i-1]}, ($mean/$OBT2)*100 ;


}

print $ofh @nm, "\n" ; 
foreach my $i (@numbers){
		 print $ofh "blue",  @{$b1[$i-1]}, "\n";
}
print $ofh "total blue",  @sb1 , "\n";
foreach my $i (@numbers){
		 print $ofh "blue",  @{$b2[$i-1]}, "\n";
}
print $ofh "total blue",  @sb2 , "\n";

print $ofh "\n\n";
### red 
foreach my $i (@numbers){
		 print $ofh "red",  @{$r1[$i-1]}, "\n";
}
print $ofh "total red",  @rb1 , "\n";
foreach my $i (@numbers){
		 print $ofh "red",  @{$r2[$i-1]}, "\n";
}
print $ofh "total red",  @rb2 , "\n";


print $ofh "\n\n";
foreach my $i (@numbers){
		 print $ofh "others",  @{$o1[$i-1]}, "\n";
}
print $ofh "total others",  @ob1 , "\n";
foreach my $i (@numbers){
		 print $ofh "others",  @{$o2[$i-1]}, "\n";
}
print $ofh "total others",  @ob2 , "\n";



sub GetBRO{
	 my ($l) = @_ ; 
	 my $b = shift @{$l}; 
	 my $r = shift @{$l}; 
	 my $o = shift @{$l}; 
	 return ($b,$r,$o); 
}
sub PUSH3space{
	my ($l) = @_ ;
	push @{$l}, "" ;
	push @{$l}, "" ;
	push @{$l}, "" ;
}

sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
