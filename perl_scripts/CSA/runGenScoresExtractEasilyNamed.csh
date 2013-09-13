#!/bin/csh -f

if($#argv != 5  ) then 
  echo "Usage : "
  exit 
endif 

set PWD = ` pwd`
set listref = $1
set listquery = $2
set tag = $3
set promfile = $4
set dist = $5
set annotate = ANNOTATE
set results = Results.$listref.$listquery
set extract = Extract.$listref.$listquery


echo " =================== Running $SRC/CSA/generateScores.csh - will generate results for each Query =================== "
$SRC/CSA/generateScores.csh $1 $2 $extract $tag $promfile $dist


echo " =================== Running $SRC/CSA/generateScoresForSingleRef.csh for each Reference =================== "
foreach ref ( ` cat $listref` )
    $SRC/CSA/generateScoresForSingleRef.csh  $ref $extract SCORES.ALL $1 $2 
	if($status != 0) then
	    echo $SRC/CSA/generateScoresForSingleRef.csh failed
		exit 1
	endif
end
