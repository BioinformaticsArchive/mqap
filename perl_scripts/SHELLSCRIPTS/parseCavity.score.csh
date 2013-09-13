if($#argv != 1  ) then 
  echo "Usage : EXEC  <list> "
  exit 
endif 

set PWD = ` pwd`
set list = $1

lc.pl -in $list -out oooooooooooo -same
foreach i ( ` cat  $list ` )
echo "parseCavity.pl -result  /home/sandeepc/Results.betalactamase/ALL/$i.pdb.out -ca working/JID$i*poc -out $i.new.ouuuut"
parseCavity.pl -result  /home/sandeepc/Results.betalactamase/ALL/$i.pdb.out -ca working/JID$i*poc -out $i.new.ouuuut >!  $i.looog
end 

foreach i ( ` cat  $list ` )
grep FINAL $i.looog
end
