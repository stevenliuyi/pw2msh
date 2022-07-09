package require PWI_Glyph 4.18.4

set filename [lindex $argv 0]

# find minimum x, y, z values of a boundary
proc findMinPositionValues { bc } {
  set doms [$bc getEntities]    
  set min { Inf Inf Inf }

  foreach dom $doms {
    set count [$dom getPointCount]
    # find minimum x, y, z values in the a domain
    # assuming the minimum values only occur at the first or last point
    foreach i [list 1 $count] {
      set pt [$dom getPoint $i]
      if { [lindex $pt 0] < [lindex $min 0] } { lset min 0 [lindex $pt 0]}
      if { [lindex $pt 1] < [lindex $min 1] } { lset min 1 [lindex $pt 1]}
      if { [lindex $pt 2] < [lindex $min 2] } { lset min 2 [lindex $pt 2]}
    }
  }
  return $min
}

# load .pw file
pw::Application reset
pw::Application load "$filename.pw"

# create msh2cdp.in
set infile [open msh2cdp.in w]
puts $infile NPART=1000

# write info for msh files and reconnect surface
set cvs [pw::VolumeCondition getNames]
set cvs [lsearch -all -inline $cvs FLUID*]
set cv_count [llength $cvs]

if { $cv_count == 1 } {
  puts $infile "MSH=./$filename.msh"
} elseif { $cv_count > 1} {
  for {set id 1} true {incr id} {
    set mshid [format "%04d" [expr $id - 1]]
    puts $infile "MSH.$mshid=./$filename\_part$id.msh"
    if {$id == $cv_count} break
  }
  for {set id 1} true {incr id} {
    set mshid [format "%04d" [expr $id - 1]]
    puts $infile "RECONN$id.$mshid=RECONNECT"
    if {$id == $cv_count} break
  }
}


# assume periodic conditions have name pairs like "Z0", "Z1", etc.
set bcs [pw::BoundaryCondition getNames]
set periodic_bcs [lsearch -all -inline $bcs *0]

# loop through all periodic conditions
foreach bc0 $periodic_bcs {
  set bc1 [string replace $bc0 end end 1]

  # check the surface pair of periodic condition
  if {$bc1 in $bcs} {
    set p0 [pw::BoundaryCondition getByName $bc0]
    set p1 [pw::BoundaryCondition getByName $bc1]

    puts $infile "$bc0=periodic_$bc0"
    puts $infile "$bc1=periodic_$bc1"

    # find minimum x, y, z values
    set p0_min [findMinPositionValues $p0]
    set p1_min [findMinPositionValues $p1]

    # calculate dx, dy, dz
    set dx [expr [lindex $p1_min 0] - [lindex $p0_min 0]]
    set dy [expr [lindex $p1_min 1] - [lindex $p0_min 1]]
    set dz [expr [lindex $p1_min 2] - [lindex $p0_min 2]]

    # set nonzero dx, dy, dz
    if {abs($dx) > 1E-6} {
      puts $infile "periodic_$bc0.DX=$dx"
      puts $infile "periodic_$bc1.DX=[expr -$dx]"
    }
    if {abs($dy) > 1E-6} {
      puts $infile "periodic_$bc0.DY=$dy"
      puts $infile "periodic_$bc1.DY=[expr -$dy]"
    }
    if {abs($dz) > 1E-6} {
      puts $infile "periodic_$bc0.DZ=$dz"
      puts $infile "periodic_$bc1.DZ=[expr -$dz]"
    }
  }
}

close $infile

