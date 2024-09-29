lab_status_interop_file = "lab_status.txt"

function open_lab_remote() printh("1", lab_status_interop_file, true) end

function close_lab_remote() printh("0", lab_status_interop_file, true) end