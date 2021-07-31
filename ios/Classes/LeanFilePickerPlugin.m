#import "LeanFilePickerPlugin.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <objc/runtime.h>

@interface LeanFilePickerPlugin ()<UIDocumentPickerDelegate>

- (NSString *)fileTypeForExtension:(NSString *)extension;

@end

@implementation LeanFilePickerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    FlutterMethodChannel *channel = [FlutterMethodChannel
        methodChannelWithName:@"lean_file_picker"
              binaryMessenger:[registrar messenger]];
    LeanFilePickerPlugin *instance = [[LeanFilePickerPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    if ([@"pickFile" isEqualToString:call.method]) {
        NSDictionary *arguments = call.arguments;
        NSArray *extensions = arguments[@"allowedExtensions"];
        NSMutableArray *fileTypes = [[NSMutableArray alloc] initWithCapacity:10];
        for (NSString *extension in extensions) {
            NSString *fileType = [self fileTypeForExtension:extension];
            [fileTypes addObject:fileType];
        }

        UIDocumentPickerViewController *documentPicker = [[UIDocumentPickerViewController alloc]
            initWithDocumentTypes:fileTypes
                           inMode:UIDocumentPickerModeImport];
        documentPicker.delegate = self;
        objc_setAssociatedObject(documentPicker, @"result", result, OBJC_ASSOCIATION_RETAIN);

        UIWindow *window = UIApplication.sharedApplication.delegate.window;
        UIViewController *controller = window.rootViewController;
        [controller presentViewController:documentPicker animated:true completion:nil];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (NSString *)fileTypeForExtension:(NSString *)extension {
    CFStringRef fileType = UTTypeCreatePreferredIdentifierForTag(
        kUTTagClassFilenameExtension, (__bridge CFStringRef)extension, NULL);
    return (__bridge_transfer NSString *)fileType;
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller
    didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    FlutterResult result = objc_getAssociatedObject(controller, @"result");
    if (urls.count > 0) {
        result(urls[0].path);
    } else {
        result(nil);
    }
    result(urls[0].absoluteString);
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    FlutterResult result = objc_getAssociatedObject(controller, @"result");
    result(nil);
}

@end
