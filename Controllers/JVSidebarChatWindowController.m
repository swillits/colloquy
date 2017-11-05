#import "JVSidebarChatWindowController.h"
#import "JVSideSplitView.h"
#import "JVDetailCell.h"

@implementation JVSidebarChatWindowController
- (id) init {
	return [self initWithWindowNibName:@"JVSidebarChatWindow"];
}

- (id) initWithWindowNibName:(NSString *) windowNibName {
	if( ( self = [super initWithWindowNibName:windowNibName] ) )
		_forceSplitViewPosition = YES;
	return self;
}

- (void) windowDidLoad {
	[super windowDidLoad];

	[chatViewsOutlineView setAllowsEmptySelection:NO];

	[chatViewsOutlineView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleSourceList];

	if( ! [[NSUserDefaults standardUserDefaults] boolForKey:@"JVSidebarSelectedRowHasBlackText"] )
		[[[chatViewsOutlineView outlineTableColumn] dataCell] setBoldAndWhiteOnHighlight:YES];

	[splitView setMainSubviewIndex:1];
	[splitView setPositionUsingName:@"JVSidebarSplitViewPosition"];
	
	[self reloadList];
}











#pragma mark -
#pragma mark Outline View

- (CGFloat) outlineView:(NSOutlineView *) outlineView heightOfRowByItem:(id) item {
	BOOL smallIcons = ([outlineView levelForItem:item] || self.usesSmallIcons);
	if( smallIcons )
		return 18.;
	return 34.;
}

- (void) outlineView:(NSOutlineView *) outlineView willDisplayCell:(id) cell forTableColumn:(NSTableColumn *) tableColumn item:(id) item {
	[super outlineView:outlineView willDisplayCell:cell forTableColumn:tableColumn item:item];

	if( [outlineView levelForItem:item] )
		[(JVDetailCell *)cell setLeftMargin:12.];
	else [(JVDetailCell *)cell setLeftMargin:0.];
}




#pragma mark -
#pragma mark Split View

- (CGFloat) splitView:(NSSplitView *) splitView constrainSplitPosition:(CGFloat) proposedPosition ofSubviewAt:(NSInteger) index {
	// don't do anything here
	return proposedPosition;
}

- (void) splitViewWillResizeSubviews:(NSNotification *) notification {
	// don't do anything here
}

- (void) splitViewDidResizeSubviews:(NSNotification *) notification {
	if( ! _forceSplitViewPosition )
		[splitView savePositionUsingName:@"JVSidebarSplitViewPosition"];
	_forceSplitViewPosition = NO;
}

- (CGFloat) splitView:(NSSplitView *) splitView constrainMinCoordinate:(CGFloat) proposedMin ofSubviewAt:(NSInteger) offset {
//	if( ! [[[chatViewsOutlineView enclosingScrollView] verticalScroller] isHidden] )
//		return 55. + NSWidth( [[[chatViewsOutlineView enclosingScrollView] verticalScroller] frame] );
	return 100.;
}

- (CGFloat) splitView:(NSSplitView *) splitView constrainMaxCoordinate:(CGFloat) proposedMax ofSubviewAt:(NSInteger) offset {
	return 300.;
}

- (BOOL) splitView:(NSSplitView *) splitView canCollapseSubview:(NSView *) subview {
	return NO;
}

- (NSToolbarItem *) toggleChatDrawerToolbarItem {
	return nil;
}



- (void)updateInterfaceSwappingOutChatViewController:(id<JVChatViewController>)old
{
	if (self.activeChatViewController) {
		[[[bodyView subviews] lastObject] removeFromSuperview];

		NSView *newView = [self.activeChatViewController view];
		[newView setAutoresizingMask:( NSViewWidthSizable | NSViewHeightSizable )];
		[newView setFrame:[bodyView bounds]];
		[bodyView addSubview:newView];

		[[self window] makeFirstResponder:[[self.activeChatViewController view] nextKeyView]];

		[self refreshToolbar];
		
	} else {
		[[[bodyView subviews] lastObject] removeFromSuperview];
		
		self.window.toolbar.delegate = nil;
		self.window.toolbar = nil;
	}
	
	[self refreshWindowTitle];
}

@end
