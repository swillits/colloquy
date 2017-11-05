//
//  JVClassicChatWindowController.m
//  Colloquy (Application)
//
//  Created by Seth Willits on 11/4/17.
//  Copyright © 2017 Colloquy Project. All rights reserved.
//

#import "JVClassicChatWindowController.h"
#import "JVDetailCell.h"
#import "MVApplicationController.h"
#import "MVConnectionsController.h"
#import "JVChatRoomPanel.h"
#import "JVDirectChatPanel.h"
#import "JVChatRoomMember.h"



@implementation JVClassicChatWindowController
{
	BOOL _reloadingData;
	BOOL _usesSmallIcons;
}



- (void)windowDidLoad
{
	[super windowDidLoad];
	
	NSTableColumn *column = [chatViewsOutlineView outlineTableColumn];
	JVDetailCell *prototypeCell = [[JVDetailCell alloc] init];
	[prototypeCell setFont:[NSFont toolTipsFontOfSize:11.]];
	[column setDataCell:prototypeCell];
	
	[chatViewsOutlineView setRefusesFirstResponder:YES];
	[chatViewsOutlineView setAutoresizesOutlineColumn:NO];
	[chatViewsOutlineView setDoubleAction:@selector( _doubleClickedListItem: )];
	[chatViewsOutlineView setAutoresizesOutlineColumn:YES];
	[chatViewsOutlineView registerForDraggedTypes:[NSArray arrayWithObjects:JVChatViewPboardType, NSFilenamesPboardType, nil]];
	NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];
	[menu setDelegate:self];
	[chatViewsOutlineView setMenu:menu];
	
	[favoritesButton setMenu:[MVConnectionsController favoritesMenu]];
	[[favoritesButton cell] setAccessibilityLabel:NSLocalizedString(@"Favorites", nil)];
	
	[[viewActionButton cell] setAccessibilityLabel:NSLocalizedString(@"Actions", nil)];
	
	[[NSNotificationCenter chatCenter] addObserver:self selector:@selector(_favoritesListDidUpdate:) name:MVFavoritesListDidUpdateNotification object:nil];
}


- (void)dealloc
{
	[viewsDrawer setDelegate:nil];
	[chatViewsOutlineView setDelegate:nil];
}



- (void)showChatViewController:(id <JVChatViewController>)controller
{
	// Ensure it's selected
	[chatViewsOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:[chatViewsOutlineView rowForItem:controller]] byExtendingSelection:NO];
	[chatViewsOutlineView scrollRowToVisible:[chatViewsOutlineView rowForItem:controller]];
	
	
	// Make it active
	[self changeActiveChatViewController:controller];
}




- (IBAction) getInfo:(id) sender
{
	NSInteger row = [chatViewsOutlineView clickedRow];
	if (row == -1)
		row = [chatViewsOutlineView selectedRow];
	id item = [chatViewsOutlineView itemAtRow:row]; // get the row the user right-clicked
	[self showInspectorForObject:item];
}



- (id <JVInspection>) objectToInspect {
	id item = [self selectedListItem];
	if( [item conformsToProtocol:@protocol( JVInspection )] ) {
		return item;
	}
	
	return nil;
}



- (id <JVChatListItem>) selectedListItem {
	long index = -1;
	if( ( index = [chatViewsOutlineView selectedRow] ) == -1 ) return nil;
	return [chatViewsOutlineView itemAtRow:index];
}





#pragma mark -
#pragma mark List

