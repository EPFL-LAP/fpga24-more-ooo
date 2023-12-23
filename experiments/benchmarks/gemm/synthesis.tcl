
set_project .
set_top_file gemm.cpp
synthesize -simple-buffers=true -verbose
#cdfg
write_hdl

exit



