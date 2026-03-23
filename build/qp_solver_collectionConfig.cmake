

####### Expanded from @PACKAGE_INIT@ by configure_package_config_file() #######
####### Any changes to this file will be overwritten by the next CMake run ####
####### The input file was Config.cmake.in                            ########

get_filename_component(PACKAGE_PREFIX_DIR "${CMAKE_CURRENT_LIST_DIR}/../../../" ABSOLUTE)

####################################################################################

include("${CMAKE_CURRENT_LIST_DIR}/qp_solver_collectionTargets.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/qp_solver_options.cmake")

set(qp_solver_collection_LIBRARIES qp_solver_collection::QpSolverCollection)
