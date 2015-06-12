#

#    FIND_PACKAGE_HANDLE_STANDARD_ARGS(<name> (DEFAULT_MSG|"Custom failure message") <var1>...<varN> )
#
#    FIND_PACKAGE_HANDLE_STANDARD_ARGS(NAME [FOUND_VAR <resultVar>]
#                                           [REQUIRED_VARS <var1>...<varN>]
#                                           [VERSION_VAR   <versionvar>]
#                                           [HANDLE_COMPONENTS]
#                                           [CONFIG_MODE]
#                                           [FAIL_MESSAGE "Custom failure message"] )

function(FIND_PACKAGE_HANDLE_STANDARD_ARGS _NAME _FIRST_ARG)

  message(STATUS "GR::FPHSA: _NAME is '${_NAME}'")
  message(STATUS "GR::FPHSA: _FIRST_ARG is '${_FIRST_ARG}'")
  message(STATUS "GR::FPHSA: \${ARGN} is '${ARGN}'")

  # save the current MODULE path

  set(SAVED_CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH})

  # clear the current MODULE path; uses system paths only; just in the
  # current context of this file.

  unset(CMAKE_MODULE_PATH)

  # pass on the function call to the cmake-provided one

  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(${_NAME} ${_FIRST_ARG} ${ARGN})

  # upon return, there were no fatal errors and the FOUND variable is
  # either true or false.
  
  # restore CMAKE_MODULE_PATH

  set(CMAKE_MODULE_PATH ${SAVED_CMAKE_MODULE_PATH})

  # do some post-handling of arguments, to make things work elsewhere
  # using auto-dependencies

  # set up the arguments for CMAKE_PARSE_ARGUMENTS and check whether we are in
  # new extended or in the "old" mode:

  set(options  CONFIG_MODE  HANDLE_COMPONENTS)
  set(oneValueArgs  FAIL_MESSAGE  VERSION_VAR  FOUND_VAR)
  set(multiValueArgs REQUIRED_VARS)
  set(_KEYWORDS_FOR_EXTENDED_MODE  ${options} ${oneValueArgs} ${multiValueArgs} )
  list(FIND _KEYWORDS_FOR_EXTENDED_MODE "${_FIRST_ARG}" INDEX)

  if(${INDEX} EQUAL -1)
    set(FPHSA_FOUND_VAR ${_NAME}_FOUND)
    set(FPHSA_REQUIRED_VARS ${ARGN})
  else()
    CMAKE_PARSE_ARGUMENTS(FPHSA "${options}" "${oneValueArgs}" "${multiValueArgs}"  ${_FIRST_ARG} ${ARGN})
  endif()

  message(STATUS "GR::FPHSA: FPHSA_FOUND_VAR is '${FPHSA_FOUND_VAR}'")
  message(STATUS "GR::FPHSA: FPHSA_REQUIRED_VARS is '${FPHSA_REQUIRED_VARS}'")
  if(${FPHSA_FOUND_VAR})
    message(STATUS "GR::FPHSA: '${_NAME}' was found.")

    # loop over all variables, try to match the _NAME (normal or
    # upper) with each, and if OK then create new cached variables
    # using the FPHSA_FOUND_VAR as a base, e.g.,
    # ${FPHSA_FOUND_VAR}_INCLUDE_DIRS. Do this for INCLUDE_DIRS,
    # LIBRARY_DIRS, and LIBRARIES.

    string(TOUPPER ${FPHSA_FOUND_VAR} FPHSA_FOUND_VAR_UPPER)
    foreach(_CURRENT_VAR ${FPHSA_REQUIRED_VARS})
      message(STATUS "GR::FPHSA: this var is '${_CURRENT_VAR}'")
      unset(_CV_NAME)
      string(TOUPPER ${_CURRENT_VAR} _CV_UPPER)
      list(APPEND COMP_LIST "INCLUDE_DIRS" "LIBRARY_DIRS" "LIBRARIES")
      foreach(_VAR ${COMP_LIST})
	string(FIND ${_CV_UPPER} ${_VAR} _CV_VAR_NDX)
	if(NOT ${_CV_VAR_NDX} EQUAL -1)
	  set(_CV_NAME ${_VAR})
	  break()
	endif()
      endforeach()
      if(_CV_NAME)
      	set(${FPHSA_FOUND_VAR_UPPER}_${_CV_NAME} ${${_CURRENT_VAR}} CACHE INTERNAL "" FORCE)
	message(STATUS "GR::FPHSA: set '${FPHSA_FOUND_VAR}_${_CV_NAME}' to be the value in '${_CURRENT_VAR}' ('${${_CURRENT_VAR}}')")
      endif()
    endforeach()
  else()
    message(STATUS "GR::FPHSA: '${_NAME}' was not found.")
  endif()

  # set FOUND variables

  string(TOUPPER ${_NAME} _NAME_UPPER)
  set(${_NAME}_FOUND ${${_NAME}_FOUND} CACHE INTERNAL "" FORCE)
  set(${_NAME_UPPER}_FOUND ${${_NAME}_FOUND} CACHE INTERNAL "" FORCE)

endfunction()