- (void) reloadListItem:(id <JVChatListItem>) item andChildren:(BOOL) children {
	id selectItem = [self selectedListItem];
	
	[chatViewsOutlineView reloadItem:item reloadChildren:( children && [chatViewsOutlineView isItemExpanded:item] ? YES : NO )];
	
	if( self.activeChatViewController == item )
		[self refreshWindowTitle];
	
	if( [self isMemberOfClass:[JVChatWindowController class]] && [[NSUserDefaults standardUserDefaults] boolForKey:@"JVKeepActiveDrawerPanelsVisible"] && [item isKindOfClass:[JVDirectChatPanel class]] && [(id)item newMessagesWaiting] ) {
		NSRange visibleRows = [chatViewsOutlineView rowsInRect:[chatViewsOutlineView visibleRect]];
		NSInteger row = [chatViewsOutlineView rowForItem:item];
		
		if( ! NSLocationInRange( row, visibleRows ) && row > 0 ) {
			NSInteger index = [self.allChatViewControllers indexOfObjectIdenticalTo:item];
			
			row = ( index > row ? NSMaxRange( visibleRows ) : visibleRows.location + 1 );
			id <JVChatListItem> rowItem = [chatViewsOutlineView itemAtRow:row];
			
			// this will break if the list has more than 2 levels
			if( [chatViewsOutlineView levelForRow:row] > 0 )
				rowItem = [rowItem parent];
			if( rowItem ) row = [self.allChatViewControllers indexOfObjectIdenticalTo:rowItem];
			
			if( rowItem && row != NSNotFound ) {
				assert(false && "Unimplemented");
				// TODO-SW:
				//		[chatViewControllers removeObjectAtIndex:index];
				//		[chatViewControllers insertObject:item atIndex:( index > row || ! row ? row : row - 1 )];
				//		[chatViewsOutlineView reloadData];
			}
		}
	}
	
	if( item == selectItem ) {
		[self _deferRefreshSelectionMenu];
	}
}

- (BOOL) isListItemExpanded:(id <JVChatListItem>) item {
	return [chatViewsOutlineView isItemExpanded:item];
}

- (void) expandListItem:(id <JVChatListItem>) item {
	[chatViewsOutlineView expandItem:item];
}

- (void) collapseListItem:(id <JVChatListItem>) item {
	[chatViewsOutlineView collapseItem:item];
}






#pragma mark -
#pragma mark 

- (void) menuNeedsUpdate:(NSMenu *) menu {
	if (menu == [chatViewsOutlineView menu]) {
		NSInteger clickedRow = [chatViewsOutlineView clickedRow];
		id item = [chatViewsOutlineView itemAtRow:clickedRow];
		if( item ) {
			[self _refreshMenuWithItem:item];
		} else {
			[[chatViewsOutlineView menu] removeAllItems];
		}
	}
}


- (BOOL) validateMenuItem:(NSMenuItem *) menuItem
{
	if( [menuItem action] == @selector( toggleSmallDrawerIcons: ) ) {
		[menuItem setState:( _usesSmallIcons ? NSOnState : NSOffState )];
		return YES;
	} else if( [menuItem action] == @selector( toggleViewsDrawer: ) ) {
		if( [viewsDrawer state] == NSDrawerClosedState || [viewsDrawer state] == NSDrawerClosingState ) {
			[menuItem setTitle:NSLocalizedString( @"Show Drawer", "show drawer menu title" )];
		} else {
			[menuItem setTitle:NSLocalizedString( @"Hide Drawer", "hide drawer menu title" )];
		}
		return YES;
	} else if( [menuItem action] == @selector( getInfo: ) ) {
		NSInteger row = [chatViewsOutlineView clickedRow];
		if (row == -1)
			row = [chatViewsOutlineView selectedRow];
		id item = [chatViewsOutlineView itemAtRow:row]; // get the row the user right-clicked
		if( [item conformsToProtocol:@protocol( JVInspection )] ) return YES;
		else return NO;
	}
	
	return [super validateMenuItem:menuItem];
}





#pragma mark -
#pragma mark 

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


- (void)chatViewControllersDidChange
{
	[super chatViewControllersDidChange];
	[self reloadList];
}


- (void)chatRoomPanelMembersDidChange:(NSNotification *)note
{
	[self reloadList];
}


- (void)chatRoomInfoDidChange:(NSNotification *)note
{
	[self reloadListItem:note.object andChildren:NO];
}


