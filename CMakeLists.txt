cmake_minimum_required(VERSION 3.21)
project(imgui 
LANGUAGES CXX)
# project(
#     imgui
#     VERSION 0.0.1
#     DESCRIPTION ""
#     HOMEPAGE_URL "https://github.com/LittleMushroom-private/imgui-cmake"
#     LANGUAGES CXX C)

    # Only set the cxx_standard if it is not set by someone else
if (NOT DEFINED CMAKE_CXX_STANDARD)
    set(CMAKE_CXX_STANDARD 20)
endif()

set(CMAKE_CXX_EXTENSIONS OFF)

# --------------------------------------------------------------------------------------------------------
# Library options
# --------------------------------------------------------------------------------------------------------

option(imgui_demo         "Include demo code (ShowDemoWindow)"          ON)
option(imgui_shared       "Build ImGui as a shared library"            OFF)
option(imgui_tables       "Include ImGuis tables library"               ON)
option(imgui_widgets      "Include ImGuis widget library"               ON)

# --------------------------------------------------------------------------------------------------------
# Library config
# --------------------------------------------------------------------------------------------------------

set(imgui_version  "v1.91.5" CACHE STRING "The ImGui version to use")
set(imgui_renderer "OpenGL3" CACHE STRING "The ImGui renderer to use")
set(imgui_platform "GLFW" CACHE STRING "The ImGui platform (backend) to use")

# --------------------------------------------------------------------------------------------------------
# Ensure valid config
# --------------------------------------------------------------------------------------------------------

set(supported_renderers "DirectX9" "DirectX10" "DirectX11" "DirectX12" "Metal" "OpenGL2" "OpenGL3" "SDL_Renderer2" "SDL_Renderer3" "Vulkan" "WebGPU")
set(supported_platforms "Unknown" "GLFW" "SDL2" "SDL3" "Win32" "Glut" "OSX" "Android")

set_property(CACHE imgui_renderer PROPERTY STRINGS ${supported_renderers})
set_property(CACHE imgui_platform PROPERTY STRINGS ${supported_platforms})

if (NOT imgui_renderer IN_LIST supported_renderers)
    message(FATAL_ERROR "Renderer must be one of ${supported_renderers}")
endif()

if (NOT imgui_platform IN_LIST supported_platforms)
    message(FATAL_ERROR "Renderer must be one of ${supported_platforms}")
endif()

# # don't know if this should be set globally from here or not...
set(CMAKE_CXX_VISIBILITY_PRESET hidden)

include(cmake/PreventInSourceBuilds.cmake)
include(ProjectOptions.cmake)

imgui_setup_options()
imgui_global_options()

include(Dependencies.cmake)
imgui_setup_dependencies()

imgui_local_options()

set(TYPE STATIC)
if (imgui_shared)
    set(TYPE SHARED)
endif()

# set(GIT_SHA
#     "Unknown"
#     CACHE STRING "SHA this build was generated from")
# string(
#   SUBSTRING "${GIT_SHA}"
#             0
#             8
#             GIT_SHORT_SHA)

target_compile_features(imgui_options INTERFACE cxx_std_${CMAKE_CXX_STANDARD})

add_library(imgui::imgui_options ALIAS imgui_options)
add_library(imgui::imgui_warnings ALIAS imgui_warnings)
add_library(${PROJECT_NAME} ${TYPE})
add_library(ocornut::${PROJECT_NAME} ALIAS ${PROJECT_NAME})

#include(cmake/PreventInSourceBuilds.cmake)
#include(ProjectOptions.cmake)
#include(Dependencies.cmake)
# imgui_global_options()
# imgui_local_options()
# imgui_setup_dependencies()


CPMAddPackage(
    NAME               imgui
    GIT_TAG            ${imgui_version}
    GITHUB_REPOSITORY  "ocornut/imgui"
    DOWNLOAD_ONLY
    )
    
target_include_directories(${PROJECT_NAME} PUBLIC "${imgui_SOURCE_DIR}")
target_include_directories(${PROJECT_NAME} PUBLIC "${imgui_SOURCE_DIR}/backends")

add_subdirectory(configured_files)

include(GenerateExportHeader)

target_link_libraries(imgui PRIVATE imgui::imgui_options imgui::imgui_warnings)

