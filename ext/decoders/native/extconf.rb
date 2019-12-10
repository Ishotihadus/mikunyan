require 'mkmf'

append_cppflags('-std=c11')
append_cppflags('-O2')
append_cppflags('-Wall')
append_cppflags('-Wextra')
append_cppflags('-Wvla')
create_makefile('mikunyan/decoders/native')
