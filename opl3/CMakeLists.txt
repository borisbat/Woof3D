cmake_minimum_required(VERSION 3.10)

# Project name and language
project(OPL3Library LANGUAGES C)

# Add source files
set(SOURCE_FILES opl3.c)

# Specify the output library name and set it as SHARED (for DLL)
add_library(OPL3 SHARED ${SOURCE_FILES})

# If you want to install the library to the system (not mandatory)
install(TARGETS OPL3
    RUNTIME DESTINATION bin   # For Windows
    LIBRARY DESTINATION lib   # For Unix-like systems
    ARCHIVE DESTINATION lib)  # For static libraries

