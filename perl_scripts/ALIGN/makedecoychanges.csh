if (! -e list.org ) then 
   mv list list.org 
endif 
makedecoychanges.pl -outf list -lis list.org -script run.csh 
source run.csh 

