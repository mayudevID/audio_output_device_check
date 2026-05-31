cmake_minimum_required(VERSION 3.14)
project(audio_output_device_check LANGUAGES CXX)

set(PLUGIN_NAME "audio_output_device_check_plugin")

add_library(${PLUGIN_NAME} SHARED
  "audio_output_device_check_plugin.cpp"
  "audio_output_device_check_plugin_c_api.cpp"
)

apply_standard_settings(${PLUGIN_NAME})
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")

target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)

target_compile_features(${PLUGIN_NAME} PUBLIC cxx_std_17)

set(audio_output_device_check_bundled_libraries
  ""
  PARENT_SCOPE
)
