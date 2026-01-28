//
//  Generated file. Do not edit.
//

// clang-format off

#import "GeneratedPluginRegistrant.h"

#if __has_include(<flutter_app_group_directory/FlutterAppGroupDirectoryPlugin.h>)
#import <flutter_app_group_directory/FlutterAppGroupDirectoryPlugin.h>
#else
@import flutter_app_group_directory;
#endif

#if __has_include(<live_activities/LiveActivitiesPlugin.h>)
#import <live_activities/LiveActivitiesPlugin.h>
#else
@import live_activities;
#endif

#if __has_include(<permission_handler_apple/PermissionHandlerPlugin.h>)
#import <permission_handler_apple/PermissionHandlerPlugin.h>
#else
@import permission_handler_apple;
#endif

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [FlutterAppGroupDirectoryPlugin registerWithRegistrar:[registry registrarForPlugin:@"FlutterAppGroupDirectoryPlugin"]];
  [LiveActivitiesPlugin registerWithRegistrar:[registry registrarForPlugin:@"LiveActivitiesPlugin"]];
  [PermissionHandlerPlugin registerWithRegistrar:[registry registrarForPlugin:@"PermissionHandlerPlugin"]];
}

@end
