#!/bin/csh -fv

cd /home/sandeepc/Bio/Code
TARBACKUP perl_scripts 
sleep 60 

cd /home/sandeepc/Bio/Data 
TARBACKUP Paper
sleep 600


cd 
TARBACKUP Documents 
sleep 600


cd 
TARBACKUP DATA
sleep 600

