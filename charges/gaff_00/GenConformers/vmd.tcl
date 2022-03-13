for {set a 1} {$a < 21} {incr a} { 
 mol new Conf${a}/Conf${a}.pdb 
 mol selection {not water} 
 mol representation Licorice 0.2 50 50 
 } 
 axes location off 
 color Display Background white 
 display antialias on
