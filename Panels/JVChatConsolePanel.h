#import "JVChatWindowController.h"
#import "JVChatWindowScripting.h"
#import "JVChatProtocols.h"

@class MVTextView;
@class MVChatConnection;

@interface JVChatConsolePanel : NSObject <JVChatViewController, JVChatViewControllerScripting, NSLayoutManagerDelegate> 
- (id) initWithConnection:(MVChatConnection *) connection;

- (void) pause;
- (void) resume;
- (BOOL) isPaused;

- (void) addMessageToDisplay:(NSString *) message asOutboundMessage:(BOOL) outbound;
- (IBAction) send:(id) sender;
@end