- (void)chatRoomMemberInfoDidChange:(NSNotification *)note
{
	JVChatRoomPanel * room = note.object;
	[self reloadListItem:room andChildren:NO];
}





#pragma mark -
#pragma mark Outline View

- (void) outlineView:(NSOutlineView *) outlineView willDisplayCell:(id) cell forTableColumn:(NSTableColumn *) tableColumn item:(id) item {
	[(JVDetailCell *) cell setRepresentedObject:item];
	[(JVDetailCell *) cell setMainText:[item title]];

	if( [item respondsToSelector:@selector( information )] ) {
		[(JVDetailCell *) cell setInformationText:[item information]];
	} else [(JVDetailCell *) cell setInformationText:nil];

	if( [item respondsToSelector:@selector( statusImage )] ) {
		[(JVDetailCell *) cell setStatusImage:[item statusImage]];
	} else [(JVDetailCell *) cell setStatusImage:nil];

	if( [item respondsToSelector:@selector( isEnabled )] ) {
		[cell setEnabled:[item isEnabled]];
	} else [cell setEnabled:YES];

	if( [item respondsToSelector:@selector( newMessagesWaiting )] ) {
		[(JVDetailCell *) cell setStatusNumber:[item newMessagesWaiting]];
	} else [(JVDetailCell *) cell setStatusNumber:0];

	if( [item respondsToSelector:@selector( newHighlightMessagesWaiting )] ) {
		[(JVDetailCell *) cell setImportantStatusNumber:[item newHighlightMessagesWaiting]];
	} else [(JVDetailCell *) cell setImportantStatusNumber:0];
}

- (NSString *) outlineView:(NSOutlineView *) outlineView toolTipForCell:(NSCell *) cell rect:(NSRectPointer) rect tableColumn:(NSTableColumn *) tableColumn item:(id) item mouseLocation:(NSPoint) mouseLocation {
	if( [item respondsToSelector:@selector( toolTip )] )
		return [item toolTip];
	return @"";
}

- (NSString *) outlineView:(NSOutlineView *) outlineView toolTipForItem:(id) item inTrackingRect:(NSRect) rect forCell:(id) cell {
	if( [item respondsToSelector:@selector( toolTip )] )
		return [item toolTip];
	return nil;
}

- (NSInteger) outlineView:(NSOutlineView *) outlineView numberOfChildrenOfItem:(id) item {
	if( item && [item respondsToSelector:@selector( numberOfChildren )] ) return [item numberOfChildren];
	else return [self.allChatViewControllers count];
}

- (BOOL) outlineView:(NSOutlineView *) outlineView isItemExpandable:(id) item {
	return ( [item respondsToSelector:@selector( numberOfChildren )] && [item numberOfChildren] ? YES : NO );
}

- (id) outlineView:(NSOutlineView *) outlineView child:(NSInteger) index ofItem:(id) item {
	if( item ) {
		if( [item respondsToSelector:@selector( childAtIndex: )] )
			return [item childAtIndex:index];
		else return nil;
	} else return [self.allChatViewControllers objectAtIndex:index];
}

- (id) outlineView:(NSOutlineView *) outlineView objectValueForTableColumn:(NSTableColumn *) tableColumn byItem:(id) item {
	float maxSideSize = ( ( _usesSmallIcons || [outlineView levelForRow:[outlineView rowForItem:item]] ) ? 16. : 32. );
	NSImage *org = [item icon];

	if( [org size].width > maxSideSize || [org size].height > maxSideSize ) {
		NSImage *ret = [[item icon] copy];
		[ret setSize:NSMakeSize( maxSideSize, maxSideSize )];
		org = ret;
	}

	return org;
}

- (BOOL) outlineView:(NSOutlineView *) outlineView shouldEditTableColumn:(NSTableColumn *) tableColumn item:(id) item {
	return NO;
}

- (BOOL) outlineView:(NSOutlineView *) outlineView shouldExpandItem:(id) item {
	if( [[[NSApplication sharedApplication] currentEvent] type] == NSLeftMouseDragged ) return NO; // if we are dragging don't expand
	return YES;
}

