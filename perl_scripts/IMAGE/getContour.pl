#!/usr/bin/perl -w 
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


my $AREACALCBYPIXEL = 0 ;
#use Time::HiRes qw( usleep ualarm gettimeofday tv_interval clock_gettime clock_getres  clock);
use POSIX qw(floor);
$, = " ";
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($infile,$outfile,$which_tech,$display,$listfile,$protein);
my ($csv,$contourcolor,$color,@expressions,$from,$to,@colornms);
my $howmany = 100000 ;
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
            "howmany=i"=>\$howmany ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
#my $ofh = util_write($outfile);
usage( "Need to give a input file name => option -infile ") if(!defined $infile);
usage( "Need to give a color => option -color ") if(!@colornms);
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

my $RlistF = $image->GetRowInfoContour(0,$colornms);
my $RlistR = $image->GetRowInfoContour(1,$colornms);
ProcessInfo($image,$RlistF,$RlistR);

#my $ClistF = $image->GetColumnInfoContour(0,$colornms);
#my $ClistR = $image->GetColumnInfoContour(1,$colornms);
#my ($CminX,$CminY,$CmaxY,$CmaxX) = ProcessInfo($image,$ClistF,$ClistR);


sub ProcessInfo{
	my ($image,$listF,$listR) = @_ ; 

    my $n = @{$listF} -1 ; 

	################################################################
	########## This gets the bounding coordinates ###################
	################################################################
    my ($minX,$minY,$maxY,$maxX) ;
    my ($CminX,$CminY,$CmaxY,$CmaxX) ;
	$CmaxX = 0 ;
	$CminX = 1000000 ;
	my ($prevStartX,$prevEndX) ; 

    #### ALL points are actually all points on the contour
	my (@allpoints);
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
	    }
    }


    
    print "$minY $maxY = Y  min max \n";
    print "$minX $maxX = X  min max \n";
    print "$CminY $CmaxY = Y  mCin mCax \n";
    print "$CminX $CmaxX = X  miCn mCax \n";

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

    #$image->SetColorToPixelByColorName($midX,$midY,"red");

    #$image->SetColorToPixelByColorName($CminX,$CminY,"red");
    #$image->SetColorToPixelByColorName($CmaxX,$CmaxY,"red");

	my @allpointssaved = @allpoints ;
	my @allpointstemp = @allpoints ;

	### for all thec contour points, get the max and min dist from the mid points -
	### This give you the major and minor axes
	my ($maxDist,$minDist,$pointAX,$pointAY,$pointBX,$pointBY,$newmidX,$newmidY) = geom_GetABForEllipse($midX,$midY,\@allpoints);
	$midX = $newmidX;
	$midY = $newmidY;



	#$image->SetColorToPixelByColorNameExtra($pointAX,$pointAY,"yellow",3);
	#$image->SetColorToPixelByColorNameExtra($pointBX,$pointBY,"green",3);


	if(defined $contourcolor){
	    $image->SetColorToFullImageByName("white");

		my $cnt = 1 ;
	    my @polygonpoints ;
		while(@allpointstemp){
			my $x = shift @allpointstemp ;
			my $y = shift @allpointstemp ;
            $image->SetColorToPixelByColorName($x,$y,"yellow");
		    my @l  = ($x , $y);
		    push @polygonpoints,\@l ; 
			$cnt++ ;
		}
		print "Perimeter size = $cnt\n";
	    $polygon->points(\@polygonpoints);
    
	     my $AREA  = $polygon->area();
	     print "$AREA polygon area\n";
	     $AREA  = $polygon->perimeter();
	     print "$AREA polygon perimeter\n";
	     print "$AREACALCBYPIXEL AREACALCBYPIXEL \n";

	    my ($extendedX,$extendedY) = geom_ExtendTwoPointsDouble($pointAX,$pointAY,$midX,$midY);
	    my @l = geom_GetPointsBetween($extendedX,$extendedY,$pointAX,$pointAY);
	    $image->SetColorToListofPixelsByColorName(\@l,"green");
    
	    ($extendedX,$extendedY) = geom_ExtendTwoPointsDouble($pointBX,$pointBY,$midX,$midY);
	    @l = geom_GetPointsBetween($extendedX,$extendedY,$pointBX,$pointBY);
	    $image->SetColorToListofPixelsByColorName(\@l,"blue");

		#my $angle = geom_AngleBetweenThreePoints($pointAX,$pointAY,0,$midX,$midY,0,$pointBX,$pointBY,0);
		my $angle = geom_AngleBetweenThreePoints($extendedX,$extendedY,0,$midX,$midY,0,$pointAX,$pointAY,0);
		print "ANGLE = $angle $pointAX,$pointAY,$midX,$midY,$pointBX,$pointBY \n";

        $image->Write("contour.$infile",$display);
	    die ;
	}



	## we have the points on the contour here 
	

	my $ratio = $maxDist/$minDist ;
	my $prod = $maxDist*$minDist ;
	my $area = 3.14* $prod ;

	#die "$maxDist $minDist";
	print "===============================================================================================\n";
	print " ( major axis = A  = $maxDist, minor axis = B = $minDist) are the ellipse \n";
	print " ( ratio  = $ratio, prod = $prod ; area = $area ; AREACALCBYPIXEL = $AREACALCBYPIXEL \n";
	print "===============================================================================================\n";

	my @colors = qw ( red green blue white );
	my $seen = {};
	my @shells ; 
	my $outshell ; 

