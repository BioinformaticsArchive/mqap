#!/bin/csh

if($#argv != 3  ) then 
  echo "Usage : "
  exit 
endif 

set PWD = ` pwd`
set top = $PWD/$1
set listnumber = $PWD/$2
set listpdbs = $3

set pdb = ` cat $top` 
echo "Working for pdb $pdb"

foreach ref ( ` cat $listnumber` )

	if(! -e $ref.run/top) then 
        createCLASPinput.csh $pdb $ref.in 3 
	    mkdir -p $ref.run/ANNOTATE
	    \cp -f $pdb.* $ref.run/ANNOTATE 
    
	    \cp -f $listpdbs $ref.run/
	    \cp -f $ref.not $ref.run/
	    \cp -f top $ref.run/
	endif 
end

foreach ref ( ` cat $listnumber` )
	cd $ref.run/
	$SRC/CSA/runRefExtractEasilyNamed.csh top $listpdbs

	cd Extract.top.list.all

	if(! -e list.ordered.scores) then 
	    getbestmatchesforsingleref.csh $pdb list.query
	endif 

    foreach PPP ( ` cat ../$listpdbs` )
		if(-e $PPP) then 
		    cd $PPP
			if(! -e oo) then
		            #addResiduestoPymolIn.pl -out pymol.in.new -in pymol.in -lis ../../*not -p 1B0F
		            #alignProteins.pl -out oo -in pymol.in.new -p2 $PPP -p1 $pdb  -decaaf 2
			endif
		    cd - 
		endif 
	end 


	cd $PWD
end

ff list.ordered.scores > ! list.list.ordered.scores
