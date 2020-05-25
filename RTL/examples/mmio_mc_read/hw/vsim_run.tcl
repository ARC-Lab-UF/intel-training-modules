add wave -r /* 
set mem_split [split [mem list -r ] "\n"]
set list_of_mem [lreplace $mem_split end end]
foreach mem_string $list_of_mem {
    set mem_field [regexp -inline -all -- {\S+} $mem_string]
    set mem_path [lindex $mem_field 1]
    add wave $mem_path
}
run -all
