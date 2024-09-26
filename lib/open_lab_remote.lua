-- this is the file that is written to, that the python script will observe
lab_open_file_path = "interop/lab_status.txt"

function open_lab_remote()
    printh(
        "1",
        lab_open_file_path,
        true
    )
end

function close_lab_remote()
    printh(
        "0",
        lab_open_file_path,
        true
    )
end