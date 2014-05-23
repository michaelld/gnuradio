# Copyright 2012-2014 Free Software Foundation, Inc.
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
# These are convenience libraries of 3rd party code.
# Change to test for distro provided packages
########################################################################
GR_INCLUDE_SUBDIRECTORY(reed-solomon)
GR_INCLUDE_SUBDIRECTORY(viterbi)

########################################################################
# Setup library
########################################################################
list(APPEND gnuradio_fec_sources
  generic_decoder.cc
  generic_encoder.cc
  decoder_impl.cc
  encoder_impl.cc
  tagged_decoder_impl.cc
  tagged_encoder_impl.cc
  async_decoder_impl.cc
  async_encoder_impl.cc
  cc_decoder_impl.cc
  cc_encoder_impl.cc
  ccsds_encoder_impl.cc
  dummy_decoder_impl.cc
  dummy_encoder_impl.cc
  repetition_decoder_impl.cc
  repetition_encoder_impl.cc
  decode_ccsds_27_fb_impl.cc
  encode_ccsds_27_bb_impl.cc
  ber_tools.cc
  ber_bf_impl.cc
  conv_bit_corr_bb_impl.cc
  puncture_bb_impl.cc
  puncture_ff_impl.cc
  depuncture_bb_impl.cc
)

#Add Windows DLL resource file if using MSVC
if(MSVC)
    include(${CMAKE_SOURCE_DIR}/cmake/Modules/GrVersion.cmake)

    configure_file(
        ${CMAKE_CURRENT_SOURCE_DIR}/gnuradio-fec.rc.in
        ${CMAKE_CURRENT_BINARY_DIR}/gnuradio-fec.rc
    @ONLY)

    list(APPEND gnuradio_fec_sources
        ${CMAKE_CURRENT_BINARY_DIR}/gnuradio-fec.rc
    )
endif(MSVC)

list(APPEND fec_extra_internal_include_dirs
    ${CMAKE_CURRENT_SOURCE_DIR}/lib/viterbi
    ${CMAKE_CURRENT_SOURCE_DIR}/lib/reed-solomon
)

GR_LIBRARY_FOO(gnuradio-fec
    RUNTIME_COMPONENT "fec_runtime"
    DEVEL_COMPONENT "fec_devel"
    AUTO_DEPS_VAR ENABLE_GR_FEC
    SOURCES ${gnuradio_fec_sources}
    EXTRA_INTERNAL_INCLUDE_DIRS ${fec_extra_internal_include_dirs}
)
