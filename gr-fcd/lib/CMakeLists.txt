# Copyright 2012-2013 Free Software Foundation, Inc.
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

GR_INCLUDE_SUBDIRECTORY(hid)
GR_INCLUDE_SUBDIRECTORY(fcd)

########################################################################
# Setup library
########################################################################

list(APPEND gr_fcd_sources
    source_c_impl.cc
)

if(WIN32)

    list(APPEND gr_fcd_extra_libs setupapi)

    #Add Windows DLL resource file if using MSVC
    if(MSVC)
        include(${CMAKE_SOURCE_DIR}/cmake/Modules/GrVersion.cmake)

        configure_file(
            ${CMAKE_CURRENT_SOURCE_DIR}/gnuradio-fcd.rc.in
            ${CMAKE_CURRENT_BINARY_DIR}/gnuradio-fcd.rc
        @ONLY)

        list(APPEND gr_fcd_sources ${CMAKE_CURRENT_BINARY_DIR}/gnuradio-fcd.rc)
    endif(MSVC)

elseif(APPLE)

    FIND_LIBRARY(IOKIT_LIBRARY IOKit)
    list(APPEND gr_fcd_extra_libs ${IOKIT_LIBRARY})

else()

    list(APPEND gr_fcd_extra_libs
        ${LIBUSB_LIBRARIES}
    )
    list(APPEND gr_fcd_extra_external_include_dirs
        ${LIBUSB_INCLUDE_DIR}
    )
    list(APPEND gr_fcd_extra_external_library_dirs
        ${LIBUSB_LIBRARY_DIRS}
    )
    if(LINUX)
        list(APPEND gr_fcd_extra_libs rt)
    endif()

endif()

GR_LIBRARY_FOO(gnuradio-fcd
    RUNTIME_COMPONENT "fcd_runtime"
    DEVEL_COMPONENT "fcd_devel"
    AUTO_DEPS_VAR ENABLE_GR_FCD
    SOURCES ${gr_fcd_sources}
    EXTRA_EXTERNAL_INCLUDE_DIRS ${gr_fcd_extra_external_include_dirs}
    EXTRA_EXTERNAL_LIBRARY_DIRS ${gr_fcd_extra_external_library_dirs}
    EXTRA_LIBS ${gr_fcd_extra_libs}
)
