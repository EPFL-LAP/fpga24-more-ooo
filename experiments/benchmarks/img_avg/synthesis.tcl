
set_project .
set_top_file img_avg.cpp
synthesize -simple-buffers=true -use-lsq=false -verbose
#cdfg
write_hdl

exit



