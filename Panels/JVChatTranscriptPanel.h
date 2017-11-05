#import "JVChatWindowController.h"
#import "JVChatWindowScripting.h"
#import <WebKit/WebKit.h>

@class JVStyleView;
@class MVMenuButton;
@class JVStyle;
@class JVEmoticonSet;
@class JVChatMessage;
@class JVChatTranscript;
@class CQEmoticonMenu;

extern NSString *JVToolbarChooseStyleItemIdentifier;
extern NSString *JVToolbarEmoticonsItemIdentifier;
extern NSString *JVToolbarFindItemIdentifier;
extern NSString *JVToolbarQuickSearchItemIdentifier;

@interface JVChatTranscriptPanel : NSObject <JVChatViewController, JVChatViewControllerScripting, NSToolbarDelegate, WebUIDelegate> {
	@protected
	IBOutlet NSView *contents;
	IBOutlet JVStyleView *display;
	BOOL _nibLoaded;
	BOOL _disposed;

	JVChatWindowController *_windowController;

	JVChatTranscript *_transcript;

	NSMenu *_styleMenu;
	CQEmoticonMenu *_emoticonsMenu;

	NSString *_searchQuery;
	NSRegularExpression *_searchQueryRegex;
}
- (id) initWithTranscript:(NSString *) filename;

- (IBAction) changeStyle:(id) sender;
- (void) setStyle:(JVStyle *) style withVariant:(NSString *) variant;
- (JVStyle *) style;

- (IBAction) changeStyleVariant:(id) sender;
- (void) setStyleVariant:(NSString *) variant;
- (NSString *) styleVariant;

- (IBAction) changeEmoticons:(id) sender;
- (void) setEmoticons:(JVEmoticonSet *) emoticons;
- (JVEmoticonSet *) emoticons;

- (JVChatTranscript *) transcript;
- (void) jumpToMessage:(JVChatMessage *) message;

- (IBAction) close:(id) sender;
- (IBAction) activate:(id) sender;

- (IBAction) performQuickSearch:(id) sender;
- (void) quickSearchMatchMessage:(JVChatMessage *) message;

- (void) setSearchQuery:(NSString *) query;
- (NSString *) searchQuery;

- (JVStyleView *) display;
@end

#pragma mark -

@interface NSObject (MVChatPluginLinkClickSupport)
- (BOOL) handleClickedLink:(NSURL *) url inView:(id <JVChatViewController>) view;
@end

#pragma mark -

@interface JVChatTranscriptPanel (Private)
// Style Support.
- (void) _refreshWindowFileProxy;
- (void) _refreshSearch;
- (void) _didSwitchStyles:(NSNotification *) notification;

- (void) _reloadCurrentStyle:(id) sender;
- (NSMenu *) _stylesMenu;
- (void) _changeStyleMenuSelection;
- (void) _updateStylesMenu;
- (BOOL) _usingSpecificStyle;

// Emoticons Support.
- (NSMenu *) _emoticonsMenu;
- (BOOL) _usingSpecificEmoticons;

- (void) _openAppearancePreferences:(id) sender;

@end
