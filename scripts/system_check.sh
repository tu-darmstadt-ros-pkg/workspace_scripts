# Aperture Science terminal
#
# Author:        Mepu

findcpu(){
	grep 'model name' /proc/cpuinfo  | uniq | awk -F':' '{ print $2}'
}
 
findkernelversion(){
	uname -mrs
}
 
totalmem(){
	grep -i 'memtotal' /proc/meminfo | awk -F':' '{ print $2}'
}

mem=$(cat /proc/meminfo | grep MemTotal | head -n 1 | awk '/[0-9]/ {print $2}')


echo "              .,-:;//;:=,               `tput smso`  Aperture Science Terminal Info        `tput rmso`
          . :H@@@MM@M#H/.,+%;,        
       ,/X+ +M@@M@MM%=,-%HMMM@X/,      $(findcpu)
     -+@MM; SM@@MH+-,;XMMMM@MMMM@+-     `tput bold`RAM memory:`tput sgr0` $[$mem/1024] MB
    ;@M@@M- XM@X;. -+XXXXXHHH@M@M#@/.   `tput bold`Kernel:`tput sgr0` $(findkernelversion) 
  ,%MM@@MH ,@%=            .---=-=:=,.    
  =@#@@@MX .,              -%HXSS%%%+;    
 =-./@M@MS                  .;@MMMM@MM: `tput smso`  GLaDOS Monitor                        `tput rmso`
 X@/ -SMM/                    .+MM@@@MS                                 ____
,@M@H: :@:                    . =X#@@@@-  `tput bold`System status:`tput sgr0`  On           /   /
,@@@MMX, .                    /H- ;@M@M=  `tput bold`Voice status:`tput sgr0`   On     ___  /   /
.H@@@@M@+,                    %MM+..%#S.                         \  \/   /
 /MMMM@MMH/.                  XM@MH; =;   `tput bold`Damaged:       `tput sgr0` No      \     /
  /%+%SXHH@S=              , .H@@@@MX,    `tput bold`Malfunctioning:`tput sgr0` Maybe    \___/ 
   .=--------.           -%H.,@@@@@MX,    
    .%MM@@@HHHXXSSS%+- .:MMX =M@@MM%.                               
     =XMMM@MM@MM#H;,-+HMM@M+ /MMMX=     `tput smso`  Date and Time                         `tput rmso`
       =%@M@M#@S-.=S@MM@@@M; %M%=     
         ':+S+-,/H#MMMMMMM@= ='           `tput bold`Date:`tput sgr0` $(date +"%A %d %B %Y")
               =++%%%%+/:-.               `tput bold`Time:`tput sgr0` $(date +"%T")
"

