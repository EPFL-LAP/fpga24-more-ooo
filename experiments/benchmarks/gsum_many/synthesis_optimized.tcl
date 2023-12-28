
set_project .
set_top_file gsum_many.cpp
synthesize -verbose
set_period 4
optimize
write_hdl

exit



