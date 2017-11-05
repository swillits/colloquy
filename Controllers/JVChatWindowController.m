#import "JVChatWindowController.h"
#import "MVApplicationController.h"
#import "MVConnectionsController.h"
#import "JVSmartTranscriptPanel.h"
#import "JVChatController.h"
#import "JVChatRoomPanel.h"
#import "JVChatConsolePanel.h"
#import "JVChatRoomBrowser.h"
#import "JVDirectChatPanel.h"

#import "MVMenuButton.h"

typedef NS_ENUM(NSUInteger, JVChatViewOrganizationType) {
	JVChatViewOrganizationTypeDefault = 0,
	JVChatViewOrganizationTypeAlphabetical,
	JVChatViewOrganizationTypeByNetworkAndRoom,
};

NSString *JVToolbarToggleChatDrawerItemIdentifier = @"JVToolbarToggleChatDrawerItem";
NSString *JVChatViewPboardType = @"Colloquy Chat View v1.0 pasteboard type";


NSString * JVChatWindowControllerChatViewsDidChangeNotificationName = @"JVChatWindowControllerChatViewsDidChangeNotificationName";


#pragma mark -

@interface NSWindow (NSWindowPrivate) // new Tiger private method
- (void) _setContentHasShadow:(BOOL) shadow;
@end


@interface JVChatWindowController ()
- (void) _saveWindowFrame;
@end



#pragma mark -

@implementation JVChatWindowController
{
	NSString *_identifier;
	NSMutableDictionary *_settings;
	NSMutableArray<id <JVChatViewController>> * _chatViewControllers;
	id <JVChatViewController> _activeViewController;
	
	BOOL _showWindowIsDelayed;
	BOOL _closing;
}



- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}


- (id)initWithWindowNibName:(NSString *)windowNibName
{
	if( ( self = [super initWithWindowNibName:windowNibName] ) ) {
		_chatViewControllers = [[NSMutableArray alloc] init];
		_settings = [[NSMutableDictionary alloc] initWithDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:[self userDefaultsPreferencesKey]]];
	}

	return self;
}



- (void)windowDidLoad
{
	[self setShouldCascadeWindows:NO];
	[self setWindowFrameAutosaveName:@""];

	[[self window] setDelegate:nil]; // so we don't act on the windowDidResize notification
	[[self window] setFrameUsingName:@"Chat Window"];

	NSRect frame = [[self window] frame];
	NSPoint point = [[self window] cascadeTopLeftFromPoint:NSMakePoint( NSMinX( frame ), NSMaxY( frame ) )];
	[[self window] setFrameTopLeftPoint:point];

	[[self window] setDelegate:self];

	[[self window] setIgnoresMouseEvents:NO];
	[[self window] setOpaque:NO]; // let us poke transparant holes in the window

	NSWindowCollectionBehavior windowCollectionBehavior = NSWindowCollectionBehaviorDefault | NSWindowCollectionBehaviorParticipatesInCycle;
	if( floor( NSAppKitVersionNumber ) >= NSAppKitVersionNumber10_7 )
		windowCollectionBehavior |= NSWindowCollectionBehaviorFullScreenPrimary;

	[[self window] setCollectionBehavior:windowCollectionBehavior];

	if( [[self window] respondsToSelector:@selector( _setContentHasShadow: )] )
		[[self window] _setContentHasShadow:NO]; // this is new in Tiger

	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector( preferencesDidChange ) object:nil];
	[self preferencesDidChange];
}



- (void) dealloc {
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[[NSNotificationCenter chatCenter] removeObserver:self];

	if( [self isWindowLoaded] ) {
		[[self window] setDelegate:nil];
		[[[self window] toolbar] setDelegate:nil];
		[[self window] close];
	}

	
	// Should already be entirely cleaned up by now.
	assert(_chatViewControllers.count == 0);
	

	_activeViewController = nil;
	_chatViewControllers = nil;
	_identifier = nil;
	_settings = nil;
	_showWindowIsDelayed = NO;
}