my $howmanyshells = 5; 
my $howmanyshellsminusone = $howmanyshells - 1 ; 
	foreach my $PPP (1..$howmanyshellsminusone){
	    print " Getting shell info for $PPP\n";
		my $colornm = shift @colors ;
		my $requiredDividingration = $PPP/$howmanyshells ;
	    my $dividingRatio = ($requiredDividingration*$prod);

	    print "===============================================================================================\n";
	    print "requiredDividingration = $requiredDividingration,,,  dividingRatio = requiredDividingration*prod = $dividingRatio \n";
	    print "===============================================================================================\n";

        my ($in,$out) =  ColorOut($image,$ratio,$prod,$dividingRatio,$requiredDividingration,
		                        $midX,$midY,$pointAX,$pointAY,$pointBX,$pointBY,$listF,$listR,$maxDist,$minDist,$colornm) ;
		$outshell = $out ;
		my @points ;
		my $innumber = @{$in};
		$innumber = $innumber/2;
	    print "there were $innumber of points inside\n";
		while(@{$in}){
			my $x  = shift @{$in};
			my $y  = shift @{$in};
			my $xy = "$x.$y";
			next if(exists $seen->{$xy});
			$seen->{$xy} = 1 ;
			push @points, $x;
			push @points, $y;
		}
		push @shells, \@points ; 
	}
	## the last shell 
	push @shells, $outshell ;

	@colors = qw ( yellow green magenta blue aqua yellow green magenta blue aqua  yellow green magenta blue aqua  );
	my $info = {};
	my $cnt = 0; 
	my @revshells = reverse @shells ;
	foreach my $shell (@revshells){
		$info->{$cnt}->{blue} = $info->{$cnt}->{red} =  $info->{$cnt}->{other} = 0  ;
		my $colornm = shift @colors ;
	     my @p = @{$shell};	
		 while(@{p}){
			my $x  = shift @p;
			my $y  = shift @p;

			my @pixel = $image->GetPixel($x,$y);
			my ($v,$name) = $image->IsSingleColor(@pixel);
			if($v && $name eq "blue" ){
			    $image->SetColorToPixelByColorName($x,$y,$colornm);
			    $info->{$cnt}->{blue} = $info->{$cnt}->{blue} + 1 ;  
			}
			elsif($v && $name eq "red"){
			    $info->{$cnt}->{red} = $info->{$cnt}->{red} + 1 ;  
			}
			else{
			    $info->{$cnt}->{other} = $info->{$cnt}->{other} + 1 ;  
			}
		}
		print " $info->{$cnt}->{blue} + $info->{$cnt}->{red} + $info->{$cnt}->{other} ...............\n";
		$cnt++;
	}

	print $ofhcsv "$infile, ";
	foreach my $cnt (sort keys %{$info}){

		  my $SUM = $info->{$cnt}->{blue} + $info->{$cnt}->{red} + $info->{$cnt}->{other}  ;

	      my @ll = util_percentages($info->{$cnt}->{blue} ,$info->{$cnt}->{red} ,$info->{$cnt}->{other} );

		  print "sim = $SUM blue red others = " , @ll , "\n";
		  print $ofhcsv " $info->{$cnt}->{blue} , $info->{$cnt}->{red} , $info->{$cnt}->{other} , ";

		  #print $ofhcsv " $ll[0],$ll[1],$ll[2], ";
		
	}
	print $ofhcsv "\n";
	print $ofhcsv "$infile, ";
	foreach my $cnt (sort keys %{$info}){
	      my @ll = util_percentages($info->{$cnt}->{blue} ,$info->{$cnt}->{red} ,$info->{$cnt}->{other} );
		  print $ofhcsv " $ll[0],$ll[1],$ll[2], ";
		
	}
	print $ofhcsv "\n";

    $image->Write($outfile,$display);
}