# target_include_directories(imgui ${WARNING_GUARD} 
# PUBLIC 
# $<BUILD_INTERFACE:${imgui_source_DIR}>
# $<BUILD_INTERFACE:${PROJECT_BINARY_DIR}/include>)

target_compile_features(imgui PUBLIC cxx_std_20)

# set_target_properties(
#   imgui
#   PROPERTIES VERSION ${PROJECT_VERSION}
#              CXX_VISIBILITY_PRESET hidden
#              VISIBILITY_INLINES_HIDDEN YES)

#generate_export_header(imgui EXPORT_FILE_NAME ${PROJECT_BINARY_DIR}/include/imgui/imgui_export.hpp)

if(NOT BUILD_SHARED_LIBS)
  target_compile_definitions(imgui PUBLIC imgui_STATIC_DEFINE)
endif()

# Don't even look at tests if we're not top level
if(NOT PROJECT_IS_TOP_LEVEL)
  return()
endif()

# --------------------------------------------------------------------------------------------------------
# Setup sources
# --------------------------------------------------------------------------------------------------------

target_sources(${PROJECT_NAME} PRIVATE 
    "${imgui_SOURCE_DIR}/imgui.cpp"
    "${imgui_SOURCE_DIR}/imgui_draw.cpp"
)

if (imgui_tables)
    target_sources(${PROJECT_NAME} PRIVATE "${imgui_SOURCE_DIR}/imgui_tables.cpp")
endif()

if (imgui_widgets)
    target_sources(${PROJECT_NAME} PRIVATE "${imgui_SOURCE_DIR}/imgui_widgets.cpp")
endif()

if (imgui_demo)
    target_sources(${PROJECT_NAME} PRIVATE "${imgui_SOURCE_DIR}/imgui_demo.cpp")
endif()

# --------------------------------------------------------------------------------------------------------
# Setup Renderers
# --------------------------------------------------------------------------------------------------------

if (imgui_renderer STREQUAL "DirectX9")
    target_link_libraries(${PROJECT_NAME} PRIVATE d3d9)
    target_sources(${PROJECT_NAME} PRIVATE "${imgui_SOURCE_DIR}/backends/imgui_impl_dx9.cpp")
endif()

if (imgui_renderer STREQUAL "DirectX10")
    target_link_libraries(${PROJECT_NAME} PRIVATE d3d10)
    target_sources(${PROJECT_NAME} PRIVATE "${imgui_SOURCE_DIR}/backends/imgui_impl_dx10.cpp")
endif()

if (imgui_renderer STREQUAL "DirectX11")
    target_link_libraries(${PROJECT_NAME} PRIVATE d3d11)
    target_sources(${PROJECT_NAME} PRIVATE "${imgui_SOURCE_DIR}/backends/imgui_impl_dx11.cpp")
endif()

if (imgui_renderer STREQUAL "DirectX12")
    target_link_libraries(${PROJECT_NAME} PRIVATE d3d12)
    target_sources(${PROJECT_NAME} PRIVATE "${imgui_SOURCE_DIR}/backends/imgui_impl_dx12.cpp")
endif()

if (imgui_renderer STREQUAL "Metal")
    # This might need additional libraries linked, however I don't have a mac to test this with.
    target_sources(${PROJECT_NAME} PRIVATE "${imgui_SOURCE_DIR}/backends/imgui_impl_metal.mm")
endif()

if (imgui_renderer STREQUAL "OpenGL2")
    find_package(OpenGL REQUIRED)
    target_link_libraries(${PROJECT_NAME} PUBLIC OpenGL::GL)
    target_sources(${PROJECT_NAME} PRIVATE "${imgui_SOURCE_DIR}/backends/imgui_impl_opengl2.cpp")
endif()

if (imgui_renderer STREQUAL "OpenGL3")
    find_package(OpenGL REQUIRED)
    target_link_libraries(${PROJECT_NAME} PUBLIC OpenGL::GL)
    target_sources(${PROJECT_NAME} PRIVATE "${imgui_SOURCE_DIR}/backends/imgui_impl_opengl3.cpp")
endif()

if (imgui_renderer STREQUAL "SDL_Renderer2")
    find_package(SDL2 REQUIRED)
    target_link_libraries(${PROJECT_NAME} PUBLIC SDL2::SDL2)
    target_sources(${PROJECT_NAME} PRIVATE "${imgui_SOURCE_DIR}/backends/imgui_impl_sdlrenderer2.cpp")
