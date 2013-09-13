#!/bin/csh -f

if($#argv != 3  ) then 
  echo "Usage : "
  exit 
endif 

set PWD = ` pwd`
set listref = $1
set listquery = $2
set close2activesite = $3
set annotate = ANNOTATE
set results = Results.$listref.$listquery
set extract = Extract.$listref.$listquery
set dirscores = $extract/SCORES.ALL/

#\rm -rf $extract/ANNOTATE


#\rm -rf $results
#\rm -rf $extract
$SRC/CSA/runRefQueryList.csh $1 $2 $results $annotate $close2activesite ; 
$SRC/CSA/extractRefQuertList.csh $1 $2 $extract $results 
cp $listref $extract/list.ref
cp $listquery $extract/list.query


cd $extract 

#getbestmatchesforsingleref.csh `cat list.ref` list.query
$SRC/SHELLSCRIPTS/getbestmatchesforsinglequery.csh `cat list.query` list.ref

exit 



set dist = ` cat ANNOTATE/dist `
echo Running for DIST $dist

$SRC/SHELLSCRIPTS/newfile.csh $PWD/score.$dist
$SRC/CSA/runGenScoresExtractEasilyNamed.csh $1 $2 3 $PWD/score.$dist $dist

############################################3
exit 
############################################3







cd $extract 
#source ~/pot.csh list.query
#parseResultsData.pl -outfile oo -lis list.query
#createTexTable.pl -in oo -out table.tex

cd $PWD/$dirscores

echo running webClaspaWriteBoth.pl 
foreach query ( ` cat $PWD/$listquery` )
       $SRC/WEB/webClaspaWriteBoth.pl -out $query.both.html -qu $query -dir ALL2ALL
end 

$SRC/PDBSEQRES/annotate.pl -in $SRC/pdb_seqres.txt  -out $PWD/$dirscores/listref.html -list $PWD/$listref -html . -header1 "Active Site Motifs used to query unknown proteins - click on PDB id to find out the best matches when this motif is queried in the list of proteins"  -anndist $dist

$SRC/PDBSEQRES/annotate.pl -in $SRC/pdb_seqres.txt  -out $PWD/$dirscores/ref.html -list $PWD/$listref -html . -header1 "List of proteins with known active site motifs" -isdummy 1  -anndist $dist


$SRC/PDBSEQRES/annotate.pl -in $SRC/pdb_seqres.txt  -out $PWD/$dirscores/listquery.html -list $PWD/$listquery -html . -header1 "Active Site Motifs used to query unknown proteins - click on PDB id to find out whether this protein has any further activities" -query2ref -anndist $dist

$SRC/PDBSEQRES/annotate.pl -in $SRC/pdb_seqres.txt  -out $PWD/$dirscores/query.html -list $PWD/$listquery -html . -header1 "Non redundant list of proteins - using the list of motifs of known active site, we will query whether these proteins have any further activities"  -query2ref -isdummy 1  -anndist $dist



cd $PWD/$extract
\cp -f $SRC/style.css  SCORES.ALL

if(! -e SCORES.ALL/ANNOTATE) then 
    cp -r $ANNDIR SCORES.ALL/ 
endif 

cd SCORES.ALL
## cant fix it without fixing naming
#source  $SRC/SHELLSCRIPTS/fixScoredir.csh 
cd -



#tar -cvzf SCORES.ALL.$listref.$listquery.tgz  SCORES.ALL > & ! /dev/null & 

