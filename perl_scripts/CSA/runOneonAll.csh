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
set protein = $6



runRefQueryList.csh $listref $listquery $results $anndir
extractRefQuertList.csh $listref $listquery $extract $results
source run.csh
generateScoresForSingleRef.csh $protein  $extract
