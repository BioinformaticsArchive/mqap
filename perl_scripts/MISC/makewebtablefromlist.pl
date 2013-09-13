#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use MyWeb;
use PDB ;
use ConfigPDB;
use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($promfile,$html,$all,$infile,$outfile,$scores,$or,$silent,$groupinfo,$pdb);
my ($addto,$matches,$DIR,$listfile,$query2ref,$mapping);
my $howmany = 600000 ; 
my ($WEIGHTEC) = $ENV{WEIGHTEC} ;
my $threshhold = 2 ; 
my $cutofflength = 0 ; 
my $isdummy = 0 ; 
my @types = (); 
my @ntypes = (); 
my @motifs = (); 
my $caption = "XXXXXXXXXXXXXXXXXXXXX";
my $header1 = "XXXXXXXXXXXXXXXXXXXXX";
my $header2 = "";
my $title = "CLASP Database";
my $ANNFILEDIST = 0 ;
GetOptions(
            "all"=>\$all ,
            "query2ref"=>\$query2ref ,
            "groupinfo"=>\$groupinfo ,
            "scores"=>\$scores ,
            "silent"=>\$silent ,
            "mapping"=>\$mapping ,
            "infile=s"=>\$infile ,
            "promidx=s"=>\$promfile ,
            "pdb=s"=>\$pdb ,
            "title=s"=>\$title ,

            "addto=s"=>\$addto ,
            "html=s"=>\$html ,
            "header1=s"=>\$header1 ,
            "header2=s"=>\$header2 ,

            "dir=s"=>\$DIR ,
            "listfile=s"=>\$listfile ,
            "howmany=i"=>\$howmany ,
            "matches=s"=>\$matches ,
            "anndist=i"=>\$ANNFILEDIST ,
            "isdummy=i"=>\$isdummy ,
            "or=i"=>\$or ,
            "cutofflength=i"=>\$cutofflength ,
            "type=s"=>\@types,
            "caption=s"=>\$caption,
            "ntype=s"=>\@ntypes,
            "motif=s"=>\@motifs,
            "outfile=s"=>\$outfile 
           );

usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
my $ofh = util_write($outfile);
usage( "Need to give a input file name => option -infile ") if(!defined $infile);
my $ifh = util_read($infile);

        web_printHtmlHead($ofh,"Target set of proteins to search in");

		$header1 = $header2 = "List of pdbs to be searched - obtained using the keyword plants in http://www.pdb.org/pdb/home/home.do ";
        web_printTableHead($ofh,$header1,$header2,"tableid");
		my @tableheaders ;
		push @tableheaders , "Sl no.";
		push @tableheaders , " Average " ;
		push @tableheaders , " Fragment alignment " ;
	    web_printTableHeader($ofh,@tableheaders);
		
while(<$ifh>){
     next if(/^\s*$/);
     next if(/^\s*\\/);
     next if(/^\s*#/);
     chop ;

	 s/,/ /g;
	 my (@x) = split " ", $_ ; 
	 my @l ;
	 push @l , shift @x  ;
	 push @l , shift @x  ;
	 foreach my $x (@x){
	   my ($a,$b) = split "-", $x ;
	   my $nm = "$a.$b.out";
	   push @l ,  web_makeLink($x,$nm,$isdummy);
	 }

	web_printTableRow($ofh,@l);
}

	    web_printTableEnd($ofh);
	    web_printHtmlEnd($ofh);


sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
