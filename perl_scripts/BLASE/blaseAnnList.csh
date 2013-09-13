#!/bin/csh -f

if($#argv != 1  ) then 
  echo "Usage : "
  exit 
endif 

set list=$1


foreach i ( A C D PBP ST)
	set listref=list.$i 
    foreach ref ( ` cat $listref` )
		echo $ref $i >> list.ann 
    end
end

#makepdblistonly.pl -in list.ann -out list.blase
\cp -f $list list.blase
