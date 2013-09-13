#!/bin/csh -f

if($#argv != 1  ) then 
  echo "Usage : "
  exit 
endif 

set image=`cat ref.txt`

ls *tif > ! list.tif

newfile.csh list.png
foreach i (`cat list.tif`)
	convert $i $i.png
	echo $i.png >> list.png
end

$SRC/IMAGE/3Dfilterimages.pl -lis list.png -out list