- (BOOL) outlineView:(NSOutlineView *) outlineView shouldCollapseItem:(id) item {
	if( [self selectedListItem] != [self activeChatViewController] )
		[outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:[outlineView rowForItem:[self activeChatViewController]]] byExtendingSelection:NO];
	return YES;
}

- (int) outlineView:(NSOutlineView *) outlineView heightOfRow:(int) row {
	return ( [outlineView levelForRow:row] || _usesSmallIcons ? 16 : 34 );
}

- (void) outlineViewSelectionDidChange:(NSNotification *) notification {
	id item = [self selectedListItem];

	[[JVInspectorController sharedInspector] inspectObject:[self objectToInspect]];

	if (item && [item conformsToProtocol:@protocol( JVChatViewController )]) {
		[self showChatViewController:item];
	}
}

- (BOOL) outlineView:(NSOutlineView *) outlineView writeItems:(NSArray *) items toPasteboard:(NSPasteboard *) board {
	id item = [items lastObject];
	if( ! [item conformsToProtocol:@protocol( JVChatViewController )] ) return NO;
	[board declareTypes:[NSArray arrayWithObjects:JVChatViewPboardType, nil] owner:self];
	[board setString:[item identifier] forType:JVChatViewPboardType];
	return YES;
}

- (NSDragOperation) outlineView:(NSOutlineView *) outlineView validateDrop:(id <NSDraggingInfo>) info proposedItem:(id) item proposedChildIndex:(NSInteger) index {
	if( [[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:NSFilenamesPboardType]] ) {
		if( [item respondsToSelector:@selector( acceptsDraggedFileOfType: )] ) {
			NSArray *files = [[info draggingPasteboard] propertyListForType:NSFilenamesPboardType];
			id file = nil;

			for( file in files )
				if( [item acceptsDraggedFileOfType:[file pathExtension]] )
					return NSDragOperationMove;

			return NSDragOperationNone;
		} else return NSDragOperationNone;
	} else if( [[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:JVChatViewPboardType]] ) {
		if( ! item ) return NSDragOperationMove;
		else return NSDragOperationNone;
	} else return NSDragOperationNone;
}

- (BOOL) outlineView:(NSOutlineView *) outlineView acceptDrop:(id <NSDraggingInfo>) info item:(id) item childIndex:(NSInteger) index {
	NSPasteboard *board = [info draggingPasteboard];
	if( [board availableTypeFromArray:[NSArray arrayWithObject:NSFilenamesPboardType]] ) {
		NSArray *files = [[info draggingPasteboard] propertyListForType:NSFilenamesPboardType];
		id file = nil;

		if( ! [item respondsToSelector:@selector( acceptsDraggedFileOfType: )] || ! [item respondsToSelector:@selector( handleDraggedFile: )] ) return NO;

		for( file in files )
			if( [item acceptsDraggedFileOfType:[file pathExtension]] )
				[item handleDraggedFile:file];

		return YES;
	} else if( [board availableTypeFromArray:[NSArray arrayWithObject:JVChatViewPboardType]] ) {
		NSString *identifierString = [board stringForType:JVChatViewPboardType];
		id <JVChatViewController> draggedController = [self chatViewControllerForIdentifier:identifierString];
		
		// Reordering
		if ([self.allChatViewControllers containsObject:draggedController]) {
			if( index != NSOutlineViewDropOnItemIndex && index >= (int) [self.allChatViewControllers indexOfObjectIdenticalTo:draggedController] ) {
				index--;
			}
			
			if (index == NSOutlineViewDropOnItemIndex) {
				index = self.allChatViewControllers.count - 1;
			}
			
			[self moveChatViewController:draggedController toIndex:index];
			
		// Moving between windows
		} else {
			[[draggedController windowController] removeChatViewController:draggedController];
			[[draggedController windowController] addChatViewController:draggedController];
		}

		return YES;
	}

	return NO;
}

