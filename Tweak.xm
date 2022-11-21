#include <unistd.h>
#include <stdio.h>
#import <UIKit/UIKit.h>

//////////////////////////////////////////
///// Hooking just for more logging!
//////////////////////////////////////////
@interface MQTTMessage
- (NSString *) payloadString;
@end

%hook MQTTClient
- ( void ( ^ )( MQTTMessage * ) ) messageHandler {
	__auto_type oriHandler = %orig;
	return ^(MQTTMessage *msg) {
		NSLog(@"Got mqtt msg: %@", [msg payloadString]);
		oriHandler(msg);
	};
}
- ( void ( ^ )( id ) ) disconnectHandler {
	__auto_type oriHandler = %orig;
	return ^(id msg) {
		NSLog(@"MQTT Disconnected: %@", msg);
		oriHandler(msg);
	};
}
- ( void ( ^ )( id ) ) connectionCompletionHandler {
	__auto_type oriHandler = %orig;
	return ^(id msg) {
		NSLog(@"MQTT Connected: %@", msg);
		oriHandler(msg);
	};
}
%end

@interface HistoryService
- (BOOL) isRunning;
@end
%hook HistoryService
- (void) process {
	NSLog(@"HistoryService processing, cur isProcessing: %d", [self isRunning]);
	%orig;
}
%end

%hook ZeroManager // for debug only
- (BOOL)decryptFileFrom:(NSString *)fromFile toFile:(NSString *)toFile {
	BOOL ret = %orig;
	NSString *fileContents = [NSString stringWithContentsOfFile:toFile encoding:NSUTF8StringEncoding error:nil];
	NSLog(@"decrypted file %@: %@", toFile, fileContents);
	return ret;
}
%end

//////////////////////////////////////////
///// Real magic starts below!
//////////////////////////////////////////
%hook UIDevice
- (BOOL)isPad {
	return YES; // force changeCount timer!
}
%end

@interface DBKeeper
+ (NSArray *) getHistories:(int64_t)count;
@end


@interface HistoryModel
- (NSString *) content;
@end


@interface ClipManager
+ (ClipManager *)sharedInstance;
- (void)setLastChangeCount:(int64_t)count;
- (void)sendTextToClipboard:(HistoryModel *)hist callback:(id)cb;
@end

%hook ClipManager

- (void)init {
	//lastClipboardCount = [[UIPasteboard generalPasteboard] changeCount];
	%orig;
}

%new 
- (void)historyDownloaded:(id)unk {
	NSLog(@"historyDownloaded!");
	NSArray *lastHistoryArr = [%c(DBKeeper) getHistories:1];
	if ([lastHistoryArr count] != 1) {
		return;
	}

	NSInteger oriChangeCount = [[UIPasteboard generalPasteboard] changeCount];
	[self setLastChangeCount:oriChangeCount + 1];
	
	HistoryModel *lastHistory = lastHistoryArr[0];
	NSLog(@"Got qtier clip length %@", lastHistory);
	
	// [UIPasteboard generalPasteboard].string = [lastHistory content]; // use QTier's own implementation so that image can be copied
	bool __block succ = false;
	[self sendTextToClipboard:lastHistory callback:^() {
		NSLog(@"ClipboardCount: %ld -> %ld", (long)oriChangeCount, (long)[[UIPasteboard generalPasteboard] changeCount]);
		succ = true;
	}];
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		if (!succ && [[UIPasteboard generalPasteboard] changeCount] == oriChangeCount) {
			NSLog(@"Warning: QTier clip -> System Clip failed, cur clipChangeCount is %ld!", oriChangeCount);
			// [self setLastChangeCount:oriChangeCount]; // if I set the clipboard I'm afraid we will shake the clipboardCount back and forth
		}
	});
}

- (void)clipboardChanged {
	NSLog(@"Got new iCloud clip: %@", [UIPasteboard generalPasteboard]);
	%orig;
}

%end

id delegate = nil;

void Init() {
	delegate = [%c(AppDelegate) alloc];
	NSLog(@"calling didFinishLaunchingWithOptions");
	[delegate application:delegate didFinishLaunchingWithOptions:0];
	NSLog(@"calling applicationDidBecomeActive");
	[delegate applicationDidBecomeActive:delegate];

	NSLog(@"adding qtier observer");
	[[NSNotificationCenter defaultCenter] 
		addObserver:[%c(ClipManager) sharedInstance] selector:@selector(historyDownloaded:) name:@"FILE_DOWNLOAD_DONE" object:nil];

	NSLog(@"finish init!");
}


// Trying to make UIApplicationMain working here, but I failed :(
// extern "C" {
// 	extern void _GSEventInitializeApp(dispatch_queue_t queue);
// 	extern void GSRegisterPulpleNamedPerPIDPort(void);
// }
//
// void *p_GSEventInitializeApp = NULL;
// %hookf(void, p_GSEventInitializeApp, void *) {
// 	printf("Stop GraphicsService init!\n");
// 	return;
// }
//
// %hookf(void, _GSEventInitializeApp, void *) {
// 	printf("Stop GraphicsService init!\n");
// 	return;
// }

%hookf(void, UIApplicationMain, int) {
	printf("Entered main!\n");
	
	// while (1) {
	// 	sleep(100);
	// } // mustn't sleep, or main queue won't run and anything will be blocking
	// dispatch_main(); // dispatch_main will abort the program :(
	
	dispatch_async(dispatch_get_main_queue(), ^() {
		Init();
	});
	CFRunLoopRun();
}

%ctor {
	NSLog(@"injected!\n");
	// p_GSEventInitializeApp = MSFindSymbol(MSGetImageByName("/System/Library/PrivateFrameworks/GraphicsServices.framework/GraphicsServices"), "__GSEventInitializeApp");
	// NSLog(@"found GSEventInitializeApp: %p\n", p_GSEventInitializeApp);
	%init;
}