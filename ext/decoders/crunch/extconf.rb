# frozen_string_literal: true

require 'mkmf'

have_library('stdc++')
append_cppflags('-std=c++11')
append_cppflags('-O2')
append_cppflags('-Wall')
append_cppflags('-Wextra')
append_cppflags('-Wvla')

create_makefile('mikunyan/decoders/crunch')
