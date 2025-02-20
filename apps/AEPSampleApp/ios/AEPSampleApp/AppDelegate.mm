/*
  Copyright 2022 Adobe. All rights reserved.
  This file is licensed to you under the Apache License, Version 2.0 (the
  "License"); you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
  http://www.apache.org/licenses/LICENSE-2.0 Unless required by applicable law
  or agreed to in writing, software distributed under the License is distributed
  on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS OF ANY KIND, either
  express or implied. See the License for the specific language governing
  permissions and limitations under the License.
 */

#import "AppDelegate.h"

#import <React/RCTBridge.h>
#import <React/RCTBundleURLProvider.h>
#import <React/RCTRootView.h>

#import <React/RCTAppSetupUtils.h>

#if RCT_NEW_ARCH_ENABLED
#import <React/CoreModulesPlugins.h>
#import <React/RCTCxxBridgeDelegate.h>
#import <React/RCTFabricSurfaceHostingProxyRootView.h>
#import <React/RCTSurfacePresenter.h>
#import <React/RCTSurfacePresenterBridgeAdapter.h>
#import <ReactCommon/RCTTurboModuleManager.h>

#import <react/config/ReactNativeConfig.h>

@interface AppDelegate () <RCTCxxBridgeDelegate,
                           RCTTurboModuleManagerDelegate> {
  RCTTurboModuleManager *_turboModuleManager;
  RCTSurfacePresenterBridgeAdapter *_bridgeAdapter;
  std::shared_ptr<const facebook::react::ReactNativeConfig> _reactNativeConfig;
  facebook::react::ContextContainer::Shared _contextContainer;
}
@end
#endif

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  RCTAppSetupPrepareApp(application);

  RCTBridge *bridge = [[RCTBridge alloc] initWithDelegate:self
                                            launchOptions:launchOptions];

#if RCT_NEW_ARCH_ENABLED
  _contextContainer =
      std::make_shared<facebook::react::ContextContainer const>();
  _reactNativeConfig =
      std::make_shared<facebook::react::EmptyReactNativeConfig const>();
  _contextContainer->insert("ReactNativeConfig", _reactNativeConfig);
  _bridgeAdapter = [[RCTSurfacePresenterBridgeAdapter alloc]
        initWithBridge:bridge
      contextContainer:_contextContainer];
  bridge.surfacePresenter = _bridgeAdapter.surfacePresenter;
#endif

  UIView *rootView = RCTAppSetupDefaultRootView(bridge, @"AEPSampleApp", nil);

  if (@available(iOS 13.0, *)) {
    rootView.backgroundColor = [UIColor systemBackgroundColor];
  } else {
    rootView.backgroundColor = [UIColor whiteColor];
  }

  self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  UIViewController *rootViewController = [UIViewController new];
  rootViewController.view = rootView;
  self.window.rootViewController = rootViewController;
  [self.window makeKeyAndVisible];
  [AEPMobileCore setLogLevel:AEPLogLevelTrace];
  [AEPMobileCore
      registerExtensions:@[
        AEPMobileEdgeIdentity.class, AEPMobileEdge.class,
        AEPMobileEdgeConsent.class, AEPMobileMessaging.class,
        AEPMobileOptimize.class, AEPMobilePlaces.class, AEPMobileTarget.class,
        AEPMobileCampaignClassic.class
      ]
              completion:^{
                [AEPMobileCore
                    configureWithAppId:@"YOUR-APP-ID"];
              }];
  return YES;
}

- (NSURL *)sourceURLForBridge:(RCTBridge *)bridge {
#if DEBUG
  return
      [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index"];
#else
  return [[NSBundle mainBundle] URLForResource:@"main"
                                 withExtension:@"jsbundle"];
#endif
}

- (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
            options:
                (NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
  [AEPMobileAssurance startSessionWithUrl:url];
  return true;
}

#if RCT_NEW_ARCH_ENABLED

#pragma mark - RCTCxxBridgeDelegate

- (std::unique_ptr<facebook::react::JSExecutorFactory>)
    jsExecutorFactoryForBridge:(RCTBridge *)bridge {
  _turboModuleManager =
      [[RCTTurboModuleManager alloc] initWithBridge:bridge
                                           delegate:self
                                          jsInvoker:bridge.jsCallInvoker];
  return RCTAppSetupDefaultJsExecutorFactory(bridge, _turboModuleManager);
}

#pragma mark RCTTurboModuleManagerDelegate

- (Class)getModuleClassFromName:(const char *)name {
  return RCTCoreModulesClassProvider(name);
}

- (std::shared_ptr<facebook::react::TurboModule>)
    getTurboModule:(const std::string &)name
         jsInvoker:(std::shared_ptr<facebook::react::CallInvoker>)jsInvoker {
  return nullptr;
}

- (std::shared_ptr<facebook::react::TurboModule>)
    getTurboModule:(const std::string &)name
        initParams:
            (const facebook::react::ObjCTurboModule::InitParams &)params {
  return nullptr;
}

- (id<RCTTurboModule>)getModuleInstanceFromClass:(Class)moduleClass {
  return RCTAppSetupDefaultModuleFromClass(moduleClass);
}

#endif

@end
