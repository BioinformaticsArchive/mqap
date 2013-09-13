
package MyMagick;
use Image::Magick;
use MyGeom;
use MyUtils;
@ISA = qw(Exporter );
@EXPORT = qw($fields);


use strict ;
use Carp ;
use FileHandle ;
use Getopt::Long;
use vars qw($AUTOLOAD);
use Getopt::Long;
use Cwd ;
use File::Basename;

no warnings 'redefine';

my @colors = qw ( magenta aqua yellow blue white black red green grey ) ;
my $del3 = 0.3 ;
my $del5 = 0.5 ;
my $del2 = 0.2 ;
my $del1 = 0.1 ;
my $del8 = 0.8 ;
my $del6 = 0.6 ;
my $del4 = 0.4 ;
my $del9 = 0.9 ;
my $del7 = 0.7 ;
my $del35 = 0.35 ;
my $del05 = 0.05 ;
my $del08 = 0.08 ;
my $del09 = 0.09 ;

my @red = ( 1, 0, 0, $del5,$del5,$del4,1,2,3);
my @blue = ( 0, 0, 1, $del6,$del5,$del5,3,2,1);
my @aqua = ( 0, 1, 1, $del05,$del05,$del05,1,2,3);
my @magenta = (  1, 0, 1, $del05,$del05,$del05,1,2,3);
my @black = ( 0, 0, 0, $del1,$del1,$del1,0);
my @white = ( 1, 1, 1,$del2,$del2,$del2,0);
#my @green = ( 0, 1, 0, $del1,$del1,$del1,2,3,1);
my @green = ( 0, .5, 0, $del1,$del1,$del1,2,3,1);
my @yellow = ( 1, 1, 0, $del05,$del05,$del05,2,3,1);
my @grey = ( .5, .5, .5, $del1,$del1,$del1,0);
#my @myown = (  0.0  ,.4 ,.5, $del3,$del3,$del8); 

my $colorinfo = {};
$colorinfo->{white} = \@white ;
$colorinfo->{black} = \@black ;
$colorinfo->{red} = \@red ;
$colorinfo->{green} = \@green ;
$colorinfo->{blue} = \@blue ;
$colorinfo->{yellow} = \@yellow ;
$colorinfo->{aqua} = \@aqua ;
$colorinfo->{magenta} = \@magenta ;
#$colorinfo->{myown} = \@myown ;


my $_verbose = 0 ;

my $fields = {
    IMAGEOBJ => undef, 
    WIDTH => undef, 
    HEIGHT => undef ,
    LOGFILE => undef 
};

sub new{
    my $that = shift ; 
    my $class = ref($that) || $that ;

	my ($filename) = @_ ; 

    my $self =  {};

    map { $self->{$_} = undef ; } (keys %{$fields});

    my $image=Image::Magick->new;
	if(!defined $filename){
	$image->Set(size=>'100x100');
	$image->ReadImage('xc:white');
	$image->Set('pixel[49,49]'=>'red');
	}
	else{
    my $x = $image->Read($filename);
    warn "$x" if "$x";
	}

    $self->{IMAGEOBJ} = $image ;

    $self->{WIDTH} = $image->Get('columns');
    $self->{HEIGHT} = $image->Get('height');
    $self->{RESIDUES} = [];
    $self->{LINES} = [];
    $self->{ADDEDATOMS} = [];
    $self->{RESTABLE} = {};
    $self->{ALLOWED_CONN_TYPE} = {};


    bless $self, $class ;
	$self ;
}

sub AUTOLOAD {
    my $self = shift;
    my $attr = $AUTOLOAD;
    $attr =~ s/.*:://;
    return unless $attr =~ /[^A-Z]/;  # skip DESTROY and all-cap methods
    croak "invalid attribute method: ->$attr()" unless exists $fields->{$attr} ; 
    $self->{$attr} = shift if @_;
    return $self->{$attr};
}

sub GetPixel{
	my ($self,$x,$y) = @_;
	$self->CheckPixel($x,$y);
	my ($r,$g,$b) = $self->{IMAGEOBJ}->GetPixel(x=>$x,y=>$y);
	$r = util_format_float($r,3);
	$g = util_format_float($g,3);
	$b = util_format_float($b,3);
    return ($r,$g,$b);
}

