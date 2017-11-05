#import "JVDirectChatPanel.h"

#import "JVBuddy.h"
#import "JVChatController.h"
#import "JVChatEvent.h"
#import "JVChatMessage.h"
#import "JVChatRoomMember.h"
#import "JVChatRoomPanel.h"
#import "JVChatTranscript.h"
#import "JVChatUserInspector.h"
#import "JVEmoticonSet.h"
#import "JVMarkedScroller.h"
#import "JVNotificationController.h"
#import "JVSpeechController.h"
#import "JVSplitView.h"
#import "JVStyle.h"
#import "JVStyleView.h"
#import "JVTabbedChatWindowController.h"
#import "KAIgnoreRule.h"
#import "MVBuddyListController.h"
#import "MVChatUserAdditions.h"
#import "MVConnectionsController.h"
#import "MVFileTransferController.h"
#import "MVMenuButton.h"
#import "MVTextView.h"
#import "MVApplicationController.h"
#import "NSAttributedStringMoreAdditions.h"
#import "NSBundleAdditions.h"
#import "NSDateAdditions.h"
#import <ChatCore/NSRegularExpressionAdditions.h>
#import "CQSendView.h"
#import "CQSendHistory.h"
#import "CQSendCompletion.h"

static NSSet *actionVerbs = nil;

const NSStringEncoding JVAllowedTextEncodings[] = {
	/* Universal */
	NSUTF8StringEncoding,
	NSNonLossyASCIIStringEncoding,
	/* Western */
	(NSStringEncoding) -1,				// Divider
	NSASCIIStringEncoding,
	NSISOLatin1StringEncoding,			// ISO Latin 1
	(NSStringEncoding) 0x80000203,		// ISO Latin 3
	(NSStringEncoding) 0x8000020F,		// ISO Latin 9
	NSMacOSRomanStringEncoding,			// Mac
	NSWindowsCP1252StringEncoding,		// Windows
	/* Baltic */
	(NSStringEncoding) -1,
	(NSStringEncoding) 0x8000020D,		// ISO Latin 7
	(NSStringEncoding) 0x80000507,		// Windows
	/* Central European */
	(NSStringEncoding) -1,
	NSISOLatin2StringEncoding,			// ISO Latin 2
	(NSStringEncoding) 0x80000204,		// ISO Latin 4
	(NSStringEncoding) 0x8000001D,		// Mac
	NSWindowsCP1250StringEncoding,		// Windows
	/* Cyrillic */
	(NSStringEncoding) -1,
	(NSStringEncoding) 0x80000A02,		// KOI8-R
	(NSStringEncoding) 0x80000205,		// ISO Latin 5
	(NSStringEncoding) 0x80000007,		// Mac
	NSWindowsCP1251StringEncoding,		// Windows
	/* Japanese */
	(NSStringEncoding) -1,				// Divider
	(NSStringEncoding) 0x80000A01,		// ShiftJIS
	NSISO2022JPStringEncoding,			// ISO-2022-JP
	NSJapaneseEUCStringEncoding,		// EUC
	(NSStringEncoding) 0x80000001,		// Mac
	NSShiftJISStringEncoding,			// Windows
	/* Simplified Chinese */
	(NSStringEncoding) -1,				// Divider
	(NSStringEncoding) 0x80000632,		// GB 18030
	(NSStringEncoding) 0x80000631,		// GBK
	(NSStringEncoding) 0x80000930,		// EUC
	(NSStringEncoding) 0x80000019,		// Mac
	(NSStringEncoding) 0x80000421,		// Windows
	/* Traditional Chinese */
	(NSStringEncoding) -1,				// Divider
	(NSStringEncoding) 0x80000A03,		// Big5
	(NSStringEncoding) 0x80000A06,		// Big5 HKSCS
	(NSStringEncoding) 0x80000931,		// EUC
	(NSStringEncoding) 0x80000002,		// Mac
	(NSStringEncoding) 0x80000423,		// Windows
	/* Korean */
	(NSStringEncoding) -1,				// Divider
	(NSStringEncoding) 0x80000940,		// EUC
	(NSStringEncoding) 0x80000003,		// Mac
	(NSStringEncoding) 0x80000422,		// Windows
	/* Hebrew */
	(NSStringEncoding) -1,				// Divider
	(NSStringEncoding) 0x80000208,		// ISO-8859-8
	(NSStringEncoding) 0x80000005,		// Mac
	(NSStringEncoding) 0x80000505,		// Windows
	/* End */ 0 };

NSString *JVToolbarTextEncodingItemIdentifier = @"JVToolbarTextEncodingItem";
NSString *JVToolbarClearScrollbackItemIdentifier = @"JVToolbarClearScrollbackItem";
NSString *JVToolbarSendFileItemIdentifier = @"JVToolbarSendFileItem";
NSString *JVToolbarMarkItemIdentifier = @"JVToolbarMarkItem";

NSString *JVChatMessageWasProcessedNotification = @"JVChatMessageWasProcessedNotification";
NSString *JVChatEventMessageWasProcessedNotification = @"JVChatEventMessageWasProcessedNotification";

@interface JVDirectChatPanel () <ABImageClient, CQSendViewDelegate>
@end

#pragma mark -

@implementation JVDirectChatPanel
- (id) init {
	if( ( self = [super init] ) ) {
		
		sendViewController = [[CQSendViewController alloc] init];
		sendViewController.delegate = self;
		sendViewController.completionHandler = [[CQChatSendCompletionHandler alloc] initWithChat:self];
		
		_target = nil;
		_firstMessage = YES;
		_newMessageCount = 0;
		_newHighlightMessageCount = 0;
		[(MVApplicationController *)[NSApp delegate] updateDockTile];
		_cantSendMessages = NO;
		_isActive = NO;
		_forceSplitViewPosition = YES;
		_historyIndex = 0;
		_sendHeight = 25.;

		_encoding = NSASCIIStringEncoding;
		_encodingMenu = nil;
		_spillEncodingMenu = nil;

		_waitingAlerts = [NSMutableArray array];
	}

	return self;
}

- (id) initWithTarget:(id) target {
	if( ( self = [self init] ) ) {
		_target = target;

		if( [self connection] ) {
			if( ( [self isMemberOfClass:[JVDirectChatPanel class]] && [[NSUserDefaults standardUserDefaults] boolForKey:@"JVLogPrivateChats"] ) ||
				( [self isMemberOfClass:[JVChatRoomPanel class]] && [[NSUserDefaults standardUserDefaults] boolForKey:@"JVLogChatRooms"] ) ) {

				[self checkTranscriptDirectoryState];
			}

			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDefaultsChanged:) name:NSUserDefaultsDidChangeNotification object:nil];

			if( ! [target isKindOfClass:[MVDirectChatConnection class]] ) {
				[[NSNotificationCenter chatCenter] addObserver:self selector:@selector( _didConnect: ) name:MVChatConnectionDidConnectNotification object:[self connection]];
				[[NSNotificationCenter chatCenter] addObserver:self selector:@selector( _didDisconnect: ) name:MVChatConnectionDidDisconnectNotification object:[self connection]];
				[[NSNotificationCenter chatCenter] addObserver:self selector:@selector( _awayStatusChanged: ) name:MVChatConnectionSelfAwayStatusChangedNotification object:[self connection]];
				[[NSNotificationCenter chatCenter] addObserver:self selector:@selector( _errorOccurred: ) name:MVChatConnectionErrorNotification object:[self connection]];
			}

			if( [target isKindOfClass:[MVChatUser class]] ) {
				[[NSNotificationCenter chatCenter] addObserver:self selector:@selector(_userNicknameDidChange:) name:MVChatUserNicknameChangedNotification object:_target];
				[[NSNotificationCenter chatCenter] addObserver:self selector:@selector(_userStatusChanged:) name:MVChatUserStatusChangedNotification object:_target];

				_watchRule = [[MVChatUserWatchRule alloc] init];
				[_watchRule setNickname:[target nickname]];

				[[self connection] addChatUserWatchRule:_watchRule];
			}
		}

		_settings = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:[[self identifier] stringByAppendingString:@" Settings"]]];
	}

	return self;
}

- (void) awakeFromNib {
	JVStyle *style = nil;
	NSString *variant = nil;
	JVEmoticonSet *emoticon = nil;

	[sendViewPlaceholder.superview replaceSubview:sendViewPlaceholder with:sendViewController.view];
	sendViewPlaceholder = nil;
	
	if( [[self target] isKindOfClass:[MVDirectChatConnection class]] ) {
		[[NSNotificationCenter chatCenter] addObserver:self selector:@selector( _refreshIcon: ) name:MVDirectChatConnectionDidConnectNotification object:[self target]];
		[[NSNotificationCenter chatCenter] addObserver:self selector:@selector( _refreshIcon: ) name:MVDirectChatConnectionDidDisconnectNotification object:[self target]];
	} else {
		[[NSNotificationCenter chatCenter] addObserver:self selector:@selector( _refreshIcon: ) name:MVChatConnectionDidConnectNotification object:[self connection]];
		[[NSNotificationCenter chatCenter] addObserver:self selector:@selector( _refreshIcon: ) name:MVChatConnectionDidDisconnectNotification object:[self connection]];
	}

	if( [self preferenceForKey:@"style"] ) {
		style = [JVStyle styleWithIdentifier:[self preferenceForKey:@"style"]];
		variant = [self preferenceForKey:@"style variant"];
		if( style ) [self setStyle:style withVariant:variant];
	}

	if( [(NSString *)[self preferenceForKey:@"emoticon"] length] ) {
		emoticon = [JVEmoticonSet emoticonSetWithIdentifier:[self preferenceForKey:@"emoticon"]];
		if( emoticon ) [self setEmoticons:emoticon];
	}

	[super awakeFromNib];

	[display setBodyTemplate:@"directChat"];

	[self changeEncoding:nil];

	if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"JVChatInputAutoResizes"] ) {
		[sendDisplaySplitView setDividerStyle:NSSplitViewDividerStylePaneSplitter];
	}
}

