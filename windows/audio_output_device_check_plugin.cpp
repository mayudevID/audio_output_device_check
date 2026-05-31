#include "audio_output_device_check_plugin.h"

#include <flutter/event_channel.h>
#include <flutter/event_stream_handler_functions.h>
#include <flutter/standard_method_codec.h>

#include <Windows.h>
#include <combaseapi.h>
#include <functiondiscoverykeys_devpkey.h>
#include <mmdeviceapi.h>
#include <propvarutil.h>

#include <algorithm>
#include <memory>
#include <string>

namespace audio_output_device_check {

namespace {

flutter::EncodableMap BuildUnknownDevicePayload() {
  flutter::EncodableMap payload;
  payload[flutter::EncodableValue("type")] = flutter::EncodableValue("unknown");
  payload[flutter::EncodableValue("name")] =
      flutter::EncodableValue("Perangkat tidak diketahui");
  return payload;
}

std::string WideToUtf8(const std::wstring& value) {
  if (value.empty()) {
    return std::string();
  }

  const int size = WideCharToMultiByte(CP_UTF8, 0, value.c_str(), -1, nullptr,
                                       0, nullptr, nullptr);
  if (size <= 1) {
    return std::string();
  }

  std::string out(static_cast<size_t>(size - 1), '\0');
  WideCharToMultiByte(CP_UTF8, 0, value.c_str(), -1, out.data(), size, nullptr,
                      nullptr);
  return out;
}

std::string ToLowerCopy(std::string value) {
  std::transform(value.begin(), value.end(), value.begin(), [](unsigned char c) {
    return static_cast<char>(std::tolower(c));
  });
  return value;
}

bool ContainsAny(const std::string& haystack,
                 const std::initializer_list<const char*> needles) {
  for (const auto* needle : needles) {
    if (haystack.find(needle) != std::string::npos) {
      return true;
    }
  }
  return false;
}

std::string ClassifyDeviceType(const std::string& name) {
  const std::string lowered = ToLowerCopy(name);
  if (ContainsAny(lowered, {"bluetooth", "a2dp", "hands-free", "handsfree"})) {
    return "bluetooth";
  }

  if (ContainsAny(lowered, {"usb", "headphone", "headset", "earphone", "hdmi", "display audio"})) {
    return "wired";
  }

  if (ContainsAny(lowered, {"speaker", "realtek", "built-in", "builtin"})) {
    return "speaker";
  }

  return "unknown";
}

flutter::EncodableMap GetCurrentDevicePayload() {
  HRESULT hr = CoInitializeEx(nullptr, COINIT_MULTITHREADED);
  const bool com_initialized_here = SUCCEEDED(hr);
  if (FAILED(hr) && hr != RPC_E_CHANGED_MODE) {
    return BuildUnknownDevicePayload();
  }

  IMMDeviceEnumerator* enumerator = nullptr;
  hr = CoCreateInstance(__uuidof(MMDeviceEnumerator), nullptr, CLSCTX_ALL,
                        __uuidof(IMMDeviceEnumerator),
                        reinterpret_cast<void**>(&enumerator));
  if (FAILED(hr) || enumerator == nullptr) {
    if (com_initialized_here) {
      CoUninitialize();
    }
    return BuildUnknownDevicePayload();
  }

  IMMDevice* device = nullptr;
  hr = enumerator->GetDefaultAudioEndpoint(eRender, eConsole, &device);
  if (FAILED(hr) || device == nullptr) {
    enumerator->Release();
    if (com_initialized_here) {
      CoUninitialize();
    }
    return BuildUnknownDevicePayload();
  }

  IPropertyStore* props = nullptr;
  hr = device->OpenPropertyStore(STGM_READ, &props);
  if (FAILED(hr) || props == nullptr) {
    device->Release();
    enumerator->Release();
    if (com_initialized_here) {
      CoUninitialize();
    }
    return BuildUnknownDevicePayload();
  }

  PROPVARIANT friendly_name;
  PropVariantInit(&friendly_name);
  hr = props->GetValue(PKEY_Device_FriendlyName, &friendly_name);

  flutter::EncodableMap payload = BuildUnknownDevicePayload();
  if (SUCCEEDED(hr) && friendly_name.vt == VT_LPWSTR &&
      friendly_name.pwszVal != nullptr) {
    const std::string name = WideToUtf8(friendly_name.pwszVal);
    if (!name.empty()) {
      payload[flutter::EncodableValue("name")] = flutter::EncodableValue(name);
      payload[flutter::EncodableValue("type")] =
          flutter::EncodableValue(ClassifyDeviceType(name));
    }
  }

  PropVariantClear(&friendly_name);
  props->Release();
  device->Release();
  enumerator->Release();

  if (com_initialized_here) {
    CoUninitialize();
  }

  return payload;
}

}  // namespace

void AudioOutputDeviceCheckPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto method_channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "audio_output_device_check",
          &flutter::StandardMethodCodec::GetInstance());

  auto event_channel =
      std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
          registrar->messenger(), "audio_output_device_check/events",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<AudioOutputDeviceCheckPlugin>();

  method_channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto& call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  event_channel->SetStreamHandler(
      std::make_unique<flutter::StreamHandlerFunctions<flutter::EncodableValue>>(
          [](const flutter::EncodableValue* /*arguments*/,
             std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& events)
              -> std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> {
            events->Success(flutter::EncodableValue(GetCurrentDevicePayload()));
            return nullptr;
          },
          [](const flutter::EncodableValue* /*arguments*/)
              -> std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> {
            return nullptr;
          }));

  registrar->AddPlugin(std::move(plugin));
}

AudioOutputDeviceCheckPlugin::AudioOutputDeviceCheckPlugin() = default;

AudioOutputDeviceCheckPlugin::~AudioOutputDeviceCheckPlugin() = default;

void AudioOutputDeviceCheckPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name() == "getCurrentDevice") {
    result->Success(flutter::EncodableValue(GetCurrentDevicePayload()));
    return;
  }

  result->NotImplemented();
}

}  // namespace audio_output_device_check
