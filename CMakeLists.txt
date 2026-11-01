cmake_minimum_required(VERSION 3.20)
project(wx_seg_obs VERSION 1.0 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# OBS itself is built with /MD, so the plugin must use the DLL CRT too.
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreadedDLL")

set(OBS_SDK_DIR "C:/obs-sdk" CACHE PATH "Path to standalone OBS SDK")
option(OPENCV_STATIC "Link the static OpenCV build (needs a static opencv_world454.lib)" OFF)

set(WXSEG_DIR   "${CMAKE_CURRENT_SOURCE_DIR}/3rd/lh320_windows_1.2.2")
set(OPENCV_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/3rd/opencv")

# ---- OpenCV 4.5.4: headers are bundled; opencv_world454.lib is NOT in the repo ----
# Looked for in: x64/vc16/staticlib (static), x64/vc15/lib or x64/vc16/lib (official prebuilt, DLL import lib)
find_library(OPENCV_WORLD_LIB NAMES opencv_world454
    PATHS "${OPENCV_ROOT}/x64/vc16/staticlib"
          "${OPENCV_ROOT}/x64/vc16/lib"
          "${OPENCV_ROOT}/x64/vc15/lib"
    NO_DEFAULT_PATH)
if(NOT OPENCV_WORLD_LIB)
    message(FATAL_ERROR "opencv_world454.lib not found under ${OPENCV_ROOT}/x64/. "
                        "Supply OpenCV 4.5.4 (see README/build notes), then re-run CMake.")
endif()

add_library(wx_seg_obs MODULE
    src/wxsegobs.cpp
    src/plugin-main.cpp
    src/plugin-macros.generated.h
)

target_include_directories(wx_seg_obs PRIVATE
    "${OBS_SDK_DIR}/include"
    "${OBS_SDK_DIR}/include/libobs"
    "${WXSEG_DIR}/include"
    "${OPENCV_ROOT}/include"
)

target_compile_definitions(wx_seg_obs PRIVATE _CRT_SECURE_NO_WARNINGS NOMINMAX WIN32_LEAN_AND_MEAN)
target_compile_options(wx_seg_obs PRIVATE /MP /utf-8)

target_link_libraries(wx_seg_obs PRIVATE
    "${OBS_SDK_DIR}/lib/libobs.lib"
    "${WXSEG_DIR}/lib/x64/wx_video_seg.lib"
    "${OPENCV_WORLD_LIB}"
)

# Static OpenCV additionally needs its bundled third-party libs (all present in staticlib/)
if(OPENCV_STATIC)
    foreach(dep zlib libpng libtiff IlmImf libjpeg-turbo libwebp libopenjp2 ade quirc libprotobuf)
        target_link_libraries(wx_seg_obs PRIVATE "${OPENCV_ROOT}/x64/vc16/staticlib/${dep}.lib")
    endforeach()
    target_link_libraries(wx_seg_obs PRIVATE ws2_32 comdlg32 advapi32 user32 gdi32 ole32 oleaut32 uuid)
endif()

set_target_properties(wx_seg_obs PROPERTIES
    PREFIX ""
    OUTPUT_NAME "wx_seg_obs"
)
