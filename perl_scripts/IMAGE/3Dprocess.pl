#!/usr/bin/perl -w 
use lib '/home/b/Bio/Code/perl_scripts/perl_scripts/';
use MyGeom;
use MyMagick;
use MyUtils;
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


#use Time::HiRes qw( usleep ualarm gettimeofday tv_interval clock_gettime clock_getres  clock);
use POSIX qw(floor);
$, = " ";
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($infile,$outfile,$which_tech,$display,$listfile,$protein);
my ($csv,$contourcolor,$color,$distfromperiphery,@expressions,$from,$to,@colornms,$specifiedcolor);
my $delta ;
my $verbose = 1 ;
my $NUMITERS = 100 ; 
my $SCALE = 1/7 ; 
GetOptions(
            "from=s"=>\$from ,
            "to=s"=>\$to ,
            "csv=s"=>\$csv ,
            "protein=s"=>\$protein ,
            "contourcolor"=>\$contourcolor ,
            "display"=>\$display ,
            "infile=s"=>\$infile ,
            "specifiedcolor=s"=>\$specifiedcolor ,
            "listfile=s"=>\$listfile ,
            "color=s"=>\@colornms ,
            "outfile=s"=>\$outfile ,
            "expr=s"=>\@expressions,
            "delta=f"=>\$delta ,
            "distfromperiphery"=>\$distfromperiphery ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
#usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
#my $ofh = util_write($outfile);
usage( "Need to give a input file name => option -infile ") if(!defined $infile);
usage( "Need to give a specifiedcolor ile name => option -specifiedcolor ") if(!defined $specifiedcolor );
usage( "Need to give a delta ile name => option -delta ") if(!defined $delta );
usage( "Need to give a color => option -color ") if(!@colornms);
my $ifh = util_read($infile);
#usage( "Need to give a from -option -from  ") if(!defined $from);
#usage( "Need to give a to -option -to  ") if(!defined $to);
$csv = "$specifiedcolor.rawdata";
my $ofhcsv = util_write($csv);


my $colornms = util_make_table(\@colornms);

my $image = new MyMagick($infile);

my $w = $image->GetWidth();
my $h = $image->GetHeight();


my $obj = $image->GetObj();

my $RlistF = $image->GetRowInfoContour(0,$colornms);
my $RlistR = $image->GetRowInfoContour(1,$colornms);
my ($minX,$minY,$maxY,$maxX,$CminX,$CminY,$CmaxY,$CmaxX,$midX,$midY,$AREACALCBYPIXEL,$insidetable,@allpoints) = GetAllPoints($image,$RlistF,$RlistR);
my @allpointstemp = @allpoints  ;
my ($maxDist,$minDist,$pointAX,$pointAY,$pointBX,$pointBY,$newmidX,$newmidY) = geom_GetABForEllipse($midX,$midY,\@allpoints);

print "W = $w H = $h maxdist = $maxDist minDist = $minDist \n";
my $ofhmax = util_write("max");
my $MM = int($maxDist);
print $ofhmax "$MM \n";



my @list= util_read_list_sentences($listfile);
my $cnt = 0; 
foreach my $i (@list){
	$cnt++ ; 
	last if($i eq $infile);
}
my $MIDCNT = $cnt ;
my $MID = $list[$cnt];

my $junkcnt = 0 ;
$cnt = 0 ; 
foreach my $i (@list){
	$cnt++ ;

	#next if($i eq $infile);


	my $dist = abs($MIDCNT - $cnt);
	my $XX = $dist * $delta ;
    my $image = new MyMagick($i);

    my $w = $image->GetWidth();
    my $h = $image->GetHeight();

    my (@blue) = $image->FindCoordsForColor("blue");
    my (@red) = $image->FindCoordsForColor("red");
    my (@speccolor) = $image->FindCoordsForColor($specifiedcolor);

	my $nblue = @blue ;
	my $nred = @red ;
	my $nspeccolor = @speccolor ;
    print "W = $w H = $h dist=$dist i=$i midcnt=$MIDCNT blue=$nblue red=$nred speccolor=$nspeccolor \n";
	my $found = 0 ; 
	while(@speccolor){
		my $x = shift @speccolor ;
		my $y = shift @speccolor ;
		my $str = GetCoord2Str($x,$y);
		next if(! exists $insidetable->{$str});
		$junkcnt++;


		# this is for green 
		if(defined $distfromperiphery){
	            my @allpointstemp1 = @allpointstemp  ;
		        my $min = 100000 ;
	            while(@allpointstemp1){
			        my $P = shift @allpointstemp1 ;
			        my $Q = shift @allpointstemp1 ;
	                my $XXX = geom_Distance_2D($P,$Q,$x,$y);
			        $min = $XXX if($XXX < $min);
	            }
		        #print "min = $min\n";
		        print $ofhcsv "$junkcnt $min\n";
        }
		else{
	            my $D = geom_Distance_2D($midX,$midY,$x,$y);
				$D = $D * $SCALE ;
		        my $ZZ = sqrt($XX*$XX + $D*$D);
		        #print "$D $XX $ZZ\n";
		        print $ofhcsv "$junkcnt $ZZ\n";
		    }
	}
	die if($found) ;
}



sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ;
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}

