cmake_minimum_required(VERSION 2.6)

if(${CMAKE_VERSION} STREQUAL "2.8.2")
	# Bug http://vtk.org/Bug/view.php?id=11020
	message(WARNING "CMake/CPack version 2.8.2 will not create working .deb packages!")
endif()

# This can be read from ${PROJECT_NAME} after project() is called
project(MultiCraft)
set(PROJECT_NAME_CAPITALIZED "MultiCraft")

# Works only for cmake 3.1 and greater
set(CMAKE_CXX_STANDARD 11)

# Also remember to set PROTOCOL_VERSION in network/networkprotocol.h when releasing
set(VERSION_MAJOR 1)
set(VERSION_MINOR 7)
set(VERSION_PATCH 0)
set(VERSION_EXTRA "" CACHE STRING "Stuff to append to version string")

# Change to false for releases
set(DEVELOPMENT_BUILD FALSE)

set(VERSION_STRING "${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}")
if(VERSION_EXTRA)
	set(VERSION_STRING ${VERSION_STRING}-${VERSION_EXTRA})
elseif(DEVELOPMENT_BUILD)
	set(VERSION_STRING "${VERSION_STRING}-dev")
endif()

if (CMAKE_BUILD_TYPE STREQUAL Debug)
	# Append "-debug" to version string
	set(VERSION_STRING "${VERSION_STRING}-debug")
endif()

message(STATUS "*** Will build version ${VERSION_STRING} ***")


# Configuration options
set(DEFAULT_RUN_IN_PLACE FALSE)
if(WIN32)
	set(DEFAULT_RUN_IN_PLACE TRUE)
endif()
set(RUN_IN_PLACE ${DEFAULT_RUN_IN_PLACE} CACHE BOOL
	"Run directly in source directory structure")


set(BUILD_CLIENT TRUE CACHE BOOL "Build client")
set(BUILD_SERVER FALSE CACHE BOOL "Build server")


set(WARN_ALL TRUE CACHE BOOL "Enable -Wall for Release build")

if(NOT CMAKE_BUILD_TYPE)
	# Default to release
	set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type: Debug or Release" FORCE)
endif()

# Included stuff
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake/Modules/")


# This is done here so that relative search paths are more reasonable
find_package(Irrlicht)


# Installation

if(WIN32)
	set(SHAREDIR ".")
	set(BINDIR "bin")
	set(DOCDIR "doc")
	set(EXAMPLE_CONF_DIR ".")
	set(LOCALEDIR "locale")
elseif(APPLE)
	set(BUNDLE_NAME ${PROJECT_NAME}.app)
	set(BUNDLE_PATH "${BUNDLE_NAME}")
	set(BINDIR ${BUNDLE_NAME}/Contents/MacOS)
	set(SHAREDIR ${BUNDLE_NAME}/Contents/Resources)
	set(DOCDIR "${SHAREDIR}/${PROJECT_NAME}")
	set(EXAMPLE_CONF_DIR ${DOCDIR})
	set(LOCALEDIR "${SHAREDIR}/locale")
elseif(UNIX) # Linux, BSD etc
	if(RUN_IN_PLACE)
		set(SHAREDIR ".")
		set(BINDIR "bin")
		set(DOCDIR "doc")
		set(EXAMPLE_CONF_DIR ".")
		set(MANDIR "unix/man")
		set(XDG_APPS_DIR "unix/applications")
		set(APPDATADIR "unix/metainfo")
		set(ICONDIR "unix/icons")
		set(LOCALEDIR "locale")
	else()
		set(SHAREDIR "${CMAKE_INSTALL_PREFIX}/share/${PROJECT_NAME}")
		set(BINDIR "${CMAKE_INSTALL_PREFIX}/bin")
		set(DOCDIR "${CMAKE_INSTALL_PREFIX}/share/doc/${PROJECT_NAME}")
		set(MANDIR "${CMAKE_INSTALL_PREFIX}/share/man")
		set(EXAMPLE_CONF_DIR ${DOCDIR})
		set(XDG_APPS_DIR "${CMAKE_INSTALL_PREFIX}/share/applications")
		set(APPDATADIR "${CMAKE_INSTALL_PREFIX}/share/metainfo")
		set(ICONDIR "${CMAKE_INSTALL_PREFIX}/share/icons")
		set(LOCALEDIR "${CMAKE_INSTALL_PREFIX}/share/${PROJECT_NAME}/locale")
	endif()
endif()

set(CUSTOM_SHAREDIR "" CACHE STRING "Directory to install data files into")
if(NOT CUSTOM_SHAREDIR STREQUAL "")
	set(SHAREDIR "${CUSTOM_SHAREDIR}")
	message(STATUS "Using SHAREDIR=${SHAREDIR}")
endif()

set(CUSTOM_BINDIR "" CACHE STRING "Directory to install binaries into")
if(NOT CUSTOM_BINDIR STREQUAL "")
	set(BINDIR "${CUSTOM_BINDIR}")
	message(STATUS "Using BINDIR=${BINDIR}")
endif()

set(CUSTOM_DOCDIR "" CACHE STRING "Directory to install documentation into")
if(NOT CUSTOM_DOCDIR STREQUAL "")
	set(DOCDIR "${CUSTOM_DOCDIR}")
	if(NOT RUN_IN_PLACE)
		set(EXAMPLE_CONF_DIR ${DOCDIR})
	endif()
	message(STATUS "Using DOCDIR=${DOCDIR}")
endif()

set(CUSTOM_MANDIR "" CACHE STRING "Directory to install manpages into")
if(NOT CUSTOM_MANDIR STREQUAL "")
	set(MANDIR "${CUSTOM_MANDIR}")
	message(STATUS "Using MANDIR=${MANDIR}")