- (void) dealloc {
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[[NSNotificationCenter chatCenter] removeObserver:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	if( _watchRule ) [[self connection] removeChatUserWatchRule:_watchRule];

	_target = nil;
	_settings = nil;
	_encodingMenu = nil;
	_spillEncodingMenu = nil;
}

#pragma mark -

- (id) target {
	return _target;
}

- (MVChatUser *) user {
	if( [[self target] isKindOfClass:[MVChatUser class]] )
		return [self target];
	if( [[self target] isKindOfClass:[MVChatRoom class]] )
		return [(MVChatRoom *)[self target] localMemberUser];
	if( [[self target] isKindOfClass:[MVDirectChatConnection class]] )
		return [(MVDirectChatConnection *)[self target] user];
	return nil;
}

- (NSURL *) url {
	NSString *server = [[[self connection] url] absoluteString];
	return [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", server, [[[self user] nickname] stringByEncodingIllegalURLCharacters]]];
}

- (MVChatConnection *) connection {
	if( [[self target] respondsToSelector:@selector( connection )] )
		return (MVChatConnection *)[[self target] connection];
	if( [[self target] isKindOfClass:[MVDirectChatConnection class]] )
		return [[(MVDirectChatConnection *)[self target] user] connection];
	return nil;
}

#pragma mark -

- (NSView *) view {
	if( ! _nibLoaded ) _nibLoaded = [[NSBundle mainBundle] loadNibNamed:@"JVDirectChat" owner:self topLevelObjects:NULL];
	return contents;
}

- (NSResponder *) firstResponder {
	return sendViewController.sendTextView;
}

#pragma mark -

- (BOOL) isEnabled {
	if( [[self target] isKindOfClass:[MVDirectChatConnection class]] )
		return ( [(MVDirectChatConnection *)[self target] status] == MVDirectChatConnectionConnectedStatus );
	MVChatUserStatus status = [(MVChatUser *)[self target] status];
	return ([[self connection] isConnected] && (status == MVChatUserAvailableStatus || status == MVChatUserAwayStatus));
}

- (NSString *) title {
/*	if( _buddy && [_buddy preferredNameWillReturn] != JVBuddyActiveNickname )
		return [_buddy preferredName]; */
	return [[self user] displayName];
}

- (NSString *) windowTitle {
/*	if( _buddy && [_buddy preferredNameWillReturn] != JVBuddyActiveNickname )
		return [NSString stringWithFormat:@"%@ (%@)", [_buddy preferredName], [[self user] serverAddress]]; */

	if( [[self target] isKindOfClass:[MVDirectChatConnection class]] ) {
		NSString *host = [(MVDirectChatConnection *)[self target] connectedHost];
		if( ! [host length] ) host = [[self user] address];
		if( [host length] ) return [NSString stringWithFormat:@"%@ (%@)", [self title], host];
		return [self title];
	}

	return [NSString stringWithFormat:@"%@ (%@)", [self title], [[self user] serverAddress]];
}

- (NSString *) information {
/*	if( _buddy && [_buddy preferredNameWillReturn] != JVBuddyActiveNickname && ! [[self target] isEqualToString:[_buddy preferredName]] )
		return [NSString stringWithFormat:@"%@ (%@)", [self target], [[self user] serverAddress]]; */
	if( [[self target] isKindOfClass:[MVDirectChatConnection class]] ) {
		if( [(MVDirectChatConnection *)[self target] status] == MVDirectChatConnectionWaitingStatus )
			return NSLocalizedString( @"waiting for connection", "waiting for connection information" );
		if( [(MVDirectChatConnection *)[self target] status] == MVDirectChatConnectionDisconnectedStatus )
			return NSLocalizedString( @"disconnected", "disconnected information" );

		NSString *host = [(MVDirectChatConnection *)[self target] connectedHost];
		if( ! [host length] ) host = [[self user] address];
		return host;
	}

	return [[self user] serverAddress];
}

- (NSString *) toolTip {
	NSString *messageCount = @"";
	if( [self newMessagesWaiting] == 0 ) messageCount = NSLocalizedString( @"no messages waiting", "no messages waiting room tooltip" );
	else if( [self newMessagesWaiting] == 1 ) messageCount = NSLocalizedString( @"1 message waiting", "one message waiting room tooltip" );
	else messageCount = [NSString stringWithFormat:NSLocalizedString( @"%d messages waiting", "messages waiting room tooltip" ), [self newMessagesWaiting]];

/*	if( _buddy && [_buddy preferredNameWillReturn] != JVBuddyActiveNickname )
		return [NSString stringWithFormat:@"%@\n%@ (%@)\n%@", [_buddy preferredName], [self target], [[self user] serverAddress], messageCount]; */

	if( [[self target] isKindOfClass:[MVDirectChatConnection class]] ) {
		NSString *info = nil;
		if( [(MVDirectChatConnection *)[self target] status] == MVDirectChatConnectionWaitingStatus )
			info = NSLocalizedString( @"waiting for connection", "waiting for connection tooltip" );
		else if( [(MVDirectChatConnection *)[self target] status] == MVDirectChatConnectionDisconnectedStatus )
			info = NSLocalizedString( @"disconnected", "disconnected tooltip" );
		else {
			info = [(MVDirectChatConnection *)[self target] connectedHost];
			if( ! [info length] ) info = [[self user] address];
		}

		if( [info length] ) return [NSString stringWithFormat:@"%@ (%@)\n%@", [self title], info, messageCount];
		return [NSString stringWithFormat:@"%@\n%@", [self title], messageCount];
	}

	return [NSString stringWithFormat:@"%@ (%@)\n%@", [self title], [[self user] serverAddress], messageCount];
}

#pragma mark -

- (NSMenu *) menu {
	NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];
	NSMenuItem *item = nil;

	NSArray *standardItems = [[self user] standardMenuItems];
	for( item in standardItems )
		if( [item action] != @selector( startDirectChat: ) )
			[menu addItem:item];

	[menu addItem:[NSMenuItem separatorItem]];

	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString( @"Ignore Notifications", "lists whether or not notifications are enabled for this conversation") action:@selector( toggleNotifications: ) keyEquivalent:@""];
	[item setTarget:self];
	[menu addItem:item];

	[menu addItem:[NSMenuItem separatorItem]];

	if( [[[self windowController] allChatViewControllers] count] > 1 ) {
		item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString( @"Detach From Window", "detach from window contextual menu item title" ) action:@selector( detachView: ) keyEquivalent:@""];
		[item setRepresentedObject:self];
		[item setTarget:[JVChatController defaultController]];
		[menu addItem:item];
	}

	if( [[self target] isKindOfClass:[MVDirectChatConnection class]] ) {
		item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString( @"Disconnect", "disconnect contextual menu item title" ) action:@selector( disconnect ) keyEquivalent:@""];
		[item setTarget:[self target]];
		[menu addItem:item];
	}

	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString( @"Close", "close contextual menu item title" ) action:@selector( close: ) keyEquivalent:@""];
	[item setTarget:self];
	[menu addItem:item];

	return menu;
}

- (BOOL) validateMenuItem:(NSMenuItem *) menuItem {
	if( [menuItem action] == @selector( toggleNotifications: ) ) {
		if( [[self preferenceForKey:@"muted"] boolValue] )
			[menuItem setState:NSOnState];
		else [menuItem setState:NSOffState];
	}

	return YES;
}

- (NSImage *) icon {
	BOOL smallIcons = [[[self windowController] preferenceForKey:@"small drawer icons"] boolValue];
	if( smallIcons || [_windowController isMemberOfClass:[JVTabbedChatWindowController class]] )
		return [NSImage imageNamed:@"privateChatTab"];
	return [NSImage imageNamed:@"messageUser"];
}

- (NSImage *) statusImage {
	if( _isActive && [[[self view] window] isKeyWindow] ) {
		_newMessageCount = 0;
		_newHighlightMessageCount = 0;
		[(MVApplicationController *)[NSApp delegate] updateDockTile];
		return nil;
	}

	if( [_windowController isMemberOfClass:[JVTabbedChatWindowController class]] )
		return ( [_waitingAlerts count] ? [NSImage imageNamed:NSImageNameCaution] : ( _newMessageCount ? ( _newHighlightMessageCount ? [NSImage imageNamed:@"privateChatTabNewMessage"] : [NSImage imageNamed:@"privateChatTabNewMessage"] ) : nil ) );

	return ( [_waitingAlerts count] ? [NSImage imageNamed:@"viewAlert"] : nil );
}

#pragma mark -

- (NSString *) identifier {
	if( [[self target] isKindOfClass:[MVDirectChatConnection class]] )
		return [NSString stringWithFormat:@"Direct Chat %@", [self user]];
	return [NSString stringWithFormat:@"Direct Chat %@ (%@)", [self user], [[self user] serverAddress]];
}

#pragma mark -

- (void) didUnselect {
	_newMessageCount = 0;
	_newHighlightMessageCount = 0;
	[(MVApplicationController *)[NSApp delegate] updateDockTile];
	_isActive = NO;
	[super didUnselect];
}

- (void) willSelect {
	_newMessageCount = 0;
	_newHighlightMessageCount = 0;
	[(MVApplicationController *)[NSApp delegate] updateDockTile];
}

- (void) didSelect {
	if( ! [[NSUserDefaults standardUserDefaults] boolForKey:@"JVChatInputAutoResizes"] ) {
		[sendDisplaySplitView setPositionUsingName:@"JVChatSplitViewPosition"];
	} else {
		[sendViewController resizeToFit];
	}

	_newMessageCount = 0;
	_newHighlightMessageCount = 0;
	[(MVApplicationController *)[NSApp delegate] updateDockTile];
	_isActive = YES;

	[super didSelect];

	[_windowController reloadListItem:self andChildren:NO];
	[[[self view] window] makeFirstResponder:self.firstResponder];

	for (NSDictionary<NSString *, id> *alertDict in _waitingAlerts) {
		NSString *alertKey = @"alert";
		NSString *handlerKey = @"handler";
		
		NSAlert *alert = alertDict[alertKey];
		void (^ __nullable handler)(NSModalResponse returnCode) = alertDict[handlerKey];
		
		[alert beginSheetModalForWindow:_windowController.window completionHandler:handler];
	}
	[_waitingAlerts removeAllObjects];
}

#pragma mark -
#pragma mark Drag & Drop Support

- (BOOL) acceptsDraggedFileOfType:(NSString *) type {
	return YES;
}

- (void) handleDraggedFile:(NSString *) path {
	BOOL passive = [[NSUserDefaults standardUserDefaults] boolForKey:@"JVSendFilesPassively"];
	[[MVFileTransferController defaultController] addFileTransfer:[[self user] sendFile:path passively:passive]];
}

#pragma mark -
#pragma mark GUI Actions

- (IBAction) getInfo:(id) sender {
	[[JVInspectorController inspectorOfObject:self] show:sender];
}

#pragma mark -

- (void) showAlert:(NSAlert *) alert withCompletionHandler:(void (^ __nullable)(NSModalResponse returnCode))handler {
	if( _isActive ) {
		[alert beginSheetModalForWindow:_windowController.window completionHandler:handler];
	} else {
		NSString *alertKey = @"alert";
		NSString *handlerKey = @"handler";
		
		[_waitingAlerts addObject:(handler ? @{alertKey: alert, handlerKey: handler} : @{alertKey: alert})];
	}

	[_windowController reloadListItem:self andChildren:NO];
}

