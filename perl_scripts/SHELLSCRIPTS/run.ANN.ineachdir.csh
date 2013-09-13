foreach i ( ` cat $1 `)
  echo mkdir -p $i.dir
  echo cd $i.dir 
  echo s ~/Bio/Code/perl_scripts/run.csh ~/nonreduntant.all.list  /home/sandeepc/Bio/Data/CSA/ANN/$i 
  echo cd - 
  #echo sleep 600 
end
