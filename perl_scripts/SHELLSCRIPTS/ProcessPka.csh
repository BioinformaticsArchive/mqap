#!/bin/bash

# Assumes APBS 0.5.0


epsp=20
kT=2.5

G1=`grep Global \$1.CHAN.pdb.pqr.out | awk '{print $6}'`
G2=`grep Global \$1.CHAN.pdb.nocharge.pqr.out | awk '{print $6}'`
G3=`grep Global NUM.\$1.CHAN.pdb.pqr.out | awk '{print $6}'`
echo $G1 $G2 $G3

dG_xfer_ASH66=`python -c "print ($G1 - $G2 - $G3)"`

G1=`grep Global $1.ORIG.pdb.pqr.out  | awk '{print $6}'`
G2=`grep Global $1.ORIG.pdb.nocharge.pqr.out | awk '{print $6}'`
G3=`grep Global NUM.\$1.ORIG.pdb.pqr.out | awk '{print $6}'`
#G3=105.5272184983;
echo $G1 $G2 $G3



dG_xfer_ASP66=`python -c "print ($G1 - $G2 - $G3)"`

echo "##########################################"
echo "Calculating the transfer free energy difference..."
ddG_xfer=`python -c "print ($dG_xfer_ASP66 - $dG_xfer_ASH66)"`
echo "Transfer free energy difference FROM TOTAL ENERGY = $ddG_xfer"

echo "##########################################"
echo "Calculating the pKa shift..."
dpKa=`python -c "print (${ddG_xfer}/${kT}/2.303)"`
echo "pKa shift FROM TOTAL ENERGY = $dpKa"