sub GetWidth{
	my ($self) = @_;
    return $self->{WIDTH};
}
sub Write{
	my ($self,$name,$display) = @_;
	print STDERR "Wrote to file $name\n";
    $self->{IMAGEOBJ}->Write($name);
	if(defined $display){
		system("eog $name");
	}
}

sub GetHeight{
	my ($self) = @_;
    return $self->{HEIGHT};
}

sub GetObj{
	my ($self) = @_;
    return $self->{IMAGEOBJ};
}

sub GetAvailableColors{
	my ($self) = @_;
    return \@colors ;
}

sub CheckPixelIsFine{
	my ($self,$x,$y) = @_;
    return 0 if($x > $self->{WIDTH} || $y >  $self->{HEIGHT});
	return 1 ;
}	

sub CheckPixel{
	my ($self,$x,$y) = @_;
    croak "Wrong coordinates $x $y, should be within  $self->{WIDTH},  $self->{HEIGHT} " if($x > $self->{WIDTH} || $y >  $self->{HEIGHT});
}

sub GetRow{
	my ($self,$y,$x) = @_;
	$x = 1 if(!defined $x);
	$self->CheckPixel($x,$y);
	my @l ;
	while($x <= $self->{WIDTH}){
		my @t = $self->GetPixel($x,$y);
		push @t, $x ; 
		push @t, $y ; 
		push @l, \@t ; 
		$x++;
	}
	return \@l;
}

sub GetRowReversed{
	my ($self,$y,$x) = @_;
	my $l = $self->GetRow($y,$x);
	my @reversed = reverse @{$l};
	return \@reversed ;
}
sub GetRowStraightorReversed{
	my ($self,$val,$y,$x) = @_;
	return $self->GetRow($y,$x) if($val == 0);
	$self->GetRowReversed($y,$x) if($val == 1);
}

sub GetColumn{
	my ($self,$x,$y) = @_;
	$y = 1 if(!defined $y);
	$self->CheckPixel($x,$y);
	my @l ;
	while($y <= $self->{HEIGHT}){
		my @t = $self->GetPixel($x,$y);
		push @t, $x ; 
		push @t, $y ; 
		push @l, \@t ; 
		$y++;
	}
	return \@l;
}

sub GetColumnReversed{
	my ($self,$x,$y) = @_;
	my $l = $self->GetColumn($x,$y);
	my @reversed = reverse @{$l};
	return \@reversed ;
}

sub GetColumnStraightorReversed{
	my ($self,$val,$x,$y) = @_;
	return $self->GetColumn($x,$y) if($val == 0);
	$self->GetColumnReversed($x,$y) if($val == 1);
}



sub IsColor{
	my ($self,$pixel,$names) = @_;
	return $self->IsSingleColor(@{$pixel});
}

sub IsSingleColor{
	    my ($self,$r1,$g1,$b1) = @_;

        #return (1,"white") if(AllGreaterThan($r1,$g1,$b1,$del9));
        return (1,"white") if(AllGreaterThan($r1,$g1,$b1,$del6));
        return (1,"black") if(AllLesserThan($r1,$g1,$b1,$del2));
        return (1,"grey")  if(AllEqual($r1,$g1,$b1,$del08));
		return (1,"green") if(abs($g1 - 0.5) < $del1 && ($r1 < $del2 ||  $b1 < $del2));
		return (1,"yellow") if(abs($r1 -1 ) < $del1 && abs($g1 -1) < $del1 && $b1 < $del2);
		if($r1 > $b1 || abs($r1 - $b1) < $del09){
		    #print "$r1,$g1,$b1 \n";
            return (1,"red") ;
		}
		else{
		    #print "$r1 $g1 $b1 \n";
            return (1,"blue") ;
		}

	    return (0,"unknown");

}

sub AllGreaterThan{
	my ($r1,$g1,$b1,$del) = @_;
	return 1 if($r1 >= $del && $g1 >= $del && $b1 >= $del);
	return 0 ;
}

sub AllLesserThan{
	my ($r1,$g1,$b1,$del) = @_;
	return 1 if($r1 <= $del && $g1 <= $del && $b1 <= $del);
	return 0 ;
}

sub AllEqual{
	my ($r1,$g1,$b1,$del) = @_;
	my $d1 = abs($r1 - $g1);
	my $d2 = abs($r1 - $b1);
	my $d3 = abs($b1 - $g1);
	return 1 if($d1 <= $del && $d2 <= $del && $d3 <= $del);
	return 0 ;
}


