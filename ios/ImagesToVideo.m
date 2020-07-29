#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(ImagesToVideo, NSObject)

RCT_EXTERN_METHOD(
                  render:(NSDictionary)options
                  withResolver:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject
                  )

// https://reactnative.dev/docs/native-modules-ios#implementing--requiresmainqueuesetup
+ (BOOL)requiresMainQueueSetup
{
  return NO;
}

@end
