# Copyright 2011-2013 Free Software Foundation, Inc.
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
list(APPEND gr_uhd_sources
    usrp_source_impl.cc
    usrp_sink_impl.cc
    amsg_source_impl.cc
)

#Add Windows DLL resource file if using MSVC
if(MSVC)
    include(${CMAKE_SOURCE_DIR}/cmake/Modules/GrVersion.cmake)

    configure_file(
        ${CMAKE_CURRENT_SOURCE_DIR}/gnuradio-uhd.rc.in
        ${CMAKE_CURRENT_BINARY_DIR}/gnuradio-uhd.rc
    @ONLY)

    list(APPEND gr_uhd_sources
        ${CMAKE_CURRENT_BINARY_DIR}/gnuradio-uhd.rc
    )
endif(MSVC)

GR_LIBRARY_FOO(gnuradio-uhd
    RUNTIME_COMPONENT "uhd_runtime"
    DEVEL_COMPONENT "uhd_devel"
    AUTO_DEPS_VAR ENABLE_GR_UHD
    SOURCES ${gr_uhd_sources}
    EXTRA_EXTERNAL_INCLUDE_DIRS ${UHD_INCLUDE_DIRS}
    EXTRA_EXTERNAL_LIBRARY_DIRS ${UHD_LIBRARY_DIRS}
    EXTRA_LIBS ${UHD_LIBRARIES}
)