- (void) outlineViewItemDidCollapse:(NSNotification *) notification {
	[chatViewsOutlineView performSelector:@selector( sizeLastColumnToFit ) withObject:nil afterDelay:0.];
	[chatViewsOutlineView performSelector:@selector( display ) withObject:nil afterDelay:0.];
	id item = [[notification userInfo] objectForKey:@"NSObject"];
	if( [item respondsToSelector:@selector( setPreference:forKey: )] )
		[(id)item setPreference:[NSNumber numberWithBool:NO] forKey:@"expanded"];
}

- (void) outlineViewItemDidExpand:(NSNotification *) notification {
	[chatViewsOutlineView performSelector:@selector( sizeLastColumnToFit ) withObject:nil afterDelay:0.];
	id item = [[notification userInfo] objectForKey:@"NSObject"];
	if( [item respondsToSelector:@selector( setPreference:forKey: )] )
		[(id)item setPreference:[NSNumber numberWithBool:YES] forKey:@"expanded"];
}


- (void) _doubleClickedListItem:(id) sender {
	id item = [self selectedListItem];
	if( [item respondsToSelector:@selector( doubleClicked: )] )
		[item doubleClicked:sender];
}





#pragma mark -
#pragma mark Drawer

- (NSToolbarItem *) toggleChatDrawerToolbarItem {
	NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:JVToolbarToggleChatDrawerItemIdentifier];
	
	[toolbarItem setLabel:NSLocalizedString( @"Drawer", "chat panes drawer toolbar item name" )];
	[toolbarItem setPaletteLabel:NSLocalizedString( @"Panel Drawer", "chat panes drawer toolbar customize palette name" )];
	
	[toolbarItem setToolTip:NSLocalizedString( @"Toggle Chat Panel Drawer", "chat panes drawer toolbar item tooltip" )];
	[toolbarItem setImage:[NSImage imageNamed:@"showdrawer"]];
	
	[toolbarItem setTarget:self];
	[toolbarItem setAction:@selector( toggleViewsDrawer: )];
	
	return toolbarItem;
}

- (IBAction) toggleViewsDrawer:(id) sender {
	if( [viewsDrawer state] == NSDrawerClosedState || [viewsDrawer state] == NSDrawerClosingState )
		[self openViewsDrawer:sender];
	else if( [viewsDrawer state] == NSDrawerOpenState || [viewsDrawer state] == NSDrawerOpeningState )
		[self closeViewsDrawer:sender];
}

- (IBAction) openViewsDrawer:(id) sender {
	NSInteger side = [[NSUserDefaults standardUserDefaults] integerForKey:@"JVChatWindowDrawerSide"];
	if( side == -1 ) [viewsDrawer openOnEdge:NSMinXEdge];
	else if( side == 1 ) [viewsDrawer openOnEdge:NSMaxXEdge];
	else [viewsDrawer open];
	
	[self setPreference:[NSNumber numberWithBool:YES] forKey:@"drawer open"];
}

- (IBAction) closeViewsDrawer:(id) sender {
	[viewsDrawer close];
	[self setPreference:[NSNumber numberWithBool:NO] forKey:@"drawer open"];
}

- (IBAction) toggleSmallDrawerIcons:(id) sender {
	_usesSmallIcons = ! _usesSmallIcons;
	[self setPreference:[NSNumber numberWithBool:_usesSmallIcons] forKey:@"small drawer icons"];
	[self reloadList];
}



- (NSSize) drawerWillResizeContents:(NSDrawer *) drawer toSize:(NSSize) contentSize {
	[self setPreference:NSStringFromSize( contentSize ) forKey:@"drawer size"];
	return contentSize;
}





#pragma mark -
#pragma mark Toolbar

#pragma mark -