endif()

if (imgui_renderer STREQUAL "SDL_Renderer3")
    find_package(SDL3 REQUIRED)
    target_link_libraries(${PROJECT_NAME} PUBLIC SDL3::SDL3)
    target_sources(${PROJECT_NAME} PRIVATE "${imgui_SOURCE_DIR}/backends/imgui_impl_sdlrenderer3.cpp")
endif()

if (imgui_renderer STREQUAL "Vulkan")
    find_package(Vulkan REQUIRED)
    target_link_libraries(${PROJECT_NAME} PUBLIC Vulkan::Vulkan)
    target_sources(${PROJECT_NAME} PRIVATE "${imgui_SOURCE_DIR}/backends/imgui_impl_vulkan.cpp")
endif()

if (imgui_renderer STREQUAL "WebGPU")
    target_sources(${PROJECT_NAME} PRIVATE "${imgui_SOURCE_DIR}/backends/imgui_impl_wgpu.cpp")
endif()

# --------------------------------------------------------------------------------------------------------
# Setup Platforms
# --------------------------------------------------------------------------------------------------------

if (imgui_platform STREQUAL "GLFW")    
    target_link_libraries(${PROJECT_NAME} PUBLIC ${GLFW_LIBRARIES})
    target_sources(${PROJECT_NAME} PRIVATE "${imgui_SOURCE_DIR}/backends/imgui_impl_glfw.cpp")
endif()

if (imgui_platform STREQUAL "SDL2")
    target_link_libraries(${PROJECT_NAME} PUBLIC SDL2::SDL2)
    target_sources(${PROJECT_NAME} PRIVATE "${imgui_SOURCE_DIR}/backends/imgui_impl_sdl2.cpp")
endif()

if (imgui_platform STREQUAL "SDL3")
    target_link_libraries(${PROJECT_NAME} PUBLIC SDL3::SDL3)
    target_sources(${PROJECT_NAME} PRIVATE "${imgui_SOURCE_DIR}/backends/imgui_impl_sdl3.cpp")
endif()

if (imgui_platform STREQUAL "Win32")
    target_sources(${PROJECT_NAME} PRIVATE "${imgui_SOURCE_DIR}/backends/imgui_impl_win32.cpp")
endif()

if (imgui_platform STREQUAL "Glut")
    target_link_libraries(${PROJECT_NAME} PUBLIC GLUT::GLUT)
    target_sources(${PROJECT_NAME} PRIVATE "${imgui_SOURCE_DIR}/backends/imgui_impl_glut.cpp")
endif()

if (imgui_platform STREQUAL "OSX")
    target_sources(${PROJECT_NAME} PRIVATE "${imgui_SOURCE_DIR}/backends/imgui_impl_osx.mm")
endif()

if (imgui_platform STREQUAL "Android")
    target_sources(${PROJECT_NAME} PRIVATE "${imgui_SOURCE_DIR}/backends/imgui_impl_android.cpp")
endif()

# set the startup project for the "play" button in MSVC
set_property(DIRECTORY PROPERTY VS_STARTUP_PROJECT standalone)

if(CMAKE_SKIP_INSTALL_RULES)
  return()
endif()

include(cmake/PackageProject.cmake)

# Add other targets that you want installed here, by default we just package the one executable
# we know we want to ship
# imgui_package_project(
#   TARGETS
#   imgui
#   imgui_options
#   imgui_warnings
#   # FIXME: this does not work! CK
#   # PRIVATE_DEPENDENCIES_CONFIGURED project_options project_warnings
# )

# Experience shows that explicit package naming can help make it easier to sort
# out potential ABI related issues before they start, while helping you
# track a build to a specific GIT SHA
set(CPACK_PACKAGE_FILE_NAME
    "${CMAKE_PROJECT_NAME}-${CMAKE_PROJECT_VERSION}-${GIT_SHORT_SHA}-${CMAKE_SYSTEM_NAME}-${CMAKE_BUILD_TYPE}-${CMAKE_CXX_COMPILER_ID}-${CMAKE_CXX_COMPILER_VERSION}"
)

include(CPack)
