# Copyright 2012 Free Software Foundation, Inc.
#
# This file is part of GNU Radio
#
# GNU Radio is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3, or (at your option)
# any later version.
#
# GNU Radio is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with GNU Radio; see the file COPYING.  If not, write to
# the Free Software Foundation, Inc., 51 Franklin Street,
# Boston, MA 02110-1301, USA.

########################################################################
# Setup library
########################################################################
list(APPEND gr_wavelet_sources
    squash_ff_impl.cc
    wavelet_ff_impl.cc
    wvps_ff_impl.cc
)

#Add Windows DLL resource file if using MSVC
if(MSVC)
    include(${CMAKE_SOURCE_DIR}/cmake/Modules/GrVersion.cmake)

    configure_file(
        ${CMAKE_CURRENT_SOURCE_DIR}/gnuradio-wavelet.rc.in
        ${CMAKE_CURRENT_BINARY_DIR}/gnuradio-wavelet.rc
    @ONLY)

    list(APPEND gr_wavelet_sources
        ${CMAKE_CURRENT_BINARY_DIR}/gnuradio-wavelet.rc
    )
endif(MSVC)

GR_LIBRARY_FOO(gnuradio-wavelet
    RUNTIME_COMPONENT "wavelet_runtime"
    DEVEL_COMPONENT "wavelet_devel"
    AUTO_DEPS_VAR ENABLE_GR_WAVELET
    SOURCES ${gr_wavelet_sources}
    EXTRA_EXTERNAL_INCLUDE_DIRS ${GSL_INCLUDE_DIRS}
    EXTRA_LIBS ${GSL_LIBRARIES}
    EXTRA_EXTERNAL_LIBRARY_DIRS ${GSL_LIBRARY_DIRS}
)

add_definitions(${GSL_DEFINITIONS})

add_dependencies(gnuradio-wavelet
  wavelet_generated_includes
  wavelet_generated_swigs
)

# we need -no-as-needed or else -lgslcblas gets stripped out on newer version of gcc
if(CMAKE_COMPILER_IS_GNUCC AND NOT ${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
    SET_TARGET_PROPERTIES(gnuradio-wavelet PROPERTIES LINK_FLAGS "-Wl,--no-as-needed")
endif()
