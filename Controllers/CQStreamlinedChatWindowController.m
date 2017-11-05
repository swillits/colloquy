//
//  CQStreamlinedChatWindowController.m
//  Colloquy (Application)
//
//  Created by Seth Willits on 11/4/17.
//  Copyright © 2017 Colloquy Project. All rights reserved.
//

#import "CQStreamlinedChatWindowController.h"
#import "JVChatRoomPanel.h"
#import "JVChatRoomMember.h"



@implementation CQStreamlinedChatWindowController
{
	IBOutlet NSView * containerView;
}



- (instancetype)init
{
	return [self initWithWindowNibName:@"CQStreamlinedChatWindowController"];
}


- (instancetype)initWithWindowNibName:(NSNibName)windowNibName
{
	if (!(self = [super initWithWindowNibName:windowNibName])) {
		return nil;
	}
	
	
	
	return self;
}


- (void)windowDidLoad
{
	[super windowDidLoad];
	
	self.window.titleVisibility = NSWindowTitleHidden;
	
}




#pragma mark -
#pragma mark Main UI

- (void)showChatViewController:(id<JVChatViewController>)controller
{
	[self changeActiveChatViewController:controller];
}


- (void)updateInterfaceSwappingOutChatViewController:(id<JVChatViewController>)old
{
	[old.view removeFromSuperview];
	
	if (self.activeChatViewController) {
		self.activeChatViewController.view.frame = containerView.bounds;
		[containerView addSubview:self.activeChatViewController.view];
		[self.window makeFirstResponder:self.activeChatViewController.view.nextKeyView];
	}
}





#pragma mark -
#pragma mark Notifications

- (void)didAddChatViewController:(id <JVChatViewController>)controller
{
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(chatRoomPanelMembersDidChange:) name:JVChatRoomPanelMembersDidChangeNotification object:controller];
	
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(chatRoomInfoDidChange:) name:JVChatViewControllerInfoDidChangeNotificationName object:controller];
	
	if ([controller isKindOfClass:[JVChatRoomPanel class]]) {
		[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(chatRoomMemberInfoDidChange:) name:JVChatRoomMemberInfoDidChangeNotificationName object:controller];
	}
}


- (void)didRemoveChatViewController:(id <JVChatViewController>)controller
{
	[NSNotificationCenter.defaultCenter removeObserver:self name:JVChatRoomPanelMembersDidChangeNotification object:controller];
	[NSNotificationCenter.defaultCenter removeObserver:self name:JVChatViewControllerInfoDidChangeNotificationName object:controller];
	[NSNotificationCenter.defaultCenter removeObserver:self name:JVChatRoomMemberInfoDidChangeNotificationName object:controller];
}


- (void)chatRoomPanelMembersDidChange:(NSNotification *)note
{
	
}


- (void)chatRoomInfoDidChange:(NSNotification *)note
{
	
}


- (void)chatRoomMemberInfoDidChange:(NSNotification *)note
{
	//JVChatRoomPanel * room = note.object;
	
}



- (void)preferencesDidChange
{
	
}






#pragma mark -
#pragma mark 




@end
