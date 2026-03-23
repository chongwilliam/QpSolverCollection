cmake_minimum_required(VERSION 3.14)
project(qp_solver_collection)

# Options for solvers
option(DEFAULT_ENABLE_ALL "Enable all QP solvers by default" OFF)
set(DEFAULT_ENABLE_VALUE ${DEFAULT_ENABLE_ALL})

option(ENABLE_QLD "Enable QLD" OFF)
option(ENABLE_QUADPROG "Enable QuadProg" OFF)
option(ENABLE_LSSOL "Enable LSSOL" OFF)
option(ENABLE_JRLQP "Enable JRLQP" OFF)
option(ENABLE_QPOASES "Enable qpOASES" OFF)
option(ENABLE_OSQP "Enable OSQP" OFF) 
option(ENABLE_NASOQ "Enable NASOQ" OFF)
option(ENABLE_HPIPM "Enable HPIPM" OFF)
option(ENABLE_PROXQP "Enable PROXQP" ON)
option(ENABLE_QPMAD "Enable QPMAD" OFF)

# Build/performance options
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  set(CMAKE_BUILD_TYPE "Release" CACHE STRING "Build type" FORCE)
endif()

option(ENABLE_NATIVE_OPTIMIZATION "Enable CPU-specific optimizations like -march=native" ON)
option(ENABLE_FAST_MATH "Enable aggressive floating-point optimizations" OFF)
option(ENABLE_IPO "Enable interprocedural optimization / LTO in Release builds" ON)

include(CheckCXXCompilerFlag)

set(QSC_NATIVE_OPT_FLAG "")
if(ENABLE_NATIVE_OPTIMIZATION)
  foreach(_candidate_flag "-march=native" "-mcpu=native")
    string(REPLACE "-" "_" _flag_var "${_candidate_flag}")
    string(REPLACE "=" "_" _flag_var "${_flag_var}")
    check_cxx_compiler_flag("${_candidate_flag}" "QSC_SUPPORTS${_flag_var}")
    if(QSC_SUPPORTS${_flag_var})
      set(QSC_NATIVE_OPT_FLAG "${_candidate_flag}")
      break()
    endif()
  endforeach()
endif()

if(CMAKE_CXX_COMPILER_ID MATCHES "Clang|GNU")
  add_compile_options(
    "$<$<CONFIG:Release>:-O3>"
    "$<$<CONFIG:Release>:-DNDEBUG>"
    "$<$<AND:$<CONFIG:Release>,$<BOOL:${QSC_NATIVE_OPT_FLAG}>>:${QSC_NATIVE_OPT_FLAG}>"
    "$<$<AND:$<CONFIG:Release>,$<BOOL:${ENABLE_FAST_MATH}>>:-ffast-math>"
  )
elseif(MSVC)
  add_compile_options(
    "$<$<CONFIG:Release>:/O2>"
    "$<$<CONFIG:Release>:/DNDEBUG>"
    "$<$<AND:$<CONFIG:Release>,$<BOOL:${ENABLE_FAST_MATH}>>:/fp:fast>"
  )
endif()

if(ENABLE_IPO)
  include(CheckIPOSupported)
  check_ipo_supported(RESULT ipo_supported OUTPUT ipo_output)
  if(ipo_supported)
    set(CMAKE_INTERPROCEDURAL_OPTIMIZATION_RELEASE ON)
  else()
    message(STATUS "IPO/LTO not enabled: ${ipo_output}")
  endif()
endif()

set(QPOASES_INCLUDE_DIR /usr/local/include)
set(QPOASES_LIBRARY_DIR /usr/local/lib)
# add_definitions(-DQP_SOLVER_COLLECTION_STANDALONE)

option(FORCE_ALL_SOLVER_TEST "Test for all solvers regardless of options" OFF)
mark_as_advanced(FORCE FORCE_ALL_SOLVER_TEST)

option(SKIP_PRIVATE_SOLVER_TEST "Skip private solver test" OFF)
mark_as_advanced(FORCE SKIP_PRIVATE_SOLVER_TEST)

option(BUILD_SHARED_LIBS "Build libraries as shared as opposed to static" ON)

if(NOT USE_ROS2)
  option(BUILD_TESTING "Build test" OFF)
  if(BUILD_TESTING)
    enable_testing()
  endif()
  include(GNUInstallDirs)
  # Place output artifacts all in the same directory to siplify running tests on Windows
  set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${CMAKE_INSTALL_BINDIR}")
  set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${CMAKE_INSTALL_LIBDIR}")
  set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${CMAKE_INSTALL_LIBDIR}")
endif()

# To build shared libraries in Windows, we set CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS to TRUE.
# See https://cmake.org/cmake/help/v3.4/variable/CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS.html
# See https://blog.kitware.com/create-dlls-on-windows-without-declspec-using-new-cmake-export-all-feature/
set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS ON)

# Eigen
find_package(Eigen3 REQUIRED)
include_directories(${EIGEN3_INCLUDE_DIR})

