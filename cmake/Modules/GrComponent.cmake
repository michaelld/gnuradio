# Copyright 2010-2015 Free Software Foundation, Inc.
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
# NOTES:
# - If a component starts with "test-", then it will not be displayed
#   nor will a user-option be provided to disable it. In this way,
#   tests can be registered in the same way as normal components, and
#   then their VAR used to determine building the test or not.
# - Similarly, if the NAME starts with "gnuradio" or "gr" (and, "volk"
#   if doing an in-tree build), then it is considered an actual
#   component. Any other naming other than "test-" can use used, of
#   course, and any such naming will be printed out with an option to
#   enable/disable. But, those are considered "external" components,
#   while all the rest are "internal" components.  Internal components
#   form a dependency tree, allowing us to know the dependencies
#   internal and external just by following the tree.
########################################################################
function(GR_REGISTER_COMPONENT name var)

    string(TOLOWER ${name} name)

    ##### DEBUG
    message(STATUS "GR_REGISTER_COMPONENT: _gr_enabled_components was '${_gr_enabled_components}'")
    message(STATUS "GR_REGISTER_COMPONENT: _gr_enabled_component_vars was '${_gr_enabled_component_vars}'")
    message(STATUS "GR_REGISTER_COMPONENT: _gr_disabled_components was '${_gr_disabled_components}'")
    ##### /DEBUG

    # is this a test?

    string(REGEX MATCH "^test-" name_has_test ${name})
    if(NOT "${name_has_test}" STREQUAL "")
        set(IS_TEST TRUE)
    else()
        set(IS_TEST FALSE)
    endif()

    if(NOT IS_TEST)
        include(CMakeDependentOption)
        message(STATUS "")
        message(STATUS "Configuring ${name} support...")
        foreach(dep ${ARGN})
            message(STATUS "  Dependency ${dep} = ${${dep}}")
        endforeach(dep)
    endif(NOT IS_TEST)

    #if the user set the var to force on, we note this

    if("${${var}}" STREQUAL "ON")
        set(VAR_FORCE TRUE)
    else()
        set(VAR_FORCE FALSE)
    endif()

    # is this an actual GR component, or just a dependency?  Assume
    # that actual components begin with "gr" or "gnuradio" or "volk"

    if(INTREE_VOLK_FOUND)
      # volk is internal; it can be a component too
      set(COMPONENT_MATCH_STRING "^(gr|gnuradio|volk)")
    else()
      # volk is external; just match "gr" or "gnuradio"
      set(COMPONENT_MATCH_STRING "^(gr|gnuradio)")
    endif()
      
    string(REGEX MATCH ${COMPONENT_MATCH_STRING} name_has_gr ${name})
    if(NOT "${name_has_gr}" STREQUAL "")
        set(IS_COMPONENT TRUE)
    else()
        set(IS_COMPONENT FALSE)
    endif()

    ##### DEBUG
    message(STATUS "GR_REGISTER_COMPONENT: '${name}' is a test: ${IS_TEST}")
    message(STATUS "GR_REGISTER_COMPONENT: '${name}' is forced on: ${VAR_FORCE}")
    message(STATUS "GR_REGISTER_COMPONENT: '${name}' is a component: ${IS_COMPONENT}")
    ##### /DEBUG

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

    ##### DEBUG
    message(STATUS "GR_REGISTER_COMPONENT: var is '${var}'")
    message(STATUS "GR_REGISTER_COMPONENT: name is '${name}'")
    message(STATUS "GR_REGISTER_COMPONENT: \${var} set to '${${var}}'")
    message(STATUS "GR_REGISTER_COMPONENT: \${var}_INTERNAL_DEPS set to '${${var}_INTERNAL_DEPS}'")
    message(STATUS "GR_REGISTER_COMPONENT: \${var}_EXTERNAL_DEPS set to '${${var}_EXTERNAL_DEPS}'")
    message(STATUS "GR_REGISTER_COMPONENT: \${var}_cached set to '${${var}_cached}'")
    message(STATUS "GR_REGISTER_COMPONENT: \${var}_NAME set to '${${var}_NAME}'")
    ##### /DEBUG

    # force was specified, but the dependencies were not met

    if(NOT ${var} AND VAR_FORCE)
        message(FATAL_ERROR "user force-enabled ${name} but configuration checked failed")
    endif()

    # append the component into one of the lists, if not a test

    if(NOT IS_TEST)
        if(${var})
            message(STATUS "  Enabling ${name} support.")
            list(APPEND _gr_enabled_components ${name})
            if(IS_COMPONENT)
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

    ##### DEBUG
    message(STATUS "GR_REGISTER_COMPONENT: _gr_enabled_components set to '${_gr_enabled_components}'")
    message(STATUS "GR_REGISTER_COMPONENT: _gr_enabled_component_vars set to '${_gr_enabled_component_vars}'")
    message(STATUS "GR_REGISTER_COMPONENT: _gr_disabled_components set to '${_gr_disabled_components}'")
    ##### /DEBUG

endfunction(GR_REGISTER_COMPONENT)

function(GR_APPEND_SUBCOMPONENT name)
  list(APPEND _gr_enabled_components "* ${name}")
  set(_gr_enabled_components ${_gr_enabled_components} CACHE INTERNAL "" FORCE)
endfunction(GR_APPEND_SUBCOMPONENT name)

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
