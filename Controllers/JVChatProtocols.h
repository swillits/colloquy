//
//  JVChatProtocols.h
//  Colloquy (Application)
//
//  Created by Seth Willits on 11/5/17.
//  Copyright © 2017 Colloquy Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class JVChatWindowController;
@protocol JVChatListItem;


//! Posted whenever view controller info changes, which might be displayed and therefor needs redisplay.
extern NSString * const JVChatViewControllerInfoDidChangeNotificationName;


// Including: JVChatTranscriptPanel, JVChatConsolePanel, JVFScriptConsolePanel
@protocol JVChatViewController <JVChatListItem>
@optional
- (id <JVChatViewController>) activeChatViewController;

@required
- (MVChatConnection *) connection;

- (JVChatWindowController *) windowController;
- (void) setWindowController:(JVChatWindowController *) controller;

- (NSView *) view;
- (NSResponder *) firstResponder;
- (NSString *) toolbarIdentifier;
- (NSString *) windowTitle;
- (NSString *) identifier;


@optional
- (void) willSelect;
- (void) didSelect;

- (void) willUnselect;
- (void) didUnselect;

- (void) willDispose;

//! Called at certain times when the view has been seen by the user (eg, the window becomes key while the view controller is visible) 
- (void)didGetNoticedByUser;
@end




// JVCatViewController, JVChatRoomMember
@protocol JVChatListItem <NSObject>
- (id <JVChatListItem>) parent;
- (NSImage *) icon;
- (NSString *) title;


@optional

- (BOOL) acceptsDraggedFileOfType:(NSString *) type;
- (void) handleDraggedFile:(NSString *) path;
- (IBAction) doubleClicked:(id) sender;
- (BOOL) isEnabled;

- (NSMenu *) menu;
- (NSString *) information;
- (NSString *) toolTip;
- (NSImage *) statusImage;

- (NSUInteger) numberOfChildren;
- (id) childAtIndex:(NSUInteger) index;
@end




@protocol JVCanHaveNewMessages <NSObject>
- (NSUInteger) newMessagesWaiting;
- (NSUInteger) newHighlightMessagesWaiting;
@end

