#!/bin/csh -f

if($#argv != 5  ) then 
  echo "Usage : "
  exit 
endif 

set PWD = ` pwd`
set listref = $1
set listquery = $2
set resdir = $3
set extractdir = $4
set anndir = $5


runRefQueryList.csh  $listref $listquery $resdir $anndir
extractRefQuertList.csh  $listref $listquery $extractdir $resdir 
generateScores.csh $listref $listquery $extractdir

