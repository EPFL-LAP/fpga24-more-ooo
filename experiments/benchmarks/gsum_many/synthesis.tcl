
set_project .
set_top_file gsum_many.cpp
synthesize -simple-buffers=true -verbose
#cdfg
write_hdl

exit



