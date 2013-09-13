#!/usr/bin/perl -w 

use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;

use MyUtils;
use MyQPaper;
use POSIX qw(floor);

my $commandline = util_get_cmdline("",\@ARGV) ;

my ($easy, $nodecimals, $infile,$subset,$qpaper,$howmany,$design,$multiple,$answer,$clocked);
$howmany = 0 ;
$multiple = 1 ;
GetOptions(
            "howmany=s"=>\$howmany ,
            "infile=s"=>\$infile ,
            "clocked:s"=>\$clocked ,
            "design=s"=>\$design ,
            "answer=s"=>\$answer ,
            "multiple=i"=>\$multiple ,
            "subset=i"=>\$subset ,
            "nodecimals"=>\$nodecimals ,
            "easy"=>\$easy ,
            "qpaper=s"=>\$qpaper );

die "Dont recognize command line arg @ARGV " if(@ARGV);

usage( "Need to give a infile, => option -infile ") if(!defined $infile);

my $id = floor(100000*rand());
$qpaper = "qpaper.$id";
$answer = "answer.$id";
while(-e $qpaper){
   $id = floor(100000*rand());
   $qpaper = "qpaper.$id";
   $answer = "answer.$id";
}

my @PLACES = qw( house bridge road garden );
my @PPL = qw(boys girls men women);
my @THINGS = qw( oranges apples mangoes books );
my @alpha = qw( a b c d e f g h i j k l m n o p q r s t u v w x y z );
my @names = qw( Ravi Rishi Sanjay Amit Pooja Ritu Amrita Amba Shalini);

my $ofh = util_write($qpaper);
my $answerfh = util_write($answer);
print STDERR "Writing qpaper file $qpaper and answers in $answer\n";

sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}

my @qtypes = util_read_list_words($infile);
if(defined $subset){
my $SMALL = util_pick_n_random_from_list(\@qtypes,$subset);
@qtypes = @{$SMALL};
}

while($multiple){
    my $cnt = 0 ;
    #print $ofh      " QUESTIONS id=$id  $multiple \\\\\n";
    #print $ofh      " ================================ \\\\\n";

    print $ofh      "\\section{Question set}\n";
    #print $ofh      " ================================ \\\\\n";

    print $answerfh " ANSWERS id=$id $multiple \\\\\n";
    print $answerfh      " ================================ \\\\\n";
    
    $multiple--;

    foreach my $iii (0..$howmany){
        foreach my $qtype (@qtypes){
            $cnt++;
            my ($q,$a) ;
		    my $sub = \&{$qtype}; 
		    ($q,$a) = $sub->();
            print $ofh      " $cnt ) {\\bf $q}\\\\ \n";
            print $answerfh " $cnt ) {\\bf $a}\\\\ \n";
        }
    }
}

sub ADD{
    my ($div) = @_ ;
    my $n1 = defined $easy ? 100 : 10000 ;
    my $n2 = defined $easy ? 10 : 100.0  ;

    $n2 = 1 if(defined $nodecimals);
    my ($p,$q);
   
    while(!($p = floor($n1*rand())/$n2)){}
    while(!($q = floor($n1*rand())/$n2)){}
 
    my $addorsub = 1 * rand() > 0.5 ? 0 : 1 ; 
    
    my $a = $addorsub ? $p + $q : $p - $q  ;
    my $oper = $addorsub ? " + " :  " - "  ;
    my $answer = "$p $oper $q\ = $a";
    my $question = "$p $oper $q\ = ? ";
    ($question,$answer);
}

sub ADDMULTIPLE{
    my ($div) = @_ ;
	my $sum = 0 ; 
	my $str = "";
	while($sum >= 0){
		$sum = 0 ; 
		$str = "";
        my $n1 = 5 ; 
        while($n1){
           my $celprob = util_round(rand());
           my $p = floor(20*rand()) + 1 ; 
	       $str = $celprob ? "$str + $p " : "$str - $p"; # do this first
	       $p = $celprob ? $p : $p * (-1) ; 
	       $sum = $sum + $p ;
	       $n1--;
	    }
	}
    my $answer = "$str = $sum";
    my $question = "Find the sum of: $str  ";
    ($question,$answer);
}

sub DIV{
	return MULT(1);
}

