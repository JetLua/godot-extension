#include "one.h"

  // --- Objective-C 代理类 ---
@interface AuthDelegate: NSObject <ASWebAuthenticationPresentationContextProviding>
@end

#if TARGET_OS_OSX
#import <AppKit/AppKit.h>
#else
#import <UIKit/UIKit.h>
#endif

@implementation AuthDelegate
- (ASPresentationAnchor)presentationAnchorForWebAuthenticationSession: (ASWebAuthenticationSession *)session {
  __block ASPresentationAnchor anchor = nil;
  void (^getAnchor)(void) = ^{
#if TARGET_OS_OSX
      // macOS
    anchor = [NSApplication sharedApplication].keyWindow;
    if (!anchor) {
      anchor = [NSApplication sharedApplication].windows.firstObject;
    }
#else
      // iOS
    if (@available(iOS 13.0, *)) {
      for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if (scene.activationState == UISceneActivationStateForegroundActive) {
          UIWindowScene *windowScene = (UIWindowScene *)scene;
          for (UIWindow *window in windowScene.windows) {
            if (window.isKeyWindow) {
              anchor = window;
              return;
            }
          }
        }
      }
    } else {
      anchor = [UIApplication sharedApplication].keyWindow;
    }
    
#endif
  };
  
  if ([NSThread isMainThread]) {
    getAnchor();
  } else {
    dispatch_sync(dispatch_get_main_queue(), getAnchor);
  }
  
  return anchor;
}
@end


  // 初始化回调
static void initialize_one(godot::ModuleInitializationLevel p_level) {
  if (p_level == godot::MODULE_INITIALIZATION_LEVEL_SCENE) {
    godot::ClassDB::register_class<godot::One>();
  }
}

  // 卸载回调
static void uninitialize_one(godot::ModuleInitializationLevel p_level) {
  if (p_level != godot::MODULE_INITIALIZATION_LEVEL_SCENE) return;
}

  // ⚠️ 入口函数（必须导出，名字与 .gdextension 的 entry_symbol 一致）
extern "C" {
GDExtensionBool GDE_EXPORT init(
                                GDExtensionInterfaceGetProcAddress p_get_proc_address,
                                const GDExtensionClassLibraryPtr p_library,
                                GDExtensionInitialization *r_initialization) {
  
  godot::GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);
  
  init_obj.register_initializer(initialize_one);
  init_obj.register_terminator(uninitialize_one);
  init_obj.set_minimum_library_initialization_level(godot::MODULE_INITIALIZATION_LEVEL_SCENE);
  
  return init_obj.init();
}
}

namespace godot {
  // ⭐ 全局持有（避免被 ARC 释放）
static ASWebAuthenticationSession *g_session = nil;
static AuthDelegate *g_delegate = nil;

One::One() {}
One::~One() {}

bool One::start_session(const String &url, const String &scheme) {
    // 更安全的字符串转换
  CharString url_cs = url.utf8();
  CharString scheme_cs = scheme.utf8();
  
  UtilityFunctions::print("start_session called");
  
  NSString *ns_url = [NSString stringWithUTF8String:url_cs.get_data()];
  NSString *ns_scheme = [NSString stringWithUTF8String:scheme_cs.get_data()];
  
  NSURL *authURL = [NSURL URLWithString:ns_url];
  
  if (!g_delegate) {
    UtilityFunctions::print("start_session called");
    g_delegate = [[AuthDelegate alloc] init];
  }
  
    // ⭐ 强引用 session
  g_session = [[ASWebAuthenticationSession alloc]
               initWithURL: authURL
               callbackURLScheme: ns_scheme
               completionHandler:^(NSURL *_Nullable callbackURL, NSError *_Nullable error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      if (callbackURL) {
        NSString *urlString = callbackURL.absoluteString ?: @"";
        this->emit_signal("auth_completed", String(urlString.UTF8String));
      } else {
        NSString *errorString = error.localizedDescription ?: @"Unknown error";
        this->emit_signal("auth_failed", String(errorString.UTF8String));
      }
      
        // ⭐ 用完释放（重要）
      g_session = nil;
    });
  }
  ];
  
  g_session.presentationContextProvider = g_delegate;
  
#if TARGET_OS_OSX
    // macOS 推荐开启（避免污染浏览器 cookie）
  if (@available(macOS 10.15, *)) {
    g_session.prefersEphemeralWebBrowserSession = YES;
  }
#endif
  
  BOOL success = [g_session start];
  
  return (bool)success;
}

void One::_bind_methods() {
  ClassDB::bind_method(D_METHOD("start_session", "url", "scheme"), &One::start_session);
  ADD_SIGNAL(MethodInfo("auth_completed", PropertyInfo(Variant::STRING, "callback_url")));
  ADD_SIGNAL(MethodInfo("auth_failed", PropertyInfo(Variant::STRING, "error_message")));
}
}
