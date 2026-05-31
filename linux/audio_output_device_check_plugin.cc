#include "include/audio_output_device_check/audio_output_device_check_plugin.h"

#include <flutter_linux/flutter_linux.h>

#include <algorithm>
#include <array>
#include <cctype>
#include <cstdio>
#include <cstring>
#include <string>

#define AUDIO_OUTPUT_DEVICE_CHECK_PLUGIN(obj)                                  \
  (G_TYPE_CHECK_INSTANCE_CAST((obj),                                           \
                              audio_output_device_check_plugin_get_type(),     \
                              AudioOutputDeviceCheckPlugin))

struct _AudioOutputDeviceCheckPlugin {
  GObject parent_instance;
  FlEventChannel* event_channel;
};

G_DEFINE_TYPE(AudioOutputDeviceCheckPlugin,
              audio_output_device_check_plugin,
              g_object_get_type())

static FlValue* build_unknown_device_payload() {
  FlValue* payload = fl_value_new_map();
  fl_value_set_string_take(payload, "type", fl_value_new_string("unknown"));
  fl_value_set_string_take(payload, "name",
                           fl_value_new_string("Perangkat tidak diketahui"));
  return payload;
}

static std::string trim_copy(const std::string& input) {
  const auto start = input.find_first_not_of(" \t\r\n");
  if (start == std::string::npos) {
    return std::string();
  }

  const auto end = input.find_last_not_of(" \t\r\n");
  return input.substr(start, end - start + 1);
}