sub SetPixel{
	my ($self,$x,$y,$pixel) = @_ ; 
	my $image = $self->{IMAGEOBJ};
    $self->GetObj()->SetPixel(x=>$x,y=>$y,color=>$pixel);
}

sub NeighbourhoodMatches{
	my ($self,$x,$y,$colornm) = @_ ; 
	my $range = 2 ;
	my $howmany = 4 ;
	my $maxX = $x + $range;
	my $minX = $x - $range;
	my $maxY = $y + $range ;
	my $minY = $y - $range ;
	my $cnt = 0 ; 
	foreach my $X ($minX..$maxX){
	    foreach my $Y ($minY..$maxY){
			next if(!$self->CheckPixelIsFine($X,$Y));
			my @pixel = $self->GetPixel($X,$Y);
	        my ($v,$name) = $self->IsSingleColor(@pixel);
			$cnt++ if($name eq $colornm);
	    }
	}
	return 1 if($cnt > $howmany );
	return 0 ; 
}

sub GetRowInfoContour{
	my ($self,$straightorreversed,$colornms) = @_ ; 
    my $info ;
	my @retvals ; 
    foreach my $i (1..$self->{HEIGHT}){
        my $p = $self->GetRowStraightorReversed($straightorreversed,$i);
		my $seen = 0 ; 
        while(@{$p}){
	        my $l = shift @{$p};
		    my ($r,$g,$b,$x,$y) = @{$l} ;
	        my @l = ($r,$g,$b);
	        my ($val,$name) = $self->IsColor(\@l,$self->GetAvailableColors());
		    if(!defined $info->{$name}){
			    $info->{$name} = 0 ; 
		    }
		    $info->{$name} = $info->{$name} + 1 ; 
			if($seen == 0 && exists $colornms->{$name} && $self->NeighbourhoodMatches($x,$y,$name) ){
			    $seen = 1 ; 
				push @retvals, $x ;
			}
        }
		if($seen == 0){
		     push @retvals, -1 ; 
		}
	}
	$self->PrintStats($info);
	return \@retvals ;
}

sub GetColumnInfoContour{
	my ($self,$straightorreversed,$colornms) = @_ ; 
    my $info ;
	my @retvals ; 
    foreach my $i (1..$self->{WIDTH}){
        my $p = $self->GetColumnStraightorReversed($straightorreversed,$i);
		my $seen = 0 ; 
        while(@{$p}){
	        my $l = shift @{$p};
		    my ($r,$g,$b,$x,$y) = @{$l} ;
	        my @l = ($r,$g,$b);
	        my ($val,$name) = $self->IsColor(\@l,$self->GetAvailableColors());
		    if(!defined $info->{$name}){
			    $info->{$name} = 0 ; 
		    }
		    $info->{$name} = $info->{$name} + 1 ; 
			if($seen == 0 && exists $colornms->{$name} ){
			    #print "$r,$g,$b,$x,$y $name \n";
			    $seen = 1 ; 
				push @retvals, $y ;
			}
        }
		if($seen == 0){
		     push @retvals, -1 ; 
		}
	}
	$self->PrintStats($info);
	return \@retvals ;
}
sub GetColorInfo{
	my ($self,$table) = @_ ; 
    return $colorinfo ;
}

sub ChangeColor{
	my ($self,$table) = @_ ; 
    my $info ;
    foreach my $i (1..$self->{HEIGHT}){
        my $p = $self->GetRowStraightorReversed(0,$i);
        while(@{$p}){
	        my $l = shift @{$p};
		    my ($r,$g,$b,$x,$y) = @{$l} ;
	        my @l = ($r,$g,$b);
	        my ($val,$name) = $self->IsColor(\@l,$self->GetAvailableColors());
		    if(!defined $info->{$name}){
			    $info->{$name} = 0 ; 
		    }
		    $info->{$name} = $info->{$name} + 1 ; 
		    if(exists $table->{$name}){
				my $to = $table->{$name} ;
				my $l = $colorinfo->{$to} ;
				my ($r,$g,$b,$del1,$del2,$del3) = @{$l};
			    my @kkk = ( $r,$g,$b);
                $self->GetObj()->SetPixel(x=>$x,y=>$y,color=>\@kkk);
                #my @pixels = $self->GetObj()->GetPixel(x=>$x,y=>$y);
	            #my ($val,$name) = $self->IsColor(\@pixels,$self->GetAvailableColors());
    
    
		    }
        }
	}
	$self->PrintStats($info);
}