sub ColorOut{
    my ($image,$ratio,$prod,$dividingRatio,$requiredDividingration,
	           $midX,$midY,$pointAX,$pointAY,$pointBX,$pointBY,$listF,$listR,$maxDist,$minDist,$colornm) = @_ ; 


	##############################################
	#####  Calculate the new major and minor axes
	##############################################
	
	### hardcoded hack of adding 1 
	my ($anew,$bnew,$c);
	my ($slope , $ANG , $ANGRAD , $COS , $SIN , $DDD);
	my $iterdiff = 1000 ; 
	my $iternum = 0;
	my @inpoints ; 
	my @outpoints  ; 
	my ($in,$out);
	while($iterdiff > .002 && $iternum < $NUMITERS ){
		@inpoints = ();
		@outpoints = ();
	    $iternum++;

        $bnew = sqrt (abs($dividingRatio/$ratio)) + 1  ; # ratio = 1.9. dividingratio = 4773 
        $anew = $ratio*$bnew   + 1 ; 
	    print "anew = $anew, bnew $bnew \n";
	    $c = sqrt(($anew*$anew) - ($bnew*$bnew));
    
    
	    $slope = (-$midX + $pointAX)/(-$midY + $pointAY) ;
	    $ANG = rad2deg(atan($slope));
	    $ANGRAD = (atan($slope));
	    $COS = cos($ANGRAD) * $c;
	    $SIN = sin($ANGRAD) * $c;
	    #$DDD = sqrt( $COS*$COS + $SIN*$SIN);
    
	    my $A1 = 3.14 * $maxDist * $minDist ; 
	    my $A2 = 3.14 * $anew * $bnew ; 
	    
    
    
	    #print " ($anew,$bnew) are the new ellipse and $c is the foci and slope is $slope and angle = $ANG and COS = $COS SIN = $SIN dd = $DDD  \n";
	    my $ADDEDX = $midX + $SIN;
	    my $ADDEDY = $midY + $COS;
	    my $SUBX = $midX - $SIN;
	    my $SUBY = $midY - $COS;

	    $in = 0 ;
	    $out = 0 ;
	    my $twiceMajor = 2*$anew ;
        my $n = @{$listF} -1 ; 
        foreach my $i (0..$n){
	        next if($listR->[$i]  == -1 || $listF->[$i]  == -1);
            my $start = $listF->[$i] ;
            my $end = $listR->[$i] ;
            my $y = $i+1 ;
            foreach my $x ($start..$end){
		       my $d1 = geom_Distance_2D($x,$y,$ADDEDX,$ADDEDY);
		       my $d2 = geom_Distance_2D($x,$y,$SUBX,$SUBY);
		       #print "$d1 $d2 $anew \n";
		       if((($d1+$d2) > ($twiceMajor)) ){
                    #$image->SetColorToPixelByColorName($x,$y,$colornm);
				    $out++;
				    push @outpoints,$x ; 
				    push @outpoints,$y ; 
		       }
		       else{
		   	        $in++;
				    push @inpoints,$x ; 
				    push @inpoints,$y ; 
		       }
			    die " mid " if($x == $SUBX && $y == $SUBY);
	        }
    
        }
    
    
	    my $PERCENT = $in/($out+$in) ;
	    my $actualdividingRatio = util_format_float($PERCENT,3) ;
	    $iterdiff = abs($actualdividingRatio -  $requiredDividingration);
	    if($actualdividingRatio >  $requiredDividingration){
		    $dividingRatio = $dividingRatio - 50 ;
	    }
	    else{
		    $dividingRatio = $dividingRatio + 50 ;
	    }
	    print  "Areas are  A1=$A1 A2=$A2 actualdividingRatio=$actualdividingRatio requiredDividingration =$requiredDividingration iterdiff=$iterdiff \n";
	}

	print " IN = $in out = $out \n";
	my @ll = util_percentages($in,$out);
	my $PERCENT = $in/$out ;
	print " PERCENT = $PERCENT requiredDividingration $requiredDividingration Percentages are ", @ll , "\n";

	return (\@inpoints, \@outpoints);
    
}
    


sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ;
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}

