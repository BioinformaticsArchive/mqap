#!/bin/csh -f

if($#argv != 1  ) then 
  echo "Usage : "
  exit 
endif 

set dirscores = $1

mkdir -p $dirscores
cd $dirscores
ln -s ~/DATA/SCORES.ALL/*  . > & ! /dev/null 
cd -



