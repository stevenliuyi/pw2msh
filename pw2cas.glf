package require PWI_Glyph 4.18.4

# delete part (name must be "FLUID1", "FLUID2"...)
proc deletePart { name } {
  # check name
  if { [string range $name 0 4] != "FLUID"} {
    puts "invalid volume condition: $name"
    exit
  }

  # get all blocks associated with the volume condition
  set vc [pw::VolumeCondition getByName $name]
  set blks [$vc getEntities]
  
  # delete all blocks
  foreach blk $blks { $blk delete -domains -connectors }

  return
}

# set boundary conditions
proc setBC { name } {
  # loop through all BCs
  foreach bc_name [pw::BoundaryCondition getNames] {
    set bc [pw::BoundaryCondition getByName $bc_name]
    set count [$bc getEntityCount]
  
    # delete BC with no associated domain
    if {$count == 0} {$bc delete}
  
    # unspecified BC
    if {$bc_name == "Unspecified"} {
  
      # create BC for connection surfaces
      set reconn_bc [pw::BoundaryCondition create]
      set id [string range $name 5 end]
      $reconn_bc setName "RECONN$id"
      $reconn_bc setPhysicalType "Wall"
  
      # get all unspecified domains
      set doms [$bc getEntities]
      foreach dom $doms {

        set blks [pw::Block getBlocksFromDomains $dom]
        set register_bcs [$dom getRegisterBoundaryConditions]
  
        # only set BC when domain is not inside a block
        if {[llength $register_bcs] == 1} {

          # check if there is only one block associated with the domain
          if {[llength $blks] != 1} {
            puts "there should be only one block associated with the domain $dom"
            exit
          }

          $reconn_bc apply [list [lindex $blks 0] $dom]
        }
      }
  
    }
  }

  return
}

# set volume conditions
proc setVC {} {
  # loop through all parts
  foreach vc_name [pw::VolumeCondition getNames] {
    set vc [pw::VolumeCondition getByName $vc_name]
    set count [$vc getEntityCount]
  
    # delete parts with no associated blocks
    if {$count == 0 && $vc_name != "Unspecified"} {$vc delete}

    # rename current part
    if {$count > 0} {$vc setName "FLUID"}
  }

  return
}

# substract part (name must be "FLUID1", "FLUID2"...)
proc substractPart { name } {
  # check name
  if { [string range $name 0 4] != "FLUID"} {
    puts "invalid volume condition: $name"
    exit
  }

  # loop through all parts
  foreach vc_name [pw::VolumeCondition getNames] {
    # delet all parts except the current one
    if { $vc_name != $name && $vc_name != "Unspecified" } { deletePart $vc_name }
  }

  # set boundary and volume conditions
  setBC $name
  setVC

  return
}

# check if the part is valid and return the total number of parts
proc getNumOfParts { id } {
  set n_parts [expr [llength [pw::VolumeCondition getNames]]-1]
  
  if  {$id > $n_parts } { exit }

  return $n_parts

}


# calculate the total cell count
proc total_cell_count {} {
  set cell_count 0
  set blks [pw::Grid getAll -type pw::Block]
  foreach blk $blks {
    set cell_count [expr $cell_count + [$blk getCellCount]]
  }
  
  return $cell_count
}

set filename [lindex $argv 0]
set partname [lindex $argv 1]

# load .pw file
pw::Application reset
pw::Application load "$filename.pw"

# get part id
set id [string range $partname 5 end]
set n_parts [getNumOfParts $id]

# substract when there are more than one part
if { $n_parts > 1 } {
  # substract part
  substractPart $partname
  
  # save .pw file
  set export_filename "$filename\_part$id"
  pw::Application save "$export_filename.pw"
  puts "Part $id is saved to $export_filename.pw (total cell count: [total_cell_count])"
} else { set export_filename $filename }

# convert to Fluent .cas file
set grid [pw::Grid getAll]
puts "Exporting $export_filename.cas..."
pw::Application export $grid "$export_filename.cas"

exit