#pragma mark -
#pragma mark Method Forwarding

- (BOOL) respondsToSelector:(SEL) selector {
	if( [self.activeChatViewController respondsToSelector:selector] ) return YES;
	else return [super respondsToSelector:selector];
}

- (void) forwardInvocation:(NSInvocation *) invocation {
	if( [self.activeChatViewController respondsToSelector:[invocation selector]] )
		[invocation invokeWithTarget:self.activeChatViewController];
	else [super forwardInvocation:invocation];
}

- (NSMethodSignature *) methodSignatureForSelector:(SEL) selector {
	if( [self.activeChatViewController respondsToSelector:selector] )
		return [(NSObject *)self.activeChatViewController methodSignatureForSelector:selector];
	else return [super methodSignatureForSelector:selector];
}





#pragma mark -

- (NSString *) identifier {
	return _identifier;
}



- (void) setIdentifier:(NSString *) identifier {
	_identifier = [identifier copy];
	_settings = [[NSMutableDictionary alloc] initWithDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:[self userDefaultsPreferencesKey]]];

	if( [[self identifier] length] ) {
		[[self window] setDelegate:nil]; // so we don't act on the windowDidResize notification
		[[self window] setFrameUsingName:[NSString stringWithFormat:@"Chat Window %@", [self identifier]]];
		[[self window] setDelegate:self];
	}
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector( preferencesDidChange ) object:nil];
	[self performSelector:@selector( preferencesDidChange ) withObject:nil afterDelay:0.];
}





#pragma mark -
#pragma mark Preferences

- (NSString *) userDefaultsPreferencesKey {
	if( [[self identifier] length] )
		return [NSString stringWithFormat:@"Chat Window %@ Settings", [self identifier]];
	return @"Chat Window Settings";
}


- (void) setPreference:(id) value forKey:(NSString *) key {
	NSParameterAssert( key != nil );
	NSParameterAssert( [key length] );

	if( value ) [_settings setObject:value forKey:key];
	else [_settings removeObjectForKey:key];

	if( [_settings count] ) [[NSUserDefaults standardUserDefaults] setObject:_settings forKey:[self userDefaultsPreferencesKey]];
	else [[NSUserDefaults standardUserDefaults] removeObjectForKey:[self userDefaultsPreferencesKey]];
	[[NSUserDefaults standardUserDefaults] synchronize];
}


- (id) preferenceForKey:(NSString *) key {
	NSParameterAssert( key != nil );
	NSParameterAssert( [key length] );
	return [_settings objectForKey:key];
}


- (void)preferencesDidChange
{
	
}





#pragma mark -
#pragma mark Display

- (void)showWindow:(id)sender {
	if ([_chatViewControllers count]) {
		[[self window] makeKeyAndOrderFront:nil];
		_showWindowIsDelayed = NO;
	} else {
		_showWindowIsDelayed = YES;
	}
}



- (void)close
{
	if (_closing) return;
	_closing = YES;
	
	[self.window orderOut:nil];
	[super close];
	[[JVChatController defaultController] performSelector:@selector( disposeChatWindowController: ) withObject:self afterDelay:0.0];
}


- (void)showChatViewController:(id <JVChatViewController>) controller
{
	[self doesNotRecognizeSelector:_cmd];
}


- (void)updateInterfaceSwappingOutChatViewController:(id<JVChatViewController>)old
{
	
}



#pragma mark -


