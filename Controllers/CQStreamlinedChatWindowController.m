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
#import "MVApplicationController.h"



@implementation CQStreamlinedChatWindowController
{
	IBOutlet NSView * containerView;
	IBOutlet NSMenu * actionMenu;
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

- (void)menuNeedsUpdate:(NSMenu *)menu
{
	if (menu == actionMenu) {
		while (actionMenu.itemArray.count > 1) {
			[actionMenu removeItemAtIndex:1];
		}
		
		if (!self.activeChatViewController) {
			return;
		}
		
		
		NSMenu * chatMenu = self.activeChatViewController.menu;
		
		for (NSMenuItem * menuItem in chatMenu.itemArray) {
			[chatMenu removeItem:menuItem];
			[menu addItem:menuItem];
		}
		
		
		NSMethodSignature *signature = [NSMethodSignature methodSignatureWithReturnAndArgumentTypes:@encode( NSArray * ), @encode( id ), @encode( id ), nil];
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
		id view = self.activeChatViewController;
		
		[invocation setSelector:@selector( contextualMenuItemsForObject:inView: )];
		MVAddUnsafeUnretainedAddress(view, 2)
		MVAddUnsafeUnretainedAddress(view, 3)
		
		NSArray *results = [[MVChatPluginManager defaultManager] makePluginsPerformInvocation:invocation];
		if( [results count] ) {
			if( [menu numberOfItems ] && ! [[[menu itemArray] lastObject] isSeparatorItem] )
				[menu addItem:[NSMenuItem separatorItem]];
			
			NSArray *items = nil;
			for( items in results ) {
				if( ![items conformsToProtocol:@protocol(NSFastEnumeration)] ) {
					continue;
				}
				
				for (NSMenuItem * menuItem in items) {
					if( [menuItem isKindOfClass:[NSMenuItem class]] ) {
						[menu addItem:menuItem];
					}
				}
			}
			
			if( [[[menu itemArray] lastObject] isSeparatorItem] ) {
				[menu removeItem:[[menu itemArray] lastObject]];
			}
		}
	}
}



@end
