#!/bin/csh -f

if($#argv != 2 ) then 
  echo "Usage : list homologouspercent "
  exit 
endif 

set list = $1
set howmuch = $2

processEC.pl -lis $list -out ooo -how 20
cat EC1  EC2  EC3  EC4  EC5  EC6 > ! ALL
wc -l ALL 
sleep 2
foreach i ( EC1  EC2  EC3  EC4  EC5  EC6)
    checkIdentity.pl -out $i.$howmuch -list $i -simi $howmuch
end