- (void)changeActiveChatViewController:(id <JVChatViewController>)controller
{
	if (_activeViewController != controller) {
		NSAssert1([self.allChatViewControllers containsObject:controller], @"%@ is not a member of this window controller.", controller);
		
		id <JVChatViewController> oldController = _activeViewController;
		
		
		if (oldController) {
			[self chatViewControllerWillResignActive:oldController];
			if ([oldController respondsToSelector:@selector( willUnselect )] ) {
				[oldController willUnselect];
			}
		}
		
		if (controller) {
			if ([controller respondsToSelector:@selector(willSelect)]) {
				[controller willSelect];
			}
		}
		
		_activeViewController = controller;
		
		[self updateInterfaceSwappingOutChatViewController:oldController];
		
		if (oldController) {
			if ([oldController respondsToSelector:@selector(didUnselect)]) {
				[oldController didUnselect];
			}
		}
		
		if (controller) {
			if ([controller respondsToSelector:@selector(didSelect)]) {
				[controller didSelect];
			}
			
			[self chatViewControllerDidBecomeActive:controller];
		}
	}
}


- (id <JVChatViewController>)activeChatViewController
{
	return _activeViewController;
}





#pragma mark -
#pragma mark Inspecting

- (IBAction)getInfo:(id)sender
{
	[self showInspectorForObject:self.objectToInspect];
}


- (id <JVInspection>)objectToInspect
{
	id item = self.activeChatViewController;
	if ([item conformsToProtocol:@protocol(JVInspection)]) {
		return item;
	}
	return nil;
}


- (void)showInspectorForObject:(id<JVInspection>)object
{
	if (object) {
		if ([[[NSApplication sharedApplication] currentEvent] modifierFlags] & NSAlternateKeyMask) {
			[JVInspectorController showInspector:object];
		} else {
			[[JVInspectorController inspectorOfObject:object] show:object];
		}
	}
}





#pragma mark -
#pragma mark Interface Action Validation

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if ([menuItem action] == @selector( closeCurrentPanel: )) {
		if( [[menuItem keyEquivalent] length] ) return YES;
		else return NO;
	} else if( [menuItem action] == @selector( detachCurrentPanel: ) ) {
		if( [_chatViewControllers count] > 1 ) return YES;
		else return NO;
	}
	
	if( [[self activeChatViewController] respondsToSelector:@selector( validateMenuItem: )] )
		return [(id)[self activeChatViewController] validateMenuItem:menuItem];
	
	return YES;
}





#pragma mark -
#pragma mark Actions

- (IBAction)joinRoom:(id)sender
{
	[[JVChatRoomBrowser chatRoomBrowserForConnection:self.activeChatViewController.connection] showWindow:nil];
}



- (IBAction) closeCurrentPanel:(id) sender
{
	if ([[self allChatViewControllers] count] == 1 ) {
		[[self window] performClose:sender];
	}

	[[JVChatController defaultController] disposeViewController:self.activeChatViewController];
}



- (IBAction) detachCurrentPanel:(id)sender
{
	[[JVChatController defaultController] detachViewController:self.activeChatViewController];
}



- (IBAction) selectPreviousPanel:(id) sender
{
	NSInteger currentIndex = [self.allChatViewControllers indexOfObject:self.activeChatViewController];
	NSUInteger index = 0;

	if( ( currentIndex - 1 ) >= 0 ) index = ( currentIndex - 1 );
	else index = ( [self.allChatViewControllers count] - 1 );

	[self showChatViewController:[self.allChatViewControllers objectAtIndex:index]];
}



- (IBAction)selectPreviousActivePanel:(id)sender
{
	NSUInteger currentIndex = [self.allChatViewControllers indexOfObject:self.activeChatViewController];
	NSUInteger index = currentIndex;
	BOOL done = NO;

	do {
		id<JVChatViewController> vc = [self.allChatViewControllers objectAtIndex:index];
		if ([vc conformsToProtocol:@protocol(JVCanHaveNewMessages)]) {
			if (((id<JVCanHaveNewMessages>)vc).newMessagesWaiting > 0) {
				done = YES;
			}
		}

		if( ! done ) {
			if( index == 0 ) index = [self.allChatViewControllers count] - 1;
			else index--;
		}
	} while( index != currentIndex && ! done );

	[self showChatViewController:[self.allChatViewControllers objectAtIndex:index]];
}



