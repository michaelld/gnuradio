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

########################################################################
# Setup library
########################################################################
list(APPEND gr_wxgui_sources
  histo_sink_f_impl.cc
  oscope_guts.cc
  oscope_sink_x.cc
  oscope_sink_f_impl.cc
)

#Add Windows DLL resource file if using MSVC
IF(MSVC)
    include(${CMAKE_SOURCE_DIR}/cmake/Modules/GrVersion.cmake)

    configure_file(
        ${CMAKE_CURRENT_SOURCE_DIR}/gnuradio-wxgui.rc.in
        ${CMAKE_CURRENT_BINARY_DIR}/gnuradio-wxgui.rc
    @ONLY)

    list(APPEND gr_wxgui_sources
        ${CMAKE_CURRENT_BINARY_DIR}/gnuradio-wxgui.rc
    )
ENDIF(MSVC)

GR_LIBRARY_FOO(gnuradio-wxgui
  RUNTIME_COMPONENT "wxgui_runtime"
  DEVEL_COMPONENT "wxgui_devel"
  AUTO_DEPS_VAR ENABLE_GR_WXGUI
  SOURCES ${gr_wxgui_sources}
)