#pragma mark -
#pragma mark Prefences/User Defaults

- (void) userDefaultsChanged:(NSNotification *) notification {
	[self checkTranscriptDirectoryState];
}

- (void) setPreference:(id) value forKey:(NSString *) key {
	NSParameterAssert( key != nil );
	NSParameterAssert( [key length] );

	if( value ) [_settings setObject:value forKey:key];
	else [_settings removeObjectForKey:key];

	if( [_settings count] ) [[NSUserDefaults standardUserDefaults] setObject:_settings forKey:[[self identifier] stringByAppendingString:@" Settings"]];
	else [[NSUserDefaults standardUserDefaults] removeObjectForKey:[[self identifier] stringByAppendingString:@" Settings"]];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (id) preferenceForKey:(NSString *) key {
	NSParameterAssert( key != nil );
	NSParameterAssert( [key length] );
	return [_settings objectForKey:key];
}

- (void) checkTranscriptDirectoryState {
	BOOL loggingEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"JVLogChatRooms"] || [[NSUserDefaults standardUserDefaults] boolForKey:@"JVLogPrivateChats"];
	NSString *logs = [[[NSUserDefaults standardUserDefaults] stringForKey:@"JVChatTranscriptFolder"] stringByStandardizingPath];
	if( !loggingEnabled )
		return;

	NSFileManager *fileManager = [NSFileManager defaultManager];

	if ( ! [fileManager fileExistsAtPath:logs])
		[fileManager createDirectoryAtPath:logs withIntermediateDirectories:YES attributes:nil error:nil];

	NSInteger org = [[NSUserDefaults standardUserDefaults] integerForKey:@"JVChatTranscriptFolderOrganization"];
	NSString *serverAddress = [[self user] serverAddress] ?: @"(Unknown)";
	if( org == 1 ) {
		logs = [logs stringByAppendingPathComponent:serverAddress];
		if( ! [fileManager fileExistsAtPath:logs] ) [fileManager createDirectoryAtPath:logs withIntermediateDirectories:YES attributes:nil error:nil];
	} else if( org == 2 ) {
		logs = [logs stringByAppendingPathComponent:[NSString stringWithFormat:@"%@ (%@)", [self target], serverAddress]];
		if( ! [fileManager fileExistsAtPath:logs] ) [fileManager createDirectoryAtPath:logs withIntermediateDirectories:YES attributes:nil error:nil];
	} else { // if( org == 3 ) {
		logs = [logs stringByAppendingPathComponent:serverAddress];
		if( ! [fileManager fileExistsAtPath:logs] ) [fileManager createDirectoryAtPath:logs withIntermediateDirectories:YES attributes:nil error:nil];

		logs = [logs stringByAppendingPathComponent:[self title]];
		if( ! [fileManager fileExistsAtPath:logs] ) [fileManager createDirectoryAtPath:logs withIntermediateDirectories:YES attributes:nil error:nil];
	}

	NSString *logName = @"";
	NSString *dateString = [NSDate formattedShortDateStringForDate:[NSDate date]];

	NSInteger session = [[NSUserDefaults standardUserDefaults] integerForKey:@"JVChatTranscriptSessionHandling"];
	if( ! session ) {
		BOOL nameFound = NO;
		NSUInteger i = 1;

		if( org ) logName = [NSString stringWithFormat:@"%@.colloquyTranscript", [self target]];
		else logName = [NSString stringWithFormat:@"%@ (%@).colloquyTranscript", [self target], [[self user] serverAddress]];
		nameFound = ! [fileManager fileExistsAtPath:[logs stringByAppendingPathComponent:logName]];

		while( ! nameFound ) {
			if( org ) logName = [NSString stringWithFormat:@"%@ %ld.colloquyTranscript", [self target], i++];
			else logName = [NSString stringWithFormat:@"%@ (%@) %ld.colloquyTranscript", [self target], [[self user] serverAddress], i++];
			nameFound = ! [fileManager fileExistsAtPath:[logs stringByAppendingPathComponent:logName]];
		}
	} else if( session == 1 ) {
		if( org ) logName = [NSString stringWithFormat:@"%@.colloquyTranscript", [self target]];
		else logName = [NSString stringWithFormat:@"%@ (%@).colloquyTranscript", [self target], [[self user] serverAddress]];
	} else /* if( session == 2 ) */ {
		if( org ) logName = [NSMutableString stringWithFormat:@"%@ %@.colloquyTranscript", [self target], dateString];
		else logName = [NSMutableString stringWithFormat:@"%@ (%@) %@.colloquyTranscript", [self target], [[self user] serverAddress], dateString];
		[(NSMutableString *)logName replaceOccurrencesOfString:@"/" withString:@"-" options:NSLiteralSearch range:NSMakeRange( 0, [logName length] )];
		[(NSMutableString *)logName replaceOccurrencesOfString:@":" withString:@"-" options:NSLiteralSearch range:NSMakeRange( 0, [logName length] )];
	}

	logs = [logs stringByAppendingPathComponent:logName];

	if( [fileManager fileExistsAtPath:logs] )
		[[self transcript] startNewSession];

	[[self transcript] setFilePath:logs];
	NSURL *connURL = [[self connection] url];
	NSString *targetName = nil;

	if( [_target respondsToSelector:@selector( name )] )
		targetName = [(MVChatRoom *)_target name];
	else if( [_target respondsToSelector:@selector( nickname )] )
		targetName = [(MVChatUser *)_target nickname];
	else targetName = [_target description];

	if( ![connURL scheme] || ![connURL host] || ![connURL path] ) return;
	NSURL *source = [[NSURL alloc] initWithScheme:[connURL scheme] host:[connURL host] path:[[connURL path] stringByAppendingString:[NSString stringWithFormat:@"/%@", targetName]]];
	[[self transcript] setSource:source];
	[[self transcript] setAutomaticallyWritesChangesToFile:YES];
	[[self transcript] setElementLimit:0]; // start with zero limit
}

#pragma mark -
#pragma mark Styles

- (IBAction) changeStyle:(id) sender {
	JVStyle *style = [sender representedObject];

	[self setPreference:[style identifier] forKey:@"style"];
	[self setPreference:nil forKey:@"style variant"];

	[super changeStyle:sender];
}

- (IBAction) changeStyleVariant:(id) sender {
	JVStyle *style = [[sender representedObject] objectForKey:@"style"];
	NSString *variant = [[sender representedObject] objectForKey:@"variant"];

	[self setPreference:[style identifier] forKey:@"style"];
	[self setPreference:variant forKey:@"style variant"];

	[super changeStyleVariant:sender];
}

- (IBAction) changeEmoticons:(id) sender {
	JVEmoticonSet *emoticon = [sender representedObject];

	[self setPreference:[emoticon identifier] forKey:@"emoticon"];

	[super changeEmoticons:sender];
}

#pragma mark -
#pragma mark Encoding Support

- (NSStringEncoding) encoding {
	return _encoding;
}

- (IBAction) changeEncoding:(id) sender {
	if( ! [[self connection] supportedStringEncodings] ) return;

	NSMenuItem *menuItem = nil;
	NSUInteger i = 0, count = 0;
	BOOL new = NO;
	if( ! [sender tag] ) {
		_encoding = (NSStringEncoding) [[self preferenceForKey:@"encoding"] intValue];
		if( ! _encoding ) _encoding = [[self connection] encoding];
	} else _encoding = (NSStringEncoding) [sender tag];

	if( ! _encodingMenu ) {
		_encodingMenu = [[NSMenu alloc] initWithTitle:@""];
		menuItem = [[NSMenuItem alloc] initWithTitle:@"" action:NULL keyEquivalent:@""];
		[menuItem setImage:[NSImage imageNamed:@"encoding"]];
		[_encodingMenu addItem:menuItem];
		new = YES;
	}

	const NSStringEncoding *supportedEncodings = [[self connection] supportedStringEncodings];

	for( i = 0; supportedEncodings[i]; i++ ) {
		/* if( supportedEncodings[i] == (NSStringEncoding) -1 ) {
			if( new ) [_encodingMenu addItem:[NSMenuItem separatorItem]];
			continue;
		} */
		if( new ) menuItem = [[NSMenuItem alloc] initWithTitle:[NSString localizedNameOfStringEncoding:supportedEncodings[i]] action:@selector( changeEncoding: ) keyEquivalent:@""];
		else menuItem = (NSMenuItem *)[_encodingMenu itemAtIndex:i + 1];
		if( _encoding == supportedEncodings[i] ) {
			[menuItem setState:NSOnState];
		} else [menuItem setState:NSOffState];
		if( new ) {
			[menuItem setTag:supportedEncodings[i]];
			[_encodingMenu addItem:menuItem];
		}
	}

	if( ! _spillEncodingMenu ) _spillEncodingMenu = [[NSMenu alloc] initWithTitle:NSLocalizedString( @"Encoding", "encoding menu toolbar item" )];
	count = [_spillEncodingMenu numberOfItems];
	for( i = 0; i < count; i++ ) [_spillEncodingMenu removeItemAtIndex:0];
	count = [_encodingMenu numberOfItems];
	for( i = 1; i < count; i++ ) [_spillEncodingMenu addItem:[(NSMenuItem *)[_encodingMenu itemAtIndex:i] copy]];

	if( _encoding != [[self connection] encoding] ) {
		[self setPreference:[NSNumber numberWithUnsignedLong:_encoding] forKey:@"encoding"];
	} else [self setPreference:nil forKey:@"encoding"];
}

#pragma mark -
#pragma mark Messages & Events

- (void) _performEmoticonSubstitutionOnStringIfNecessary:(NSMutableAttributedString *) string {
	if ([self emoticons] == [JVEmoticonSet textOnlyEmoticonSet])
		return;

	[[self emoticons] performEmoticonSubstitution:string];
}

- (void) addEventMessageToDisplay:(NSString *) message withName:(NSString *) name andAttributes:(NSDictionary *) attributes {
	if( ! _nibLoaded ) [self view];

	NSParameterAssert( name != nil );
	NSParameterAssert( [name length] );

	// The message needs to be able to convert to UTF8, otherwise we can't display it.
	if( ! [message UTF8String] )
		return;

	JVMutableChatEvent *event = [JVMutableChatEvent chatEventWithName:name andMessage:message];
	[event setAttributes:attributes];

	[display setScrollbackLimit:[[NSUserDefaults standardUserDefaults] integerForKey:@"JVChatScrollbackLimit"]];
	if( [[self transcript] automaticallyWritesChangesToFile] )
		[[self transcript] setElementLimit:( [display scrollbackLimit] * 2 )];

	JVChatEvent *newEvent = [[self transcript] appendEvent:event];
	[display appendChatTranscriptElement:newEvent];

	[[NSNotificationCenter chatCenter] postNotificationName:JVChatEventMessageWasProcessedNotification object:self userInfo:[NSDictionary dictionaryWithObject:newEvent forKey:@"event"]];

	if( ! [[[_windowController window] representedFilename] length] )
		[self _refreshWindowFileProxy];
}

