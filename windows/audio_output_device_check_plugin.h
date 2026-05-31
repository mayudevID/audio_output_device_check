#ifndef FLUTTER_PLUGIN_AUDIO_OUTPUT_DEVICE_CHECK_PLUGIN_H_
#define FLUTTER_PLUGIN_AUDIO_OUTPUT_DEVICE_CHECK_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace audio_output_device_check {

class AudioOutputDeviceCheckPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  AudioOutputDeviceCheckPlugin();
  ~AudioOutputDeviceCheckPlugin() override;

  AudioOutputDeviceCheckPlugin(const AudioOutputDeviceCheckPlugin&) = delete;
  AudioOutputDeviceCheckPlugin& operator=(
      const AudioOutputDeviceCheckPlugin&) = delete;

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace audio_output_device_check

#endif  // FLUTTER_PLUGIN_AUDIO_OUTPUT_DEVICE_CHECK_PLUGIN_H_