sub MULT{
    my ($div) = @_ ;
    my $n1 = defined $easy ? 100 : 10000 ;
    my $n2 = defined $easy ? 10 : 100.0  ;
    if(defined $div){
        $nodecimals = 1 ;
         $n1 = defined $easy ? 20 : 100 ; 
         $n2 = defined $easy ? 10.0 : 10.0;
    }

    $n2 = 1 if(defined $nodecimals);
    my ($p,$q);
   
    while(!($p = floor($n1*rand())/$n2)){}
    while(!($q = floor($n1*rand())/$n2)){}
    
    my $a = $p * $q ;
    my $oper = " X " ;
    if(defined $div){
         $oper = " / " ;
         my $t = $a ; 
         $a = $p ; 
         $p = $t ; 
    }
    my $answer = "$p $oper $q\ = $a";
    my $question = "$p $oper $q\ = ? ";
    undef $nodecimals ;
    ($question,$answer);
}

sub TEMPERATURE{
    my $n1 = 1000 ;
    my $cel = floor($n1*rand());
    my $fahren = (9*$cel)/5 + 32 ; 
    
    my $celprob = util_round(rand());
    if($celprob){
        return "$cel degree C = ? degree F" , " $cel degree C = $fahren F";
    }
    else {
        return "$fahren degree F = ? degree C" , " $fahren degree F = $cel C";
    }
}


sub FRACTIONS{
    my $n1 = 20 ;
	my ($a,$b,$c,$d) = QP_GetNRandomNumbersBelowValue(4,$n1);
    my $answer = ($a/$b + $c/$d) ; 
    $answer = QP_round2place($answer);
    my $q = $a . "/" . $b . "+" . $c . "/" . $d ; 
    return " $q ", " $q = $answer";
}

sub ASCDESC{
    my $n1 = 15 ;
	my ($a,$b,$c,$d,$e,$f) = QP_GetNRandomNumbersBelowValue(6,$n1);

    my $p = $a . "/" . $b  ;
    my $q = $c . "/" . $d  ;
    my $r = $e . "/" . $f  ;
 
    my $x = QP_round2place($a/$b * 1.00);
    my $y = QP_round2place($c/$d * 1.00);
    my $z = QP_round2place($e/$f * 1.00);
    if($x > $y ){
        ($x,$y) = ($y,$x) ;
        ($p,$q) = ($q,$p) ;
    }
    if($y > $z ){
        ($y,$z) = ($z,$y) ;
        ($q,$r) = ($r,$q) ;
    }
   
    my $celprob = util_round(rand());
    my $answer = $celprob ?  " $p $q $r " : " $r $q $p";
    my $what = $celprob ? " ascending " : " descending ";
    my $question = $a . "/" . $b . " , " . $c . "/" . $d . " , " . $e . "/" . $f  ; 
    return " Arrange in $what order $question ", " $answer";
}

sub CIRCLE{
    my $n1 = 9 ;
    my $r = (floor($n1*rand()) + 1)*7;
    my $a = 3.14 * $r * $r ;
    my $c = 3.14 * 2 * $r ;
    return " Radius of a circle is $r cm. Find its area and circumference" , 
	       "Area = $a sq cm , Circumference = $c cm";
}


sub UNITARYWORK{
    my $n1 = 15 ;
    my $n2 = 15 ;
    my ($days,$boys) =  QP_GetNRandomNumbersBelowValue(2,15);
    my ($X1,$X2) =  QP_GetNRandomNumbersBelowValue(2,10);
    my $days1 = $days * ($X1+1);
    my $boys1 =  $boys * ($X2+1);

	my $WHOM = util_pick_random_from_list(\@PPL);
    my $what = util_pick_random_from_list(\@PLACES);
    
    
    my $celprob = util_round(rand());
    if($celprob){
        my $q = "$boys $WHOM can build a $what in $days days. How many days will $boys1 $WHOM build it?"; 
        my $a = QP_round2place(($boys*$days)/$boys1);
        return $q , "$q = $a";
    }
    else {
        my $q = "$boys $WHOM can build a $what in $days days. How many $WHOM will make it in $days1 days ?"; 
        my $a = QP_round2place(($boys*$days)/$days1);
        return $q , "$q = $a";
    }
}

sub UNITARYCOST{
    my ($cost,$num) =  QP_GetNRandomNumbersBelowValue(2,15);
    my ($X1,$X2) =  QP_GetNRandomNumbersBelowValue(2,10);
    my $cost1 = $cost* ($X1+1);
    my $num1 =  $num * ($X2+1);

    my $what = util_pick_random_from_list(\@THINGS);
    
    
    my $celprob = util_round(rand());
    if($celprob){
        my $q = "$num $what costs Rs $cost . What is the cost of $num1 $what?";
        my $a = QP_round2place(($cost/$num)*$num1);
        return $q , "$q = $a";
    }
    else {
        my $q = "$num $what costs Rs $cost . How many $what can you buy for Rs $cost1?";
        my $a = QP_round2place(($num/$cost)*$cost1);
        return $q , "$q = $a";
    }
}

