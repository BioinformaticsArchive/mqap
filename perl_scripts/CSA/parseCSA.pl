#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use POSIX qw(floor);
use PDB ; 
use ConfigPDB;
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($all,$infile,$annotate,$outfile,$or,$silent,$groupinfo,$specific);
my ($DIR);
my $howmany = 600000 ; 
my $length ;
my @types = (); 
GetOptions(
            "all"=>\$all ,
            "groupinfo"=>\$groupinfo ,
            "silent"=>\$silent ,
            "specific"=>\$specific ,
            "annotate"=>\$annotate ,
            "infile=s"=>\$infile ,
            "dir=s"=>\$DIR ,
            "howmany=i"=>\$howmany ,
            #"or=i"=>\$or ,
            "length=i"=>\$length ,
            "type=s"=>\@types,
            "outfile=s"=>\$outfile 
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a input file name => option -infile ") if(!defined $infile);
#usage( "Need to give a length ") if(!defined $length);

my $ofhall = util_write("list.all");

my ($grpconfig) = $ENV{CONFIGGRP} or die ;
    ConfigPDB_Init($grpconfig);
    my $CNT = 0 ; 
    print STDERR "Info: parsing file $infile \n";
    my $ifh = util_read($infile);
    my $info = {};
    my $groupbylength = {};
	my ($lastchain,$lastsitenum);
    while(<$ifh>){
         next if(/^\s*$/);
         #next if(!/1t4c/);
	        my ($pdb,$sitenum,$restype,$chain,$resnum,$chemfunc,$evidence,$lit) = parseSingleLine($_);
			next if(!defined $pdb); 
			#next if($chain ne "A");
			next if($restype =~ /^\s*$/);  ## this is water - not handled currently

			## just process proteins unless all is specified
			if(!defined $all){
			     next if($evidence !~ /LIT/i);
			}

	        last if($CNT > $howmany) ;

			
			if(!exists $info->{$pdb}){
				$lastsitenum = $sitenum ; 
				$lastchain = $chain; 
			    $CNT++ ;
		        $info->{$pdb} = {} ;
		    }

			if(!exists $info->{$pdb}->{$sitenum}){
				print "creatinf site $sitenum \n";
		        $info->{$pdb}->{$sitenum} = {} ;
			}
		    $info->{$pdb}->{$sitenum}->{$chain} = [] if(!exists $info->{$pdb}->{$sitenum}->{$chain});
		    push @{$info->{$pdb}->{$sitenum}->{$chain}} , $restype;
		    push @{$info->{$pdb}->{$sitenum}->{$chain}} , $resnum;

			if(($lastsitenum == $sitenum) && ($chain ne $lastchain)){
				print " Same site but diff chains for ($pdb,$sitenum,$restype,$chain,$resnum,$chemfunc,$evidence,$lit) \n";
				$info->{$pdb}->{$sitenum}->{DIRTY} = 1 ;
			}

			$lastsitenum = $sitenum ; 
			$lastchain = $chain; 
    
   }

my @vals = qw ( 10 9 8 7 6 5 4 3 2  );
#my @vals = qw ( 3);
my $done = {};
foreach my $length (@vals){
   my $outfile = TopLevel($info,$length,$done);
   if(defined $annotate){
       util_Annotate($outfile);
   }
}


sub TopLevel{
	my ($info,$length) = @_ ; 
    $outfile = "list.CSA.$length";
    my $ofh = util_write($outfile);



  
    my $cnt = 0 ; 
    foreach my $k (keys %{$info}){
	  my $val = $info->{$k} ; 
      my (@sites) = (keys %{$val});
	  my $numsites = @sites ;

	  print "Num sites = $numsites \n";

	  #next if($numsites != 1);

	  foreach my $site (@sites){
	 	my $v = $info->{$k}->{$site}; 
	 	my (@chains) = (keys %{$v}); 
		my $numchains = @chains ; 

		if( exists $v->{DIRTY}){
			print " JJJJJJJJJ This is mutli chain \n";
			next ;
		}
		my $chain = $v->{$chains[0]}; 
		my @chain ;

		next if($numchains != 1);
		next if($chains[0] ne "A");

		my @tmpchain = @{$chain};
		my $bad = 0 ; 
		while(@tmpchain){
			my $a = shift @tmpchain ;
			my $b = shift @tmpchain ;
		    $bad = 1  if($a eq "MN");
		    $bad = 1  if($a eq "DDZ");
		    $bad = 1  if($a eq "HIP");
		    $bad = 1  if($a eq "FE");
		    $bad = 1  if($a eq "CSO");
		    $bad = 1  if($a eq "HEM");
		    $bad = 1  if($a eq "MET");
		    $bad = 1  if($a eq "PLP");
		    $bad = 1  if($a eq "FGL");
		    $bad = 1  if($a eq "ZN");
		    $bad = 1  if($a eq "CSE");
		    $bad = 1  if($a eq "CA");
		    $bad = 1  if($a eq "MG");
		    $bad = 1  if($a eq "LLP");
		    $bad = 1  if($a eq "PHD");
		    $bad = 1  if($a eq "ILE");
		    $bad = 1  if($a eq "VAL");
		    $bad = 1  if($a eq "NA");
		    $bad = 1  if($a eq "CSS");
		    $bad = 1  if($a eq "CU1");
		    $bad = 1  if($a eq "PTR");
		    $bad = 1  if($a eq "FAD");
		    $bad = 1  if($a eq "SEP");
		    $bad = 1  if($a eq "SEC");
		    $bad = 1  if($a eq "SCY");
		    $bad = 1  if($a eq "NAD");
		    $bad = 1  if($a eq "NAP");
		    $bad = 1  if($a eq "FMN");
		    $bad = 1  if($a eq "MGD");
		    $bad = 1  if($a eq "SAM");
		    $bad = 1  if($a eq "VO4");
		    $bad = 1  if($a eq "FES");
		    if(!$bad){
				push @chain, $a ;
				push @chain, $b ;
			}
		}
		next if($bad);
		my $numberofres = @chain ; 


		next if(defined $length && $numberofres/2 != $length);

		$cnt++ ;

		my $UC = uc($k);
		next if(exists $done->{$UC});
		$done->{$UC} = 1 ;

		print $ofh "$UC\n";
		print $ofhall "$UC\n";
		
        #my $outconf = "$UC.$length.CSA.outconf";
        my $outconf = "$UC.CSA.outconf";
        my $outconffh = util_write($outconf);
		my @groups ; 
	    #print $outconffh "POINTS ";
		my $cnt = 0 ;
		while(@chain){
			last if($cnt == 6);
			$cnt++;
			my $a = shift @chain ;
			my $b = shift @chain ;
			if(defined $specific){
			    push @groups,  ConfigPDB_GetOnlyGrpNameForRes($a);
			}
			else{
			    push @groups,  ConfigPDB_GetGrpNameForRes($a);
			}
			print $outconffh " $a$b ";
		}
	    print $outconffh "\n";
		$, = "  " ; 
	    #print $outconffh "GROUPS " , @groups , "\n";
		close($outconffh);



		## print $ofh "\t Site $numchains $cnt has ALL SITES on diff chain\n" ;
	 	
	 }
}


print STDERR "There were $CNT results - and $cnt number of results written \n";
print STDERR "List written in $outfile \n";
return $outfile ;
}

sub parseSingleLine{
	my ($line) = @_ ; 
	my ($pdb,$sitenum,$restype,$chain,$resnum,$chemfunc,$evidence,$lit) = split "," , $line ; 
	return  ($pdb,$sitenum,$restype,$chain,$resnum,$chemfunc,$evidence,$lit) ;

}
sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
