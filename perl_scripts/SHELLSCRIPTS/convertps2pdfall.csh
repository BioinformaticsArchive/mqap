#!/bin/csh -f


foreach i (`ls *ps`)
   ps2pdf $i
end 