- (void) addMessageToDisplay:(NSData *) message fromUser:(MVChatUser *) user asAction:(BOOL) action withIdentifier:(NSString *) identifier andType:(JVChatMessageType) type
{
	[self addMessageToDisplay:message fromUser:user withAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:action] forKey:@"action"] withIdentifier:identifier andType:type];
}

- (void) addMessageToDisplay:(NSData *) message fromUser:(MVChatUser *) user withAttributes:(NSDictionary *) msgAttributes withIdentifier:(NSString *) identifier andType:(JVChatMessageType) type {
	if( ! _nibLoaded ) [self view];

	NSParameterAssert( message != nil );
	NSParameterAssert( user != nil );

	NSFont *baseFont = [[NSFontManager sharedFontManager] fontWithFamily:[[display preferences] standardFontFamily] traits:( NSUnboldFontMask | NSUnitalicFontMask ) weight:5 size:[[display preferences] defaultFontSize]];
	if( ! baseFont ) baseFont = [NSFont userFontOfSize:12.];

	NSMutableDictionary *options = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedLong:_encoding], @"StringEncoding", [NSNumber numberWithBool:[[NSUserDefaults standardUserDefaults] boolForKey:@"JVChatStripMessageColors"]], @"IgnoreFontColors", [NSNumber numberWithBool:[[NSUserDefaults standardUserDefaults] boolForKey:@"JVChatStripMessageFormatting"]], @"IgnoreFontTraits", baseFont, @"BaseFont", nil];
	NSTextStorage *messageString = [NSTextStorage attributedStringWithChatFormat:message options:options];

	if( ! messageString ) {
		[options setObject:[NSNumber numberWithUnsignedLong:NSISOLatin1StringEncoding] forKey:@"StringEncoding"];
		messageString = [[NSTextStorage alloc] initWithAttributedString:[NSMutableAttributedString attributedStringWithChatFormat:message options:options]];

		NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:baseFont, NSFontAttributeName, nil];
		NSMutableAttributedString *error = [[NSMutableAttributedString alloc] initWithString:[@" " stringByAppendingString:NSLocalizedString( @"incompatible encoding", "encoding of the message different than your current encoding" )] attributes:attributes];
		[error addAttribute:@"CSSClasses" value:[NSSet setWithObjects:@"error", @"encoding", nil] range:NSMakeRange( 1, ( [error length] - 1 ) )];
		[messageString appendAttributedString:error];
	}

	// The message needs to be able to convert to UTF8, otherwise we can't display it.
	if( ! [messageString length] || ! [[messageString string] UTF8String] ) {
		NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:baseFont, NSFontAttributeName, [NSSet setWithObjects:@"error", @"encoding", nil], @"CSSClasses", nil];
		messageString = [[NSTextStorage alloc] initWithString:NSLocalizedString( @"incompatible encoding", "encoding of the message different than your current encoding" ) attributes:attributes];
	}

	JVMutableChatMessage *cmessage = [[JVMutableChatMessage alloc] initWithText:messageString sender:user];
	if (msgAttributes[@"time"]) [cmessage setDate:msgAttributes[@"time"]];
	[cmessage setMessageIdentifier:identifier];
	[cmessage setAttributes:msgAttributes];
	[cmessage setAction:[[msgAttributes objectForKey:@"action"] boolValue]];
	[cmessage setType:type];

	if ( !cmessage )
		return;

	messageString = [cmessage body]; // just incase

	if( !messageString) {
		return;
	}

	[self _setCurrentMessage:cmessage];

	if( ! [user isLocalUser] )
		[cmessage setIgnoreStatus:[[JVChatController defaultController] shouldIgnoreUser:user withMessage:messageString inView:self]];

	if( ! [user isLocalUser] && [cmessage ignoreStatus] == JVNotIgnored )
		_newMessageCount++;

	if( ! [[NSUserDefaults standardUserDefaults] boolForKey:@"MVChatDisableLinkHighlighting"] ) {
		[messageString makeLinkAttributesAutomatically];
		[self _hyperlinkRoomNames:messageString];
	}

	[self _performEmoticonSubstitutionOnStringIfNecessary:messageString];

	if( ! [user isLocalUser] ) {
		NSCharacterSet *escapeSet = [NSCharacterSet characterSetWithCharactersInString:@"^[]{}()\\.$*+?|"];
		NSMutableArray *names = [[[NSUserDefaults standardUserDefaults] stringArrayForKey:@"MVChatHighlightNames"] mutableCopy];
		if( [self connection] )
			[names addObject:[[self connection] nickname]];

		NSRegularExpression *regex = nil;

		for( __strong NSString *name in names ) {
			if( ! [name length] ) continue;

			if( [name hasPrefix:@"/"] && [name hasSuffix:@"/"] && [name length] > 1 ) {
				regex = [NSRegularExpression cachedRegularExpressionWithPattern:[name substringWithRange:NSMakeRange( 1, [name length] - 2 )] options:NSRegularExpressionCaseInsensitive error:nil];
			} else {
				name = [name stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\"'"]];
				NSString *pattern = [NSString stringWithFormat:@"(?<=^|\\s|[^\\w])%@(?=$|\\s|[^\\w])", [name stringByEscapingCharactersInSet:escapeSet]];
				regex = [NSRegularExpression cachedRegularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
			}

			NSArray *matches = [regex matchesInString:[messageString string] options:0 range:NSMakeRange( 0, [messageString string].length ) ];
			for( NSTextCheckingResult *match in matches ) {
				NSRange foundRange = [match range];
				NSMutableSet *classes = [NSMutableSet setWithSet:[messageString attribute:@"CSSClasses" atIndex:foundRange.location effectiveRange:NULL]];
				[classes addObject:@"highlight"];
				[messageString addAttribute:@"CSSClasses" value:[NSSet setWithSet:classes] range:foundRange];
				[cmessage setHighlighted:YES];
			}
		}
	}

	[self processIncomingMessage:cmessage];

	if( [[cmessage sender] isKindOfClass:[JVChatRoomMember class]] )
		user = [(JVChatRoomMember *)[cmessage sender] user]; // if this is a chat room, JVChatRoomPanel makes the sender a member object
	else user = [cmessage sender]; // if plugins changed the sending user for some reason, allow it

	if( ! [messageString length] && [cmessage ignoreStatus] == JVNotIgnored ) {  // plugins decided to excluded this message, decrease the new message counts
		_newMessageCount--;
		return;
	}

	if( [cmessage isHighlighted] && [cmessage ignoreStatus] == JVNotIgnored ) {
		_newHighlightMessageCount++;
		NSMutableDictionary *context = [NSMutableDictionary dictionary];
		[context setObject:[NSString stringWithFormat:NSLocalizedString( @"%@ Mentioned a Highlight Word", "mention bubble title" ), [user displayName]] forKey:@"title"];
		[context setObject:[messageString string] forKey:@"description"];
		[context setObject:[NSImage imageNamed:@"activityNewImportant"] forKey:@"image"];
		[context setObject:self forKey:@"target"];
		[context setObject:NSStringFromSelector( @selector( activate: ) ) forKey:@"action"];
		[self performNotification:@"JVChatMentioned" withContextInfo:context];
	}

	if( [cmessage ignoreStatus] != JVNotIgnored ) {
		NSMutableDictionary *context = [NSMutableDictionary dictionary];
		[context setObject:( ( [cmessage ignoreStatus] == JVUserIgnored ) ? NSLocalizedString( @"User Ignored", "user ignored bubble title" ) : NSLocalizedString( @"Message Ignored", "message ignored bubble title" ) ) forKey:@"title"];
		if( [self isMemberOfClass:[JVChatRoomPanel class]] ) [context setObject:[NSString stringWithFormat:NSLocalizedString( @"%@'s message was ignored in %@.", "chat room user ignored bubble text" ), user, [self title]] forKey:@"description"];
		else [context setObject:[NSString stringWithFormat:NSLocalizedString( @"%@'s message was ignored.", "direct chat user ignored bubble text" ), user] forKey:@"description"];
		[context setObject:[NSImage imageNamed:@"activity"] forKey:@"image"];
		[self performNotification:( ( [cmessage ignoreStatus] == JVUserIgnored ) ? @"JVUserIgnored" : @"JVMessageIgnored" ) withContextInfo:context];
	}

	[display setScrollbackLimit:[[NSUserDefaults standardUserDefaults] integerForKey:@"JVChatScrollbackLimit"]];
	if( [[self transcript] automaticallyWritesChangesToFile] )
		[[self transcript] setElementLimit:( [display scrollbackLimit] * 2 )];

	JVChatMessage *newMessage = [[self transcript] appendMessage:cmessage];
	if( [display appendChatMessage:newMessage] ) {
		if( [cmessage isHighlighted] ) [display markScrollbarForMessage:newMessage];
		[self quickSearchMatchMessage:newMessage];
		_firstMessage = NO; // not the first message anymore
	} else if( [cmessage ignoreStatus] == JVNotIgnored ) {
		// the style decided to excluded this message, decrease the new message counts
		if( [cmessage isHighlighted] ) _newHighlightMessageCount--;
		_newMessageCount--;
	}

	if( [cmessage ignoreStatus] == JVNotIgnored ) {
		NSString *voiceIdentifier = [[[MVBuddyListController sharedBuddyList] buddyForUser:user] speechVoice];
		if( [voiceIdentifier length] ) {
			NSString *text = [cmessage bodyAsPlainText];
			if( [cmessage isAction] ) text = [NSString stringWithFormat:@"%@ %@", [[cmessage sender] displayName], text];
			[[JVSpeechController sharedSpeechController] startSpeakingString:text usingVoice:voiceIdentifier];
		}
	}

	[[NSNotificationCenter chatCenter] postNotificationName:JVChatMessageWasProcessedNotification object:self userInfo:[NSDictionary dictionaryWithObject:newMessage forKey:@"message"]];

	[self _setCurrentMessage:nil];

	[_windowController reloadListItem:self andChildren:NO];

	if( ! [[[_windowController window] representedFilename] length] )
		[self _refreshWindowFileProxy];

	[(MVApplicationController *)[NSApp delegate] updateDockTile];
}

