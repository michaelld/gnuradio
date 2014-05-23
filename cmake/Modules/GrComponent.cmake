# Copyright 2010-2011 Free Software Foundation, Inc.
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

if(DEFINED __INCLUDED_GR_COMPONENT_CMAKE)
    return()
endif()
set(__INCLUDED_GR_COMPONENT_CMAKE TRUE)

set(_gr_enabled_components "" CACHE INTERNAL "" FORCE)
set(_gr_enabled_component_vars "" CACHE INTERNAL "" FORCE)
set(_gr_disabled_components "" CACHE INTERNAL "" FORCE)

if(NOT DEFINED ENABLE_DEFAULT)
    set(ENABLE_DEFAULT ON)
    message(STATUS "")
    message(STATUS "The build system will automatically enable all components.")
    message(STATUS "Use -DENABLE_DEFAULT=OFF to disable components by default.")
endif()

########################################################################
# Register a component into the system
# - name: canonical component name
# - var: variable for enabled status
# - argn: list of dependencies, both in-build and out-of-build
########################################################################
function(GR_REGISTER_COMPONENT name var)

    string(TOLOWER ${name} name)

    # is this a test?
    string(REGEX MATCH "^test" name_has_test ${name})
    if(NOT "${name_has_test}" STREQUAL "")
        set(is_test TRUE)
    else()
        set(is_test FALSE)
    endif()

    if(NOT is_test)
        include(CMakeDependentOption)
        message(STATUS "")
        message(STATUS "Configuring ${name} support...")
        foreach(dep ${ARGN})
            message(STATUS "  Dependency ${dep} = ${${dep}}")
        endforeach(dep)
    endif()

    #if the user set the var to force, we note this
    if("${${var}}" STREQUAL "FORCE")
        set(${var} ON)
        set(var_force TRUE)
    else()
        set(var_force FALSE)
    endif()

    # is this an actual GR component, or just a dependency?  Assume
    # that actual components begin with "gr" or "gnuradio" or "volk"

    string(REGEX MATCH "^(gr|gnuradio|volk)" name_has_gr ${name})
    if(NOT "${name_has_gr}" STREQUAL "")
        set(is_component TRUE)
    else()
        set(is_component FALSE)
    endif()

    # rewrite the dependency list so that deps that are
    # also components use the cached version

    unset(comp_deps)
    unset(internal_deps)
    unset(external_deps)
    foreach(dep ${ARGN})
        set(dep_enb_index -1)
        set(dep_dis_index -1)
        if(NOT ${${dep}_NAME} STREQUAL "")
            list(FIND _gr_enabled_components ${${dep}_NAME} dep_enb_index)
            list(FIND _gr_disabled_components ${${dep}_NAME} dep_dis_index)
        endif()
        if(${dep_enb_index} EQUAL -1 AND ${dep_dis_index} EQUAL -1)
            list(APPEND comp_deps ${dep})
        else()
            list(APPEND comp_deps ${dep}_cached) #is a component, use cached version
        endif()
        list(FIND _gr_enabled_component_vars ${dep} dep_enb_index)
        if(${dep_enb_index} EQUAL -1)
            list(APPEND external_deps ${dep})
        else()
            list(APPEND internal_deps ${dep})
        endif()
    endforeach(dep)

    # setup the dependent option for this component

    CMAKE_DEPENDENT_OPTION(${var} "enable ${name} support" 
        ${ENABLE_DEFAULT} "${comp_deps}" OFF)
    set(${var} "${${var}}" PARENT_SCOPE)
    set(${var}_cached "${${var}}" CACHE INTERNAL "" FORCE)
    set(${var}_NAME ${name} CACHE INTERNAL "" FORCE)

    # recursively add to internal deps to get all internal deps

    list(APPEND all_internal_deps ${internal_deps})
    list(LENGTH internal_deps len)
    while(NOT len EQUAL 0)
    	# get first item
        list(GET internal_deps 0 item)
        list(REMOVE_AT internal_deps 0)
        list(APPEND all_internal_deps ${${item}_INTERNAL_DEPS})
        list(APPEND internal_deps ${${dep}_INTERNAL_DEPS})
        list(LENGTH internal_deps len)
    endwhile()

    # sort and make internal deps unique

    list(LENGTH all_internal_deps len)
    if(NOT len EQUAL 0)
        list(REMOVE_DUPLICATES all_internal_deps)
        list(SORT all_internal_deps)
    endif()

    set(${var}_INTERNAL_DEPS "${all_internal_deps}" CACHE INTERNAL "" FORCE)
    set(${var}_EXTERNAL_DEPS "${external_deps}" CACHE INTERNAL "" FORCE)

    # force was specified, but the dependencies were not met

    if(NOT ${var} AND var_force)
        message(FATAL_ERROR "user force-enabled ${name} but configuration checked failed")
    endif()

    # append the component into one of the lists, if not a test

    if(NOT is_test)
        if(${var})
            message(STATUS "  Enabling ${name} support.")
            list(APPEND _gr_enabled_components ${name})
            if(is_component)
                list(APPEND _gr_enabled_component_vars ${var})
            endif()
        else(${var})
            message(STATUS "  Disabling ${name} support.")
            list(APPEND _gr_disabled_components ${name})
        endif(${var})
        message(STATUS "  Override with -D${var}=ON/OFF")
    endif()

    # make components lists into global variables

    set(_gr_enabled_components ${_gr_enabled_components} CACHE INTERNAL "" FORCE)
    set(_gr_enabled_component_vars ${_gr_enabled_component_vars} CACHE INTERNAL "" FORCE)
    set(_gr_disabled_components ${_gr_disabled_components} CACHE INTERNAL "" FORCE)

endfunction(GR_REGISTER_COMPONENT)

########################################################################
# Print the registered component summary
########################################################################
function(GR_PRINT_COMPONENT_SUMMARY)
    message(STATUS "")
    message(STATUS "######################################################")
    message(STATUS "# Gnuradio enabled components                         ")
    message(STATUS "######################################################")
    foreach(comp ${_gr_enabled_components})
        message(STATUS "  * ${comp}")
    endforeach(comp)

    message(STATUS "")
    message(STATUS "######################################################")
    message(STATUS "# Gnuradio disabled components                        ")
    message(STATUS "######################################################")
    foreach(comp ${_gr_disabled_components})
        message(STATUS "  * ${comp}")
    endforeach(comp)

    message(STATUS "")
endfunction(GR_PRINT_COMPONENT_SUMMARY)