sub SQUAREROOTIRRATIONAL{


    my ($num,$num1) =  QP_GetNRandomNumbersBelowValue(2,10);
	my $sum = $num + $num1 ; 
	my $prod  = 4* $num * $num1 ; 
    
    my $celprob = util_round(rand());
    if($celprob){
        my $q = "Find the square root of $sum + sqrt($prod)";
        my $a = "sqrt($num) + sqrt($num1)";
        return $q , "$q = $a";
    }
    else {
        my $q = "Find the square root of $sum - sqrt($prod)";
        my $a = "sqrt($num) - sqrt($num1), or sqrt($num1) - sqrt($num)";
        return $q , "$q = $a";
    }
	
}


sub SUMOFSQUARES{
    my ($n1,$n2) =  QP_GetNRandomNumbersBelowValue(2,10);
	my $square1 = $n1 *$n1 ; 
	my $square2 = $n2 *$n2 ; 
	my $sum = $square1 + $square2 ;


    my $q = "Express $sum as the sum of two squares";
    my $a = "$n1 x $n1 + $n2 x $n2 " ;
    return $q , "$q = $a";
	
}



sub MULTEXPR{
    my @l1 ; 
    my @l2 ; 
    my @l ; 
    
    push @l1 , genTerm("a");
    push @l1 , genTerm("b");
    
    push @l2 , genTerm("a");
    push @l2 , genTerm("b");
    
    push @l , \@l1 ;
    push @l , \@l2;
    
    my $q = printExpr(@l);
    my $a = multExpr(@l);
    return "multiply $q" , "$q = $a";
}
sub FACTOREXPR{
    my @l1 ; 
    my @l2 ; 
    my @l ; 
    
    push @l1 , genTerm("a");
    push @l1 , genTerm("b");
    
    push @l2 , genTerm("a");
    push @l2 , genTerm("b");
    
    push @l , \@l1 ;
    push @l , \@l2;
    
    my $a = printExpr(@l);
    my $q = multExpr(@l);
    return "Factorise $q" , "$q = $a";
}

sub genTerm{
	my ($a) = @_ ; 
    my $celprob = util_round(rand());
    my $n1 =  floor(5*rand())+1;
	my @term ; 
	if($celprob){
		 push @term , "+";
		 push @term , $n1 ; 
		 push @term , $a ; 
	}
	else{
		 push @term , "-";
		 push @term , $n1 ; 
		 push @term , $a ; 
	}
	return \@term ; 
}

sub printExpr{
	my (@l) = @_ ; 
	my $finalexpr = "";
	foreach my $l (@l){
		my @exprs = @{$l} ; 
        my $expr = "( ";
		foreach my $e (@exprs){
		    my $term = join "",  @{$e};
			$expr = $expr . $term ; 
		}
		$expr = $expr . ") " ; 
		$finalexpr = $finalexpr . $expr ; 
	}
	return $finalexpr ;
}

sub multExpr{
	my (@l) = @_ ; 
	my $l1 = shift (@l);
	my @exprs1 = @{$l1} ; 
	my $l2 = shift (@l);
	my @exprs2 = @{$l2} ; 

    my $finalexpr = "";
	my $done = {};
	foreach my $e1 (@exprs1){
	    my ($sign1, $coeff1, $nm1) = @{$e1};
		
	    foreach my $e2 (@exprs2){
			 my ($sign2, $coeff2, $nm2) = @{$e2};
			 my $SIGN = $sign1 eq $sign2 ? "+" : "-";
			 my $COEFF = $coeff1 * $coeff2 ;
			 my $NM =  $nm1 lt $nm2 ? $nm1 . $nm2 :$nm2 . $nm1  ; 
			 $done->{$NM} = 0 if(!defined $done->{$NM});

			 $done->{$NM} = $sign1 eq $sign2 ?  $COEFF + $done->{$NM} : - $COEFF + $done->{$NM}  ; 
		}
	}
	foreach my $k (keys %{$done}){
		my $v = $done->{$k} ;
		my $expr = "$v$k" ;
		$expr = "+" . $expr if(!($expr =~ /^\s*-/));
		$finalexpr = $finalexpr . " " .  $expr ; 
	}
	return $finalexpr ;
}


