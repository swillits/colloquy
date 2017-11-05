#import "JVClassicChatWindowController.h"

@class JVSideSplitView;

@interface JVSidebarChatWindowController : JVClassicChatWindowController {
	IBOutlet JVSideSplitView *splitView;
	IBOutlet NSView *bodyView;
	BOOL _forceSplitViewPosition;
}
@end
