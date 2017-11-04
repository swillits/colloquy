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
@protocol CQSendViewDelegate;
@protocol JVChatViewController;
NS_ASSUME_NONNULL_BEGIN



@interface CQSendView : NSView

@property (readwrite, weak) IBOutlet id<CQSendViewDelegate> delegate;
@property (readonly) CQSendHistory * history;
@property (readwrite, copy, null_resettable) NSAttributedString * stringToSend;

@property (readwrite, assign) IBOutlet NSTextView * sendTextView;


//! Resizes the text view when JVChatInputAutoResizes pref is true
- (void)resizeToFit;


//! Sends the current string in the text view, handling history as appropriate.
- (void)sendWithConnection:(MVChatConnection *)connection inView:(id<JVChatViewController>)chatView;

@end



@protocol CQSendViewDelegate <NSObject>
// OR.... do we drop the delegate and just send the @selector(send:) action and rely on JVChatConsolePanel etc to catch it? Probably the more idiomatic thing to do.
- (void)sendViewRequestedSend:(CQSendView *)theSendView;

- (void)sendViewWillResize:(CQSendView *)theSendView;
- (void)sendViewDidResize:(CQSendView *)theSendView;

@end



NS_ASSUME_NONNULL_END

