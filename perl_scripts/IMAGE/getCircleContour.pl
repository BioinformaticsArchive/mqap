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
my ($annotate,$infile,$outfile,$which_tech,$display,$listfile,$protein);
my ($csv,$contourcolor,$color,@expressions,$from,$to,@colornms);
my $howmany = 100000 ;
my $verbose = 1 ;

my $NUMITERS = 20 ; 
my $ALLOWEDDIFF = 250 ; 

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
            "annotate=s"=>\$annotate ,
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

if(defined $annotate){
    my $ofhann = util_append($annotate);
    #my (@coordscentre) = $image->FindCoordsForColor("yellow","red");

    my (@coordscentre) = $image->FindCoordsForColor("white");
    my ($midCentreX,$midCentreY) = $image->GetMidPoint(@coordscentre);
    print  "$midCentreX,$midCentreY\n" ;

    my (@coordsradius) = $image->FindCoordsForColor("green");
    my ($midradiusX,$midradiusY) = $image->GetMidPoint(@coordsradius);
    print  "$midradiusX,$midradiusY\n" ;

    #$image->SetColorToPixelByColorName($midCentreX,$midCentreY,"green");
    #$image->SetColorToPixelByColorName(105,110,"white");
    #$image->Write($outfile,$display);
	#die ;

	my $R = geom_Distance_2D($midradiusX,$midradiusY,$midCentreX,$midCentreY);
    my $iter = 0; 
    my ($nBlack, $diff,$redcolor,$bluecolor,$redorblue);
    my $incrstep = 5 ; 
    my $decrstep = 5 ; 

	
    while($iter< $NUMITERS){
	    $incrstep = 1 if(!$incrstep);
	    $decrstep = 1 if(!$decrstep);
	    $iter++ ;
    
	    my $Rextend = $R + 5 ; 
	    my $minX = $midCentreX - $Rextend ;
	    my $maxX = $midCentreX + $Rextend ;
	    my $minY = $midCentreY - $Rextend ;
	    my $maxY = $midCentreY + $Rextend ;
    
    
	    my $junkseen ;
	    my $points = ProcessOneRadius($junkseen,$R,$minX,$maxX,$minY,$maxY,$midCentreX,$midCentreY) ;
	    my @points = @{$points};
	    $nBlack = 0 ;
	    while(@points){
		    my $x = shift @points ;
		    my $y = shift @points ;
	        my $xy = "$x.$y";
		    $junkseen->{$xy} = 1 ;
    
	        my @pixel = $image->GetPixel($x,$y);
		    my ($v,$name) = $image->IsSingleColor(@pixel);
		    if($v && $name eq "black" ){
			    $nBlack++;
		    }
	    }
    
	    my $height = $image->GetHeight();
	    $redorblue = $redcolor = $bluecolor = 0 ;
            foreach my $i (1..$height){
                my $p = $image->GetRowStraightorReversed(0,$i);
                while(@{$p}){
	                my $l = shift @{$p};
		            my ($r,$g,$b,$x,$y) = @{$l} ;
	                my @l = ($r,$g,$b);
	                my ($val,$name) = $image->IsColor(\@l,$image->GetAvailableColors());
        
			    my $xy = "$x.$y";
			    next if(exists $junkseen->{$xy});
    
		        if($name eq "blue"){
				    $bluecolor++;
			    }
		        elsif($name eq "red"){
				    $redcolor++;
				}
		    }
	    }
		 $redorblue = $redcolor + $bluecolor ;
         $diff = abs ($redorblue - $nBlack);
         last if($diff < $ALLOWEDDIFF );
         if($redorblue > $nBlack){
	          $R = $R + $incrstep-- ;
                print "Increasing rad $R $iter $redorblue - $nBlack $diff\n";
         }
         else{
	          $R = $R - $incrstep-- ;
             print "decreasin rad $R $iter $redorblue - $nBlack $diff\n";
         }
    } ## end of iterations

    print "final $R $iter $redorblue - $nBlack $diff\n";
	print $ofhann "$infile $midCentreX $midCentreY $R $redcolor $bluecolor $nBlack $redorblue\n";
}
else{
	my ($REF,$midCentreX,$midCentreY,$R,$redcolor,$bluecolor,$nBlack,$redorblue) ;
    my $ifhlist = util_read($listfile);
	my $found = 0 ; 
    while(<$ifhlist>){
        next if(/^\s*$/);
        next if(/^\s*#/);
        chop ;
	    ($REF,$midCentreX,$midCentreY,$R,$redcolor,$bluecolor,$nBlack,$redorblue) = split ;
		if($REF eq $infile){
			$found = 1 ; 
			last ; 
		}
	}
	if(!$found){
		print STDERR "$infile is not found in $listfile. Hence not processing\n";
		exit ;
	}
	my $area = 3.14 * $R * $R ; 
	my $seen = {};
	my @shells ; 

	my $Rextend = $R + 5 ; 
	my $minX = $midCentreX - $Rextend ;
	my $maxX = $midCentreX + $Rextend ;
	my $minY = $midCentreY - $Rextend ;
	my $maxY = $midCentreY + $Rextend ;

	foreach my $X (1..5){
	     my $shellarea = $X * ($area/5); 	
	     my $shellradius = sqrt($shellarea/3.14);
		 print "$shellradius llllllllllll\n";
		 my $points = ProcessOneRadius($seen,$shellradius,$minX,$maxX,$minY,$maxY,$midCentreX,$midCentreY) ;
	     push @shells, $points ; 
	}
    $image->ProcessShells($ofhcsv,$infile,$outfile,$display,$redcolor,$bluecolor,@shells) ; 
}



sub ProcessOneRadius{
	my ($seen,$shellradius,$minX,$maxX,$minY,$maxY,$midCentreX,$midCentreY) = @_ ; 
     my @points ; 
     foreach my $x ($minX...$maxX){
         foreach my $y ($minY...$maxY){
		      my $d1 = geom_Distance_2D($x,$y,$midCentreX,$midCentreY);
		      if($d1 < $shellradius){
			       my $xy = "$x.$y";
			       next if(exists $seen->{$xy});
			       $seen->{$xy} = 1 ;
			        push @points, $x;
			        push @points, $y;
		     }
         }
     }
     return \@points ;
}