- (void) processIncomingMessage:(JVMutableChatMessage *) message {
	if( [[message sender] respondsToSelector:@selector( isLocalUser )] && ! [[message sender] isLocalUser] ) {
		NSString *windowTitle = [self windowTitle];
		if (!windowTitle) return;

		if( [message ignoreStatus] == JVNotIgnored && _firstMessage ) {
			NSMutableDictionary *context = [NSMutableDictionary dictionary];
			[context setObject:NSLocalizedString( @"New Private Message", "first message bubble title" ) forKey:@"title"];
			[context setObject:[NSString stringWithFormat:NSLocalizedString( @"%@ wrote you a private message.", "first message bubble text" ), [self title]] forKey:@"description"];
			[context setObject:[NSImage imageNamed:@"messageUser"] forKey:@"image"];
			[context setObject:[windowTitle stringByAppendingString:@"JVChatPrivateMessage"] forKey:@"coalesceKey"];
			[context setObject:self forKey:@"target"];
			[context setObject:NSStringFromSelector( @selector( activate: ) ) forKey:@"action"];
			[context setObject:[NSString stringWithFormat:@"%@: %@", self.target, [message bodyAsPlainText]] forKey:@"subtitle"];
			[self performNotification:@"JVChatFirstMessage" withContextInfo:context];
		} else if( [message ignoreStatus] == JVNotIgnored ) {
			NSMutableDictionary *context = [NSMutableDictionary dictionary];
			[context setObject:NSLocalizedString( @"Private Message", "new message bubble title" ) forKey:@"title"];
			if( [self newMessagesWaiting] == 1 ) [context setObject:[NSString stringWithFormat:NSLocalizedString( @"You have 1 message waiting from %@.", "new single message bubble text" ), [self title]] forKey:@"description"];
			[context setObject:[NSString stringWithFormat:NSLocalizedString( @"You have %d messages waiting from %@.", "new messages bubble text" ), [self newMessagesWaiting], [self title]] forKey:@"description"];
			[context setObject:[NSImage imageNamed:@"messageUser"] forKey:@"image"];
			[context setObject:[windowTitle stringByAppendingString:@"JVChatPrivateMessage"] forKey:@"coalesceKey"];
			[context setObject:self forKey:@"target"];
			[context setObject:NSStringFromSelector( @selector( activate: ) ) forKey:@"action"];
			[context setObject:[NSString stringWithFormat:@"%@: %@", self.target, [message bodyAsPlainText]] forKey:@"subtitle"];
			[self performNotification:@"JVChatAdditionalMessages" withContextInfo:context];
		}
	}

	NSMethodSignature *signature = [NSMethodSignature methodSignatureWithReturnAndArgumentTypes:@encode( void ), @encode( JVMutableChatMessage * ), @encode( id ), nil];
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];

	[invocation setSelector:@selector( processIncomingMessage:inView: )];
	MVAddUnsafeUnretainedAddress(message, 2);
	MVAddUnsafeUnretainedAddress(self, 3);

	[[MVChatPluginManager defaultManager] makePluginsPerformInvocation:invocation stoppingOnFirstSuccessfulReturn:NO];
}

- (void) echoSentMessageToDisplay:(JVMutableChatMessage *) message {
	NSString *cformat = nil;

	switch( [[self connection] outgoingChatFormat] ) {
	case MVChatConnectionDefaultMessageFormat:
	case MVChatWindowsIRCMessageFormat:
		cformat = NSChatWindowsIRCFormatType;
		break;
	case MVChatCTCPTwoMessageFormat:
		cformat = NSChatCTCPTwoFormatType;
		break;
	default:
	case MVChatNoMessageFormat:
		cformat = nil;
	}

	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedLong:[self encoding]], @"StringEncoding", cformat, @"FormatType", nil];
	NSData *msgData = [[message body] chatFormatWithOptions:options]; // we could save this back to the message object before sending
	[self addMessageToDisplay:msgData fromUser:[message sender] withAttributes:[message attributes] withIdentifier:[message messageIdentifier] andType:[message type]];
}

- (NSUInteger) newMessagesWaiting {
	return _newMessageCount;
}

- (NSUInteger) newHighlightMessagesWaiting {
	return _newHighlightMessageCount;
}

- (JVMutableChatMessage *) currentMessage {
	return _currentMessage;
}

#pragma mark -
#pragma mark History manipulation

// Should this exist? When does history need to be modified by anything but the send view controller itself?
- (void) addMessageToHistory:(NSAttributedString *) message {
	[sendViewController.history addToHistory:message];
}

#pragma mark -
#pragma mark Notifications Handling

/**
 * This method should be used to handle all notification processing. It will check to see if
 * notifications have been muted for the given chat room, and if they have, it will not pass
 * the notification request on to the JVNotificationController.
 */
- (void) performNotification:(NSString *) identifier withContextInfo:(NSDictionary *) context {
	if( ![[self preferenceForKey:@"muted"] boolValue] )
		[[JVNotificationController defaultController] performNotification:identifier withContextInfo:context];
}

/**
 * Toggles notifications (this is for private, direct user-user chats)
 */
- (IBAction) toggleNotifications:(id) sender {
	if( [self preferenceForKey:@"muted"] == [NSNumber numberWithBool:YES] )
		[self setPreference:[NSNumber numberWithBool:NO] forKey:@"muted"];
	else [self setPreference:[NSNumber numberWithBool:YES] forKey:@"muted"];
}


#pragma mark -
#pragma mark Send View Support

- (void)sendViewRequestedSend:(CQSendViewController *)sendVC options:(CQSendViewOptions)options
{
	[self send_asAction:((options & CQSendViewSendAsAction) != 0)];
}


- (void)sendViewWillResize:(CQSendViewController *)sendVC
{
	// Before the resize happens, take note of whether the chat transcript is "at the bottom",
	// and then in didResize, ensure it scrolls to the bottom if it should.
	_scrollerIsAtBottom = [display scrolledNearBottom];
}


- (void)sendViewDidResize:(CQSendViewController *)sendVC
{
	if (_scrollerIsAtBottom) {
		[display scrollToBottom];
	}
}


- (void)sendView:(CQSendViewController *)sendView navigationKeyPressed:(NSEvent *)event
{
	[[[[display mainFrame] findFrameNamed:@"content"] frameView] keyDown:event];
}




#pragma mark -
#pragma mark Input Handling

- (IBAction) send:(id) sender
{
	[self send_asAction:NO];
}


- (void)send_asAction:(BOOL)asAction
{
	// Allow commands to be passed to plugins if we aren't connected
	// Allow commands to pass to plugins and server if we are just out of the room
	if ((_cantSendMessages || !self.isEnabled) && !sendViewController.stringToSendIsACommand) {
		if( [[self target] isKindOfClass:[MVChatUser class]] && [[self user] status] == MVChatUserOfflineStatus ) {
			NSAlert *alert = [[NSAlert alloc] init];
			[alert setMessageText:[NSString stringWithFormat:NSLocalizedString( @"User \"%@\" is not online", "user not online alert dialog title" ), [[self user] displayName]]];
			[alert setInformativeText:[NSString stringWithFormat:NSLocalizedString( @"The user \"%@\" is not online and is unavailable until they reconnect.", "user not online alert dialog message" ), [[self user] displayName]]];
			[alert setAlertStyle:NSInformationalAlertStyle];
			[alert runModal];
		}
		return;
	}
	
	[sendViewController sendWithConnection:self.connection asAction:asAction inView:self];
	[display scrollToBottom];
}



- (void)sendView:(CQSendViewController *)sendView sendCommand:(NSString *)command withArguments:(NSAttributedString *)arguments
{
	[[self target] sendCommand:command withArguments:arguments withEncoding:_encoding];
}



- (void)sendView:(CQSendViewController *)sendView sendMessage:(NSAttributedString *)message asAction:(BOOL)asAction
{
	MVChatUser* localUser = ( [[self target] isKindOfClass:[MVChatRoom class]] ? [[self target] localMemberUser] : [[self connection] localUser] );
	JVMutableChatMessage * msg = [[JVMutableChatMessage alloc] initWithText:message sender:localUser];
	msg.action = asAction;
	
	[self sendMessage:msg];
	
	// echo after the plugins process the message, if the server won't echo it for us
	if (![self.connection.supportedFeatures containsObject:MVChatConnectionEchoMessageFeature]) {
		[self echoSentMessageToDisplay:msg];
	}
}



- (void) sendMessage:(JVMutableChatMessage *) message {
	NSMethodSignature *signature = [NSMethodSignature methodSignatureWithReturnAndArgumentTypes:@encode( void ), @encode( JVMutableChatMessage * ), @encode( id ), nil];
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];

	[invocation setSelector:@selector( processOutgoingMessage:inView: )];
	MVAddUnsafeUnretainedAddress(message, 2);
	MVAddUnsafeUnretainedAddress(self, 3);

	[self _setCurrentMessage:message];
	[[MVChatPluginManager defaultManager] makePluginsPerformInvocation:invocation stoppingOnFirstSuccessfulReturn:NO];
	[self _setCurrentMessage:nil];

	if( [[message body] length] )
		[[self target] sendMessage:[message body] withEncoding:_encoding withAttributes:[message attributes]];
}

#pragma mark -
#pragma mark ScrollBack

- (IBAction) clear:(id) sender {
	sendViewController.stringToSend = nil;
}

- (IBAction) clearDisplay:(id) sender {
	[display clear];
}

- (IBAction) markDisplay:(id) sender {
	[display mark];
}




#pragma mark -
#pragma mark SplitView Support

- (CGFloat) splitView:(NSSplitView *) splitView constrainSplitPosition:(CGFloat) proposedPosition ofSubviewAt:(NSInteger) index {
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"JVChatInputAutoResizes"] )
		return ( NSHeight( [[[splitView subviews] objectAtIndex:index] frame] ) ); // prevents manual resize
	return proposedPosition;
}

- (void) splitViewDidResizeSubviews:(NSNotification *) notification {
	// Cache the height of the send box so we can keep it constant during window resizes.
	NSRect sendFrame = sendViewController.view.frame;
	_sendHeight = sendFrame.size.height;

	if( _scrollerIsAtBottom ) [display scrollToBottom];

	if( ! _forceSplitViewPosition && ! [[NSUserDefaults standardUserDefaults] boolForKey:@"JVChatInputAutoResizes"] )
		[(JVSplitView *)[notification object] savePositionUsingName:@"JVChatSplitViewPosition"];

	_forceSplitViewPosition = NO;
}

