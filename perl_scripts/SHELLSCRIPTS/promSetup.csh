#!/bin/csh -f

if($#argv != 2  ) then 
  echo "Usage : "
  exit 
endif 

set PWD = ` pwd`
set listref = $PWD/$1
set anndir = $2


foreach i ( 1 2 3 4 6 7 8 9 10 11 12 13 14 15 )
   set fastadir = ANNOTATE.$i
   #cp -r $anndir $fastadir 
   $SRC/CSA/createClosetoAnnotate.pl $listref $fastadir 
   $SRC/SHELLSCRIPTS/peptideInfoFromFasta.csh $listref $fastadir

end

