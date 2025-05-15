# Script to fix file_picker plugin issues for Windows build

# Get the path to the file_picker plugin
$flutterPath = (Get-Command flutter).Source
$flutterDir = Split-Path -Parent $flutterPath
$pubCachePath = Join-Path (Split-Path -Parent $flutterDir) ".pub-cache\hosted\pub.dev"

# Find the file_picker plugin directory
$filePickerDir = Get-ChildItem -Path $pubCachePath -Filter "file_picker-*" -Directory | Sort-Object -Property Name -Descending | Select-Object -First 1

if ($filePickerDir) {
    $filePickerPath = $filePickerDir.FullName
    Write-Host "Found file_picker plugin at: $filePickerPath"
    
    # Fix the pubspec.yaml file
    $pubspecPath = Join-Path $filePickerPath "pubspec.yaml"
    if (Test-Path $pubspecPath) {
        $pubspecContent = Get-Content $pubspecPath -Raw
        
        # Remove the default_package references for problematic platforms
        $pubspecContent = $pubspecContent -replace "windows:\s+default_package: file_picker", "windows: {}"
        $pubspecContent = $pubspecContent -replace "linux:\s+default_package: file_picker", "linux: {}"
        $pubspecContent = $pubspecContent -replace "macos:\s+default_package: file_picker", "macos: {}"
        
        Set-Content -Path $pubspecPath -Value $pubspecContent
        Write-Host "Fixed file_picker pubspec.yaml"
    }
    
    # Create a temporary fix for the Windows implementation
    $windowsDir = Join-Path $filePickerPath "windows"
    if (-not (Test-Path $windowsDir)) {
        New-Item -ItemType Directory -Path $windowsDir -Force
        Write-Host "Created Windows directory for file_picker"
        
        # Create a minimal implementation file
        $implPath = Join-Path $windowsDir "file_picker_plugin.cpp"
        $implContent = @"
#include "include/file_picker/file_picker_plugin.h"

// This is a temporary stub implementation to satisfy the Flutter plugin system
// It doesn't actually implement any functionality

namespace {

class FilePickerPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrar *registrar) {
    auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
        registrar->messenger(), "file_picker",
        &flutter::StandardMethodCodec::GetInstance());
    auto plugin = std::make_unique<FilePickerPlugin>();
    channel->SetMethodCallHandler(
        [plugin_pointer = plugin.get()](const auto &call, auto result) {
          plugin_pointer->HandleMethodCall(call, std::move(result));
        });
    registrar->AddPlugin(std::move(plugin));
  }

  FilePickerPlugin() {}

  virtual ~FilePickerPlugin() {}

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    // Just return not implemented for all methods
    result->NotImplemented();
  }
};

}  // namespace

void FilePickerPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  FilePickerPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrar>(registrar));
}
"@
        Set-Content -Path $implPath -Value $implContent
        
        # Create the header file
        $includePath = Join-Path $windowsDir "include\file_picker"
        New-Item -ItemType Directory -Path $includePath -Force
        
        $headerPath = Join-Path $includePath "file_picker_plugin.h"
        $headerContent = @"
#ifndef FLUTTER_PLUGIN_FILE_PICKER_PLUGIN_H_
#define FLUTTER_PLUGIN_FILE_PICKER_PLUGIN_H_

#include <flutter_plugin_registrar.h>

#ifdef FLUTTER_PLUGIN_IMPL
#define FLUTTER_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FLUTTER_PLUGIN_EXPORT __declspec(dllimport)
#endif

#if defined(__cplusplus)
extern "C" {
#endif

FLUTTER_PLUGIN_EXPORT void FilePickerPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar);

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // FLUTTER_PLUGIN_FILE_PICKER_PLUGIN_H_
"@
        Set-Content -Path $headerPath -Value $headerContent
        
        # Create the CMakeLists.txt file
        $cmakePath = Join-Path $windowsDir "CMakeLists.txt"
        $cmakeContent = @"
cmake_minimum_required(VERSION 3.14)
set(PROJECT_NAME "file_picker")
project(${PROJECT_NAME} LANGUAGES CXX)

# This value is used when generating builds using this plugin, so it must
# not be changed
set(PLUGIN_NAME "file_picker_plugin")

add_library(${PLUGIN_NAME} SHARED
  "file_picker_plugin.cpp"
)
apply_standard_settings(${PLUGIN_NAME})
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)

# List of absolute paths to libraries that should be bundled with the plugin
set(file_picker_bundled_libraries
  ""
  PARENT_SCOPE
)
"@
        Set-Content -Path $cmakePath -Value $cmakeContent
        
        Write-Host "Created minimal Windows implementation for file_picker"
    }
} else {
    Write-Host "Could not find file_picker plugin directory"
}

Write-Host "File picker fix complete. Try building the Windows app now."
