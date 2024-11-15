include(cmake/SystemLink.cmake)
include(cmake/LibFuzzer.cmake)
include(CMakeDependentOption)
include(CheckCXXCompilerFlag)


macro(imgui_supports_sanitizers)
  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND NOT WIN32)
    set(SUPPORTS_UBSAN ON)
  else()
    set(SUPPORTS_UBSAN OFF)
  endif()

  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND WIN32)
    set(SUPPORTS_ASAN OFF)
  else()
    set(SUPPORTS_ASAN ON)
  endif()
endmacro()

macro(imgui_setup_options)
  option(imgui_ENABLE_HARDENING "Enable hardening" ON)
  option(imgui_ENABLE_COVERAGE "Enable coverage reporting" OFF)
  cmake_dependent_option(
    imgui_ENABLE_GLOBAL_HARDENING
    "Attempt to push hardening options to built dependencies"
    ON
    imgui_ENABLE_HARDENING
    OFF)

  imgui_supports_sanitizers()

  if(NOT PROJECT_IS_TOP_LEVEL OR imgui_PACKAGING_MAINTAINER_MODE)
    option(imgui_ENABLE_IPO "Enable IPO/LTO" OFF)
    option(imgui_WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
    option(imgui_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(imgui_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" OFF)
    option(imgui_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(imgui_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" OFF)
    option(imgui_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(imgui_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(imgui_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(imgui_ENABLE_CLANG_TIDY "Enable clang-tidy" OFF)
    option(imgui_ENABLE_CPPCHECK "Enable cpp-check analysis" OFF)
    option(imgui_ENABLE_PCH "Enable precompiled headers" OFF)
    option(imgui_ENABLE_CACHE "Enable ccache" OFF)
  else()
    option(imgui_ENABLE_IPO "Enable IPO/LTO" ON)
    # produce warning: optimization flag '-fno-fat-lto-objects' is not supported
    # option(imgui_ENABLE_IPO "Enable IPO/LTO" OFF)
    # option(imgui_WARNINGS_AS_ERRORS "Treat Warnings As Errors" ON)
    # suppress warning as error above
    option(imgui_WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
    option(imgui_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(imgui_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" ${SUPPORTS_ASAN})
    option(imgui_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(imgui_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" ${SUPPORTS_UBSAN})
    option(imgui_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(imgui_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(imgui_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(imgui_ENABLE_CLANG_TIDY "Enable clang-tidy" ON)
    option(imgui_ENABLE_CPPCHECK "Enable cpp-check analysis" ON)
    option(imgui_ENABLE_PCH "Enable precompiled headers" OFF)
    option(imgui_ENABLE_CACHE "Enable ccache" ON)
  endif()

  if(NOT PROJECT_IS_TOP_LEVEL)
    mark_as_advanced(
      imgui_ENABLE_IPO
      imgui_WARNINGS_AS_ERRORS
      imgui_ENABLE_USER_LINKER
      imgui_ENABLE_SANITIZER_ADDRESS
      imgui_ENABLE_SANITIZER_LEAK
      imgui_ENABLE_SANITIZER_UNDEFINED
      imgui_ENABLE_SANITIZER_THREAD
      imgui_ENABLE_SANITIZER_MEMORY
      imgui_ENABLE_UNITY_BUILD
      imgui_ENABLE_CLANG_TIDY
      imgui_ENABLE_CPPCHECK
      imgui_ENABLE_COVERAGE
      imgui_ENABLE_PCH
      imgui_ENABLE_CACHE)
  endif()

  imgui_check_libfuzzer_support(LIBFUZZER_SUPPORTED)
  if(LIBFUZZER_SUPPORTED AND (imgui_ENABLE_SANITIZER_ADDRESS OR imgui_ENABLE_SANITIZER_THREAD OR imgui_ENABLE_SANITIZER_UNDEFINED))
    set(DEFAULT_FUZZER ON)
  else()
    set(DEFAULT_FUZZER OFF)
  endif()

  option(imgui_BUILD_FUZZ_TESTS "Enable fuzz testing executable" ${DEFAULT_FUZZER})

endmacro()

macro(imgui_global_options)
  if(imgui_ENABLE_IPO)
    include(cmake/InterproceduralOptimization.cmake)
    imgui_enable_ipo()
  endif()

  imgui_supports_sanitizers()

  if(imgui_ENABLE_HARDENING AND imgui_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR imgui_ENABLE_SANITIZER_UNDEFINED
       OR imgui_ENABLE_SANITIZER_ADDRESS
       OR imgui_ENABLE_SANITIZER_THREAD
       OR imgui_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    message("${imgui_ENABLE_HARDENING} ${ENABLE_UBSAN_MINIMAL_RUNTIME} ${imgui_ENABLE_SANITIZER_UNDEFINED}")
    imgui_enable_hardening(imgui_options ON ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()
endmacro()

macro(imgui_local_options)
  if(PROJECT_IS_TOP_LEVEL)
    include(cmake/StandardProjectSettings.cmake)
  endif()

  add_library(imgui_warnings INTERFACE)
  add_library(imgui_options INTERFACE)

  include(cmake/CompilerWarnings.cmake)
  imgui_set_project_warnings(
    imgui_warnings
    ${imgui_WARNINGS_AS_ERRORS}
    ""
    ""
    ""
    "")

  if(imgui_ENABLE_USER_LINKER)
    include(cmake/Linker.cmake)
    imgui_configure_linker(imgui_options)
  endif()

  include(cmake/Sanitizers.cmake)
  imgui_enable_sanitizers(
    imgui_options
    ${imgui_ENABLE_SANITIZER_ADDRESS}
    ${imgui_ENABLE_SANITIZER_LEAK}
    ${imgui_ENABLE_SANITIZER_UNDEFINED}
    ${imgui_ENABLE_SANITIZER_THREAD}
    ${imgui_ENABLE_SANITIZER_MEMORY})

  set_target_properties(imgui_options PROPERTIES UNITY_BUILD ${imgui_ENABLE_UNITY_BUILD})

  if(imgui_ENABLE_PCH)
    target_precompile_headers(
      imgui_options
      INTERFACE
      <vector>
      <string>
      <utility>)
  endif()

  if(imgui_ENABLE_CACHE)
    include(cmake/Cache.cmake)
    imgui_enable_cache()
  endif()

  include(cmake/StaticAnalyzers.cmake)
  if(imgui_ENABLE_CLANG_TIDY)
    imgui_enable_clang_tidy(imgui_options ${imgui_WARNINGS_AS_ERRORS})
  endif()

  if(imgui_ENABLE_CPPCHECK)
    imgui_enable_cppcheck(${imgui_WARNINGS_AS_ERRORS} "" # override cppcheck options
    )
  endif()

  if(imgui_ENABLE_COVERAGE)
    include(cmake/Tests.cmake)
    imgui_enable_coverage(imgui_options)
  endif()

  if(imgui_WARNINGS_AS_ERRORS)
    check_cxx_compiler_flag("-Wl,--fatal-warnings" LINKER_FATAL_WARNINGS)
    if(LINKER_FATAL_WARNINGS)
      # This is not working consistently, so disabling for now
      # target_link_options(imgui_options INTERFACE -Wl,--fatal-warnings)
    endif()
  endif()

  if(imgui_ENABLE_HARDENING AND NOT imgui_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR imgui_ENABLE_SANITIZER_UNDEFINED
       OR imgui_ENABLE_SANITIZER_ADDRESS
       OR imgui_ENABLE_SANITIZER_THREAD
       OR imgui_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    imgui_enable_hardening(imgui_options OFF ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()

endmacro()