- (void) splitViewWillResizeSubviews:(NSNotification *) notification {
	_scrollerIsAtBottom = [display scrolledNearBottom];
}

- (void) splitView:(NSSplitView *) sender resizeSubviewsWithOldSize:(NSSize) oldSize {
	float dividerThickness = [sender dividerThickness];
	NSRect newFrame = [sender frame];

	// Keep the size of the send box constant during window resizes

	// We need to resize the scroll view frames of the webview and the textview.
	// The scroll views are two superviews up: NSTextView(WebView) -> NSClipView -> NSScrollView
	NSRect sendFrame = sendViewController.view.frame;
	NSRect webFrame = [display frame];

	// Set size of the web view to the maximum size possible
	webFrame.size.height = NSHeight( newFrame ) - dividerThickness - _sendHeight;
	webFrame.size.width = NSWidth( newFrame );
	webFrame.origin = NSMakePoint( 0., 0. );

	// Keep the send box the same size
	sendFrame.size.height = _sendHeight;
	sendFrame.size.width = NSWidth( newFrame );
	sendFrame.origin.y = NSHeight( webFrame ) + dividerThickness;

	// Commit the changes
	sendFrame.size.width = newFrame.size.width;
	sendViewController.view.frame = sendFrame;
	[display setFrame:webFrame];
}

#pragma mark -
#pragma mark Toolbar Support

- (NSString *) toolbarIdentifier {
	return @"Direct Chat";
}

- (NSToolbarItem *) toolbar:(NSToolbar *) toolbar itemForItemIdentifier:(NSString *) identifier willBeInsertedIntoToolbar:(BOOL) willBeInserted {
	if( [identifier isEqual:JVToolbarTextEncodingItemIdentifier] ) {
		NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:identifier];

		[toolbarItem setLabel:NSLocalizedString( @"Encoding", "encoding menu toolbar item" )];
		[toolbarItem setPaletteLabel:NSLocalizedString( @"Text Encoding", "encoding menu toolbar customize palette name" )];

		[toolbarItem setTarget:nil];
		[toolbarItem setAction:NULL];

		NSPopUpButton *button = [[NSPopUpButton alloc] initWithFrame:NSMakeRect( 0., 0., 53., 20. ) pullsDown:YES];
		[button setMenu:_encodingMenu];

		[toolbarItem setToolTip:NSLocalizedString( @"Text Encoding Options", "encoding menu toolbar item tooltip" )];
		[toolbarItem setMinSize:NSMakeSize( 60., 24. )];
		[toolbarItem setMaxSize:NSMakeSize( 60., 32. )];

		[toolbarItem setView:button];

		NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString( @"Encoding", "encoding menu toolbar item" ) action:NULL keyEquivalent:@""];
		[menuItem setImage:[NSImage imageNamed:@"encoding"]];
		[menuItem setSubmenu:_spillEncodingMenu];

		[toolbarItem setMenuFormRepresentation:menuItem];

		return toolbarItem;
	} else if( [identifier isEqual:JVToolbarClearScrollbackItemIdentifier] ) {
		NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:identifier];

		[toolbarItem setLabel:NSLocalizedString( @"Clear", "clear display toolbar button name" )];
		[toolbarItem setPaletteLabel:NSLocalizedString( @"Clear Display", "clear display toolbar customize palette name" )];

		[toolbarItem setToolTip:NSLocalizedString( @"Clear Display", "clear display tooltip" )];
		[toolbarItem setImage:[NSImage imageNamed:@"clear"]];

		[toolbarItem setTarget:self];
		[toolbarItem setAction:@selector( clearDisplay: )];

		return toolbarItem;
	} else if( [identifier isEqual:JVToolbarMarkItemIdentifier] ) {
		NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:identifier];

		[toolbarItem setLabel:NSLocalizedString( @"Mark", "mark display toolbar button name" )];
		[toolbarItem setPaletteLabel:NSLocalizedString( @"Mark Display", "mark display toolbar customize palette name" )];

		[toolbarItem setToolTip:NSLocalizedString( @"Mark Display", "mark display tooltip" )];
		[toolbarItem setImage:[NSImage imageNamed:@"markDisplay"]];

		[toolbarItem setTarget:self];
		[toolbarItem setAction:@selector( markDisplay: )];

		return toolbarItem;
	} else if( [identifier isEqual:JVToolbarSendFileItemIdentifier] ) {
		NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:identifier];

		[toolbarItem setLabel:NSLocalizedString( @"Send File", "send file toolbar button name" )];
		[toolbarItem setPaletteLabel:NSLocalizedString( @"Send File", "send file toolbar customize palette name" )];

		[toolbarItem setToolTip:NSLocalizedString( @"Send File", "send file toolbar tooltip" )];
		[toolbarItem setImage:[NSImage imageNamed:@"fileSend"]];

		[toolbarItem setTarget:[self user]];
		[toolbarItem setAction:@selector( sendFile: )];

		return toolbarItem;
	}

	return [super toolbar:toolbar itemForItemIdentifier:identifier willBeInsertedIntoToolbar:willBeInserted];
}

- (NSArray *) toolbarDefaultItemIdentifiers:(NSToolbar *) toolbar {
	NSMutableArray *list = [NSMutableArray arrayWithArray:[super toolbarDefaultItemIdentifiers:toolbar]];
	if( [self isMemberOfClass:[JVDirectChatPanel class]] ) {
		[list addObject:JVToolbarSendFileItemIdentifier];
		[list addObject:JVToolbarTextEncodingItemIdentifier];
		[list addObject:NSToolbarFlexibleSpaceItemIdentifier];
		[list addObject:JVToolbarMarkItemIdentifier];
		[list addObject:JVToolbarClearScrollbackItemIdentifier];
		[list addObject:NSToolbarSeparatorItemIdentifier];
		[list addObject:JVToolbarQuickSearchItemIdentifier];
	}
	return list;
}

- (NSArray *) toolbarAllowedItemIdentifiers:(NSToolbar *) toolbar {
	NSMutableArray *list = [NSMutableArray arrayWithArray:[super toolbarAllowedItemIdentifiers:toolbar]];
	if( [self isMemberOfClass:[JVDirectChatPanel class]] ) [list addObject:JVToolbarSendFileItemIdentifier];
	[list addObject:JVToolbarTextEncodingItemIdentifier];
	[list addObject:JVToolbarClearScrollbackItemIdentifier];
	[list addObject:JVToolbarMarkItemIdentifier];
	return list;
}

#pragma mark-
#pragma mark WebKit Support

- (NSArray *) webView:(WebView *) sender contextMenuItemsForElement:(NSDictionary *) element defaultMenuItems:(NSArray *) defaultMenuItems {
	NSMutableArray *ret = [NSMutableArray array];

	BOOL found = NO;

	for( NSMenuItem *item in defaultMenuItems ) {
		switch( [item tag] ) {
			case WebMenuItemTagCopy:
			case WebMenuItemTagDownloadLinkToDisk:
			case WebMenuItemTagDownloadImageToDisk:
				found = YES;
				break;
		}
	}

	if( ! found && ! [[element objectForKey:WebElementIsSelectedKey] boolValue] ) {
		NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString( @"Clear Display", "clear display contextual menu" ) action:NULL keyEquivalent:@""];
		[item setTarget:self];
		[item setAction:@selector( clearDisplay: )];
		[ret addObject:item];

		item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString( @"Encoding", "encoding contextual menu" ) action:NULL keyEquivalent:@""];
		[item setSubmenu:_spillEncodingMenu];
		[ret addObject:item];
	}

	[ret addObjectsFromArray:[super webView:sender contextMenuItemsForElement:element defaultMenuItems:defaultMenuItems]];

	return ret;
}

#pragma mark - ABImageClient

- (void) consumeImageData:(NSData *) data forTag:(NSInteger) tag {
	_personImageData = data;
	_loadingPersonImage = NO;
}
@end

#pragma mark -

@implementation JVDirectChatPanel (Private)
- (NSString *) _selfCompositeName {
	ABPerson *_person = [[ABAddressBook sharedAddressBook] me];
	NSString *firstName = [_person valueForProperty:kABFirstNameProperty];
	NSString *lastName = [_person valueForProperty:kABLastNameProperty];

	if( ! firstName && lastName ) return lastName;
	else if( firstName && ! lastName ) return firstName;
	else if( firstName && lastName ) {
		return [NSString stringWithFormat:@"%@ %@", firstName, lastName];
	}

	firstName = [_person valueForProperty:kABNicknameProperty];
	if( firstName ) return firstName;

	return [[self connection] nickname];
}

- (NSString *) _selfStoredNickname {
	NSString *nickname = [[[ABAddressBook sharedAddressBook] me] valueForProperty:kABNicknameProperty];
	if( nickname ) return nickname;
	return [[self connection] nickname];
}

- (NSMenu *) _encodingMenu {
	if( ! _nibLoaded ) [self view];
	return _encodingMenu;
}

- (void) _hyperlinkRoomNames:(NSMutableAttributedString *) message {
	if( ! message || ! [message string] ) return;
	if( [[self connection] type] != MVChatConnectionIRCType ) return;

	// catch IRC rooms like "#room" but not HTML colors like "#ab12ef" nor HTML entities like "&#135;" or "&amp;"
	NSRegularExpression *regex = [NSRegularExpression cachedRegularExpressionWithPattern:@"\\B(?<!&)#(?![\\da-fA-F]{6}\\b|\\d{1,3}\\b)[\\w-_.+&#]{2,}\\b" options:NSRegularExpressionCaseInsensitive error:nil];
	NSArray *matches = [regex matchesInString:[message string] options:0 range:NSMakeRange( 0, [message string].length )];

	for( NSTextCheckingResult *match in matches ) {
		NSRange foundRange = [match range];
		NSString *text = [[message string] substringWithRange:foundRange];
		id currentLink = [message attribute:NSLinkAttributeName atIndex:foundRange.location effectiveRange:NULL];
		if( ! currentLink ) [message addAttribute:NSLinkAttributeName value:[NSString stringWithFormat:@"%@://%@/%@", [[self connection] urlScheme], [[self connection] server], text] range:foundRange];
	}
}

- (NSMutableAttributedString *) _convertRawMessage:(NSData *) message {
	return [self _convertRawMessage:message withBaseFont:nil];
}

