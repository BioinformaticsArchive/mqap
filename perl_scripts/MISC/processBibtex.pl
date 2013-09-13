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
my ($infile,$outfile,$which_tech,$listfile,$protein);
my (@expressions);
my $howmany = 100000 ;
my $verbose = 1 ;
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "protein=s"=>\$protein ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "expr=s"=>\@expressions,
            "howmany=i"=>\$howmany ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a input file name => option -infile ") if(!defined $infile);
my $ifh = util_read($infile);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
my $ofh = util_write($outfile);
my $CNT = 0 ; 
my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC) = util_SetEnvVars();
my $PWD = cwd;

my $info = {};
my $inside = 0 ; 
my @l = ();
my @infos ;
while(<$ifh>){
     next if(/^\s*$/);
	 chop ;
     next if(/^\s*%/);
	 push @l, $_;
     if(/^\s*}/){
	 	my $info = Process(\@l);
		push @infos, $info if(defined $info);
		@l = ();
	 }
}

Print(\@infos);

close($ifh);

sub Process{
	my ($line) = @_ ; 
	my $info; 
	my @l = @{$line};
	my ($name,$fullauthor,$author,$year,$title) ;
	foreach my $i (@l){
		my $do = 1 ;
		if($i =~ /^\s*@/){
			($name) = ($i =~ /\{(.*),/);
			if($name !~ /^\s*PLC/){
				 $do = 0 ; 
			}
		}
		return if(!$do);
		if($i =~ /^\s*Author/i){
			$i =~ s/^\s*//g;
			$i =~ s/"//g;
			$i =~ s/,//g;
			$i =~ s/Author//ig;
			$i =~ s/=//g;
			$i =~ s/ and /,/g;
			my @l = split  ",", $i;
			my $n = @l - 1 ;
			$fullauthor = $l[$n] ;
			my @l1 = split " ",$fullauthor;
			my $n1 = @l1 - 1 ;
			$author = $l1[0] ;
			
			#print "$i \n";
		}
		if($i =~ /^\s*Title/i){
			$i =~ s/^\s*//g;
			$i =~ s/"//g;
			$i =~ s/,//g;
			$i =~ s/=//g;
			$i =~ s/Title//ig;
			$i =~ s/\{//g;
			$i =~ s/\}//g;
			my @l = split  ",", $i;
			my $n = @l - 1 ;
			$title = $l[$n] ;
			#print "$i \n";
		}
		if($i =~ /^\s*Year/i){
			$i =~ s/^\s*//g;
			$i =~ s/"//g;
			$i =~ s/,//g;
			$i =~ s/=//g;
			$i =~ s/Year//ig;
			$i =~ s/\{//g;
			$i =~ s/\}//g;
			my @l = split  ",", $i;
			my $n = @l - 1 ;
			$year = $l[$n] ;
			#print "$i \n";
		}
	}
	print "($name,$author,$year,$title) \n";
	$info->{name} = $name;
	$info->{year} = $year;
	$info->{author} = $author;
	$info->{fullauthor} = $fullauthor;
	$info->{title} = $title;
	return $info ;
}

sub Print{
	my ($infos) = @_ ;
	my @i = @{$infos};
    my @resultssorted = sort { $b->{year} <=> $a->{year} } @i ;
    foreach my $info (@resultssorted){
	    print "$info->{year} $info->{author}, $info->{fullauthor}, $info->{title}  \n";
		my $name = $info->{author} ; 
		my $year = $info->{year} ; 
		my $title = $info->{title} ; 




print $ofh "Dear Dr $name,\n";
   print $ofh "Greetings! I am a student working under the supervision of Professor BJ Rao.(http://www.tifr.res.in/~dbs/faculty/bjr/)\n";
   print $ofh "I'm writing this mail requesting you for some purified protein ($title,$year). We have recently got into studying active site evolution through bioinformatic approaches, which has led us to a protein which exhibits metal dependent beta lactamase activity. Since we have been unable to commercially procure metallo beta lactamases, which we intend to use as a control protein in our assays, we would appreciate it if you could spare the purified enzyme for our studies which we will kindly acknowledge. Please let me know. A few hundred micrograms of enzyme might suffice.\n";
print $ofh "\n";
print $ofh "Thank you and best regards\n";
print $ofh "\n";
print $ofh "Sincerely yours\n";
print $ofh "Sandeep Chakraborty.\n";
print $ofh "\n\n\n\n\n\n\n\n\n"

    }
}

sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
