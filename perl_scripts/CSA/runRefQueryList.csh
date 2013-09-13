#!/bin/csh -f

if($#argv != 5  ) then 
  echo "Usage : "
  exit 
endif 

set PWD = ` pwd`
set listref = $PWD/$1
set listquery = $PWD/$2
set dir = $PWD/$3
set anndir = $PWD/$4
set close2activesite = $5

mkdir -p $dir

foreach ref ( ` cat $listref` )
  mkdir -p $dir/$ref 	
  cd $dir/$ref 	
  cp -r  $anndir/$ref.outconf.annotated . 
  #if( ! -e $ref.pdb.out  || -z $ref.pdb.out ) then 

  if(-e $CACHEPDB/$ref/$ref.outconf.annotated) then 
  	 #diff $ref.outconf.annotated $CACHEPDB/$ref/$ref.outconf.annotated
     #if($status == 0) then 
	 	echo "====================================================="
	 	echo "Copying PDB  $CACHEPDB/$ref/$ref.pdb.out since the annotated files are the same "
		head -4  $CACHEPDB/$ref/$ref.pdb.out
	 	echo "====================================================="
	 	cp $CACHEPDB/$ref/$ref.pdb.out $dir/$ref/
	 #endif 
  endif 



  if( ! -e $ref.pdb.out   ) then 

echo "Making rr $ref"
      echo \#\!/bin/csh \-f > ! $PWD/sandeep.1
      echo $SRC/3DMatch -annd $anndir -outf $dir/$ref/$ref.pdb.out -pdb $ref -inc $anndir/$ref.outconf.annotated -fin -close2activesite $close2activesite >> $PWD/sandeep.1
      #bsub < $PWD/sandeep  > & /dev/null 
	  source $PWD/sandeep.1
  endif 

  foreach query ( ` cat $listquery` )
  #if( ! -e $query.pdb.out  || -z $query.pdb.out ) then 
       if( ! -e $query.pdb.out   ) then 
            echo $ref $query 
           echo \#\!/bin/csh \-f > ! $PWD/sandeep.1
           echo $SRC/3DMatch -annd $anndir -outf $dir/$ref/$query.pdb.out -pdb $query -inc $anndir/$ref.outconf.annotated -fin -close2activesite $close2activesite >> $PWD/sandeep.1
           #bsub < $PWD/sandeep  > & /dev/null 
	       source $PWD/sandeep.1
  endif 


  end
  cd $PWD 
end

