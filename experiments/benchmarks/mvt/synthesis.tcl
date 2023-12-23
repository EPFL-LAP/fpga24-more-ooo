
set_project .
set_top_file mvt.cpp
synthesize -simple-buffers=true -use-lsq=false -verbose
#cdfg
write_hdl

exit