- (NSToolbarItem *) toolbar:(NSToolbar *) toolbar itemForItemIdentifier:(NSString *) identifier willBeInsertedIntoToolbar:(BOOL) willBeInserted {
	NSMethodSignature *signature = [NSMethodSignature methodSignatureWithReturnAndArgumentTypes:@encode( NSToolbarItem * ), @encode( NSString * ), @encode( id ), @encode( BOOL ), nil];
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
	
	id vc = self.activeChatViewController;
	
	[invocation setSelector:@selector( toolbarItemForIdentifier:inView:willBeInsertedIntoToolbar: )];
	MVAddUnsafeUnretainedAddress(identifier, 2)
	MVAddUnsafeUnretainedAddress(vc, 3)
	[invocation setArgument:&willBeInserted atIndex:4];
	
	NSArray *items = [[MVChatPluginManager defaultManager] makePluginsPerformInvocation:invocation stoppingOnFirstSuccessfulReturn:YES];
	if( [[items lastObject] isKindOfClass:[NSToolbarItem class]] )
		return [items lastObject];
	
	if( [self.activeChatViewController respondsToSelector:@selector( toolbar:itemForItemIdentifier:willBeInsertedIntoToolbar: )] ) {
		NSToolbarItem *item = [(id)self.activeChatViewController toolbar:toolbar itemForItemIdentifier:identifier willBeInsertedIntoToolbar:willBeInserted];
		if( item ) return item;
	}
	
	if( [identifier isEqualToString:JVToolbarToggleChatDrawerItemIdentifier] )
		return [self toggleChatDrawerToolbarItem];
	
	return nil;
}

- (NSArray *) toolbarDefaultItemIdentifiers:(NSToolbar *) toolbar {
	NSMutableArray *result = [NSMutableArray arrayWithObject:JVToolbarToggleChatDrawerItemIdentifier];
	
	if( [self.activeChatViewController respondsToSelector:@selector( toolbarDefaultItemIdentifiers: )] ) {
		NSArray *identifiers = [(id)self.activeChatViewController toolbarDefaultItemIdentifiers:toolbar];
		if( identifiers ) [result addObjectsFromArray:identifiers];
	}
	
	return result;
}

- (NSArray *) toolbarAllowedItemIdentifiers:(NSToolbar *) toolbar {
	NSMutableArray *result = [NSMutableArray arrayWithObjects:NSToolbarFlexibleSpaceItemIdentifier, NSToolbarSpaceItemIdentifier,
							  NSToolbarSeparatorItemIdentifier, NSToolbarCustomizeToolbarItemIdentifier, JVToolbarToggleChatDrawerItemIdentifier, nil];
	
	if( [self.activeChatViewController respondsToSelector:@selector( toolbarAllowedItemIdentifiers: )] ) {
		NSArray *identifiers = [(id)self.activeChatViewController toolbarAllowedItemIdentifiers:toolbar];
		if( [identifiers count] ) [result addObjectsFromArray:identifiers];
	}
	
	NSMethodSignature *signature = [NSMethodSignature methodSignatureWithReturnAndArgumentTypes:@encode( NSArray * ), @encode( id ), nil];
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
	
	id vc = self.activeChatViewController;
	
	[invocation setSelector:@selector( toolbarItemIdentifiersForView: )];
	MVAddUnsafeUnretainedAddress(vc, 2)
	
	NSArray *results = [[MVChatPluginManager defaultManager] makePluginsPerformInvocation:invocation];
	if( [results count] ) {
		NSArray *identifiers = nil;
		
		for( identifiers in results )
			if( [identifiers isKindOfClass:[NSArray class]] && [identifiers count] )
				[result addObjectsFromArray:identifiers];
	}
	
	return result;
}

- (BOOL) validateToolbarItem:(NSToolbarItem *) toolbarItem {
	return YES;
}













#pragma mark -
#pragma mark 

- (void) _deferRefreshSelectionMenu {
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_refreshSelectionMenu) object:nil];
	[self performSelector:@selector(_refreshSelectionMenu) withObject:nil afterDelay:0.];
}

- (void) _refreshSelectionMenu {
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_refreshSelectionMenu) object:nil];
	
	id item = [self selectedListItem];
	if( ! item ) item = [self activeChatViewController];
	[self _refreshMenuWithItem:item];
}


