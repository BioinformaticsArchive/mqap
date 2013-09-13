#!/usr/bin/perl -w 
use MyGeom;
use MyMagick;
use MyUtils;
use MyBlock;
use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use ConfigPDB;
use PDB;
use POSIX ;
use Algorithm::Combinatorics qw(combinations) ;
use Math::Geometry ;
use Math::Geometry::Planar;
my $polygon = Math::Geometry::Planar->new; 
   #$contour = Math::Geometry::Planar->new; creates a new contour object;


use Time::HiRes qw( usleep ualarm gettimeofday tv_interval clock_gettime clock_getres  clock);
use POSIX qw(floor);
$, = " ";
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($infile,$outfile,$which_tech,$display,$listfile,$protein);
my ($csv,$contourcolor,$color,@expressions,$from,$to,@colornms);
my $threshold ;
my $verbose = 1 ;
my $NUMITERS = 100 ; 
GetOptions(
            "from=s"=>\$from ,
            "to=s"=>\$to ,
            "csv=s"=>\$csv ,
            "protein=s"=>\$protein ,
            "contourcolor"=>\$contourcolor ,
            "display"=>\$display ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "color=s"=>\@colornms ,
            "outfile=s"=>\$outfile ,
            "expr=s"=>\@expressions,
            "threshold=i"=>\$threshold ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
my $ofh = util_write($outfile);
usage( "Need to give a input file name => option -infile ") if(!defined $infile);
usage( "Need to give a color => option -color ") if(!@colornms);
usage( "Need to give a thresh => option -thresh ") if(!defined $threshold);
my $ifh = util_read($infile);
#usage( "Need to give a from -option -from  ") if(!defined $from);
#usage( "Need to give a to -option -to  ") if(!defined $to);
usage( "Need to give a csv => option -csv ") if(!defined $csv);
my $ofhcsv = util_write($csv);


my $colornms = util_make_table(\@colornms);

my $image = new MyMagick($infile);

my $w = $image->GetWidth();
my $h = $image->GetHeight();

print "W = $w H = $h\n";

my $obj = $image->GetObj();


my $blkcnt = 0 ;
my @blocks ; 
my $block ; 
my $globalblockinfo = {};
my @colors = @{$image->GetAvailableColors()};
foreach my $i (1..$image->{HEIGHT}){
        my $p = $image->GetRowStraightorReversed(0,$i);
		my $seen = 0 ; 
        while(@{$p}){
	        my $l = shift @{$p};
		    my ($r,$g,$b,$x,$y) = @{$l} ;
	        my @l = ($r,$g,$b);
	        my ($val,$name) = $image->IsColor(\@l,$image->GetAvailableColors());
			if($colornms->{$name}){
				if($seen){
					$block->Add($x,$y,$globalblockinfo);
				}
				else{
					$block = new MyBlock($blkcnt++);
					$block->Add($x,$y,$globalblockinfo);
					push @blocks, $block ;
					$seen = 1 ;
				}
			}
			else{
				$seen = 0 ; 
			}
        }
}
print "Number of blks = $blkcnt \n";
$image->Write("hhh.png");

if($verbose){
    foreach my $k (keys %{$globalblockinfo}){
	    my $val = $globalblockinfo->{$k} ; 
	    print "$k $val \n";
    }
}

my $done = {};
my $tmp = 0 ; 
my $colorcnt = @colors ;
#die "$colorcnt = colornm\n";
foreach my $block (@blocks){
     my @points = $block->GetPoints();	
	 my $blkcnt = $block->GetBlkCnt();
	 #next if(exists $done->{$blkcnt});
	 if(!defined $done->{$blkcnt}){
	     $done->{$blkcnt} = [];
		 push @{$done->{$blkcnt}},$block ;
	 }
	 my $color = $colors[$tmp++%5];
	 print "$color = color for blk\n"  if($verbose);

	print "blkcnt for $blkcnt\n" if($verbose);
	 while(@points){
	 	my $x = shift @points ;
	 	my $y = shift @points ;
		#$image->SetColorToPixelByColorName($x,$y,$color);
		$y++;
		my $str = "$x.$y";
		print "\tchecking for $str\n" if($verbose); 
		if(exists $globalblockinfo->{$str}){
			my $thiscnt =  $globalblockinfo->{$str};
			if($thiscnt ne $blkcnt){
			    print "\t\tmerging $thiscnt ne $blkcnt \n"  if($verbose);;
			    my $newblock = $blocks[$thiscnt];
			    my $retblkcnt = $newblock->SetBlock($block,$globalblockinfo);
	            if(!defined $done->{$retblkcnt}){
	                $done->{$retblkcnt} = [];
		            push @{$done->{$retblkcnt}},$block ;
	            }
		        push @{$done->{$retblkcnt}},$newblock ;

				if(exists $done->{$thiscnt}){
					my @thisblocks = @{$done->{$thiscnt}};
					foreach my $nn (@thisblocks){
					       $nn->{TOUCHED} = 0 ;
			               my $retblkcnt = $nn->SetBlock($block,$globalblockinfo);
						   print "KKKK = $retblkcnt \n";
		                   push @{$done->{$retblkcnt}},$nn ;
					}
					delete $done->{$thiscnt};
				}


			}


		}
	 }
}


my @usecolors = qw (red magenta green yellow aqua );
my $NNNN = @usecolors ;
my $tmp = 0 ;
my $junk = 0 ;
#print $ofh " 	convert hhh.png -pointsize 20  ";
my $totalcnt = 0 ; 
foreach my $k (keys %{$done}){
	   my $color = $usecolors[$tmp++%$NNNN];

	   my @finalblocks = @{$done->{$k}} ; 
	   my $nblocks = @finalblocks ;
	   #print "UNIQUE $k $nblocks\n";

		my $npoints = 0 ;
		my $seen = {};
		foreach my $block (@finalblocks){

		   next if(exists $seen->{$block->{ORIGBLKCNT}});
		   $seen->{$block->{ORIGBLKCNT}} = 1 ;

           my @points = $block->GetPoints();	
		   $npoints = $npoints +  @points  ;
		   if($npoints > $threshold){
			   my $div = $npoints/20 ; 
			   my $floor = util_floor($div);
		       print $ofh "number = $npoints $floor \n" ;
			   $floor = 4 if($floor > 4 );
			   $totalcnt = $totalcnt + $floor; 
		   }
		}

		$seen = {};
		my @meanx ;
		my @meany ;

		foreach my $block (@finalblocks){

		   next if(exists $seen->{$block->{ORIGBLKCNT}});
		   $seen->{$block->{ORIGBLKCNT}} = 1 ;

		   next if ($npoints < $threshold );

           my @points = $block->GetPoints();	
           my $N = @points/2;
	       while(@points){
	 	      my $x = shift @points ;
	 	      my $y = shift @points ;
			  push @meanx, $x;
			  push @meany, $y;
			  $image->SetColorToPixelByColorName($x,$y,$color);
			  #print $ofh "$image->SetColorToPixelByColorName($x,$y,$color); N=$N npoints=$npoints \n";
			   
		    }
			  #print $ofh "meanx = $meanx, meany = $meany \n";

		}
		if(0){
		     my $meanx = Math::NumberCruncher::Mean(\@meanx) or warn "Mean not found" ;
		     my $meany = Math::NumberCruncher::Mean(\@meany) or warn "Mean not found" ;
		     if($meanx){
			     $junk++;
		          print $ofh " -draw \"text $meanx,$meany '$tmp'\" ";
			      #last if($junk eq 3) ;
		     }
		}
}
#print $ofh " 	text.png \n";
print $ofh "totalcnt = $totalcnt\n";

$image->Write("hhh.png");


exit ;

sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ;
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}

