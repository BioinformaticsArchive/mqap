
package MyWeb;
use Carp ;
use POSIX ;
require Exporter;
use Algorithm::Combinatorics qw(combinations) ;
use Math::NumberCruncher;
use Math::MatrixReal;  # Not required for pure vector math as above
use Math::Geometry ; 
#use Math::Trig;
#use Math::Trig ':radial';
no warnings 'redefine';
my $EPSILON = 0.01;

  local $SIG{__WARN__} = sub {};

@ISA = qw(Exporter);
@EXPORT = qw( 
web_printTableRow
web_printTableSingleLine
web_printTableHeader
web_printTableHead
web_printTableEnd
web_printHtmlHead
web_printHtmlEnd
web_makeLink
	    );

use strict ;
use FileHandle ;
use Getopt::Long;


my $verbose = 0 ;
my $havetokeepthispostive = 13 ;

sub web_printTableRow{
	my ($ofh,@l) = @_ ; 
	my $first = 1 ;
	print $ofh "\n\n\n";
    print $ofh "<tr> \n";
	foreach my $l (@l){
	    web_printTableSingleLine($ofh,$l,$first);
	    $first = 0  ;
     }  
	print $ofh "</tr>\n";
}
	


sub web_printTableSingleLine{
	my ($ofh,$str,$first) = @_; 
	if($first){
	     print $ofh "<th scope=\"row\" class=\"spec\">$str</th>\n";
	}
	else{
	     print $ofh "<td>$str</td>\n" ;
	}
}



sub web_printTableHeader{
	my ($ofh,@tableheaders) = @_ ; 
    print $ofh "<tr> \n";
	foreach my $str (@tableheaders){
	    print $ofh "<th scope=\"col\"  class=\"nobg\">$str</th>\n";
	}
	print $ofh "</tr>\n";
}


sub web_printTableHead{
	my ($ofh,$caption,$summary,$tableid) = @_ ;
     print $ofh " \n";
    print $ofh "<div id=\"body\"> \n";
     print $ofh " \n";
    print $ofh "<table id=\"$tableid\" cellspacing=\"0\" summary=\"$summary\"> \n";
    print $ofh "<caption>$caption</caption> \n";
}


sub web_printTableEnd{
	my ($ofh) = @_ ; 
    print $ofh "</div> \n";
    print $ofh "</div> \n";
    print $ofh "</body> \n";
}

sub web_printHtmlHead{
	my ($ofh,$title) = @_ ; 
    print $ofh "<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\" lang=\"en\"> \n";
     print $ofh "<head> \n";
    print $ofh "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\"/> \n";
     print $ofh " \n";
    print $ofh "<title>$title</title> \n";
    print $ofh "<link rel=\"stylesheet\" href=\"style.css\" type=\"text/css\" charset=\"utf-8\" /> \n";
    print $ofh " \n";
     print $ofh "</head> \n";
     print $ofh "<body> \n";
}

sub web_printHtmlEnd{
	my ($ofh) = @_ ; 
    print $ofh "</html> \n";
}


sub web_makeLink{
    my ($nm,$link,$isdummy) = @_ ;
	return $nm if(defined $isdummy && $isdummy eq 1);
	return  "<a href=\"$link\"> $nm</a>";
}

