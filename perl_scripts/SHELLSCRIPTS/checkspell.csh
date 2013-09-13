#!/bin/csh -f


foreach i ( title.tex ack.tex abstract.tex introduction.tex results.tex methods.tex discussion.tex ack.tex document.tex )
   aspell -c $i 
end

