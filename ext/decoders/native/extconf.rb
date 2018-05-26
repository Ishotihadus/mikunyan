require 'mkmf'

append_cppflags('-O3')
append_cppflags('-Wall')
append_cppflags('-Wextra')
append_cppflags('-Wvla')
create_makefile('mikunyan/decoders/native')
