//
//  CQSendView.h
//  Colloquy (Application)
//
//  Created by Seth Willits on 11/4/17.
//  Copyright © 2017 Colloquy Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MVTextView;
@class CQSendHistory;
@class MVChatConnection;
@protocol CQSendCompletionHandler;
@protocol CQSendViewDelegate;
@protocol JVChatViewController;
NS_ASSUME_NONNULL_BEGIN



@interface CQSendViewController : NSViewController

@property (readwrite, weak) IBOutlet id<CQSendViewDelegate> delegate;
@property (readwrite, retain) id<CQSendCompletionHandler> completionHandler;
@property (readonly) CQSendHistory * history;


@property (readwrite, copy, null_resettable) NSAttributedString * stringToSend;
@property (readonly) BOOL stringToSendIsACommand;

@property (readwrite, assign) IBOutlet MVTextView * sendTextView;
@property (readwrite, assign) IBOutlet NSButton * emoticonButton;

//! Inserts the emoticon text into the text view;
- (void)insertEmoticon:(NSString *)emoticon;

//! Resizes the text view when JVChatInputAutoResizes pref is true
- (void)resizeToFit;

//! Sends the current string in the text view, handling history as appropriate.
- (void)sendWithConnection:(MVChatConnection *)connection asAction:(BOOL)asAction inView:(id<JVChatViewController>)chatView;


//! Returns YES if the string, which is potentially large, should be sent (either because prefs say so, or user agreed)
- (BOOL)confirmSendingLargeMessage:(NSString *)stringToSend;

@end



typedef NS_OPTIONS(NSUInteger, CQSendViewOptions) {
	CQSendViewSendAsAction = 1 << 0
};



@protocol CQSendViewDelegate <NSObject>
- (void)sendViewRequestedSend:(CQSendViewController *)sendVC options:(CQSendViewOptions)options;
- (void)sendViewWillResize:(CQSendViewController *)sendVC;
- (void)sendViewDidResize:(CQSendViewController *)sendVC;

@optional
- (void)sendView:(CQSendViewController *)sendView sendCommand:(NSString *)command withArguments:(NSAttributedString * _Nullable)arguments;
- (void)sendView:(CQSendViewController *)sendView sendMessage:(NSAttributedString *)message asAction:(BOOL)asAction;

//! Page Up, Page Down, Home, Begin, End was pressed.
- (void)sendView:(CQSendViewController *)sendView navigationKeyPressed:(NSEvent *)event;
@end



NS_ASSUME_NONNULL_END

