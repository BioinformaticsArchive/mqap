#!/bin/csh -f
alias sp 'set path = ( \!* $path )'

setenv BIOPERLHOME /home/sandeepc/Bio/Code/perl_scripts/perl_scripts/
setenv PRISM $BIOPERLHOME/PRISM

setenv PDB2PQR /home/sandeepc/pdb2pqr/
setenv PDBDIR /home/data/pdbs/
setenv APBSDIR  /home/data/apbs/

setenv PDBDIRDECOY /home/data/pdbsdecoy/
setenv APBSDIRDECOY  /home/data/apbsdecoy/

setenv UNIPROT  /home/data/uniprot/
setenv FASTADIR /home/data/FASTADIR/
setenv CONFIGGRP /home/sandeepc/DATA/data/config.grp 
setenv MAPPINGFILE /home/sandeepc/DATA/data/mapping.txt

setenv ANNDIR  $SRC
setenv CACHEPDB  $SRC
setenv FPOCKET  $SRC
setenv MATCH3D  $SRC
setenv RESULTDIR  $SRC



sp $BIOPERLHOME
sp $BIOPERLHOME/APBS
sp $BIOPERLHOME/DELPHI
sp $BIOPERLHOME/EXTERNALTOOLS
sp $BIOPERLHOME/SHELLSCRIPTS
sp $BIOPERLHOME/BIOPERL
sp $BIOPERLHOME/PDBSEQRES
sp $BIOPERLHOME/MISC
sp $BIOPERLHOME/ALIGN
sp $BIOPERLHOME/CSA
sp $BIOPERLHOME/WEB
sp $BIOPERLHOME/IMAGE
sp $BIOPERLHOME/PRIMER
sp $BIOPERLHOME/DECAAF
sp $BIOPERLHOME/BLASE
sp $BIOPERLHOME/NAMD
sp $BIOPERLHOME/FRAGALWEB
sp $PRISM
setenv PERLLIB "/home/sandeepc/Bio/Code/perl_scripts/perl_scripts/PRISM:$BIOPERLHOME/PRIMER/:$PERLLIB"



sp /home/sandeepc/DownloadedTools/apbs/
# for multivalue - 
sp /home/sandeepc/DownloadedTools/apbs/apbs-1.2.1-source/tools/mesh/
# for pdb2pqr.py
sp /home/sandeepc/pdb2pqr
