# Copyright 2010-2011,2015 Free Software Foundation, Inc.
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

if(DEFINED __INCLUDED_GR_TEST_CMAKE)
    return()
endif()
set(__INCLUDED_GR_TEST_CMAKE TRUE)

########################################################################
# Add a unit test and setup the environment for a unit test.
#
# Old way: Takes the same arguments as the ADD_TEST function.
#
# Before calling set the following variables:
# GR_TEST_TARGET_DEPS  - built targets for the library path
# GR_TEST_LIBRARY_DIRS - directories for the library path
# GR_TEST_PYTHON_DIRS  - directories for the Python path
# GR_TEST_ENVIRONS  - other environment key/value pairs
#
# New Way: Encloses ADD_TEST, with additional functionality to create
# a shell script that sets the environment to gain access to in-build
# binaries properly. The following variables are used to pass in
# settings:
#
# NAME           - the test name
# SOURCES        - sources for the test
# TARGET_DEPS    - build target dependencies (e.g., libraries)
# PYTHON_DIRS    - directories for the Python path
# EXTRA_LIB_DIRS - other directories for the library path
# ENVIRONS       - other environment key/value pairs
# ARGS           - arguments for the test
########################################################################
function(GR_ADD_TEST test_name)

    # parse the arguments for component names

    include(CMakeParseArgumentsCopy)
    cmake_parse_arguments(GR_TEST "" "" "SOURCES;TARGET_DEPS;PYTHON_DIRS;EXTRA_LIB_DIRS;ENVIRONS;ARGS" ${ARGN})

    # set the initial environs to use

    set(environs ${GR_TEST_ENVIRONS})
    list(APPEND environs
      "VOLK_GENERIC=1"
      "GR_DONT_LOAD_PREFS=1"
      "GR_CONF_CONTROLPORT_ON=False"
    )

    # set the source directory environment variable, which is mostly FYI

    file(TO_NATIVE_PATH ${CMAKE_CURRENT_SOURCE_DIR} srcdir)
    list(APPEND environs "srcdir=${srcdir}")

    # switch method used based on whether new or old, UNIX or not

    if(DEFINED GR_TEST_SOURCES)

      # New Way

      if(NOT UNIX)
	message(STATUS "Warning in GrTest::GR_ADD_TEST")
	message(STATUS "  Using new-style auto-dependencies on non-UNIX systems (e.g., Windows)")
	message(STATUS "  may or not work.  If not, please support GNU Radio by helping debug")
	message(STATUS "  this function on your OS.")
      endif()

      message(STATUS "GR_ADD_TEST: new style")

      # create the initial library path

      file(TO_NATIVE_PATH "${GR_TEST_EXTRA_LIB_DIRS}" libpath)

      if(APPLE)
        set(LD_PATH_VAR "DYLD_LIBRARY_PATH")
      else()
        set(LD_PATH_VAR "LD_LIBRARY_PATH")
      endif()

      # create a list of target directories to be determined by the
      # "add_test" command, via the $<FOO:BAR> operator; make sure the
      # test's directory is first, since it ($1) is prepended to PATH.

      unset(TARGET_DIR_LIST)
      foreach(target ${test_name} ${GR_TEST_TARGET_DEPS})
        message(STATUS "GR_ADD_TEST: target is '${target}'")
        list(APPEND TARGET_DIR_LIST "\$<TARGET_FILE_DIR:${target}>")
      endforeach()

      # augment the PATH to start with the directory of the test

      set(binpath "\"$1:\$PATH\"")
      list(APPEND environs "PATH=${binpath}")

      # set the shell to use

      if(CMAKE_CROSSCOMPILING)
        set(SHELL "/bin/sh")
      else()
        find_program(SHELL sh)
      endif()

      # check to see if the shell supports "$*" expansion with IFS

      if(NOT TESTED_SHELL_SUPPORTS_IFS)

        set(TESTED_SHELL_SUPPORTS_IFS TRUE CACHE BOOL "")
        set(sh_file ${CMAKE_CURRENT_BINARY_DIR}/ifs_test.sh)
        file(WRITE ${sh_file} "#!${SHELL}\n")
        file(APPEND ${sh_file} "export IFS=:\n")
        file(APPEND ${sh_file} "echo \"$*\"\n")
        # make the shell file executable
        execute_process(COMMAND chmod +x ${sh_file})

        # execute the shell script
        execute_process(COMMAND ${sh_file} "a" "b" "c"
          OUTPUT_VARIABLE output OUTPUT_STRIP_TRAILING_WHITESPACE
        )

        # check the output to see if it is correct
        string(COMPARE EQUAL ${output} "a:b:c" SHELL_SUPPORTS_IFS)
        set(SHELL_SUPPORTS_IFS ${SHELL_SUPPORTS_IFS} CACHE BOOL
          "Set this value to TRUE if the shell supports IFS argument expansion"
        )

      endif()

      unset(testlibpath)

      if(SHELL_SUPPORTS_IFS)

        # "$*" expands in the shell into a list of all of the
        # arguments to the shell script, concatenated using the
        # character provided in ${IFS}.
        list(APPEND testlibpath "$*")

      else()

        # shell does not support IFS expansion; use a loop instead
        list(APPEND testlibpath "\${LL}")

      endif()

      # finally: add in the current library path variable

      list(INSERT libpath 0 ${testlibpath})
      list(APPEND libpath "$${LD_PATH_VAR}")

      # replace list separator with the path separator

      string(REPLACE ";" ":" libpath "${libpath}")
      list(APPEND environs "${LD_PATH_VAR}=\"${libpath}\"")

      # generate a shell script file that sets the environment
      # and runs the test.

      set(sh_file ${CMAKE_CURRENT_BINARY_DIR}/${test_name}_test.sh)
      file(WRITE ${sh_file} "#!${SHELL}\n")
      if(SHELL_SUPPORTS_IFS)
        file(APPEND ${sh_file} "export IFS=:\n")
      else()
        file(APPEND ${sh_file} "LL=\"$1\" && for tf in \"\$@\"; do LL=\"\${LL}:\${tf}\"; done\n")
      endif()

      # each line sets an environment variable

      foreach(environ ${environs})
        file(APPEND ${sh_file} "export ${environ}\n")
      endforeach(environ)

      # redo the test args to have a space between each

      string(REPLACE ";" " " GR_TEST_ARGS "${GR_TEST_ARGS}")

      # finally: append the test name to execute

      file(APPEND ${sh_file} ${test_name} " " ${GR_TEST_ARGS} "\n")

      # make the shell file executable

      execute_process(COMMAND chmod +x ${sh_file})

      # add the test executable

      add_executable(${test_name} ${GR_TEST_SOURCES})

      # and add target dependencies

      target_link_libraries(${test_name} ${GR_TEST_TARGET_DEPS})

      # add the shell file as the test to execute;
      # use the form that allows for $<FOO:BAR> substitutions,
      # then combine the script arguments inside the script.

      add_test(NAME qa_${test_name}
        COMMAND ${SHELL} ${sh_file} ${TARGET_DIR_LIST}
      )

    else()

      # Old Way
      message(STATUS "GR_ADD_TEST: old style")

      #Ensure that the build exe also appears in the PATH.
      list(APPEND GR_TEST_TARGET_DEPS ${ARGN})

      #In the land of windows, all libraries must be in the PATH.
      #Since the dependent libraries are not yet installed,
      #we must manually set them in the PATH to run tests.
      #The following appends the path of a target dependency.
      foreach(target ${GR_TEST_TARGET_DEPS})
        message(STATUS "GR_ADD_TEST: target is '${target}'")
        get_target_property(location ${target} LOCATION)
        if(location)
          get_filename_component(path ${location} PATH)
          string(REGEX REPLACE "\\$\\(.*\\)" ${CMAKE_BUILD_TYPE} path ${path})
          list(APPEND GR_TEST_LIBRARY_DIRS ${path})
        endif(location)
      endforeach(target)

    if(WIN32)
        #SWIG generates the python library files into a subdirectory.
        #Therefore, we must append this subdirectory into PYTHONPATH.
        #Only do this for the python directories matching the following:
        foreach(pydir ${GR_TEST_PYTHON_DIRS})
            get_filename_component(name ${pydir} NAME)
            if(name MATCHES "^(swig|lib|src)$")
                list(APPEND GR_TEST_PYTHON_DIRS ${pydir}/${CMAKE_BUILD_TYPE})
            endif()
        endforeach(pydir)
    endif(WIN32)

    file(TO_NATIVE_PATH ${CMAKE_CURRENT_SOURCE_DIR} srcdir)
    file(TO_NATIVE_PATH "${GR_TEST_LIBRARY_DIRS}" libpath) #ok to use on dir list?
    file(TO_NATIVE_PATH "${GR_TEST_PYTHON_DIRS}" pypath) #ok to use on dir list?

    #http://www.cmake.org/pipermail/cmake/2009-May/029464.html
    #Replaced this add test + set environs code with the shell script generation.
    #Its nicer to be able to manually run the shell script to diagnose problems.
    #ADD_TEST(${ARGV})
    #SET_TESTS_PROPERTIES(${test_name} PROPERTIES ENVIRONMENT "${environs}")

    if(UNIX)
        set(LD_PATH_VAR "LD_LIBRARY_PATH")
        if(APPLE)
            set(LD_PATH_VAR "DYLD_LIBRARY_PATH")
        endif()

        set(binpath "${CMAKE_CURRENT_BINARY_DIR}:$PATH")
        list(APPEND libpath "$${LD_PATH_VAR}")
        list(APPEND pypath "$PYTHONPATH")

        #replace list separator with the path separator
        string(REPLACE ";" ":" libpath "${libpath}")
        string(REPLACE ";" ":" pypath "${pypath}")
        list(APPEND environs "PATH=${binpath}" "${LD_PATH_VAR}=${libpath}" "PYTHONPATH=${pypath}")

        #generate a bat file that sets the environment and runs the test
        if (CMAKE_CROSSCOMPILING)
                set(SHELL "/bin/sh")
        else(CMAKE_CROSSCOMPILING)
                find_program(SHELL sh)
        endif(CMAKE_CROSSCOMPILING)
        set(sh_file ${CMAKE_CURRENT_BINARY_DIR}/${test_name}_test.sh)
        file(WRITE ${sh_file} "#!${SHELL}\n")
        #each line sets an environment variable
        foreach(environ ${environs})
            file(APPEND ${sh_file} "export ${environ}\n")
        endforeach(environ)
        #load the command to run with its arguments
        foreach(arg ${ARGN})
            file(APPEND ${sh_file} "${arg} ")
        endforeach(arg)
        file(APPEND ${sh_file} "\n")

        #make the shell file executable
        execute_process(COMMAND chmod +x ${sh_file})

        add_test(${test_name} ${SHELL} ${sh_file})

    endif(UNIX)

    if(WIN32)
        list(APPEND libpath ${DLL_PATHS} "%PATH%")
        list(APPEND pypath "%PYTHONPATH%")

        #replace list separator with the path separator (escaped)
        string(REPLACE ";" "\\;" libpath "${libpath}")
        string(REPLACE ";" "\\;" pypath "${pypath}")
        list(APPEND environs "PATH=${libpath}" "PYTHONPATH=${pypath}")

        #generate a bat file that sets the environment and runs the test
        set(bat_file ${CMAKE_CURRENT_BINARY_DIR}/${test_name}_test.bat)
        file(WRITE ${bat_file} "@echo off\n")
        #each line sets an environment variable
        foreach(environ ${environs})
            file(APPEND ${bat_file} "SET ${environ}\n")
        endforeach(environ)
        #load the command to run with its arguments
        foreach(arg ${ARGN})
            file(APPEND ${bat_file} "${arg} ")
        endforeach(arg)
        file(APPEND ${bat_file} "\n")

        add_test(${test_name} ${bat_file})
    endif(WIN32)
  endif()
endfunction(GR_ADD_TEST)
