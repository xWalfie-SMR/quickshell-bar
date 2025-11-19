cmake_minimum_required(VERSION 3.16)
project(VirtualDesktopPlugin VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Set compiler for Windows when using NMake
if(WIN32 AND CMAKE_GENERATOR MATCHES "NMake")
    if(NOT CMAKE_CXX_COMPILER)
        set(CMAKE_CXX_COMPILER "cl")
    endif()
endif()

find_package(Qt6 REQUIRED COMPONENTS Core Qml)

qt_add_qml_module(VirtualDesktopPlugin
    URI VirtualDesktop
    VERSION 1.0
    PLUGIN_TARGET VirtualDesktopPlugin
    SOURCES
        virtualdesktopmanager.h
        virtualdesktopmanager.cpp
)

target_link_libraries(VirtualDesktopPlugin PRIVATE
    Qt6::Core
    Qt6::Qml
)

# Windows-specific libraries
if(WIN32)
    target_link_libraries(VirtualDesktopPlugin PRIVATE
        ole32
        oleaut32
    )
endif()
