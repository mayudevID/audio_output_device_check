#include "include/audio_output_device_check/audio_output_device_check_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "audio_output_device_check_plugin.h"

void AudioOutputDeviceCheckPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  audio_output_device_check::AudioOutputDeviceCheckPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
