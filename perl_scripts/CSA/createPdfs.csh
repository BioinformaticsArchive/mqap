#!/bin/csh -f

if($#argv != 4  ) then 
   "Usage : "
  exit 
endif 

set PWD = ` pwd`
set ref = $PWD/$1
set listquery = $PWD/$2
set dir = $PWD/$3
set tag = $4

set dirscores = $PWD/SCORES.ALL/

exit ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


cd $dirscores
\rm -f $dirscores/dataset.pdf $dir/dataset.$1.pdf

set tex = INPUT.tex
\rm -f $tex
touch $tex

foreach query ( ` cat $listquery` )
   echo \\input\{$query.$tag.sorted.annotated\} >> $tex 
end

$SRC/CSA/reorderInputTex.pl -out oo -lis $tex
mv -f oo $tex

echo Generating pdf 
./do.sh > & ! /dev/null

mv $dirscores/dataset.pdf $dir/dataset.$1.pdf
evince $dir/dataset.$1.pdf


cd $PWD
