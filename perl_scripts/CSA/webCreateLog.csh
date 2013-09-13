#!/bin/csh -f

if($#argv != 6  ) then 
  echo "Usage : "
  exit 
endif 

set PWD = ` pwd`
set listref = $1
set listquery = $2
set results = $3
set extract = $4
set anndir = $5
set scores = $6




foreach query ( ` cat $listquery` )
    foreach ref ( ` cat $listref` )
        webCreateLogForOne.csh $ref $query $3 $4 $5 $6 
    end
end
