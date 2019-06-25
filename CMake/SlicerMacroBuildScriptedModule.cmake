################################################################################
#
#  Program: 3D Slicer
#
#  Copyright (c) Kitware Inc.
#
#  See COPYRIGHT.txt
#  or http://www.slicer.org/copyright/copyright.txt for details.
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
#  This file was originally developed by Jean-Christophe Fillion-Robin, Kitware Inc.
#  and was partially funded by NIH grant 3P41RR013218-12S1
#
################################################################################

macro(slicerMacroBuildScriptedModule)
  set(options
    WITH_GENERIC_TESTS
    WITH_SUBDIR
    VERBOSE
    )
  set(oneValueArgs
    NAME
    )
  set(multiValueArgs
    SCRIPTS
    RESOURCES
    )
  cmake_parse_arguments(MY_SLICER
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
    )

  message(STATUS "Configuring Scripted module: ${MY_SLICER_NAME}")

  # --------------------------------------------------------------------------
  # Print information helpful for debugging checks
  # --------------------------------------------------------------------------
  if(MY_SLICER_VERBOSE)
    list(APPEND ALL_OPTIONS ${options} ${oneValueArgs} ${multiValueArgs})
    foreach(curr_opt ${ALL_OPTIONS})
      message(STATUS "${curr_opt} = ${MY_SLICER_${curr_opt}}")
    endforeach()
  endif()

  # --------------------------------------------------------------------------
  # Sanity checks
  # --------------------------------------------------------------------------
  if(MY_SLICER_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "Unknown keywords given to slicerMacroBuildScriptedModule(): \"${MY_SLICER_UNPARSED_ARGUMENTS}\"")
  endif()

  if(NOT DEFINED MY_SLICER_NAME)
    message(FATAL_ERROR "NAME is mandatory")
  endif()

  set(expected_existing_vars SCRIPTS RESOURCES)
  foreach(var ${expected_existing_vars})
    foreach(value ${MY_SLICER_${var}})
      if(NOT IS_ABSOLUTE ${value})
        set(value_absolute ${CMAKE_CURRENT_SOURCE_DIR}/${value})
      else()
        set(value_absolute ${value})
      endif()
      if(NOT EXISTS ${value_absolute} AND NOT EXISTS ${value_absolute}.py)
        if(NOT IS_ABSOLUTE ${value})
          set(value_absolute ${CMAKE_CURRENT_BINARY_DIR}/${value})
        endif()
        get_source_file_property(is_generated ${value_absolute} GENERATED)
        if(NOT is_generated)
          message(FATAL_ERROR
            "slicerMacroBuildScriptedModule(${var}) given nonexistent"
            " file or directory '${value}'")
        endif()
      endif()
    endforeach()
  endforeach()

  if(NOT Slicer_USE_PYTHONQT)
      message(FATAL_ERROR
        "Attempting to build the Python scripted module '${MY_SLICER_NAME}'"
        " when Slicer_USE_PYTHONQT is OFF")
  endif()

  set(_no_install_subdir_option NO_INSTALL_SUBDIR)
  set(_destination_subdir "")
  if(MY_SLICER_WITH_SUBDIR)
    get_filename_component(_destination_subdir ${CMAKE_CURRENT_SOURCE_DIR} NAME)
    set(_destination_subdir "/${_destination_subdir}")
    set(_no_install_subdir_option "")
  endif()

  #--------------------------------------------------------------------------
  # Translation
  # --------------------------------------------------------------------------

  if(Slicer_BUILD_I18N_SUPPORT)
    message(STATUS "  Slicer_BUILD_I18N_SUPPORT")
    message(STATUS "  Available module translations: ${Slicer_UPDATE_TRANSLATION}")
    message(STATUS "Language: '${Slicer_LANGUAGES}' ")

    set(TS_DIR "${CMAKE_CURRENT_SOURCE_DIR}/Resources/Translations/")
    message(STATUS "TS_DIR: '${TS_DIR}' ")

    get_property(Slicer_LANGUAGES GLOBAL PROPERTY Slicer_LANGUAGES)

    # Lookup loadable module translation files
    set(_available_ts_languages "")
    foreach(language ${Slicer_LANGUAGES})
      set(_expected_ts_file "${TS_DIR}${LOADABLEMODULE_NAME}_${language}.ts")
      if(EXISTS "${_expected_ts_file}")
        list(APPEND _available_ts_languages ${language})
      endif()
    endforeach()

    if(NOT _available_ts_languages STREQUAL "")
      message(STATUS "  Generating the files *.ts: '${Slicer_LANGUAGES}'")

      set(tr_input_scripts)
      set(rewrite_script "C:/D/pythonScripts/I18n_python/RewriteTr.py")

      foreach(python_script IN ITEMS ${MY_SLICER_SCRIPTS})
        message(STATUS "Rewriting ${python_script} with QT_TRANSLATE_NOOP")
        if(IS_ABSOLUTE ${python_script})
          message(STATUS "Ignoring [${python_script}]")
          continue()
        endif()

        set(input_python_script ${CMAKE_CURRENT_SOURCE_DIR}/${python_script})

        get_filename_component(script_ext ${input_python_script} EXT)
        if(NOT script_ext STREQUAL ".py")
          set(input_python_script "${input_python_script}.py")
        endif()

        set(python_tr_script "${CMAKE_CURRENT_BINARY_DIR}/${python_script}.tr")

        execute_process(
          COMMAND ${PYTHON_EXECUTABLE}
            ${rewrite_script} -i ${input_python_script}  -o ${python_tr_script}
          RESULT_VARIABLE result
          )
        if(NOT result EQUAL 0)
          message(FATAL_ERROR "Failed to process ${input_python_script} using RewriteTr.py")
        endif()
        list(APPEND tr_input_scripts ${python_tr_script})
      endforeach()
      message(STATUS  "Slicer_INSTALL_QM_DIR is ${Slicer_INSTALL_QM_DIR}")

      set(SCRIPTEDMODULE_UI_SRCS "")
      include(SlicerMacroTranslation)
      SlicerMacroTranslation(
        SRCS ${tr_input_scripts}
        UI_SRCS ${SCRIPTEDMODULE_UI_SRCS}
        TS_DIR ${TS_DIR}
        TS_BASEFILENAME ${MY_SLICER_NAME}
        TS_LANGUAGES ${Slicer_LANGUAGES}
        QM_OUTPUT_DIR_VAR QM_OUTPUT_DIR
        QM_OUTPUT_FILES_VAR QM_OUTPUT_FILES
        )

      # store the paths where the qm files are located
      set_property(GLOBAL APPEND PROPERTY Slicer_QM_OUTPUT_DIRS ${QM_OUTPUT_DIR})

      set_property(GLOBAL APPEND PROPERTY QMTSFiles ${QM_OUTPUT_DIR})
        message(STATUS "   QM_OUTPUT_DIR_VAR is ${QM_OUTPUT_DIR}")
        message(STATUS "   QM_OUTPUT_FILES is '${QM_OUTPUT_FILES}'")

        if(MY_SLICER_NAME STREQUAL "Endoscopy")
        add_custom_target(Generate${MY_SLICER_NAME}QmFiles
          DEPENDS ${QM_OUTPUT_FILES}
          )
      endif()

   endif()
  endif()

  ctkMacroCompilePythonScript(
    TARGET_NAME ${MY_SLICER_NAME}
    SCRIPTS "${MY_SLICER_SCRIPTS}"
    RESOURCES "${MY_SLICER_RESOURCES}"
    DESTINATION_DIR ${CMAKE_BINARY_DIR}/${Slicer_QTSCRIPTEDMODULES_LIB_DIR}${_destination_subdir}
    INSTALL_DIR ${Slicer_INSTALL_QTSCRIPTEDMODULES_LIB_DIR}
    ${_no_install_subdir_option}
    )

  if(BUILD_TESTING AND MY_SLICER_WITH_GENERIC_TESTS)
    set(_generic_unitest_scripts)
    SlicerMacroConfigureGenericPythonModuleTests("${MY_SLICER_NAME}" _generic_unitest_scripts)

    foreach(script_name ${_generic_unitest_scripts})
      slicer_add_python_unittest(
        SCRIPT ${script_name}
        SLICER_ARGS --no-main-window --disable-cli-modules
                    --additional-module-path ${CMAKE_BINARY_DIR}/${Slicer_QTSCRIPTEDMODULES_LIB_DIR}
        TESTNAME_PREFIX nomainwindow_
        )
    endforeach()
  endif()

endmacro()