sub ChangeColorInv{
	my ($self,$from,$to) = @_ ; 
    my $info ;
    foreach my $i (1..$self->{HEIGHT}){
        my $p = $self->GetRowStraightorReversed(0,$i);
        while(@{$p}){
	        my $l = shift @{$p};
		    my ($r,$g,$b,$x,$y) = @{$l} ;
	        my @l = ($r,$g,$b);
	        my ($val,$name) = $self->IsColor(\@l,$self->GetAvailableColors());
		    if(!defined $info->{$name}){
			    $info->{$name} = 0 ; 
		    }
		    $info->{$name} = $info->{$name} + 1 ; 
		    if($name eq $from){
			}
			else{
				my $l = $colorinfo->{$to} ;
				my ($r,$g,$b,$del1,$del2,$del3) = @{$l};
			    my @kkk = ( $r,$g,$b);
                $self->GetObj()->SetPixel(x=>$x,y=>$y,color=>\@kkk);
                #my @pixels = $self->GetObj()->GetPixel(x=>$x,y=>$y);
	            #my ($val,$name) = $self->IsColor(\@pixels,$self->GetAvailableColors());
    
    
		    }
        }
	}
	$self->PrintStats($info);
}


sub PrintStats{
	my ($self,$info) = @_ ; 
	my $sum = 0;
    foreach my $key (keys %{$info}){
		$sum+= $info->{$key};
    }
	print "Sum = $sum \n";
    foreach my $key (keys %{$info}){
		my $percent = 100* ($info->{$key}/$sum );
	    print "$key $info->{$key} $percent \n";
	}
}


sub DebugInfo{
	my ($self) = @_ ; 
	my $ofh = util_write("debug.out");
    my $info ;
    foreach my $i (1..$self->{HEIGHT}){
        my $p = $self->GetRowStraightorReversed(0,$i);
	    print $ofh "Row$i ";
        while(@{$p}){
	        my $l = shift @{$p};
		    my ($r,$g,$b,$x,$y) = @{$l} ;
	        my @l = ($r,$g,$b);
	        my ($val,$name) = $self->IsColor(\@l,$self->GetAvailableColors());
			print $ofh "$name ($r $g $b) ";
        }
	    print $ofh "\n";
	}
	die "Written debug info";
}


sub SetColorToFullImage{
	my ($self,$colorpixel) = @_ ; 
    foreach my $i (1..$self->{HEIGHT}){
        my $p = $self->GetRowStraightorReversed(0,$i);
        while(@{$p}){
	        my $l = shift @{$p};
		    my ($r,$g,$b,$x,$y) = @{$l} ;
	        my @l = ($r,$g,$b);
            $self->SetPixel($x,$y,$colorpixel);
			#$self->SetColorToPixelByColorName($x,$y,"blue");
        }
	}
}

sub SetColorToFullImageByName{
	my ($self,$colornm) = @_ ; 
    foreach my $i (1..$self->{HEIGHT}){
        my $p = $self->GetRowStraightorReversed(0,$i);
        while(@{$p}){
	        my $l = shift @{$p};
		    my ($r,$g,$b,$x,$y) = @{$l} ;
	        my @l = ($r,$g,$b);
			$self->SetColorToPixelByColorName($x,$y,$colornm);
        }
	}
}


sub SetColorToPixelByColorName{
	my ($self,$x,$y,$name) = @_ ;
    my $l = $colorinfo->{$name} or die "Could not find color $name" ;
	my ($r,$g,$b,$del1,$del2,$del3) = @{$l};
	#print  "SSSSSSSSSS $r $g $b \n";
	my @kkk = ( $r,$g,$b);
	$self->GetObj()->SetPixel(x=>$x,y=>$y,color=>\@kkk);
}


sub SetColorToPixelByColorNameExtra{
	my ($self,$x,$y,$name,$howmany) = @_ ;
	die if(! defined $howmany);
    my $l = $colorinfo->{$name} or die "Could not find color $name" ;
	my ($r,$g,$b,$del1,$del2,$del3) = @{$l};
	my @kkk = ( $r,$g,$b);
	$self->GetObj()->SetPixel(x=>$x,y=>$y,color=>\@kkk);
	while($howmany){
	    $howmany-- ;
	    $x++ ;
	    $self->GetObj()->SetPixel(x=>$x,y=>$y,color=>\@kkk);
	    $y++;
	    $self->GetObj()->SetPixel(x=>$x,y=>$y,color=>\@kkk);
    }
}

