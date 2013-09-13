#!/bin/csh -f

if($#argv != 3  ) then 
  echo "Usage : prog useer mempercent "
  exit 
endif 

set PWD = ` pwd`
set prog = $1
set User = $2
set Val = $3


while (1)

top -b -n 1 -u $User | grep $prog | perl -ne ' @l = split ; print "$l[0] $l[9] \n"; if (int($l[9]) >= 70) { `kill -9 $l[0] `; print "killing kill -9 $l[0] as $l[9] \n" ;} '

sleep 60 
end
