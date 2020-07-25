#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(ImagesToVideo, NSObject)

RCT_EXTERN_METHOD(
                  render:(NSDictionary)options
                  withResolver:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject
                  )

@end