sub SetColorToListofPixelsByColorName{
	my ($self,$list,$name) = @_ ;
	my @list = @{$list};
	while(@list){
		my $x = shift @list;
		my $y = shift @list;
		$self->SetColorToPixelByColorName($x,$y,$name);
	}
}

sub FindCoordsForColor{
	my ($self,$color,$to) = @_ ; 
	my @ret ; 
    foreach my $i (1..$self->{HEIGHT}){
        my $p = $self->GetRowStraightorReversed(0,$i);
        while(@{$p}){
	        my $l = shift @{$p};
		    my ($r,$g,$b,$x,$y) = @{$l} ;
	        my @l = ($r,$g,$b);
	        my ($val,$name) = $self->IsColor(\@l,$self->GetAvailableColors());
		    if($name eq $color){
				push @ret, $x ;
				push @ret, $y ;
				if(defined $to){
				     my $l = $colorinfo->{$to} ;
				     my ($r,$g,$b,$del1,$del2,$del3) = @{$l};
			         my @kkk = ( $r,$g,$b);
                     $self->GetObj()->SetPixel(x=>$x,y=>$y,color=>\@kkk);
				}
		    }
        }
	}
	return @ret ;
}


sub GetMidPoint{
	my ($self,@list) = @_ ;
	my $totX = 0 ; 
	my $totY = 0 ; 
	my $cnt =0 ; 
	while(@list){
		$cnt++ ;
	    my $x = shift @list ;
	    my $y = shift @list ;
		$totY = $totY + $y ;
		$totX = $totX + $x ;
	}
	croak if(!$cnt);
	my $averX = $totX/$cnt ;
	my $averY = $totY/$cnt ;
	return ($averX,$averY);
	
}
sub ProcessShells{
	my ($self,$ofhcsv,$infile,$outfile,$display,$redcolor,$bluecolor,@shells) = @_ ; 
	@colors = qw ( yellow green magenta blue aqua);
	my $info = {};
	my $cnt = 0; 
	while(@shells){
		my $shell = shift @shells ;
		$info->{$cnt}->{blue} = $info->{$cnt}->{red} =  $info->{$cnt}->{other} = 0  ;
		my $colornm = shift @colors ;
	     my @p = @{$shell};	
		 while(@{p}){
			my $x  = shift @p;
			my $y  = shift @p;

			my @pixel = $self->GetPixel($x,$y);
			my ($v,$name) = $self->IsSingleColor(@pixel);
			if($v && $name eq "blue" ){
			    $self->SetColorToPixelByColorName($x,$y,$colornm);
			    $info->{$cnt}->{blue} = $info->{$cnt}->{blue} + 1 ;  
			}
			elsif($v && $name eq "red"){
			    $info->{$cnt}->{red} = $info->{$cnt}->{red} + 1 ;  
			}
			else{
				if(@shells){
			         $info->{$cnt}->{other} = $info->{$cnt}->{other} + 1 ;  
				}
			}
		}
		if(!@shells){
		       $info->{$cnt}->{blue} = $info->{$cnt}->{blue} + $bluecolor ;
		       $info->{$cnt}->{red} = $info->{$cnt}->{red} + $redcolor ;
			   print "Adding b $bluecolor and r $redcolor \n";
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

    $self->Write($outfile,$display);
}

sub GetCoord2Str{
	my ($self,$x,$y) = @_ ; 
	my $str = "$x,$y";
	return $str ;
}

sub GetAllPoints{
	my ($self,$listF,$listR) = @_ ; 
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
	my @allpointstemp = @allpoints  ;
	my $insidetable = {};
	while(@allpointstemp){
			my $x = shift @allpointstemp ;
			my $y = shift @allpointstemp ;
		   my $str = $self->GetCoord2Str($x,$y);
		   $insidetable->{$str} = 1 ;
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

    #$image->SetColorToPixelByColorName($midX,$midY,"red");

    #$image->SetColorToPixelByColorName($CminX,$CminY,"red");
    #$image->SetColorToPixelByColorName($CmaxX,$CmaxY,"red");
	return ($minX,$minY,$maxY,$maxX,$CminX,$CminY,$CmaxY,$CmaxX,$midX,$midY,$AREACALCBYPIXEL,$insidetable,@allpoints);
}