set(EXIST_ENABLED_SOLVER FALSE)
macro(add_qp_solver _SOLVER_NAME)
  if(${ENABLE_${_SOLVER_NAME}})
    foreach(_PACKAGE_NAME ${ARGN})
      find_package(${_PACKAGE_NAME} REQUIRED)
    endforeach()
    set(EXIST_ENABLED_SOLVER TRUE)
  endif()
  message(NOTICE "- ENABLE_${_SOLVER_NAME}: ${ENABLE_${_SOLVER_NAME}}")
endmacro()

# eigen-qld
add_qp_solver(QLD eigen-qld)

# eigen-quadprog
add_qp_solver(QUADPROG eigen-quadprog)

# eigen-lssol
add_qp_solver(LSSOL eigen-lssol)

# JRLQP
add_qp_solver(JRLQP jrl-qp)

# qpOASES
add_qp_solver(QPOASES)

# OsqpEigen
add_qp_solver(OSQP OsqpEigen)

# NASOQ
add_qp_solver(NASOQ nasoq)

# HPIPM
add_qp_solver(HPIPM blasfeo hpipm)

# PROXQP
add_qp_solver(PROXQP proxsuite)

# QPMAD
add_qp_solver(QPMAD qpmad)

if(NOT ${EXIST_ENABLED_SOLVER})
  message(FATAL_ERROR "None of the QP solvers are enabled. Enable at least one QP solver.")
endif()

if(USE_ROS2)
  find_package(ament_cmake REQUIRED)
  find_package(rclcpp REQUIRED)
endif()

set(QP_SOLVER_OPTIONS_HEADER_FILE "${PROJECT_SOURCE_DIR}/include/qp_solver_collection/QpSolverOptions.h")
configure_file("${QP_SOLVER_OPTIONS_HEADER_FILE}.in" "${QP_SOLVER_OPTIONS_HEADER_FILE}")

set(QP_SOLVER_OPTIONS_CMAKE_FILE "${PROJECT_SOURCE_DIR}/cmake/qp_solver_options.cmake")
configure_file("${QP_SOLVER_OPTIONS_CMAKE_FILE}.in" "${QP_SOLVER_OPTIONS_CMAKE_FILE}")

add_subdirectory(src)

if(NOT USE_ROS2)
  install(EXPORT ${PROJECT_NAME}
    FILE ${PROJECT_NAME}Targets.cmake
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}
    NAMESPACE ${PROJECT_NAME}::
    )

  # Write initial config cmake file
  file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/Config.cmake.in"
"
\@PACKAGE_INIT\@

include(\"\${CMAKE_CURRENT_LIST_DIR}/\@PROJECT_NAME\@Targets.cmake\")
include(\"\${CMAKE_CURRENT_LIST_DIR}/qp_solver_options.cmake\")

set(\@PROJECT_NAME\@_LIBRARIES \@PROJECT_NAME\@::QpSolverCollection)
")

  include(CMakePackageConfigHelpers)
  # generate the config file that is includes the exports
  configure_package_config_file(${CMAKE_CURRENT_BINARY_DIR}/Config.cmake.in
    "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
    INSTALL_DESTINATION "lib/cmake/${PROJECT_NAME}"
    NO_SET_AND_CHECK_MACRO
    NO_CHECK_REQUIRED_COMPONENTS_MACRO
    )

  # generate the version file for the config file
  # Extract version numbers from package.xml
  file(READ package.xml PACKAGE_XML)
  string(REGEX MATCH "<version>[0-9]+\\.[0-9]+\\.[0-9]+</version>" DIRTY_VERSION_STRING ${PACKAGE_XML})
  string(REGEX REPLACE "^<version>([0-9]+)\\.([0-9]+)\\.([0-9]+)</version>$" "\\1" OSC_MAJOR_VERSION "${DIRTY_VERSION_STRING}")
  string(REGEX REPLACE "^<version>([0-9]+)\\.([0-9]+)\\.([0-9]+)</version>$" "\\2" QSC_MINOR_VERSION "${DIRTY_VERSION_STRING}")
  string(REGEX REPLACE "^<version>([0-9]+)\\.([0-9]+)\\.([0-9]+)</version>$" "\\3" QSC_PATCH_VERSION "${DIRTY_VERSION_STRING}")
  write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
    VERSION "${QSC_MAJOR_VERSION}.${QSC_MINOR_VERSION}.${QSC_PATCH_VERSION}"
    COMPATIBILITY AnyNewerVersion
    )

  # install config files
  install(FILES
    "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
    "${QP_SOLVER_OPTIONS_CMAKE_FILE}"
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}
    )
endif()

if(BUILD_TESTING)
  add_subdirectory(tests)
endif()

OPTION(INSTALL_DOCUMENTATION "Generate and install the documentation" OFF)
if(INSTALL_DOCUMENTATION)
  add_subdirectory(doc)
endif()

if(USE_ROS2)
  ament_export_include_directories(include)
  ament_export_dependencies(
    rclcpp
    Eigen3
  )
  ament_export_targets(${PROJECT_NAME} HAS_LIBRARY_TARGET)
  ament_package()
endif()
