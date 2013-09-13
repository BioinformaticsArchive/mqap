#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use MyUtils;
use ConfigPDB;
use MyGeom;
use BP;

use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($infile,$outfile,$which_tech,$listfile);
my ($justone,$table,$save,$arg,$findmatch,$needleoutfile,@expressions);
my $simi ;
my $verbose = 0 ;
my $verb;
my $TEX2PDF = "/home/sandeepc/DATA/Tex2Pdf";
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "justone=s"=>\$justone ,
            "outfile=s"=>\$outfile ,
            "needleoutfile=s"=>\$needleoutfile ,
            "arg=s"=>\$arg ,
            "verb"=>\$verb,
            "table=s"=>\$table,
            "save"=>\$save,
            "expr=s"=>\@expressions,
            "simi=f"=>\$simi ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
usage( "Need to give a listfile -option -listfile  ") if(!defined $listfile);
usage( "Need to give a listfile -option -needleoutfile  ") if(!defined $needleoutfile);
usage( "Need to give a simi -option -simi  ") if(!defined $simi);
usage( "Need to give a arg -option -arg  ") if(!defined $arg);
my $CNT = 0 ; 


$simi = 100 if(defined $table);


$verbose = 1 if(defined $verbose);

my ($RESULTDIR,$PDBDIR,$FASTADIR) = util_SetEnvVars();

my @pdbs= util_read_list_words($listfile);
@pdbs = ( $justone, @pdbs) if(defined $justone);


my @ignored = ();
print STDERR "Getting fasta file, either from DB $FASTADIR or thru the net\n";

my ($mapinfo,@files)  = util_GetFastaFiles($FASTADIR,@pdbs);



my $len = @files ;
print STDERR "Started with $len files \n";
my $iii = "/tmp/ignored";
my $ofh = util_write($iii);
print STDERR "Writing ignored files to $iii \n";

unlink $needleoutfile ;

my @goodones = ();
my $dontdo = {};
my $tableinfo = {};
my @tablekeys ; 
my $repeat = {};
while(@files){
	my $f1 = shift @files ;

	print "KKKKKKKKK $f1 \n";
	next if(exists $repeat->{$f1});
	$repeat->{$f1} = 1 ;

	die if($dontdo->{$f1});
	my $remlen = @files ; 
	my $ignlen = @ignored ; 
	print STDERR "Rem len = $remlen, ignored = $ignlen\n";

	push @goodones, $f1 if(! defined $justone);
	my @vals ; 
	$tableinfo->{$f1} = \@vals ;
	push @tablekeys , $f1 ;

	my @ttt = ();
    foreach my $f2 (@files){
	   next if($dontdo->{$f2});
	   #next if(exists $repeat->{$f2});
	   #$repeat->{$f2} = 1 ;
	   print "Writing file $needleoutfile\n" if($verbose);

	   if(! -e $needleoutfile){
	       BP_Needle($needleoutfile,"/",$f1,$f2,$arg); 
	   }
	   my ($iden,$simival) = BP_Needle_parseout($needleoutfile);




	   # for table 
	   push @vals, $iden ; 
	   push @vals, $simival ; 

	   print " ($f1,$f2) iden,simi  = ($iden,$simival) \n" if($verbose);
	   my $simiLOCAL = $simi ;

	   #$simival = $simival + $iden ;
	   my $notok = defined $justone ? $simival < $simi : $simival > $simi ;
	   if($notok){
	   	    $dontdo->{$f2} = 1 ; 
	        print "ignored $iden $simival $f2 $f1 $simi \n" if($verbose) ;
            push @ignored, $f2;
			my $mapped = $mapinfo->{$f2};
			print $ofh "$mapped\n";
	     
	   }
	   else{
		   push @ttt,$f2 ;
	       print "saved $iden $simival $f2 $f1 $simi \n" if($verbose) ;
		   push @goodones,$f2 if(defined $justone) ;
	   }
	   util_printAndDo("cp -f $needleoutfile .") if(defined $save);
	   #unlink $needleoutfile ;
    }
	print "@files lllllllll \n";
	@files = @ttt ;
	last if(defined $justone);
}

#shift @goodones, if(defined $justone);


if(defined $table){

    my $ofhtab = util_write($table);
    print STDERR "Writing to table $table\n";
    my $cnt = 0 ; 
    $, = " " ;
    #print $ofhtab " " ,  @tablekeys , "\n";
    my @tt = @tablekeys ;
    print $ofhtab " PDB " ;
    foreach my $key (@tt){
	    $key =~ s/.*\///;
	    $key =~ s/.ALL.*fasta//;
	    #print $ofhtab "$key & ";
	    print $ofhtab "$key  ";
    }
    print $ofhtab "\n";
    
    foreach my $key (@tablekeys){
	    my $l = $tableinfo->{$key};
	    $key =~ s/.*\///;
	    $key =~ s/.ALL.*fasta//;
	    #print $ofhtab "$key & ";
	    print $ofhtab "$key  ";
	    $cnt++;
	    my $tmp = $cnt ; 
	    while($tmp){
	       $tmp-- ; 
	       my $V = "NA";
	       $V = "-/-" if($tmp == 0);
	       print $ofhtab " $V  ";
	    }
    
	    while(@{$l}){
		    my $iden = shift @{$l} ;
		    my $simi = shift @{$l} ;
		    $iden =~ s/\s*//g ;
		    $simi =~ s/\s*//g ;
		    $iden = int($iden);
		    $simi = int($simi);
		    print $ofhtab " $iden\/$simi  ";
		    #print $ofhtab " $simi  ";
		    #print $ofhtab " $iden  ";
	    }
	    print $ofhtab "\n";
    }
    system(" cat $table");
    system(" createTexTable.pl -li $table -out $TEX2PDF/file.tex ");
    system(" cd $TEX2PDF ; ./do.sh   ");
    
}

print "Started with $len files \n";
$len = @goodones  ;
print "Ending with $len files after removing (or keeping if justone) similar ones.Writing these to $outfile \n";
$ofh = util_write($outfile);

## justone is not mapped, hence it comes as null
if(defined $justone){
	print $ofh "$justone\n";
    foreach my $k (keys %{$dontdo}){
	    print "Ignored $k \n";
    }
}

map { 
      my $mapped = $mapinfo->{$_};
      print $ofh $mapped , "\n" if($mapped !~ /^\s*$/) ;
} @goodones ;



chmod 0777, $outfile ;
sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
