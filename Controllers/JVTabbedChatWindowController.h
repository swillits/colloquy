#import "JVClassicChatWindowController.h"

@class AICustomTabsView;


/*
 
 
 		Should just be deleted and completely rewritten.
 		No drawer, modern tabs...
 
 
 */

@interface JVTabbedChatWindowController : JVClassicChatWindowController {
	IBOutlet AICustomTabsView *customTabsView;
	IBOutlet NSTabView *tabView;
	NSMutableArray *_tabItems;
    BOOL _supressHiding;
    BOOL _tabIsShowing;
    BOOL _autoHideTabBar;
	NSInteger _forceTabBarVisible; // -1 = Doesn't matter, 0 = NO, 1 = YES;
    CGFloat _tabHeight;
}
- (IBAction) toggleTabBarVisible:(id) sender;
- (void) updateTabBarVisibilityAndAnimate:(BOOL) animate;
@end
