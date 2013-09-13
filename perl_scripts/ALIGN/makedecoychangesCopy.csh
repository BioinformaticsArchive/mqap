#!/bin/csh -f


foreach i ( ` cat list` )
	cd $i 

    foreach j ( ` cat list` )
		\cp -f $PDBDIR/$j.pdb ~/PBDDIRDECOY 
		if(! -e ~/APBSDECOY/$j) then 
			mv $APBSDIR/$j ~/APBSDECOY/
		endif 
    end

  cd - 
end