endif()

set(CUSTOM_EXAMPLE_CONF_DIR "" CACHE STRING "Directory to install example config file into")
if(NOT CUSTOM_EXAMPLE_CONF_DIR STREQUAL "")
	set(EXAMPLE_CONF_DIR "${CUSTOM_EXAMPLE_CONF_DIR}")
	message(STATUS "Using EXAMPLE_CONF_DIR=${EXAMPLE_CONF_DIR}")
endif()

set(CUSTOM_XDG_APPS_DIR "" CACHE STRING "Directory to install .desktop files into")
if(NOT CUSTOM_XDG_APPS_DIR STREQUAL "")
	set(XDG_APPS_DIR "${CUSTOM_XDG_APPS_DIR}")
	message(STATUS "Using XDG_APPS_DIR=${XDG_APPS_DIR}")
endif()

set(CUSTOM_ICONDIR "" CACHE STRING "Directory to install icons into")
if(NOT CUSTOM_ICONDIR STREQUAL "")
	set(ICONDIR "${CUSTOM_ICONDIR}")
	message(STATUS "Using ICONDIR=${ICONDIR}")
endif()

set(CUSTOM_LOCALEDIR "" CACHE STRING "Directory to install l10n files into")
if(NOT CUSTOM_LOCALEDIR STREQUAL "")
	set(LOCALEDIR "${CUSTOM_LOCALEDIR}")
	message(STATUS "Using LOCALEDIR=${LOCALEDIR}")
endif()


install(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/builtin" DESTINATION "${SHAREDIR}")
install(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/client" DESTINATION "${SHAREDIR}")
install(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/clientmods" DESTINATION "${SHAREDIR}")
install(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/games" DESTINATION "${SHAREDIR}" PATTERN ".git*" EXCLUDE)

if(BUILD_CLIENT)
	install(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/textures" DESTINATION "${SHAREDIR}")
endif()

install(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/fonts" DESTINATION "${SHAREDIR}")

install(FILES "README.md" DESTINATION "${DOCDIR}")
install(FILES "doc/lua_api.txt" DESTINATION "${DOCDIR}")
install(FILES "doc/menu_lua_api.txt" DESTINATION "${DOCDIR}")
install(FILES "doc/texture_packs.txt" DESTINATION "${DOCDIR}")
install(FILES "doc/world_format.txt" DESTINATION "${DOCDIR}")
install(FILES "multicraft.conf.example" DESTINATION "${EXAMPLE_CONF_DIR}")

if(UNIX AND NOT APPLE)
	install(FILES "doc/MultiCraft.6" "doc/MultiCraftServer.6" DESTINATION "${MANDIR}/man6")
	install(FILES "misc/MultiCraft.desktop" DESTINATION "${XDG_APPS_DIR}")
	install(FILES "misc/MultiCraft.appdata.xml" DESTINATION "${APPDATADIR}")
	install(FILES "misc/MultiCraft.svg" DESTINATION "${ICONDIR}/hicolor/scalable/apps")
	install(FILES "misc/MultiCraft-xorg-icon-128.png"
		DESTINATION "${ICONDIR}/hicolor/128x128/apps"
		RENAME "MultiCraft.png")
endif()

if(APPLE)
	install(FILES "misc/MultiCraft-icon.icns" DESTINATION "${SHAREDIR}")
	install(FILES "misc/Info.plist" DESTINATION "${BUNDLE_PATH}/Contents")
endif()

# Library pack
find_package(GMP REQUIRED)
find_package(Json REQUIRED)
find_package(Lua REQUIRED)

# Subdirectories
# Be sure to add all relevant definitions above this

add_subdirectory(src)


# CPack

set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "An Minecraft inspired game")
set(CPACK_PACKAGE_VERSION_MAJOR ${VERSION_MAJOR})
set(CPACK_PACKAGE_VERSION_MINOR ${VERSION_MINOR})
set(CPACK_PACKAGE_VERSION_PATCH ${VERSION_PATCH})
set(CPACK_PACKAGE_VENDOR "MoNTE48")
set(CPACK_PACKAGE_CONTACT "MoNTE48@mail.ua")

if(WIN32)
	if(CMAKE_SIZEOF_VOID_P EQUAL 8)
		set(CPACK_PACKAGE_FILE_NAME "${PROJECT_NAME}-${VERSION_STRING}-win64")
	else()
		set(CPACK_PACKAGE_FILE_NAME "${PROJECT_NAME}-${VERSION_STRING}-win32")
	endif()

	set(CPACK_GENERATOR ZIP)
elseif(APPLE)
	set(CPACK_INCLUDE_TOPLEVEL_DIRECTORY 0)
	set(CPACK_PACKAGE_FILE_NAME "${PROJECT_NAME}-${VERSION_STRING}-osx")
	set(CPACK_GENERATOR ZIP)
else()
	set(CPACK_PACKAGE_FILE_NAME "${PROJECT_NAME}-${VERSION_STRING}-linux")
	set(CPACK_GENERATOR TGZ)
	set(CPACK_SOURCE_GENERATOR TGZ)
endif()

include(CPack)


# Add a target to generate API documentation with Doxygen
find_package(Doxygen)
if(DOXYGEN_FOUND)
	configure_file(${CMAKE_CURRENT_SOURCE_DIR}/doc/Doxyfile.in
			${CMAKE_CURRENT_BINARY_DIR}/doc/Doxyfile @ONLY)
	add_custom_target(doc
		${DOXYGEN_EXECUTABLE} ${CMAKE_CURRENT_BINARY_DIR}/doc/Doxyfile
		WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/doc
		COMMENT "Generating API documentation with Doxygen" VERBATIM
	)
endif()
