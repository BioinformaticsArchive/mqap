#!/bin/csh -f

if($#argv != 4  ) then 
  echo "Usage : "
  exit 
endif 

set PWD = ` pwd`
set listref = $PWD/$1
set listquery = $PWD/$2
set dir = $PWD/$3
set resultsdir = $PWD/$4

set runfile = $PWD/run.csh

mkdir -p $dir


foreach query ( ` cat $listquery` )

  foreach ref ( ` cat $listref` )
      echo \#\!/bin/csh \-f > ! $runfile
      echo mkdir -p $dir/$query 	 >> $runfile
      echo mkdir -p $dir/$query/$ref 	 >> $runfile
      echo cd $dir/$query/$ref 	 >> $runfile
      echo echo will check for $query.$ref.pdb.out >> $runfile
      echo if\( \! -e $query.$ref.pdb.out \|\| -z $query.$ref.pdb.out \) then  >> $runfile 
          echo $SRC/CLASP -q $query -ref $ref -dontrunapbs   -link $resultsdir -relax  >>$runfile
	  echo endif >> $runfile 


	  echo mv \-f \* ../ >> $runfile 
      echo cd -  >> $runfile
	  if( (! -e $dir/$query/$query.$ref.pdb.out)  && (  -e $resultsdir/$ref/$query.pdb.out ) && \
			          ( ! -z $resultsdir/$ref/$query.pdb.out) && (  -e $resultsdir/$ref/$ref.pdb.out ) && ( ! -z  $resultsdir/$ref/$ref.pdb.out) ) then
			source $runfile
			
			# if you run even one, you need to rescore
            #\rm -rf $dir/SCORES.ALL/
			#mkdir -p $dir/SCORES.ALL/
	  endif 

      #bsub < $runfile  > & /dev/null 

	  cd $dir/$query

      #$SRC/MISC/fixMatchesForCorrectDistance.pl -pdb $query -outf $query.$ref.SERLYS -res $query.pdb.out -ref $ref
      
      #$SRC/MISC/fixMatchesForCorrectDistance.pl -pdb $ref -outf $ref.SERLYS -res $ref.pdb.out -ref $ref

	  cd ..//..
  end

  cd $PWD 
end
