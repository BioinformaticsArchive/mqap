#!/bin/csh -fv

if($#argv != 1  ) then 
  echo "Usage : "
  exit 
endif 

set BACKUP=$1 

mkdir $BACKUP
mkdir $BACKUP/DOTFILES
mkdir $BACKUP/HOMEFILES

\cp $HOME/.* $BACKUP/DOTFILES
\cp $HOME/* $BACKUP/HOMEFILES

cd /home/sandeepc/Bio/Code
TARBACKUP perl_scripts 
sleep 120 

cd /home/sandeepc/Bio/Data 
TARBACKUP Paper 
sleep 300 


cd 
TARBACKUP Documents 
sleep 300 

TARBACKUP DATA 

ls $PDBDIR/*pdb > ! $BACKUP/list.pdb
ls $APBSDIR > ! $BACKUP/list.apbsdir




