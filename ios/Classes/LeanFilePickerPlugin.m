#import "LeanFilePickerPlugin.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <objc/runtime.h>

@interface LeanFilePickerPlugin ()<UIDocumentPickerDelegate, FlutterStreamHandler>
@end

@implementation LeanFilePickerPlugin {
    FlutterEventSink eventSink;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    FlutterMethodChannel *channel = [FlutterMethodChannel
        methodChannelWithName:@"lean_file_picker"
              binaryMessenger:[registrar messenger]];
    LeanFilePickerPlugin *instance = [[LeanFilePickerPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];

    FlutterEventChannel *eventChannel = [FlutterEventChannel
        eventChannelWithName:@"lean_file_picker_events"
             binaryMessenger:[registrar messenger]];
    [eventChannel setStreamHandler:instance];
}

- (FlutterError *)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)events {
    eventSink = events;
    return nil;
}

- (FlutterError *)onCancelWithArguments:(id)arguments {
    eventSink = nil;
    return nil;
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    if ([@"pickFile" isEqualToString:call.method]) {
        NSDictionary *arguments = call.arguments;
        NSArray *extensions = arguments[@"allowedExtensions"];
        if ([extensions isKindOfClass:[NSNull class]]) {
            extensions = [NSArray array];
        }
        NSArray *mimeTypes = arguments[@"allowedMimeTypes"];
        if ([mimeTypes isKindOfClass:[NSNull class]]) {
            mimeTypes = [NSArray array];
        }
        [self pickFile:result extensions:extensions mimeTypes:mimeTypes];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)pickFile:(FlutterResult)result extensions:(NSArray<NSString *> *)extensions mimeTypes:(NSArray<NSString *> *)mimeTypes {
    NSUInteger capacity = extensions.count + mimeTypes.count;
    NSMutableArray *fileTypes = [[NSMutableArray alloc] initWithCapacity:capacity];
    [fileTypes addObjectsFromArray:mimeTypes];
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