- (IBAction)selectNextPanel:(id)sender
{
	NSUInteger currentIndex = [self.allChatViewControllers indexOfObject:self.activeChatViewController];
	NSUInteger index = 0;

	if( currentIndex + 1 < [self.allChatViewControllers count] ) index = ( currentIndex + 1 );
	else index = 0;

	[self showChatViewController:[self.allChatViewControllers objectAtIndex:index]];
}



- (IBAction) selectNextActivePanel:(id) sender {
	NSUInteger currentIndex = [self.allChatViewControllers indexOfObject:self.activeChatViewController];
	NSUInteger index = currentIndex;
	BOOL done = NO;

	do {
		id<JVChatViewController> vc = [self.allChatViewControllers objectAtIndex:index];
		if ([vc conformsToProtocol:@protocol(JVCanHaveNewMessages)]) {
			if (((id<JVCanHaveNewMessages>)vc).newMessagesWaiting > 0) {
				done = YES;
			}
		}
		
		if( ! done ) {
			if( index == [self.allChatViewControllers count] - 1 ) index = 0;
			else index++;
		}
	} while( index != currentIndex && ! done );

	[self showChatViewController:[self.allChatViewControllers objectAtIndex:index]];
}



// It doesn't work. And why would it?
- (void) swipeWithEvent:(NSEvent *) event
{
	CGFloat deltaX = [event deltaX];
	CGFloat deltaY = [event deltaY];

	if( deltaX > 0 || deltaY > 0 ) {
		if( [event modifierFlags] & NSAlternateKeyMask )
			[self selectPreviousActivePanel:nil];
		else [self selectPreviousPanel:nil];
	} else if( deltaX < 0 || deltaY < 0 ) {
		if( [event modifierFlags] & NSAlternateKeyMask )
			[self selectNextActivePanel:nil];
		else [self selectNextPanel:nil];
	}
}






#pragma mark -
#pragma mark Chat View Management