- (NSMutableAttributedString *) _convertRawMessage:(NSData *) message withBaseFont:(NSFont *) baseFont {
	if( ! message || ! [message length] ) return nil;

	if( ! baseFont ) baseFont = [[NSFontManager sharedFontManager] fontWithFamily:[[display preferences] standardFontFamily] traits:( NSUnboldFontMask | NSUnitalicFontMask ) weight:5 size:[[display preferences] defaultFontSize]];
	if( ! baseFont ) baseFont = [NSFont userFontOfSize:12.];

	NSMutableDictionary *options = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedLong:_encoding], @"StringEncoding", [NSNumber numberWithBool:[[NSUserDefaults standardUserDefaults] boolForKey:@"JVChatStripMessageColors"]], @"IgnoreFontColors", [NSNumber numberWithBool:[[NSUserDefaults standardUserDefaults] boolForKey:@"JVChatStripMessageFormatting"]], @"IgnoreFontTraits", baseFont, @"BaseFont", nil];
	NSMutableAttributedString *messageString = [NSMutableAttributedString attributedStringWithChatFormat:message options:options];

	if( ! messageString ) {
		[options setObject:[NSNumber numberWithUnsignedLong:NSISOLatin1StringEncoding] forKey:@"StringEncoding"];
		messageString = [NSMutableAttributedString attributedStringWithChatFormat:message options:options];
	}

	if( ! [[NSUserDefaults standardUserDefaults] boolForKey:@"MVChatDisableLinkHighlighting"] ) {
		[messageString makeLinkAttributesAutomatically];
		[self _hyperlinkRoomNames:messageString];
	}

	[self _performEmoticonSubstitutionOnStringIfNecessary:messageString];

	return messageString;
}

- (void) _didConnect:(NSNotification *) notification {
	[self addEventMessageToDisplay:NSLocalizedString( @"You reconnected to the server.", "reconnected to server status message" ) withName:@"reconnected" andAttributes:nil];
	if( [self isMemberOfClass:[JVDirectChatPanel class]] )
		_cantSendMessages = NO;
}

- (void) _didDisconnect:(NSNotification *) notification {
	[self addEventMessageToDisplay:NSLocalizedString( @"You left the chat by being disconnected from the server.", "disconnect from the server status message" ) withName:@"disconnected" andAttributes:nil];
	_cantSendMessages = YES;
}

- (void) _errorOccurred:(NSNotification *) notification {
	NSError *error = [[notification userInfo] objectForKey:@"error"];
	if( [error code] == MVChatConnectionNoSuchUserError ) {
		MVChatUser *user = [[error userInfo] objectForKey:@"user"];
		if( [user isEqualTo:[self user]] )
			[self addEventMessageToDisplay:[NSString stringWithFormat:NSLocalizedString( @"%@ is not online. Any messages sent will not be received.", "user not online" ), [[[self user] displayName] stringByEncodingXMLSpecialCharactersAsEntities]] withName:@"offline" andAttributes:nil];
	}
}

- (void) _awayStatusChanged:(NSNotification *) notification {
	if( [[self connection] awayStatusMessage] ) {
		NSMutableAttributedString *messageString = [[[self connection] awayStatusMessage] mutableCopy];

		if( ! [[NSUserDefaults standardUserDefaults] boolForKey:@"MVChatDisableLinkHighlighting"] )
			[messageString makeLinkAttributesAutomatically];

		[self _performEmoticonSubstitutionOnStringIfNecessary:messageString];

		NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"IgnoreFonts", [NSNumber numberWithBool:YES], @"IgnoreFontSizes", nil];
		NSString *msgString = [messageString HTMLFormatWithOptions:options];

		[self addEventMessageToDisplay:[NSString stringWithFormat:NSLocalizedString( @"You have set yourself away with \"%@\".", "self away status set message" ), msgString] withName:@"awaySet" andAttributes:[NSDictionary dictionaryWithObjectsAndKeys:messageString, @"away-message", nil]];

		NSUInteger messageCount = [display _visibleMessageCount];
		NSUInteger loc = [display _locationOfElementAtIndex:( messageCount - 1 )];
		if( loc != NSNotFound ) [[display verticalMarkedScroller] startShadedAreaAt:loc];
	} else {
		[self addEventMessageToDisplay:NSLocalizedString( @"You have returned from away.", "self away status removed message" ) withName:@"awayRemoved" andAttributes:nil];

		NSUInteger messageCount = [display _visibleMessageCount];
		NSUInteger loc = [display _locationOfElementAtIndex:( messageCount - 1 )];
		if( loc != NSNotFound ) [[display verticalMarkedScroller] stopShadedAreaAt:loc];
	}
}

- (void) _updateEmoticonsMenu {
	NSEnumerator *enumerator = nil;
	NSMenu *menu = nil, *subMenu = nil;
	NSMenuItem *menuItem = nil;
	BOOL new = YES;

	if( ! ( menu = _emoticonMenu ) ) {
		menu = [[NSMenu alloc] initWithTitle:@""];
		_emoticonMenu = menu;
	} else {
		new = NO;
		enumerator = [[[menu itemArray] copy] objectEnumerator];
		if( ! [menu indexOfItemWithTitle:NSLocalizedString( @"Emoticons", "choose emoticons toolbar item label" )] )
			[enumerator nextObject];
		while( ( menuItem = [enumerator nextObject] ) )
			if( ! [menuItem tag] && ! [menuItem isSeparatorItem] )
				[menu removeItem:menuItem];
	}

	NSUInteger count = 0;
	if( ! [menu indexOfItemWithTitle:NSLocalizedString( @"Emoticons", "choose emoticons toolbar item label" )] )
		count++;

	NSArray *menuItems = [[self emoticons] emoticonMenuItems];
	for( menuItem in menuItems ) {
		[menuItem setAction:@selector( _insertEmoticon: )];
		[menuItem setTarget:self];
		[menu insertItem:menuItem atIndex:count++];
	}

	if( ! [menuItems count] ) {
		menuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString( @"No Selectable Emoticons", "no selectable emoticons menu item title" ) action:NULL keyEquivalent:@""];
		[menuItem setEnabled:NO];
		[menu insertItem:menuItem atIndex:count];
	}

	if( new ) {
		JVEmoticonSet *emoticon = nil;

		[menu addItem:[NSMenuItem separatorItem]];

		subMenu = [[NSMenu alloc] initWithTitle:@""];
		menuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString( @"Preferences", "preferences menu item title" ) action:NULL keyEquivalent:@""];
		[menuItem setSubmenu:subMenu];
		[menuItem setTag:20];
		[menu addItem:menuItem];

		menuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString( @"Style Default", "default style emoticons menu item title" ) action:@selector( changeEmoticons: ) keyEquivalent:@""];
		[menuItem setTarget:self];
		[subMenu addItem:menuItem];

		[subMenu addItem:[NSMenuItem separatorItem]];

		menuItem = [[NSMenuItem alloc] initWithTitle:[[JVEmoticonSet textOnlyEmoticonSet] displayName] action:@selector( changeEmoticons: ) keyEquivalent:@""];
		[menuItem setTarget:self];
		[menuItem setRepresentedObject:[JVEmoticonSet textOnlyEmoticonSet]];
		[subMenu addItem:menuItem];

		[subMenu addItem:[NSMenuItem separatorItem]];

		enumerator = [[[[JVEmoticonSet emoticonSets] allObjects] sortedArrayUsingSelector:@selector( compare: )] objectEnumerator];
		while( ( emoticon = [enumerator nextObject] ) ) {
			if( ! [[emoticon displayName] length] ) continue;
			menuItem = [[NSMenuItem alloc] initWithTitle:[emoticon displayName] action:@selector( changeEmoticons: ) keyEquivalent:@""];
			[menuItem setTarget:self];
			[menuItem setRepresentedObject:emoticon];
			[subMenu addItem:menuItem];
		}

		[subMenu addItem:[NSMenuItem separatorItem]];

		menuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString( @"Appearance Preferences...", "appearance preferences menu item title" ) action:@selector( _openAppearancePreferences: ) keyEquivalent:@""];
		[menuItem setTarget:self];
		[menuItem setTag:10];
		[subMenu addItem:menuItem];
	}

	[self _changeEmoticonsMenuSelection];
}

- (void) _insertEmoticon:(id) sender {
	[sendViewController insertEmoticon:(NSString *)[sender representedObject]];
}

- (BOOL) _usingSpecificStyle {
	return ( [self preferenceForKey:@"style"] ? YES : NO );
}

- (BOOL) _usingSpecificEmoticons {
	return ( [self preferenceForKey:@"emoticon"] ? YES : NO );
}

- (void) _didSwitchStyles:(NSNotification *) notification {
	[super _didSwitchStyles:notification];
	
	NSFont *baseFont = nil;
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"JVChatInputUsesStyleFont"] ) {
		WebPreferences *preferences = [display preferences];
		// in some versions of WebKit (v125.9 at least), this is a font name, not a font family, try both
		NSString *fontFamily = [preferences standardFontFamily];
		NSInteger fontSize = [preferences defaultFontSize];
		baseFont = [NSFont fontWithName:fontFamily size:fontSize];
		if( ! baseFont ) baseFont = [[NSFontManager sharedFontManager] fontWithFamily:fontFamily traits:( NSUnboldFontMask | NSUnitalicFontMask ) weight:5 size:fontSize];
	}

	[sendViewController.sendTextView setBaseFont:baseFont];
}

- (void) _saveSelfIcon {
	if( _loadingPersonImage ) return;
	_loadingPersonImage = YES;

	ABPerson *me = [[ABAddressBook sharedAddressBook] me];

	@try {
		[me beginLoadingImageDataForClient:self];
	} @catch ( NSException *exception ) {
		_loadingPersonImage = NO;
		return;
	}

	while( ! _personImageData && _loadingPersonImage ) // asynchronously load the image incase it is on the network
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];

	if( ! [_personImageData length] ) {
		[[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"/tmp/%@.tif", [me uniqueId]] error:nil];
	} else {
		NSImage *icon = [[NSImage alloc] initWithData:_personImageData];
		NSData *imageData = [icon TIFFRepresentation];
		[imageData writeToFile:[NSString stringWithFormat:@"/tmp/%@.tif", [me uniqueId]] atomically:NO];

		_personImageData = nil;
	}
}

- (void) _saveBuddyIcon:(JVBuddy *) buddy {
	NSData *imageData = [[buddy picture] TIFFRepresentation];
	if( ! [imageData length] ) {
		[[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"/tmp/%@.tif", [buddy uniqueIdentifier]] error:nil];
		return;
	}

	[imageData writeToFile:[NSString stringWithFormat:@"/tmp/%@.tif", [buddy uniqueIdentifier]] atomically:NO];
}

- (void) _refreshIcon:(NSNotification *) notification {
	[_windowController reloadListItem:self andChildren:NO];
}

