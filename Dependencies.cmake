include(cmake/CPM.cmake)

# Done as a function so that updates to variables like
# CMAKE_CXX_FLAGS don't propagate out to other
# targets
function(imgui_setup_dependencies)


# --------------------------------------------------------------------------------------------------------
# Setup Platforms
# --------------------------------------------------------------------------------------------------------

if (imgui_platform STREQUAL "GLFW")
    # find_package(glfw3 REQUIRED)
    #https://github.com/glfw/glfw.git
    if(NOT TARGET glfw)
        # cpmaddpackage("gh:glfw/glfw#3.4")
        CPMAddPackage(
        NAME               glfw
        GIT_TAG            3.4
        GITHUB_REPOSITORY  "glfw/glfw"
        OPTIONS
            "GLFW_USE_WAYLAND=1"
    )
    endif()
endif()

if (imgui_platform STREQUAL "SDL2")
    find_package(SDL2 REQUIRED)
endif()

if (imgui_platform STREQUAL "SDL3")
    find_package(SDL3 REQUIRED)
endif()


if (imgui_platform STREQUAL "Glut")
    find_package(GLUT REQUIRED)
endif()
  
endfunction()
