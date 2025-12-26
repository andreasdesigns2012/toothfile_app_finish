# CMakeLists.txt for Firebase stub library
cmake_minimum_required(VERSION 3.14)

# Create a static library for Firebase stub
add_library(firebase_app_stub STATIC firebase_stub.cpp)

# Set C++ standard
target_compile_features(firebase_app_stub PUBLIC cxx_std_17)

# Set Release configuration for Release builds
if(CMAKE_BUILD_TYPE STREQUAL "Release")
    target_compile_definitions(firebase_app_stub PRIVATE NDEBUG)
    target_compile_options(firebase_app_stub PRIVATE /O2 /MD)
endif()

# Export the library for linking
set_target_properties(firebase_app_stub PROPERTIES OUTPUT_NAME "firebase_app")