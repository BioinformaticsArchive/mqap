cd ANNOTATE
ls 
foreach i ( *outconf.annotated)
	if(! -e $i.html.txt) then 
       \cp -f $i $i.html.txt
	endif 
end
cd -



\cp -f ~/style.css .
foreach i ( *html )
	grep annotated.html $i > & ! /dev/null 
	if($status != 0) then 
       replacestring.pl -in $i -with "annotated.html" -which "annotated" -out ooo -same
    endif 
end 

foreach i ( *annotated )
    mv $i $i.html 
end