static std::string to_lower_copy(std::string value) {
  std::transform(value.begin(), value.end(), value.begin(),
                 [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
  return value;
}

static bool contains_any(const std::string& haystack,
                         const std::initializer_list<const char*>& needles) {
  for (const auto* needle : needles) {
    if (haystack.find(needle) != std::string::npos) {
      return true;
    }
  }
  return false;
}

static std::string classify_device_type(const std::string& name,
                                        const std::string& sink_name) {
  const std::string lowered_name = to_lower_copy(name);
  const std::string lowered_sink = to_lower_copy(sink_name);

  if (contains_any(lowered_name, {"bluetooth", "a2dp", "bluez"}) ||
      contains_any(lowered_sink, {"bluez", "bluetooth"})) {
    return "bluetooth";
  }

  if (contains_any(lowered_name, {"usb", "headphone", "headset", "hdmi"}) ||
      contains_any(lowered_sink, {"usb", "hdmi"})) {
    return "wired";
  }

  if (contains_any(lowered_name, {"speaker", "analog", "built-in", "builtin"}) ||
      contains_any(lowered_sink, {"analog", "speaker"})) {
    return "speaker";
  }

  return "unknown";
}

static std::string run_command_output(const char* command) {
  std::array<char, 256> buffer{};
  std::string output;

  FILE* pipe = popen(command, "r");
  if (pipe == nullptr) {
    return output;
  }

  while (fgets(buffer.data(), static_cast<int>(buffer.size()), pipe) != nullptr) {
    output += buffer.data();
  }

  pclose(pipe);
  return output;
}

static std::string extract_default_sink_name(const std::string& output) {
  return trim_copy(output);
}

static std::string extract_sink_description(const std::string& sinks_output,
                                            const std::string& sink_name) {
  if (sink_name.empty()) {
    return std::string();
  }

  const std::string name_prefix = "Name: ";
  const std::string desc_prefix = "Description: ";

  bool in_target_block = false;
  size_t start = 0;

  while (start < sinks_output.size()) {
    const size_t line_end = sinks_output.find('\n', start);
    const size_t end = (line_end == std::string::npos) ? sinks_output.size() : line_end;
    std::string line = trim_copy(sinks_output.substr(start, end - start));

    if (line.rfind(name_prefix, 0) == 0) {
      const std::string current_name = trim_copy(line.substr(name_prefix.size()));
      in_target_block = (current_name == sink_name);
    } else if (in_target_block && line.rfind(desc_prefix, 0) == 0) {
      return trim_copy(line.substr(desc_prefix.size()));
    } else if (line.rfind("Sink #", 0) == 0 && in_target_block) {
      return std::string();
    }

    if (line_end == std::string::npos) {
      break;
    }
    start = line_end + 1;
  }

  return std::string();
}

static FlValue* get_current_device_payload() {
  const std::string sink_name = extract_default_sink_name(
      run_command_output("pactl get-default-sink 2>/dev/null"));

  if (sink_name.empty()) {
    return build_unknown_device_payload();
  }

  const std::string sinks_output = run_command_output("pactl list sinks 2>/dev/null");
  const std::string description = extract_sink_description(sinks_output, sink_name);

  const std::string resolved_name =
      description.empty() ? sink_name : description;

  if (resolved_name.empty()) {
    return build_unknown_device_payload();
  }

  FlValue* payload = fl_value_new_map();
  fl_value_set_string_take(payload, "type",
                           fl_value_new_string(classify_device_type(resolved_name, sink_name).c_str()));
  fl_value_set_string_take(payload, "name",
                           fl_value_new_string(resolved_name.c_str()));
  return payload;
}

static void audio_output_device_check_plugin_handle_method_call(
    AudioOutputDeviceCheckPlugin* self,
    FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;

  const gchar* method = fl_method_call_get_name(method_call);

  if (strcmp(method, "getCurrentDevice") == 0) {
    response = FL_METHOD_RESPONSE(
        fl_method_success_response_new(get_current_device_payload()));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

static gboolean audio_output_device_check_on_listen(const gchar* /*arguments*/,
                                                    FlEventChannel* /*channel*/,
                                                    FlValue** event,
                                                    gpointer /*user_data*/,
                                                    GError** /*error*/) {
  *event = get_current_device_payload();
  return TRUE;
}

static gboolean audio_output_device_check_on_cancel(const gchar* /*arguments*/,
                                                    gpointer /*user_data*/,
                                                    GError** /*error*/) {
  return TRUE;
}

static void audio_output_device_check_plugin_dispose(GObject* object) {
  AudioOutputDeviceCheckPlugin* self = AUDIO_OUTPUT_DEVICE_CHECK_PLUGIN(object);

  if (self->event_channel != nullptr) {
    g_clear_object(&self->event_channel);
  }

  G_OBJECT_CLASS(audio_output_device_check_plugin_parent_class)->dispose(object);
}

static void audio_output_device_check_plugin_class_init(
    AudioOutputDeviceCheckPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = audio_output_device_check_plugin_dispose;
}

static void audio_output_device_check_plugin_init(
    AudioOutputDeviceCheckPlugin* self) {
  self->event_channel = nullptr;
}

static void method_call_cb(FlMethodChannel* /*channel*/, FlMethodCall* method_call,
                           gpointer user_data) {
  AudioOutputDeviceCheckPlugin* plugin =
      AUDIO_OUTPUT_DEVICE_CHECK_PLUGIN(user_data);
  audio_output_device_check_plugin_handle_method_call(plugin, method_call);
}

void audio_output_device_check_plugin_register_with_registrar(
    FlPluginRegistrar* registrar) {
  AudioOutputDeviceCheckPlugin* plugin = AUDIO_OUTPUT_DEVICE_CHECK_PLUGIN(
      g_object_new(audio_output_device_check_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) method_codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) method_channel = fl_method_channel_new(
      fl_plugin_registrar_get_messenger(registrar),
      "audio_output_device_check",
      FL_METHOD_CODEC(method_codec));
  fl_method_channel_set_method_call_handler(method_channel, method_call_cb,
                                            g_object_ref(plugin), g_object_unref);

  g_autoptr(FlStandardMethodCodec) event_codec = fl_standard_method_codec_new();
  plugin->event_channel = fl_event_channel_new(
      fl_plugin_registrar_get_messenger(registrar),
      "audio_output_device_check/events",
      FL_METHOD_CODEC(event_codec));
  fl_event_channel_set_stream_handlers(
      plugin->event_channel,
      audio_output_device_check_on_listen,
      audio_output_device_check_on_cancel,
      g_object_ref(plugin),
      g_object_unref);

  g_object_unref(plugin);
}