- (void) _refreshMenuWithItem:(id) item {
	[MVConnectionsController refreshFavoritesMenu];

	id menuItem = nil;
	NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];
	[menu setDelegate:self];

	NSMenu *newMenu = ( [item respondsToSelector:@selector( menu )] ? [item menu] : nil );

	for( menuItem in [[newMenu itemArray] copy] ) {
		[newMenu removeItem:menuItem];
		[menu addItem:menuItem];
	}

	NSMethodSignature *signature = [NSMethodSignature methodSignatureWithReturnAndArgumentTypes:@encode( NSArray * ), @encode( id ), @encode( id ), nil];
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
	id view = [item parent];
	if( ! view ) view = item;

	[invocation setSelector:@selector( contextualMenuItemsForObject:inView: )];
	MVAddUnsafeUnretainedAddress(item, 2)
	MVAddUnsafeUnretainedAddress(view, 3)

	NSArray *results = [[MVChatPluginManager defaultManager] makePluginsPerformInvocation:invocation];
	if( [results count] ) {
		if( [menu numberOfItems ] && ! [[[menu itemArray] lastObject] isSeparatorItem] )
			[menu addItem:[NSMenuItem separatorItem]];

		NSArray *items = nil;
		for( items in results ) {
			if( ![items conformsToProtocol:@protocol(NSFastEnumeration)] )
				continue;

			for( menuItem in items)
				if( [menuItem isKindOfClass:[NSMenuItem class]] )
					[menu addItem:menuItem];
		}

		if( [[[menu itemArray] lastObject] isSeparatorItem] )
			[menu removeItem:[[menu itemArray] lastObject]];
	}

	if( [menu numberOfItems] ) {
		[viewActionButton setEnabled:YES];
		[viewActionButton setMenu:menu];
	} else [viewActionButton setEnabled:NO];

	[chatViewsOutlineView setMenu:[menu copy]];
}



- (void)reloadList {
	if (_reloadingData)
		return;
	
	_reloadingData = YES;
	
	id selectItem = [self selectedListItem];
	
	[chatViewsOutlineView reloadData];
	[chatViewsOutlineView sizeLastColumnToFit];
	
	if (selectItem) {
		[chatViewsOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:[chatViewsOutlineView rowForItem:selectItem]] byExtendingSelection:NO];
	}
	
	_reloadingData = NO;
}



- (void)refreshWindowTitle {
	NSString *title = [self.activeChatViewController windowTitle];
	if( ! title ) title = @"";
	[[self window] setTitle:title];
}


- (void) refreshToolbar {
	NSToolbar *oldToolbar = [[self window] toolbar];
	BOOL oldToolbarVisisble = [oldToolbar isVisible];
	
	NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:[self.activeChatViewController toolbarIdentifier]];
	[toolbar setDelegate:self];
	[toolbar setAllowsUserCustomization:YES];
	[toolbar setAutosavesConfiguration:YES];
	
	[[self window] setToolbar:toolbar];
	
	if( oldToolbar ) {
		[toolbar setDisplayMode:[oldToolbar displayMode]];
		[toolbar setSizeMode:[oldToolbar sizeMode]];
		[toolbar setVisible:oldToolbarVisisble];
	}
	
}




- (void) preferencesDidChange {
	NSSize drawerSize = NSSizeFromString( [self preferenceForKey:@"drawer size"] );
	if( drawerSize.width ) [viewsDrawer setContentSize:drawerSize];
	
	if( [[self preferenceForKey:@"drawer open"] boolValue] )
		[self performSelector:@selector( openViewsDrawer: ) withObject:nil afterDelay:0.0];
	
	_usesSmallIcons = [[self preferenceForKey:@"small drawer icons"] boolValue];
}


@synthesize usesSmallIcons = _usesSmallIcons;


- (void) _favoritesListDidUpdate:(NSNotification *) notification {
	[self _refreshMenuWithItem:notification.object];
}

@end
