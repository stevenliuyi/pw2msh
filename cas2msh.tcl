set filename [lindex [ic_argv] 0]

ic_empty_tetin 
ic_read_external $env(ICEM_ACN)/icemcfd/result-interfaces/readfluent "$filename.cas" 1 2 0 {}
ic_boco_solver {Ansys Fluent}
ic_solution_set_solver {Ansys Fluent} 1
ic_boco_save "$filename.fbc"
ic_boco_save_atr "$filename.atr"
ic_delete_empty_parts 
ic_save_unstruct "$filename.uns" 1 {} {} {}
ic_save_project_file "$filename.prj"
ic_exec $env(ICEM_ACN)/icemcfd/output-interfaces/fluent6 -dom "$filename.uns" -b "$filename.fbc" $filename
ic_uns_print_info summary

exit
