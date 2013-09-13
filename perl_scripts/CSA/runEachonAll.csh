#!/bin/csh -f

if($#argv != 2  ) then 
  echo "Usage : "
  exit 
endif 

set PWD = ` pwd`
set list = $1
set anndir = $2



foreach ref ( ` cat $list` )
	echo $ref > ! list.$ref

	runOneonAll.csh  list.$ref $list RESULTS.$ref  EXTRACT.$ref $anndir $ref

	#runRefQueryList.csh list.$ref $list RESULTS.$ref $anndir
	#extractRefQuertList.csh list.$ref $list EXTRACT.$ref RESULTS.$ref
	#source run.csh
	#generateScoresForSingleRef.csh $ref  EXTRACT.$ref
end

