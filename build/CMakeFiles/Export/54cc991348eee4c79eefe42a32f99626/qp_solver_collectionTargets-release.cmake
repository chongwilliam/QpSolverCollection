#----------------------------------------------------------------
# Generated CMake target import file for configuration "Release".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "qp_solver_collection::QpSolverCollection" for configuration "Release"
set_property(TARGET qp_solver_collection::QpSolverCollection APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(qp_solver_collection::QpSolverCollection PROPERTIES
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/libQpSolverCollection.dylib"
  IMPORTED_SONAME_RELEASE "@rpath/libQpSolverCollection.dylib"
  )

list(APPEND _cmake_import_check_targets qp_solver_collection::QpSolverCollection )
list(APPEND _cmake_import_check_files_for_qp_solver_collection::QpSolverCollection "${_IMPORT_PREFIX}/lib/libQpSolverCollection.dylib" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