- (void) _setCurrentMessage:(JVMutableChatMessage *) message {
	[_currentMessage setObjectSpecifier:nil];
	_currentMessage = message;

	id classDescription = [NSClassDescription classDescriptionForClass:[self class]];
	id msgSpecifier = [[NSPropertySpecifier alloc] initWithContainerClassDescription:classDescription containerSpecifier:[self objectSpecifier] key:@"currentMessage"];
	[_currentMessage setObjectSpecifier:msgSpecifier];
}

- (void) _userNicknameDidChange:(NSNotification *) notification {
	if( ! _watchRule ) return;

	[[self connection] removeChatUserWatchRule:_watchRule];

	[_watchRule setNickname:[_target nickname]];

	[[self connection] addChatUserWatchRule:_watchRule];
}

- (void) _userStatusChanged:(NSNotification *) notification {
	if ([(MVChatUser *)_target status] == MVChatUserOfflineStatus)
		[self addEventMessageToDisplay:[NSString stringWithFormat:NSLocalizedString( @"%@ disconnected from the server.", "User disconnected event message" ), [[[self user] displayName] stringByEncodingXMLSpecialCharactersAsEntities]] withName:@"userDisconnected" andAttributes:nil];
	else if ([(MVChatUser *)_target status] == MVChatUserAwayStatus)
		[self addEventMessageToDisplay:[NSString stringWithFormat:NSLocalizedString( @"<span class=\"member\">%@</span> is marked as away.", "User marked as away event message" ), [[[self user] displayName] stringByEncodingXMLSpecialCharactersAsEntities]] withName:@"userAway" andAttributes:nil];
	else if ([(MVChatUser *)_target status] == MVChatUserAvailableStatus)
		[self addEventMessageToDisplay:[NSString stringWithFormat:NSLocalizedString( @"<span class=\"member\">%@</span> is now available.", "User available event message" ), [[[self user] displayName] stringByEncodingXMLSpecialCharactersAsEntities]] withName:@"userAvailable" andAttributes:nil];
}

@end

#pragma mark -

@implementation NSApplication (NSApplicationActivePanelScripting)
- (void) sendMessageScriptCommand:(NSScriptCommand *) command {
	// if there is a subject or target parameter, perform the default implementation
	if( [command subjectSpecifier] || [[command evaluatedArguments] objectForKey:@"target"] ) {
		[command performDefaultImplementation];
		return;
	}

	// if nothing responds to this command make it perform on the active panel of the front window
	id classDescription = [NSClassDescription classDescriptionForClass:[NSApplication class]];
	id container = [[NSIndexSpecifier alloc] initWithContainerClassDescription:classDescription containerSpecifier:nil key:@"orderedWindows" index:0];
	if( ! container ) return;

	classDescription = [NSClassDescription classDescriptionForClass:[NSWindow class]];
	id specifier = [[NSPropertySpecifier alloc] initWithContainerClassDescription:classDescription containerSpecifier:container key:@"activeChatViewController"];
	if( ! specifier ) return;

	[command setSubjectSpecifier:specifier];
	[command performDefaultImplementation];
}

- (id) addEventMessageScriptCommand:(NSScriptCommand *) command {
	// if there is a subject, perform the default implementation
	if( [command subjectSpecifier] ) {
		[command performDefaultImplementation];
		return nil;
	}

	// if nothing responds to this command make it perform on the active panel of the front window
	id classDescription = [NSClassDescription classDescriptionForClass:[NSApplication class]];
	id container = [[NSIndexSpecifier alloc] initWithContainerClassDescription:classDescription containerSpecifier:nil key:@"orderedWindows" index:0];
	if( ! container ) return nil;

	classDescription = [NSClassDescription classDescriptionForClass:[NSWindow class]];
	id specifier = [[NSPropertySpecifier alloc] initWithContainerClassDescription:classDescription containerSpecifier:container key:@"activeChatViewController"];
	if( ! specifier ) return nil;

	[command setSubjectSpecifier:specifier];
	[command performDefaultImplementation];
	return nil;
}
@end

#pragma mark -

@implementation JVDirectChatPanel (JVDirectChatScripting)
- (void) sendMessageScriptCommand:(NSScriptCommand *) command {
	NSDictionary *args = [command evaluatedArguments];
	id message = [command evaluatedDirectParameter];
	id action = [args objectForKey:@"action"];
	id localEcho = [args objectForKey:@"echo"];

	if( [args objectForKey:@"message"] ) // support the old command that had a message parameter instead
		message = [args objectForKey:@"message"];

	if( ! message ) {
		[command setScriptErrorNumber:-1715]; // errAEParamMissed
		[command setScriptErrorString:@"The message was missing."];
		return;
	}

	if( ! [message isKindOfClass:[NSString class]] ) {
		message = [[NSScriptCoercionHandler sharedCoercionHandler] coerceValue:message toClass:[NSString class]];
		if( ! [message isKindOfClass:[NSString class]] ) {
			[command setScriptErrorNumber:-1700]; // errAECoercionFail
			[command setScriptErrorString:@"The message was not a string value and coercion failed."];
			return;
		}
	}

	if( ! [(NSString *)message length] ) {
		[command setScriptErrorNumber:-1715]; // errAEParamMissed
		[command setScriptErrorString:@"The message can't be blank."];
		return;
	}

	if( action && ! [action isKindOfClass:[NSNumber class]] ) {
		action = [[NSScriptCoercionHandler sharedCoercionHandler] coerceValue:action toClass:[NSNumber class]];
		if( ! [action isKindOfClass:[NSNumber class]] ) {
			[command setScriptErrorNumber:-1700]; // errAECoercionFail
			[command setScriptErrorString:@"The action tense parameter was not a boolean value and coercion failed."];
			return;
		}
	}

	if( localEcho && ! [localEcho isKindOfClass:[NSNumber class]] ) {
		localEcho = [[NSScriptCoercionHandler sharedCoercionHandler] coerceValue:localEcho toClass:[NSNumber class]];
		if( ! [localEcho isKindOfClass:[NSNumber class]] ) {
			[command setScriptErrorNumber:-1700]; // errAECoercionFail
			[command setScriptErrorString:@"The local echo parameter was not a boolean value and coercion failed."];
			return;
		}
	}

	NSAttributedString *realMessage = [NSAttributedString attributedStringWithHTMLFragment:message];
	BOOL realAction = ( action ? [action boolValue] : NO );
	BOOL realLocalEcho = ( localEcho ? [localEcho boolValue] : YES );

	JVMutableChatMessage *cmessage = [[JVMutableChatMessage alloc] initWithText:realMessage sender:[[self connection] localUser]];
	[cmessage setAction:realAction];

	[self sendMessage:cmessage];
	if( realLocalEcho ) [self echoSentMessageToDisplay:cmessage];

	return;
}

#pragma mark -

- (OSType) scriptTypedEncoding {
	return [NSString scriptTypedEncodingFromStringEncoding:[self encoding]];
}

- (void) setScriptTypedEncoding:(OSType) encoding {
	[self setPreference:[NSNumber numberWithLong:encoding] forKey:@"encoding"];
	[self changeEncoding:self];
}
@end

#pragma mark -

@interface JVAddEventMessageScriptCommand : NSScriptCommand {}
@end

@implementation JVAddEventMessageScriptCommand
- (id) performDefaultImplementation {
	// check if the subject responds to the command directly, if so execute that implementation
	if( [self subjectSupportsCommand] ) return [self executeCommandOnSubject];

	// the subject didn't respond to the command, so do our default implementation
	NSDictionary *args = [self evaluatedArguments];
	id target = [self subjectParameter];
	id message = [self evaluatedDirectParameter];
	id name = [args objectForKey:@"name"];
	id attributes = [args objectForKey:@"attributes"];

	if( [message isKindOfClass:[JVDirectChatPanel class]] ) {
		// this is from an old compiled script, flip the parameters
		target = message;
		message = [args objectForKey:@"message"];
	}

	if( ! target || ( target && [target isKindOfClass:[NSArray class]] && ! [(NSArray *)target count] ) )
		return nil; // silently fail like normal tell blocks do when the target is nil or an empty list

	if( ! [target isKindOfClass:[JVDirectChatPanel class]] && ! [target isKindOfClass:[NSArray class]] ) {
		[self setScriptErrorNumber:-1703]; // errAEWrongDataType
		[self setScriptErrorString:@"The nearest enclosing tell block target does not inherit from the direct chat panel class."];
		return nil;
	}

	if( ! message ) {
		[self setScriptErrorNumber:-1715]; // errAEParamMissed
		[self setScriptErrorString:@"The event message was missing."];
		return nil;
	}

	if( ! [message isKindOfClass:[NSString class]] ) {
		message = [[NSScriptCoercionHandler sharedCoercionHandler] coerceValue:message toClass:[NSString class]];
		if( ! [message isKindOfClass:[NSString class]] ) {
			[self setScriptErrorNumber:-1700]; // errAECoercionFail
			[self setScriptErrorString:@"The event message was not a string value and coercion failed."];
			return nil;
		}
	}

	if( ! [(NSString *)message length] ) {
		[self setScriptErrorNumber:-1715]; // errAEParamMissed
		[self setScriptErrorString:@"The event message can't be blank."];
		return nil;
	}

	if( ! name ) name = NSLocalizedString( @"unknown", "unknown name for script event" );
	if( ! [name isKindOfClass:[NSString class]] ) {
		name = [[NSScriptCoercionHandler sharedCoercionHandler] coerceValue:name toClass:[NSString class]];
		if( ! [name isKindOfClass:[NSString class]] ) {
			[self setScriptErrorNumber:-1700]; // errAECoercionFail
			[self setScriptErrorString:@"The event name was not a string value and coercion failed."];
			return nil;
		}
	}

	if( ! [(NSString *)name length] ) {
		[self setScriptErrorNumber:-1715]; // errAEParamMissed
		[self setScriptErrorString:@"The event name can't be blank."];
		return nil;
	}

	if( attributes && ! [attributes isKindOfClass:[NSDictionary class]] ) {
		attributes = [[NSScriptCoercionHandler sharedCoercionHandler] coerceValue:attributes toClass:[NSDictionary class]];
		if( ! [attributes isKindOfClass:[NSDictionary class]] ) {
			[self setScriptErrorNumber:-1700]; // errAECoercionFail
			[self setScriptErrorString:@"The event attributes was not a record value and coercion failed."];
			return nil;
		}
	}

	NSArray *targets = nil;
	if( [target isKindOfClass:[NSArray class]] ) targets = target;
	else targets = [NSArray arrayWithObject:target];

	for( target in targets ) {
		if( ! [target isKindOfClass:[JVDirectChatPanel class]] ) continue;
		[target addEventMessageToDisplay:message withName:name andAttributes:attributes];
	}

	return nil;
}
@end
