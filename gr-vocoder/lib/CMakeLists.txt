# Copyright 2011,2013 Free Software Foundation, Inc.
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
# Check for system libgsm....
########################################################################
if(NOT GR_USE_SYSTEM_LIBGSM)
  find_path(LIBGSM_INCLUDE_DIR NAMES gsm.h
    PATHS
    ${LIBGSM_PKG_INCLUDE_DIRS}
    /usr/include/gsm
    /usr/include
  )

  find_library(LIBGSM_LIBRARIES NAMES gsm
    PATHS
    ${LIBGSM_PKG_LIBRARY_DIRS}
    /usr/lib
  )

if(LIBGSM_INCLUDE_DIR AND LIBGSM_LIBRARIES)
  set(GR_USE_SYSTEM_LIBGSM TRUE CACHE INTERNAL "system libgsm found")
  message(STATUS "Found libgsm: ${LIBGSM_INCLUDE_DIR}, ${LIBGSM_LIBRARIES}")
else(LIBGSM_INCLUDE_DIR AND LIBGSM_LIBRARIES)
  set(GR_USE_SYSTEM_LIBGSM FALSE CACHE INTERNAL "system libgsm found")
  message(STATUS "system libgsm not found.")
endif(LIBGSM_INCLUDE_DIR AND LIBGSM_LIBRARIES)

mark_as_advanced(LIBGSM_INCLUDE_DIR LIBGSM_LIBRARIES)
endif(NOT GR_USE_SYSTEM_LIBGSM)

########################################################################
# Check for system libcodec2....
########################################################################
if(NOT GR_USE_SYSTEM_LIBCODEC2)
  find_path(LIBCODEC2_INCLUDE_DIR NAMES codec2.h
    PATHS
    ${LIBCODEC2_PKG_INCLUDE_DIRS}
    /usr/include/codec2
    /usr/include
  )

  find_library(LIBCODEC2_LIBRARIES NAMES codec2
    PATHS
    ${LIBCODEC2_PKG_LIBRARY_DIRS}
    /usr/lib
  )

if(LIBCODEC2_INCLUDE_DIR AND LIBCODEC2_LIBRARIES)
  set(GR_USE_SYSTEM_LIBCODEC2 TRUE CACHE INTERNAL "system libcodec2 found")
  message(STATUS "Found libcodec2: ${LIBCODEC2_INCLUDE_DIR}, ${LIBCODEC2_LIBRARIES}")
else(LIBCODEC2_INCLUDE_DIR AND LIBCODEC2_LIBRARIES)
  set(GR_USE_SYSTEM_LIBCODEC2 FALSE CACHE INTERNAL "system libcodec2 found")
  message(STATUS "system libcodec2 not found.")
endif(LIBCODEC2_INCLUDE_DIR AND LIBCODEC2_LIBRARIES)

mark_as_advanced(LIBCODEC2_INCLUDE_DIR LIBCODEC2_LIBRARIES)
endif(NOT GR_USE_SYSTEM_LIBCODEC2)

########################################################################
# Setup library
########################################################################
list(APPEND gr_vocoder_sources
    alaw_decode_bs_impl.cc
    alaw_encode_sb_impl.cc
    codec2.cc
    codec2_decode_ps_impl.cc
    codec2_encode_sp_impl.cc
    cvsd_decode_bs_impl.cc
    cvsd_encode_sb_impl.cc
    g721_decode_bs_impl.cc
    g721_encode_sb_impl.cc
    g723_24_decode_bs_impl.cc
    g723_24_encode_sb_impl.cc
    g723_40_decode_bs_impl.cc
    g723_40_encode_sb_impl.cc
    gsm_fr_decode_ps_impl.cc
    gsm_fr_encode_sp_impl.cc
    ulaw_decode_bs_impl.cc
    ulaw_encode_sb_impl.cc
)

#Add Windows DLL resource file if using MSVC
if(MSVC)
    include(${CMAKE_SOURCE_DIR}/cmake/Modules/GrVersion.cmake)

    configure_file(
        ${CMAKE_CURRENT_SOURCE_DIR}/gnuradio-vocoder.rc.in
        ${CMAKE_CURRENT_BINARY_DIR}/gnuradio-vocoder.rc
    @ONLY)

    list(APPEND gr_uhd_sources
        ${CMAKE_CURRENT_BINARY_DIR}/gnuradio-vocoder.rc
    )
endif(MSVC)

########################################################################
# Include subdirs rather to populate to the sources lists.
########################################################################
GR_INCLUDE_SUBDIRECTORY(g7xx)

set(gr_vocoder_libs)

if(NOT GR_USE_SYSTEM_LIBCODEC2)
    GR_INCLUDE_SUBDIRECTORY(codec2)
else()
    list(APPEND gr_vocoder_libs ${LIBCODEC2_LIBRARIES})
endif(NOT GR_USE_SYSTEM_LIBCODEC2)

if(NOT GR_USE_SYSTEM_LIBGSM)
    GR_INCLUDE_SUBDIRECTORY(gsm)
else()
    list(APPEND gr_vocoder_libs ${LIBGSM_LIBRARIES})
endif(NOT GR_USE_SYSTEM_LIBGSM)

GR_LIBRARY_FOO(gnuradio-vocoder
    RUNTIME_COMPONENT "vocoder_runtime"
    DEVEL_COMPONENT "vocoder_devel"
    AUTO_DEPS_VAR ENABLE_GR_VOCODER
    SOURCES ${gr_vocoder_sources}
    EXTRA_LIBS ${gr_vocoder_libs}
)
