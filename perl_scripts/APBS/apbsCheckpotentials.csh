
if($#argv != 2  ) then
  echo "Usage : "
    exit
endif

set PWD = ` pwd`
set listref = $PWD/$1

foreach $i ( ` cat $1` )
    $SRC//APBS/apbsGetVolt.pl -howmany 1 -resultfile $2/$i/$i.pdb.out -proteinName $i -pqr $APBSDIR//$i/$i.pqr -out $i.potentials -pot $APBSDIR/$i/pot1.dx.atompot -dis dis.ref
end
