# Copyright 2011,2012 Free Software Foundation, Inc.
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
list(APPEND video_sdl_sources
  sink_s_impl.cc
  sink_uc_impl.cc
)

#Add Windows DLL resource file if using MSVC
IF(MSVC)
    include(${CMAKE_SOURCE_DIR}/cmake/Modules/GrVersion.cmake)

    configure_file(
        ${CMAKE_CURRENT_SOURCE_DIR}/gnuradio-video-sdl.rc.in
        ${CMAKE_CURRENT_BINARY_DIR}/gnuradio-video-sdl.rc
    @ONLY)

    list(APPEND video_sdl_sources
        ${CMAKE_CURRENT_BINARY_DIR}/gnuradio-video-sdl.rc
    )
ENDIF(MSVC)

GR_LIBRARY_FOO(gnuradio-video-sdl
    RUNTIME_COMPONENT "video_sdl_runtime"
    DEVEL_COMPONENT "video_sdl_devel"
    AUTO_DEPS_VAR ENABLE_GR_VIDEO_SDL
    SOURCES ${video_sdl_sources}
    EXTRA_EXTERNAL_INCLUDE_DIRS ${SDL_INCLUDE_DIR}
    EXTRA_LIBS ${SDL_LIBRARY}
)
