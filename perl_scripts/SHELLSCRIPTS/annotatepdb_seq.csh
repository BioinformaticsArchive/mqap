touch $1.annotate
foreach i ( ` cat $1 `)
	grep -i $i /home/sandeepc/pdb_seqres.txt >> $1.annotate 
end