sub DENSITY{
    my ($n1,$n2,$n3,$n4) =  QP_GetNRandomNumbersBelowValue(4,20);
    my $q = "The volume of $n1 Kg of material M1 is $n2 litres, and the volume of $n3 KG of material M2 is $n4 litres. Which material is heavier?";
	my $heavier = $n1/$n2 > $n3/$n4 ? "M1" : "M2";
    my $a = $heavier ; 
    return $q , "$q = $a";
}


sub MOLE{
    my ($n1,$n2) =  QP_GetNRandomNumbersBelowValue(2,30);
    my $q = "The molecular mass of a compound C is $n1. How many atoms are there in $n2 grams of the compound?";
	my $a = "$n2/$n1 * 6.023 * \$10^{23}\$" ;
    return $q , "$q = $a";
}

sub ATOMICNUMBER{
    my ($n1,$n2) =  QP_GetNRandomNumbersBelowValueSorted(2,30);
    my $q = "The atomic number of an element E is $n1, and its mass number is $n2. How many neutrons does the element have?";
	my $a = $n2 - $n1 ;
    return $q , "$q = $a";
}

sub SET_INTERSECTION{
	my $U = util_pick_n_random_from_list(\@alpha,10);
	my $A = util_pick_n_random_from_list($U,5);
	my $B = util_pick_n_random_from_list($U,6);

	my $strU = join ", ", @{$U};
	my $strA = join ", ", @{$A};
	my $strB = join ", ",  @{$B};

    my $celprob = util_round(rand());
	my $what ; 
	my $strC ; 
    if($celprob){
		$what = "intersection";
	    my $tabA = util_make_table($A);
	    my @intersection = ();
	    foreach my $p (@{$B}){
	      push @intersection,$p if(exists $tabA->{$p});	
	    }
	    $strC = join",",  @intersection ;
	}
	else{
		$what = "union";
	    my $tabA = util_make_table($A);
	    foreach my $p (@{$B}){
	      $tabA->{$p} = 1 ;
	    }
	    my @intersection = (keys %{$tabA});
	    $strC = join",",  @intersection ;
	}

    my $q = "Universal set = ( $strU ) set A = ( $strA ), set B = ( $strB ) . Find A $what B by drawing venn diagrams";
	my $a = " ( $strC ) " ;
    return $q , "$q = $a";

}

sub EQN_MONEY{
	my ($nm1,$nm2) = @{util_pick_n_random_from_list(\@names,2)} ; 

    my ($M1,$M2)         =  QP_GetNRandomNumbersBelowValue(2,15);
    my ($n1,$n2,$n3,$n4) =  QP_GetNRandomNumbersBelowValue(4,15);

	my $V1 = $n1 * $M1 ; 
	my $V2 = $n2 * $M2 ; 
	my $S1 = $V1 + $V2 ; 

	my $V3 = $n3 * $M1 ; 
	my $V4 = $n4 * $M2 ; 
	my $S2 = $V3 + $V4 ; 

    my $q = "$nm1 and $nm2 have some money. If you multiply $nm1 's money by $n1 and $nm2 's money by $n2 and add them up, you get Rs $S1. If you multiply $nm1 's money by $n3 and $nm2 's money by $n4 and add them up, you get Rs $S2. How much money does each person have? " ;
 
	my $a = "$nm1 = $M1, $nm2 = $M2";
    return $q , "$q = $a";

}

sub FACTOREXPR_CUBE{
	my ($nm1,$nm2) = @{util_pick_n_random_from_list(\@alpha,2)} ; 

    my ($M1,$M2)         =  QP_GetNRandomNumbersBelowValue(2,6);
	
	my $cube1 = $M1 * $M1 * $M1 ;
	my $cube2 = $M2 * $M2 * $M2 ;

	my $sq1 = $M1 * $M1 ;
	my $sq2 = $M2 * $M2 ;


	print "$nm1*$nm2 $M1 $M2\n";

    my $random = util_round(rand()) ;
    my $celprob = $random ? "-" : "+";
    my $celprobNot = $random ? "+" : "-";
    my $q = "Factorize \$ ${cube1}$nm1\^\{3\} $celprob ${cube2}$nm2\^\{3\} \$\n";
 
 	my $MULT = $M1 * $M2 ; 
	my $a = "\$ (${M1}$nm1 $celprobNot ${M2}$nm2) (${sq1}$nm1\^\{2\} $celprob ${MULT}${nm1}$nm2 + ${sq2}$nm2\^\{2\}) \$  ";
    return $q , "$q = $a";

}
