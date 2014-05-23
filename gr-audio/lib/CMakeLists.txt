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
# Setup the include and linker paths
########################################################################

list(APPEND gr_audio_sources audio_registry.cc)
list(APPEND gr_audio_confs ${CMAKE_CURRENT_SOURCE_DIR}/gr-audio.conf)

########################################################################
## ALSA Support
########################################################################
find_package(ALSA)

if(ALSA_FOUND)

    list(APPEND gr_audio_internal_include_dirs ${CMAKE_CURRENT_SOURCE_DIR}/alsa)
    list(APPEND gr_audio_external_include_dirs ${ALSA_INCLUDE_DIRS})
    list(APPEND gr_audio_extra_libs ${ALSA_LIBRARIES})
    list(APPEND gr_audio_sources
        ${CMAKE_CURRENT_SOURCE_DIR}/alsa/alsa_impl.cc
        ${CMAKE_CURRENT_SOURCE_DIR}/alsa/alsa_source.cc
        ${CMAKE_CURRENT_SOURCE_DIR}/alsa/alsa_sink.cc
    )
    list(APPEND gr_audio_confs ${CMAKE_CURRENT_SOURCE_DIR}/alsa/gr-audio-alsa.conf)

endif(ALSA_FOUND)

########################################################################
## OSS Support
########################################################################
find_package(OSS)

if(OSS_FOUND)

    list(APPEND gr_audio_internal_include_dirs ${CMAKE_CURRENT_SOURCE_DIR}/oss)
    list(APPEND gr_audio_external_include_dirs ${OSS_INCLUDE_DIRS})
    list(APPEND gr_audio_sources
        ${CMAKE_CURRENT_SOURCE_DIR}/oss/oss_source.cc
        ${CMAKE_CURRENT_SOURCE_DIR}/oss/oss_sink.cc
    )
    list(APPEND gr_audio_confs ${CMAKE_CURRENT_SOURCE_DIR}/oss/gr-audio-oss.conf)

endif(OSS_FOUND)


########################################################################
## Jack Support
########################################################################
find_package(Jack)

if(JACK_FOUND)

    list(APPEND gr_audio_internal_include_dirs ${CMAKE_CURRENT_SOURCE_DIR}/jack)
    list(APPEND gr_audio_external_include_dirs ${JACK_INCLUDE_DIRS})
    list(APPEND gr_audio_extra_libs ${JACK_LIBRARIES})
    add_definitions(${JACK_DEFINITIONS})
    list(APPEND gr_audio_sources
        ${CMAKE_CURRENT_SOURCE_DIR}/jack/jack_impl.cc
        ${CMAKE_CURRENT_SOURCE_DIR}/jack/jack_source.cc
        ${CMAKE_CURRENT_SOURCE_DIR}/jack/jack_sink.cc
    )
    list(APPEND gr_audio_confs ${CMAKE_CURRENT_SOURCE_DIR}/jack/gr-audio-jack.conf)

endif(JACK_FOUND)

########################################################################
## OSX Support
########################################################################
include(CheckIncludeFileCXX)
CHECK_INCLUDE_FILE_CXX(AudioUnit/AudioUnit.h AUDIO_UNIT_H)
CHECK_INCLUDE_FILE_CXX(AudioToolbox/AudioToolbox.h AUDIO_TOOLBOX_H)

if(AUDIO_UNIT_H AND AUDIO_TOOLBOX_H)

    set(OSX_AUDIO_VALID 1 CACHE INTERNAL "OSX Audio is valid")

    list(APPEND gr_audio_internal_include_dirs ${CMAKE_CURRENT_SOURCE_DIR}/osx)
    list(APPEND gr_audio_extra_libs
        "-framework AudioUnit"
        "-framework CoreAudio"
        "-framework AudioToolbox"
        "-framework Carbon"
    )
    list(APPEND gr_audio_sources
        ${CMAKE_CURRENT_SOURCE_DIR}/osx/osx_impl.cc
        ${CMAKE_CURRENT_SOURCE_DIR}/osx/osx_source.cc
        ${CMAKE_CURRENT_SOURCE_DIR}/osx/osx_sink.cc
    )

    list(APPEND gr_audio_confs ${CMAKE_CURRENT_SOURCE_DIR}/osx/gr-audio-osx.conf)

else(AUDIO_UNIT_H AND AUDIO_TOOLBOX_H)

    set(OSX_AUDIO_VALID 0 CACHE INTERNAL "OSX Audio is not valid")

endif(AUDIO_UNIT_H AND AUDIO_TOOLBOX_H)

########################################################################
## PortAudio Support
########################################################################
find_package(Portaudio)

if(PORTAUDIO_FOUND)

    list(APPEND gr_audio_internal_include_dirs ${CMAKE_CURRENT_SOURCE_DIR}/portaudio)
    list(APPEND gr_audio_external_include_dirs ${PORTAUDIO_INCLUDE_DIRS})
    list(APPEND gr_audio_extra_libs ${PORTAUDIO_LIBRARIES})
    add_definitions(${PORTAUDIO_DEFINITIONS})
    list(APPEND gr_audio_sources
        ${CMAKE_CURRENT_SOURCE_DIR}/portaudio/portaudio_impl.cc
        ${CMAKE_CURRENT_SOURCE_DIR}/portaudio/portaudio_source.cc
        ${CMAKE_CURRENT_SOURCE_DIR}/portaudio/portaudio_sink.cc
    )
    list(APPEND gr_audio_confs ${CMAKE_CURRENT_SOURCE_DIR}/portaudio/gr-audio-portaudio.conf)

endif(PORTAUDIO_FOUND)

########################################################################
## Windows Support
########################################################################
if(WIN32)

    list(APPEND gr_audio_internal_include_dirs ${CMAKE_CURRENT_SOURCE_DIR}/windows)
    list(APPEND gr_audio_extra_libs winmm.lib)
    list(APPEND gr_audio_sources
        ${CMAKE_CURRENT_SOURCE_DIR}/windows/windows_source.cc
        ${CMAKE_CURRENT_SOURCE_DIR}/windows/windows_sink.cc
    )

    #Add Windows DLL resource file if using MSVC
    IF(MSVC)
        include(${CMAKE_SOURCE_DIR}/cmake/Modules/GrVersion.cmake)

        configure_file(
            ${CMAKE_CURRENT_SOURCE_DIR}/gnuradio-audio.rc.in
            ${CMAKE_CURRENT_BINARY_DIR}/gnuradio-audio.rc
        @ONLY)

        list(APPEND gr_audio_sources
            ${CMAKE_CURRENT_BINARY_DIR}/gnuradio-audio.rc
        )
    ENDIF()

endif(WIN32)

########################################################################
# Setup library
########################################################################

GR_LIBRARY_FOO(gnuradio-audio
    RUNTIME_COMPONENT "audio_runtime"
    DEVEL_COMPONENT "audio_devel"
    AUTO_DEPS_VAR ENABLE_GR_AUDIO
    SOURCES ${gr_audio_sources}
    EXTRA_INTERNAL_INCLUDE_DIRS ${gr_audio_internal_include_dirs}
    EXTRA_EXTERNAL_INCLUDE_DIRS ${gr_audio_external_include_dirs}
    EXTRA_LIBS ${gr_audio_extra_libs}
)

install(FILES ${gr_audio_confs} DESTINATION ${GR_PREFSDIR} COMPONENT "audio_runtime")
