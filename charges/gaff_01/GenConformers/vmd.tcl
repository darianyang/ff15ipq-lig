for {set a 1} {$a < 21} {incr a} { 
 mol new Conf${a}/Conf${a}.pdb 
 mol delrep 0 top 
 set index [ expr $a -1 ] 
 mol selection all not water 
 mol rep Licorice 0.2 50 50 
 mol addrep $index 
 set sel0 [atomselect 0 "all not water"] 
 set sel1 [atomselect $index "all not water"] 
 set M [measure fit $sel1 $sel0] 
 $sel1 move $M 
 } 
 axes location off 
 color Display Background white 
 display antialias on