sub GetAllPoints{
	my ($IMAGE,$listF,$listR) = @_ ; 
	my $AREACALCBYPIXEL = 0 ;
    my $n = @{$listF} -1 ; 
	################################################################
	########## This gets the bounding coordinates ###################
	################################################################
    my ($minX,$minY,$maxY,$maxX) ;
    my ($CminX,$CminY,$CmaxY,$CmaxX) ;
	$CmaxX = 0 ;
	$CminX = 1000000 ;
	my ($prevStartX,$prevEndX) ; 
	my (@allpoints);
	
	my $Insidetable = {};
    foreach my $i (0..$n){
	    next if($listR->[$i]  == -1 || $listF->[$i]  == -1);
    
        my $start = $listF->[$i] ;
        my $end = $listR->[$i] ;
        my $y = $i+1 ;
		if(!defined $prevStartX){
                foreach my $XXX ($start..$end){
					push @allpoints, $XXX ;
					push @allpoints, $y ;
				}
		}
		if($start < $CminX){
			$CminX = $start ; 
			$CminY = $y;
		}
		if($end > $CmaxX){
			$CmaxX = $end ; 
			$CmaxY = $y;
		}

	    $minY = $y if(!defined $minY);
	    $maxY = $y ;
    
	    $minX = $start if(!defined $minX);
	    $maxX = $start ;
    
		my $x = $start ;
		push @allpoints, $x ;
		push @allpoints, $y ;

		$x = $end ;
		push @allpoints, $x ;
		push @allpoints, $y ;


		############################################
		#### this makes the line continuous #########
		############################################
		if(defined $prevStartX){
				my $A =$prevStartX > $start ?  $start : $prevStartX ;
				my $B =$prevStartX > $start ? $prevStartX :$start  ;
                foreach my $XXX ($A..$B){
					push @allpoints, $XXX ;
					push @allpoints, $y ;
				}
				$A =$prevEndX > $end ?  $end : $prevEndX ;
				$B =$prevEndX > $end ? $prevEndX :$end  ;
                foreach my $XXX ($A..$B){
					push @allpoints, $XXX ;
					push @allpoints, $y ;
				}
		}
		$prevStartX = $start;
		$prevEndX = $end;
		

        foreach my $x ($start..$end){
           $AREACALCBYPIXEL++;
	       my $str = GetCoord2Str($x,$y);
	       $Insidetable->{$str} = 1 ;
           $image->SetColorToPixelByColorName($x,$y,"white");
	    }
    }

	my @allpointstemp = @allpoints  ;
	while(@allpointstemp){
			my $x = shift @allpointstemp ;
			my $y = shift @allpointstemp ;
	}

	#####################################################
	## There are two midpoints - which one to choose? 
	##################################################
    my $midX = ($minX + $maxX)/2 ;
    my $midY = ($minY + $maxY)/2 ;
    #my $midX = (($minX + $maxX)/2 + ($CminX + $CmaxX)/2)/2 ;
    #my $midY = (($minY + $maxY)/2 + ($CminY + $CmaxY)/2)/2 ;
    print "midx =  $midX = ($minX + $maxX)/2 ; \n";
    print "midy  $midY = ($minY + $maxY)/2 ; \n";


    #$image->SetColorToPixelByColorName($minX,$minY,"red");
    #$image->SetColorToPixelByColorName($maxX,$maxY,"red");

    $image->SetColorToPixelByColorName($midX,$midY,"red");

    #$image->SetColorToPixelByColorName($CminX,$CminY,"red");
    #$image->SetColorToPixelByColorName($CmaxX,$CmaxY,"red");

	$image->Write("tttt.png",$display);

	return ($minX,$minY,$maxY,$maxX,$CminX,$CminY,$CmaxY,$CmaxX,$midX,$midY,$AREACALCBYPIXEL,$Insidetable,@allpoints);
}

sub GetCoord2Str{
	my ($x,$y) = @_ ; 
	my $str = "$x,$y";
	return $str ;
}
