#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($all,$infile,$outfile,$or,$silent,$groupinfo);
my ($DIR);
my $howmany = 600000 ; 
my $cutofflength = 0 ; 
my @types = (); 
my @ntypes = (); 
my @motifs = (); 
GetOptions(
            "all"=>\$all ,
            "groupinfo"=>\$groupinfo ,
            "silent"=>\$silent ,
            "infile=s"=>\$infile ,
            "dir=s"=>\$DIR ,
            "howmany=i"=>\$howmany ,
            "or=i"=>\$or ,
            "cutofflength=i"=>\$cutofflength ,
            "type=s"=>\@types,
            "ntype=s"=>\@ntypes,
            "motif=s"=>\@motifs,
            "outfile=s"=>\$outfile 
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a input file name => option -infile ") if(!defined $infile);
usage( "Need to give a dir => option -dir ") if(!defined $DIR);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
usage( "Need specify if the type exprs are ORed or ANDed=> option -or ") if(!defined $or);
my $ofh = util_write($outfile);

my $typeexpr = @types ?  join "|", @types : "YYYYYYYYYYYYY" ; 
my $ntypeexpr = @ntypes ?  join "|", @ntypes : "YYYYYYYYYYYYY" ; 
my $motifexpr = @motifs ?  join "|", @motifs : "YYYYYYYYYYYYY" ; 
my $CNT = 0 ; 

my ($RESULTDIR,$PDBDIR) = util_SetEnvVars();


my $seqlist = {};

    print STDERR "Info: parsing file $infile - might take some time\n";
    my $ifh = util_read($infile);
    my $info = {};
    my $groupbylength = {};

	my $seenNm = {};
    while(<$ifh>){
         next if(/^\s*$/);
	     if(/^\s*>/){
	        my ($nm,$type,$len,$fullnm) = parseSingleLine($_);
			next if(!defined $nm); 
			next if(exists $seenNm->{$nm}); 
			$seenNm->{$nm} = 1 ;
	        my $seq = <$ifh> ;
		    chomp $seq ; 

			if(@motifs){
			    next if(!($seq =~ /$motifexpr/i));
			}

			next if($len < $cutofflength); 

			## just process proteins unless all is specified
			if(!defined $all){
			     next if($type !~ /protein/i);
			}

			if(@types){
				if($or == 1){
			        next if(!($fullnm =~ /$typeexpr/i));
				}
				else{
				    my $giveup = 0 ; 
					foreach my $e (@types){
			            if(!($fullnm =~ /$e/i)){
							$giveup = 1 ;
							last ; 
						}
					}
					next if($giveup);
				}
			}
			if(@ntypes){
			    next if(($fullnm =~ /$ntypeexpr/i));
			}
	        last if($CNT > $howmany) ;

			$CNT++ ; 
		    $info->{$nm} = {};
		    $info->{$nm}->{TYPE} = $type ;
		    $info->{$nm}->{LEN} = $len ;
		    $info->{$nm}->{FULLNM} = $fullnm ;
			if(!defined $groupbylength->{$len}){
				$groupbylength->{$len} = [];
			}
			push @{$groupbylength->{$len}},$_ ; 
			print "nm = $nm len = $len  full nm = $fullnm \n" if(!defined $silent);
    
		    $info->{$nm}->{SEQ} = $seq ;
			if(exists $seqlist->{$seq}){
			  # die " $seq exists \n";	
			}
			else{
				$seqlist->{$seq} = 1 ; 
			}
	 }
   }
  

   my @choose1ofEachLength = ();
   print $ofh "mkdir $DIR \n";
   if(defined $groupinfo){
   	    my $len = keys %{$groupbylength}; 
   		print "There were $len groups based on lenght\n";
		foreach my $k (keys %{$groupbylength}){
		    next if( $k > 600 || $k < 70);
			my @l = @{$groupbylength->{$k}};
			my $l = @l ; 
			`mkdir -p $DIR/len.$k` ;
			my $outlist = "$DIR/len.$k/list" ;
            my $ofhoutlist = util_write($outlist);
			print "\t For length $k there were $l number of proteins\n";
	        my ($nm,$type,$len,$fullnm) = parseSingleLine($l[0]);
			foreach my $xxx (@l){
	            my ($nm,$type,$len,$fullnm) = parseSingleLine($xxx);
				print $ofhoutlist "$nm\n";
			}
			push @choose1ofEachLength, $nm ; 
			my $k = uc($nm); 
            print $ofh "cp $PDBDIR/$k.pdb $DIR/ \n";
			#print $ofh "$k ,";
	        #print $ofh "  $l[0]";
		}
			print $ofh "\n";
   }
   else{
		foreach my $k (keys %{$info}){
			$k = uc($k);
			#print $ofh "cp $PDBDIR/$k.pdb $DIR/ \n";
			#print $ofh "grep $k oo \n";
			print $ofh "$k \n";
		}
   }
   print $ofh "tar -cvzf $DIR.tgz $DIR  \n";

print "There were $CNT results \n";

sub parseSingleLine{
	my ($line) = @_ ; 
	my ($nm,$type,$len,$fullnm) = ($line =~ /.(....).*mol:(\w+)\s*length:(\d+)\s*(.*)/);
	return ($nm,$type,$len,$fullnm) ;

}
sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
