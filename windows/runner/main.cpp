#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  // 启用Impeller渲染引擎（Windows）
  // Flutter 3.40+ 默认支持Impeller，通过环境变量确保启用
  _wputenv(L"FLUTTER_ENABLE_IMPELLER=1");

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  
  // 设置窗口标题和图标
  if (!window.Create(L"课程表", origin, size)) {
    return EXIT_FAILURE;
  }
  
  // 设置窗口样式 - 隐藏原生标题栏
  HWND hwnd = window.GetHandle();
  
  // 获取窗口当前样式
  LONG_PTR style = GetWindowLongPtr(hwnd, GWL_STYLE);
  // 移除标题栏和边框
  style &= ~(WS_CAPTION | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX | WS_SYSMENU);
  SetWindowLongPtr(hwnd, GWL_STYLE, style);
  
  // 设置窗口扩展样式 - 透明效果
  LONG_PTR exStyle = GetWindowLongPtr(hwnd, GWL_EXSTYLE);
  exStyle |= WS_EX_LAYERED;
  SetWindowLongPtr(hwnd, GWL_EXSTYLE, exStyle);
  
  // 设置窗口透明度（Mica效果需要）
  SetLayeredWindowAttributes(hwnd, 0, 255, LWA_ALPHA);
  
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
