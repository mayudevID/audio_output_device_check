#ifndef FLUTTER_PLUGIN_AUDIO_OUTPUT_DEVICE_CHECK_PLUGIN_H_
#define FLUTTER_PLUGIN_AUDIO_OUTPUT_DEVICE_CHECK_PLUGIN_H_

#include <flutter_linux/flutter_linux.h>

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(AudioOutputDeviceCheckPlugin,
                     audio_output_device_check_plugin,
                     AUDIO_OUTPUT_DEVICE_CHECK,
                     PLUGIN,
                     GObject)

void audio_output_device_check_plugin_register_with_registrar(
    FlPluginRegistrar* registrar);

G_END_DECLS

#endif  // FLUTTER_PLUGIN_AUDIO_OUTPUT_DEVICE_CHECK_PLUGIN_H_
