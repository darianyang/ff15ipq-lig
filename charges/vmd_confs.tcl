for {set a 1} {$a < 21} {incr a} {
mol new v00/mon.top type {parm7} 
mol addfile v00/GenConformers/Conf${a}/Conf${a}.rst type {netcdf} first 0 last -1 step 1 waitfor -1
set mol_index [ expr $a -1 ]
mol modselect 0 $mol_index all not water
mol modselect 0 $mol_index Licorice 0.2 50 50
set sel0 [atomselect 0 "all not water"]	 
set sel1 [atomselect $mol_index "all not water"]	 
set M [measure fit $sel0 $sel1]	 
$sel0 move $M
}
axes location off
color Display Background white
display antialias on
