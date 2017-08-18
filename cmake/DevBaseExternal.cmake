if(APPLE)
    # Detect if the "port" command is valid on this system; if so, return
    # full path.
    execute_process(
        COMMAND which port
        RESULT_VARIABLE DETECT_MACPORTS
        OUTPUT_VARIABLE MACPORTS_PREFIX
        ERROR_QUIET
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    if(${DETECT_MACPORTS} EQUAL 0)
        # /opt/local/bin/port -> /opt/local/bin -> /opt/local
        get_filename_component(MACPORTS_PREFIX ${MACPORTS_PREFIX} DIRECTORY)
        get_filename_component(MACPORTS_PREFIX ${MACPORTS_PREFIX} DIRECTORY)

        set(CMAKE_PREFIX_PATH
            ${MACPORTS_PREFIX}
            ${CMAKE_PREFIX_PATH}
        )

        message(STATUS "Probing MacPorts installation in: ${MACPORTS_PREFIX}")
    endif()


    # TODO Also detect homebrew, using "brew --prefix"
endif()


# Variable that can be set in this module:
#
# DEVBASE_EXTERNAL_SOURCES
#   List with directory pathnames containing sources to document. These are
#   used to tell Doxygen which files to document.
# DEVBASE_DOXYGEN_EXTERNAL_SOURCES_FILE_PATTERNS
#   List with filename patterns of external sources to document. Only needed
#   for non-standard filename patterns. These are used to tell Doxygen which
#   files to document.


# Configure and find packages, configure project. ------------------------------
if(DEVBASE_BOOST_REQUIRED)
    set(Boost_USE_STATIC_LIBS OFF)
    set(Boost_USE_STATIC_RUNTIME OFF)
    add_definitions(
        # Use dynamic libraries.
        -DBOOST_ALL_DYN_LINK
        # Prevent auto-linking.
        -DBOOST_ALL_NO_LIB

        # No deprecated features.
        -DBOOST_FILESYSTEM_NO_DEPRECATED

        # -DBOOST_CHRONO_DONT_PROVIDE_HYBRID_ERROR_HANDLING
        # -DBOOST_CHRONO_HEADER_ONLY
    )
    set(CMAKE_CXX_FLAGS_RELEASE
        # Disable range checks in release builds.
        "${CMAKE_CXX_FLAGS_RELEASE} -DBOOST_DISABLE_ASSERTS"
    )
    list(REMOVE_DUPLICATES DEVBASE_REQUIRED_BOOST_COMPONENTS)
    find_package(Boost
        ${DEVBASE_BOOST_VERSION}  # If set, minimum version of boost to find
        REQUIRED
        COMPONENTS ${DEVBASE_REQUIRED_BOOST_COMPONENTS})
    if(NOT Boost_FOUND)
        message(FATAL_ERROR "Boost not found")
    endif()
    include_directories(
        SYSTEM
        ${Boost_INCLUDE_DIRS}
    )
    list(APPEND DEVBASE_EXTERNAL_LIBRARIES
        ${Boost_LIBRARIES}
    )
    message(STATUS "  includes : ${Boost_INCLUDE_DIRS}")
    message(STATUS "  libraries: ${Boost_LIBRARIES}")

    # In older versions of Boost, signal2's scoped_connection was not
    # movable. This has implications when storing these in a collection.
    if(Boost_VERSION VERSION_GREATER "105600")
        set(DEVBASE_BOOST_SCOPED_CONNECTION_IS_MOVABLE TRUE)
    else()
        set(DEVBASE_BOOST_SCOPED_CONNECTION_IS_MOVABLE FALSE)
    endif()

    # In older versions of Boost, lexical cast didn't provide
    # try_lexical_convert.
    if(Boost_VERSION VERSION_GREATER "105500")
        set(DEVBASE_BOOST_LEXICAL_CAST_PROVIDES_TRY_LEXICAL_CONVERT TRUE)
    else()
        set(DEVBASE_BOOST_LEXICAL_CAST_PROVIDES_TRY_LEXICAL_CONVERT FALSE)
    endif()
endif()


if(DEVBASE_CURL_REQUIRED)
    find_package(CURL REQUIRED)
    include_directories(
        SYSTEM
        ${CURL_INCLUDE_DIRS}
    )
    list(APPEND DEVBASE_EXTERNAL_LIBRARIES
        ${CURL_LIBRARIES}
    )
endif()


if(DEVBASE_CURSES_REQUIRED)
    # set(CURSES_NEED_NCURSES TRUE)  # Assume we need this one for now.

    find_package(Curses REQUIRED)
    # Check CURSES_HAVE_NCURSES_H -> cursesw.h in .../include
    # Check CURSES_HAVE_NCURSES_NCURSES_H -> curses.h in .../ncursesw
    include_directories(
        SYSTEM
        ${CURSES_INCLUDE_DIRS}  # /ncursesw
    )

    if(NOT DEFINED DEVBASE_CURSES_WIDE_CHARACTER_SUPPORT_REQUIRED)
        set(DEVBASE_CURSES_WIDE_CHARACTER_SUPPORT_REQUIRED TRUE)
    endif()

    if(DEVBASE_CURSES_WIDE_CHARACTER_SUPPORT_REQUIRED)
        set(CURSES_LIBRARIES formw menuw ncursesw)
    endif()

    list(APPEND DEVBASE_EXTERNAL_LIBRARIES
        ${CURSES_LIBRARIES}
    )
endif()


if(DEVBASE_DOCOPT_REQUIRED)
    find_package(Docopt REQUIRED)

    include_directories(
        SYSTEM
        ${DOCOPT_INCLUDE_DIRS}
    )
    list(APPEND DEVBASE_EXTERNAL_LIBRARIES
        ${DOCOPT_LIBRARIES}
    )
endif()


if(DEVBASE_DOXYGEN_REQUIRED)
    find_package(Doxygen REQUIRED)

    if(NOT DOXYGEN_FOUND)
        message(FATAL_ERROR "Doxygen not found")
    endif()
endif()


if(DEVBASE_EXPAT_REQUIRED)
    find_package(EXPAT REQUIRED)
    include_directories(
        SYSTEM
        ${EXPAT_INCLUDE_DIRS}
    )
    list(APPEND DEVBASE_EXTERNAL_LIBRARIES
        ${EXPAT_LIBRARIES}
    )
endif()


if(DEVBASE_FERN_REQUIRED)
    find_package(Fern REQUIRED)

    if(NOT FERN_FOUND)
        message(FATAL_ERROR "Fern not found")
    endif()

    include_directories(
        SYSTEM
        ${FERN_INCLUDE_DIRS}
    )
    list(APPEND DEVBASE_EXTERNAL_LIBRARIES
        ${FERN_LIBRARIES}
    )
endif()


if(DEVBASE_GDAL_USEFUL OR DEVBASE_GDAL_REQUIRED)
    find_package(GDAL)

    if(DEVBASE_GDAL_REQUIRED AND NOT GDAL_FOUND)
        message(FATAL_ERROR "GDAL not found")
    endif()

    include_directories(
        SYSTEM
        ${GDAL_INCLUDE_DIRS}
    )
    list(APPEND DEVBASE_EXTERNAL_LIBRARIES
        ${GDAL_LIBRARIES}
    )
    find_program(GDAL_TRANSLATE gdal_translate
        HINTS ${GDAL_INCLUDE_DIR}/../bin
    )
    # TODO This dir isn't correct. GDAL_DIRECTORY is not defined.
    if(WIN32)
        SET(GDAL_DATA ${GDAL_DIRECTORY}/data)
    else()
        SET(GDAL_DATA ${GDAL_DIRECTORY}/share/gdal)
    endif()

    include(CheckGDalLibrary)
endif()


if(DEVBASE_GEOS_REQUIRED)
    find_package(GEOS REQUIRED)
    include_directories(
        SYSTEM
        ${GEOS_INCLUDE_DIR}
    )
    list(APPEND DEVBASE_EXTERNAL_LIBRARIES
        ${GEOS_LIBRARY}
    )
endif()


if(DEVBASE_GRAPHVIZ_REQUIRED)
    find_package(Graphviz REQUIRED)

    if(GRAPHVIZ_FOUND)
        include(DevBaseGraphvizMacro)
    endif()
endif()


if(DEVBASE_HDF5_REQUIRED)
    list(REMOVE_DUPLICATES DEVBASE_REQUIRED_HDF5_COMPONENTS)
    find_package(HDF5 REQUIRED
        COMPONENTS ${DEVBASE_REQUIRED_HDF5_COMPONENTS})
    if(NOT HDF5_FOUND)
        message(FATAL_ERROR "HDF5 not found")
    endif()
    include_directories(
        SYSTEM
        ${HDF5_INCLUDE_DIRS}
    )
    list(APPEND DEVBASE_EXTERNAL_LIBRARIES
        ${HDF5_LIBRARIES}
    )
    add_definitions(${HDF5_DEFINITIONS})
endif()


if(DEVBASE_HPX_USEFUL OR DEVBASE_HPX_REQUIRED)
    # http://stellar.cct.lsu.edu/files/hpx-0.9.99/html/hpx/manual/build_system/using_hpx/using_hpx_cmake.html
    # See lib/cmake/hpx/HPXTargets.cmake for names of HPX targets to link
    # against.

    if(DEVBASE_HPX_REQUIRED)
        find_package(HPX REQUIRED)
    else()
        find_package(HPX)

        if(NOT HPX_FOUND)
            message(STATUS "Could not find HPX")
        endif()
    endif()

    if(HPX_FOUND)
        message(STATUS "Found HPX")
        message(STATUS "  includes : ${HPX_INCLUDE_DIRS}")
        message(STATUS "  libraries: ${HPX_LIBRARIES}")

        include_directories(
            SYSTEM
            ${HPX_INCLUDE_DIRS}
        )

        # Check whether we are using the same build type as HPX
        if (NOT "${HPX_BUILD_TYPE}" STREQUAL "${CMAKE_BUILD_TYPE}")
            message(WARNING
                "CMAKE_BUILD_TYPE does not match HPX_BUILD_TYPE: "
                "\"${CMAKE_BUILD_TYPE}\" != \"${HPX_BUILD_TYPE}\"\n"
                "ABI compatibility is not guaranteed. Expect link errors.")
        endif()
    endif()
endif()


if(DEVBASE_IMAGE_MAGICK_REQUIRED)
    find_package(ImageMagick REQUIRED
        COMPONENTS convert)
endif()


if(DEVBASE_LATEX_REQUIRED)
    # TODO Find LaTeX.
    include(UseLATEX)
endif()


if(DEVBASE_LIB_XML2_REQUIRED)
    find_package(LibXml2 REQUIRED)
endif()


if(DEVBASE_LIB_XSLT_REQUIRED)
    find_package(LibXslt REQUIRED)

    if(DEVBASE_LIB_XSLT_XSLTPROC_REQUIRED)
        if(NOT LIBXSLT_XSLTPROC_EXECUTABLE)
            message(FATAL_ERROR "xsltproc executable not found")
        endif()
    endif()
endif()


if(DEVBASE_LINKCHECKER_REQUIRED)
    find_package(Linkchecker REQUIRED)

    if(LINKCHECKER_FOUND)
        include(DevBaseLinkcheckerMacro)
    endif()
endif()


if(DEVBASE_NLOHMANN_JSON_REQUIRED)
    find_package(nlohmann_json REQUIRED)

    if(NOT nlohmann_json_FOUND)
        message(FATAL_ERROR "nlohmann json not found")
    endif()

    message(STATUS "Found nlohmann json: ${JSON_INCLUDE_DIR}")

    include_directories(
        SYSTEM
        ${JSON_INCLUDE_DIR}
    )
endif()


if(DEVBASE_LOKI_REQUIRED)
    find_package(Loki REQUIRED)
endif()


if(DEVBASE_MPI_REQUIRED)
    find_package(MPI REQUIRED)

    if(NOT MPI_C_FOUND)
        message(FATAL_ERROR "MPI for C not found")
    endif()

    include_directories(
        SYSTEM
        ${MPI_C_INCLUDE_PATH}
    )
    list(APPEND DEVBASE_EXTERNAL_LIBRARIES
        ${MPI_C_LIBRARIES}
    )
endif()


if(DEVBASE_NETCDF_REQUIRED)
    find_package(NetCDF REQUIRED)
    include_directories(
        SYSTEM
        ${NETCDF_INCLUDE_DIRS}
    )
    find_program(NCGEN ncgen
        HINTS ${NETCDF_INCLUDE_DIRS}/../bin
    )
    list(APPEND DEVBASE_EXTERNAL_LIBRARIES
        ${NETCDF_LIBRARIES}
    )
    message(STATUS "Found NetCDF:")
    message(STATUS "  includes : ${NETCDF_INCLUDE_DIRS}")
    message(STATUS "  libraries: ${NETCDF_LIBRARIES}")
endif()


if(DEVBASE_NUMPY_REQUIRED)
    find_package(NumPy REQUIRED)
    include_directories(
        SYSTEM
        ${NUMPY_INCLUDE_DIRS}
    )
    # http://docs.scipy.org/doc/numpy-dev/reference/c-api.deprecations.html
    add_definitions(-DNPY_NO_DEPRECATED_API=NPY_1_7_API_VERSION)
endif()


if(DEVBASE_OPENGL_REQUIRED)
    find_package(OpenGL REQUIRED)

    include_directories(
        SYSTEM
        ${OPENGL_INCLUDE_DIR}
    )
    list(APPEND DEVBASE_EXTERNAL_LIBRARIES
        ${OPENGL_LIBRARIES}
    )
endif()


if(DEVBASE_PANDOC_REQUIRED)
    find_package(Pandoc REQUIRED)

    if(PANDOC_FOUND)
        include(DevBasePandocMacro)
    endif()
endif()


if(DEVBASE_PCRASTER_RASTER_FORMAT_REQUIRED)
    find_package(PCRasterRasterFormat REQUIRED)

    if(NOT PCRASTER_RASTER_FORMAT_FOUND)
        message(FATAL_ERROR "PCRaster Raster Format library not found")
    endif()

    include_directories(
        ${PCRASTER_RASTER_FORMAT_INCLUDE_DIRS}
    )
    list(APPEND DEVBASE_EXTERNAL_LIBRARIES
        ${PCRASTER_RASTER_FORMAT_LIBRARIES}
    )

    message(STATUS "Found PCRaster Raster Format:")
    message(STATUS "  includes : ${PCRASTER_RASTER_FORMAT_INCLUDE_DIRS}")
    message(STATUS "  libraries: ${PCRASTER_RASTER_FORMAT_LIBRARIES}")
endif()


if(DEVBASE_PYBIND11_REQUIRED)
    find_package(Pybind11 REQUIRED)

    if(NOT PYBIND11_FOUND)
        message(FATAL_ERROR "pybind11 library not found")
    endif()

    include_directories(
        SYSTEM
        ${PYBIND11_INCLUDE_DIRS}
    )
endif()


# This one first, before FindPythonLibs. See CMake docs.
if(DEVBASE_PYTHON_INTERP_REQUIRED)
    if(DEFINED DEVBASE_REQUIRED_PYTHON_VERSION)
        set(Python_ADDITIONAL_VERSIONS ${DEVBASE_REQUIRED_PYTHON_VERSION})
    endif()

    find_package(PythonInterp REQUIRED)
endif()


if(DEVBASE_PYTHON_LIBS_REQUIRED)
    if(DEFINED DEVBASE_REQUIRED_PYTHON_VERSION)
        set(Python_ADDITIONAL_VERSIONS ${DEVBASE_REQUIRED_PYTHON_VERSION})
    endif()

    find_package(PythonLibs REQUIRED)
    include_directories(
        SYSTEM
        ${PYTHON_INCLUDE_DIRS}
    )
    list(APPEND DEVBASE_EXTERNAL_LIBRARIES
        ${PYTHON_LIBRARIES}
    )
endif()


if(DEVBASE_QT_REQUIRED)
    if(NOT DEFINED DEVBASE_REQUIRED_QT_VERSION)
        set(DEVBASE_REQUIRED_QT_VERSION "5")
    endif()

    if(DEVBASE_REQUIRED_QT_VERSION VERSION_EQUAL "4")
        find_package(Qt4 REQUIRED)
        include(${QT_USE_FILE})

        # Explicitly configure Qt's include directory. This is also done in
        # ${QT_USE_FILE} above, but we want to shove the SYSTEM option in.
        include_directories(
            SYSTEM
            ${QT_INCLUDE_DIR}
        )
    else()
        # http://doc.qt.io/qt-5/cmake-manual.html

        ### # Find includes in corresponding build directories
        ### set(CMAKE_INCLUDE_CURRENT_DIR ON)

        ### # Instruct CMake to run moc automatically when needed.
        ### set(CMAKE_AUTOMOC ON)

        list(REMOVE_DUPLICATES DEVBASE_REQUIRED_QT_COMPONENTS)
        find_package(Qt5 REQUIRED COMPONENTS ${DEVBASE_REQUIRED_QT_COMPONENTS})

        foreach(component ${DEVBASE_REQUIRED_QT_COMPONENTS})
            if(NOT Qt5${component}_FOUND)
                message(FATAL_ERROR "Qt5${component} not found")
            endif()
            message(STATUS "Found Qt5${component}: ${Qt5${component}_VERSION}")
            message(STATUS "  includes : ${Qt5${component}_INCLUDE_DIRS}")
            message(STATUS "  libraries: ${Qt5${component}_LIBRARIES}")
        endforeach()
    endif()
endif()


if(DEVBASE_QWT_REQUIRED)
    find_package(Qwt REQUIRED)

    if(NOT QWT_FOUND)
        message(FATAL_ERROR "Qwt not found")
    endif()

    include_directories(
        SYSTEM
        ${QWT_INCLUDE_DIR}
    )
    list(APPEND DEVBASE_EXTERNAL_LIBRARIES
        ${QWT_LIBRARY}
    )
    message(STATUS "Found Qwt:")
    message(STATUS "  includes : ${QWT_INCLUDE_DIRS}")
    message(STATUS "  libraries: ${QWT_LIBRARIES}")
endif()


if(DEVBASE_READLINE_REQUIRED)
    find_package(Readline REQUIRED)
    include_directories(
        SYSTEM
        ${READLINE_INCLUDE_DIR}
    )
    list(APPEND DEVBASE_EXTERNAL_LIBRARIES
        ${READLINE_LIBRARY}
    )
endif()


if(DEVBASE_SPHINX_REQUIRED)
    # TODO Find Sphinx Python package.
    include(SphinxDoc)

    if(NOT SPHINX_BUILD_EXECUTABLE OR NOT SPHINX_APIDOC_EXECUTABLE)
        message(FATAL_ERROR "sphinx not found")
    endif()
endif()


if(DEVBASE_SQLITE_REQUIRED)
    find_package(SQLite3 REQUIRED)
endif()


if(DEVBASE_SWIG_REQUIRED)
    find_package(SWIG REQUIRED)
endif()


if(DEVBASE_XERCES_REQUIRED)
    find_package(XercesC REQUIRED)
    include_directories(
        SYSTEM
        ${XercesC_INCLUDE_DIRS}
    )
    list(APPEND DEVBASE_EXTERNAL_LIBRARIES
        ${XercesC_LIBRARIES}
    )
endif()


if(DEVBASE_XSD_REQUIRED)
    find_package(XSD REQUIRED)
    include_directories(
        SYSTEM
        ${XSD_INCLUDE_DIRS}
    )
    list(APPEND DEVBASE_EXTERNAL_SOURCES ${XSD_INCLUDE_DIRS})
    list(APPEND DEVBASE_DOXYGEN_EXTERNAL_SOURCES_FILE_PATTERNS *.ixx)
    list(APPEND DEVBASE_DOXYGEN_EXTERNAL_SOURCES_FILE_PATTERNS *.txx)
    message(STATUS "Found XSD:")
    message(STATUS "  includes  : ${XSD_INCLUDE_DIRS}")
    message(STATUS "  executable: ${XSD_EXECUTABLE}")
endif()


# Turn list into a space-separated string. This string is used by
# DoxygenDoc.cmake.
string(REPLACE ";" " " DEVBASE_DOXYGEN_EXTERNAL_SOURCES_FILE_PATTERNS
    "${DEVBASE_DOXYGEN_EXTERNAL_SOURCES_FILE_PATTERNS}")