- (void) addChatViewController:(id <JVChatViewController>) controller
{
	NSInteger organizationType = [[NSUserDefaults standardUserDefaults] integerForKey:@"JVChatViewOrganizationType"];
	NSUInteger i = [self.allChatViewControllers count];

	if ( organizationType != 0 ) {
		SEL localizedCaseInsensitive = @selector(localizedCaseInsensitiveCompare:);
		NSMutableArray* sortDescriptors = [NSMutableArray array];

		switch ( organizationType ) {
			case JVChatViewOrganizationTypeByNetworkAndRoom:
				[sortDescriptors addObject:[[NSSortDescriptor alloc] initWithKey:@"connection.server" ascending:YES selector:localizedCaseInsensitive]];
				[sortDescriptors addObject:[[NSSortDescriptor alloc] initWithKey:@"connection.preferredNickname" ascending:YES selector:localizedCaseInsensitive]];
			case JVChatViewOrganizationTypeAlphabetical:
				[sortDescriptors addObject:[[NSSortDescriptor alloc] initWithKey:@"className" ascending:YES]];
				[sortDescriptors addObject:[[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES selector:localizedCaseInsensitive]];
				break;
			default:
				break;
		}

		NSMutableArray* sortedViews = [self.allChatViewControllers mutableCopy];
		[sortedViews addObject:controller];
		[sortedViews sortUsingDescriptors:sortDescriptors];
		i = [sortedViews indexOfObject:controller];
	}

	[self insertChatViewController:controller atIndex:i];
}



- (void) insertChatViewController:(id <JVChatViewController>) controller atIndex:(NSUInteger) index
{
	NSParameterAssert( controller != nil );
	NSAssert1( ! [_views containsObject:controller], @"%@ already added.", controller );
	NSAssert( index <= [_views count], @"Index is beyond bounds." );

	BOOL needShow = (_chatViewControllers.count == 0);
	
	
	[self willAddChatViewController:controller];
	{
		[_chatViewControllers insertObject:controller atIndex:index];
		[controller setWindowController:self];
	}
	[self didAddChatViewController:controller];
	[self chatViewControllersDidChange];
	[NSNotificationCenter.defaultCenter postNotificationName:JVChatWindowControllerChatViewsDidChangeNotificationName object:self];
	
	
	
	if( ! [[self identifier] length] && [_chatViewControllers count] == 1 ) {
		[[self window] setDelegate:nil]; // so we don't act on the windowDidResize notification
		[[self window] setFrameUsingName:[NSString stringWithFormat:@"Chat Window %@", [controller identifier]]];
		[[self window] setDelegate:self];
	}

	if( needShow && ! _showWindowIsDelayed )
		[[self  window] orderWindow:NSWindowBelow relativeTo:[[[NSApplication sharedApplication] keyWindow] windowNumber]];

	if( _showWindowIsDelayed ) [self showWindow:nil];

	[self _saveWindowFrame];
}



- (void)moveChatViewController:(id <JVChatViewController>)controller toIndex:(NSUInteger)index
{
	[_chatViewControllers removeObject:controller];
	[_chatViewControllers insertObject:controller atIndex:index];
}



- (void)removeChatViewController:(id <JVChatViewController>) controller
{
	NSParameterAssert( controller != nil );
	NSAssert1( [_views containsObject:controller], @"%@ is not a member of this window controller.", controller );

	if (self.activeChatViewController == controller) {
		[self changeActiveChatViewController:nil];
	}
	
	
	[self willRemoveChatViewController:controller];
	{
		[controller setWindowController:nil];
		[_chatViewControllers removeObjectIdenticalTo:controller];
	}
	[self didRemoveChatViewController:controller];
	[self chatViewControllersDidChange];
	[NSNotificationCenter.defaultCenter postNotificationName:JVChatWindowControllerChatViewsDidChangeNotificationName object:self];
	
	[self closeWindowIfEmptyAndVisible];
}



- (void)removeChatViewControllerAtIndex:(NSUInteger)index
{
	NSAssert( index <= [_views count], @"Index is beyond bounds." );
	[self removeChatViewController:[_chatViewControllers objectAtIndex:index]];
}



- (void)removeAllChatViewControllers
{
	NSArray * controllers = [_chatViewControllers copy];
	
	[self changeActiveChatViewController:nil];
	
	for (id<JVChatViewController> controller in controllers) {
		[self willRemoveChatViewController:controller];
		[controller setWindowController:nil];
	}
	
	[_chatViewControllers removeAllObjects];
	
	for (id<JVChatViewController> controller in controllers) {
		[self didRemoveChatViewController:controller];
	}
	
	[self chatViewControllersDidChange];
	[NSNotificationCenter.defaultCenter postNotificationName:JVChatWindowControllerChatViewsDidChangeNotificationName object:self];
	
	[self closeWindowIfEmptyAndVisible];
}


- (void)closeWindowIfEmptyAndVisible
{
	if (self.allChatViewControllers.count == 0 && self.window.visible) {
		[self close];
	}
}



- (void) replaceChatViewController:(id <JVChatViewController>) controller withController:(id <JVChatViewController>) newController {
	NSParameterAssert( controller != nil );
	NSParameterAssert( newController != nil );
	NSAssert1( [_views containsObject:controller], @"%@ is not a member of this window controller.", controller );
	NSAssert1( ! [_views containsObject:newController], @"%@ is already a member of this window controller.", newController );

	[self replaceChatViewControllerAtIndex:[_chatViewControllers indexOfObjectIdenticalTo:controller] withController:newController];
}



- (void) replaceChatViewControllerAtIndex:(NSUInteger) index withController:(id <JVChatViewController>) controller {
	NSParameterAssert( controller != nil );
	NSAssert1( ! [_views containsObject:controller], @"%@ is already a member of this window controller.", controller );
	NSAssert( index <= [_views count], @"Index is beyond bounds." );

	id <JVChatViewController> oldController = [_chatViewControllers objectAtIndex:index];
	
	if ( self.activeChatViewController == oldController ) {
		[self changeActiveChatViewController:nil];
	}
	
	[self willRemoveChatViewController:oldController];
	[self willAddChatViewController:controller];
	{
		[oldController setWindowController:nil];
		[_chatViewControllers replaceObjectAtIndex:index withObject:controller];
		[controller setWindowController:self];
	}
	[self didRemoveChatViewController:oldController];
	[self didAddChatViewController:controller];
	[self chatViewControllersDidChange];
	[NSNotificationCenter.defaultCenter postNotificationName:JVChatWindowControllerChatViewsDidChangeNotificationName object:self];
	
	[self _saveWindowFrame];
}





#pragma mark -

- (id <JVChatViewController>) chatViewControllerForIdentifier:(NSString *) identifier {
	for( id <JVChatViewController> controller in self.allChatViewControllers )
		if( [[controller identifier] isEqualToString:identifier] )
			return controller;
	return nil;
}



- (NSArray *) chatViewControllersForConnection:(MVChatConnection *) connection {
	NSParameterAssert( connection != nil );

	NSMutableArray *ret = [NSMutableArray array];
	id <JVChatViewController> controller = nil;

	for( controller in self.allChatViewControllers )
		if( [controller connection] == connection )
			[ret addObject:controller];

	return ret;
}



- (NSArray *) chatViewControllersWithControllerClass:(Class) class {
	NSParameterAssert( class != NULL );
	NSAssert( [class conformsToProtocol:@protocol( JVChatViewController )], @"The tab controller class must conform to the JVChatViewController protocol." );

	NSMutableArray *ret = [NSMutableArray array];
	id <JVChatViewController> controller = nil;

	for( controller in self.allChatViewControllers )
		if( [controller isMemberOfClass:class] )
			[ret addObject:controller];

	return ret;
}



- (NSArray *) allChatViewControllers {
	return [NSArray arrayWithArray:_chatViewControllers];
}


- (void)reorderChatViewControllers:(NSArray *)controllers
{
	NSAssert([[NSSet setWithArray:_chatViewControllers] isEqual:[NSSet setWithArray:controllers]], @"the set controllers must be identical");
	[_chatViewControllers setArray:controllers];
}



#pragma mark -
#pragma mark 

- (void)willAddChatViewController:(id <JVChatViewController>)controller
{
	
}


- (void)didAddChatViewController:(id <JVChatViewController>)controller
{
	
}



- (void)willRemoveChatViewController:(id <JVChatViewController>)controller
{
	
}


- (void)didRemoveChatViewController:(id <JVChatViewController>)controller
{
	
}



- (void)chatViewControllersDidChange
{
	
}



- (void)chatViewControllerWillResignActive:(id <JVChatViewController>)controller
{
	
}


- (void)chatViewControllerDidResignActive:(id <JVChatViewController>)controller
{
	
}


- (void)chatViewControllerWillBecomeActive:(id <JVChatViewController>)controller
{
	
}


- (void)chatViewControllerDidBecomeActive:(id <JVChatViewController>)controller
{
	
}







#pragma mark -
#pragma mark Window Delegate

- (void) windowWillClose:(NSNotification *) notification {
    if( ! [[[[[NSApplication sharedApplication] keyWindow] windowController] className] isEqual:[self className]] )
		[self resignMenuBarItems];
	
	if (self.window.isVisible) {
		[self close];
	}
}



- (BOOL) windowShouldClose:(id) sender {
	if( [[self chatViewControllersWithControllerClass:[JVChatRoomPanel class]] count] <= 1 ) return YES; // no rooms, close without a prompt
	
	NSAlert *alert = [[NSAlert alloc] init];
	alert.messageText = NSLocalizedString( @"Are you sure you want to part from all chat rooms and close this window?", "are you sure you want to part all chat rooms dialog title" );
	alert.informativeText = NSLocalizedString( @"You will exit all chat rooms and lose any unsaved chat transcripts. Do you want to proceed?", "confirm close of window message" );
	[alert addButtonWithTitle:NSLocalizedString( @"Close", "close button" )];
	[alert addButtonWithTitle:NSLocalizedString( @"Cancel", "close button" )];
	alert.alertStyle = NSAlertStyleCritical;
	NSModalResponse response = [alert runModal];
	
	if( response == NSAlertFirstButtonReturn ) {
		return YES;
	}
	return NO;
}



- (void) windowDidResignKey:(NSNotification *) notification {
    if( ! [[[[[NSApplication sharedApplication] keyWindow] windowController] className] isEqual:[self className]] )
		[self resignMenuBarItems];
}



- (void) windowDidBecomeKey:(NSNotification *) notification {
	[self claimMenuBarItems];
	if( self.activeChatViewController ) {
		[[self window] makeFirstResponder:self.activeChatViewController.firstResponder];
		
		if ([self.activeChatViewController respondsToSelector:@selector(didGetNoticedByUser)]) {
			[self.activeChatViewController didGetNoticedByUser];
		}
	}
}



- (void) windowDidMove:(NSNotification *) notification {
	[self _saveWindowFrame];
}



- (void) windowDidResize:(NSNotification *) notification {
	[self _saveWindowFrame];
}



- (NSApplicationPresentationOptions) window:(NSWindow *) window willUseFullScreenPresentationOptions:(NSApplicationPresentationOptions) proposedOptions {
	return (proposedOptions | NSApplicationPresentationAutoHideToolbar);
}




#pragma mark -

- (void) claimMenuBarItems
{
	NSMenuItem *closeItem = [[[[[NSApplication sharedApplication] mainMenu] itemAtIndex:1] submenu] itemWithTag:1];
	[closeItem setKeyEquivalentModifierMask:NSCommandKeyMask];
	[closeItem setKeyEquivalent:@"W"];

	closeItem = (NSMenuItem *)[[[[[NSApplication sharedApplication] mainMenu] itemAtIndex:1] submenu] itemWithTag:2];
	[closeItem setKeyEquivalentModifierMask:NSCommandKeyMask];
	[closeItem setKeyEquivalent:@"w"];
}


- (void) resignMenuBarItems
{
	NSMenuItem *closeItem = [[[[[NSApplication sharedApplication] mainMenu] itemAtIndex:1] submenu] itemWithTag:1];
	[closeItem setKeyEquivalentModifierMask:NSCommandKeyMask];
	[closeItem setKeyEquivalent:@"w"];

	closeItem = (NSMenuItem *)[[[[[NSApplication sharedApplication] mainMenu] itemAtIndex:1] submenu] itemWithTag:2];
	[closeItem setKeyEquivalentModifierMask:0];
	[closeItem setKeyEquivalent:@""];
}








#pragma mark -
#pragma mark MISCCCCCC


- (void) _saveWindowFrame {
	if( [[self identifier] length] ) {
		[[self window] saveFrameUsingName:@"Chat Window"];
		[[self window] saveFrameUsingName:[NSString stringWithFormat:@"Chat Window %@", [self identifier]]];
	} else {
		[[self window] saveFrameUsingName:@"Chat Window"];

		for( id <JVChatViewController> controller in [self allChatViewControllers])
			[[self window] saveFrameUsingName:[NSString stringWithFormat:@"Chat Window %@", [controller identifier]]];
	}
}

- (void) _switchViews:(id) sender {
	[self showChatViewController:[sender representedObject]];
}


@end


