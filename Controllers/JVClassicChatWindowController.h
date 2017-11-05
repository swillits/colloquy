//
//  JVClassicChatWindowController.h
//  Colloquy (Application)
//
//  Created by Seth Willits on 11/4/17.
//  Copyright © 2017 Colloquy Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JVChatWindowController.h"


// Everything that was specific to the UI of the sidebar and tabbed chat windows has been moved out of JVChatWindowController and into this controller to continue supporting those classes, while JVChatWindowController can become an entirely abstract UI-non-specific base class which new UIs can be implemented ontop of. 

@interface JVClassicChatWindowController : JVChatWindowController
{
	IBOutlet NSDrawer *viewsDrawer;
	IBOutlet NSOutlineView *chatViewsOutlineView;

	IBOutlet NSButton *viewActionButton;
	IBOutlet NSButton *favoritesButton;
}


@property (readonly) BOOL usesSmallIcons;
@property (readonly) id <JVChatListItem> selectedListItem;

- (NSToolbarItem *) toggleChatDrawerToolbarItem;
- (IBAction) toggleViewsDrawer:(id) sender;
- (IBAction) openViewsDrawer:(id) sender;
- (IBAction) closeViewsDrawer:(id) sender;
- (IBAction) toggleSmallDrawerIcons:(id) sender;


- (void)refreshWindowTitle;
- (void)refreshToolbar;


// Reloads the chats/members shown in the list
- (void)reloadList;


- (id <JVInspection>) objectToInspect;
- (void) _deferRefreshSelectionMenu;
- (void) _refreshSelectionMenu;
- (void) _refreshMenuWithItem:(id) item;

@end
