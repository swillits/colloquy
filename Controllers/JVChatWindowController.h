#import "JVInspectorController.h"

@class MVMenuButton;
@class MVChatConnection;
@class JVChatWindowController;
@class JVChatRoomMember;
@protocol JVChatViewController;
@protocol JVChatListItem;


extern NSString *JVToolbarToggleChatDrawerItemIdentifier;
extern NSString *JVChatViewPboardType;





/**
 
 	Subclassing:
 		- showChatViewController
 		- updateInterfaceSwappingOutChatViewController
 
 
 */

@interface JVChatWindowController : NSWindowController <JVInspectionDelegator, NSMenuDelegate, NSOutlineViewDataSource, NSOutlineViewDelegate, NSToolbarDelegate, NSWindowDelegate> 


@property (readwrite, copy) NSString * identifier;


@property (readonly) NSString * userDefaultsPreferencesKey;
- (void) setPreference:(id) value forKey:(NSString *) key;
- (id) preferenceForKey:(NSString *) key;





//! Returns which controller is currently shown in the window
@property (readonly) id <JVChatViewController> activeChatViewController;


//! To be called only by subclasses when they actually change which controller is active. The high level method to display a particular chat is `showChatViewController:` 
- (void)changeActiveChatViewController:(id <JVChatViewController>)controller;

//! Makes the given view controller become active and displays it. Must be implemented by subclasses and should eventually trigger the call to changeActiveChatViewController: if the chat view is shown.
- (void)showChatViewController:(id <JVChatViewController>)controller;

//! Swapping in the active one
- (void)updateInterfaceSwappingOutChatViewController:(id<JVChatViewController>)old;




/*
 
 	Chat View Controller Management
 
 */


// ------------------------------------------------
// Access to the chat view controllers
// ------------------------------------------------

- (NSArray *)allChatViewControllers;
- (id <JVChatViewController>)chatViewControllerForIdentifier:(NSString *)identifier;
- (NSArray *)chatViewControllersForConnection:(MVChatConnection *)connection;
- (NSArray *)chatViewControllersWithControllerClass:(Class)class;




// ------------------------------------------------
// Add/Removing chat view controllers
// ------------------------------------------------
// These methods are the high level methods to add or remove a chat from the window. They should not be subclassed. Instead, use the notification/override methods such as willAddChatViewController etc.

- (void)addChatViewController:(id <JVChatViewController>) controller;
- (void)insertChatViewController:(id <JVChatViewController>) controller atIndex:(NSUInteger) index;
- (void)removeChatViewController:(id <JVChatViewController>) controller;
- (void)removeChatViewControllerAtIndex:(NSUInteger) index;
- (void)removeAllChatViewControllers;
- (void)replaceChatViewController:(id <JVChatViewController>) controller withController:(id <JVChatViewController>) newController;
- (void)replaceChatViewControllerAtIndex:(NSUInteger) index withController:(id <JVChatViewController>) controller;

//! Reorders the array, nothing more. Will fail if the controllers passed in are not the same controllers that already exist.
- (void)reorderChatViewControllers:(NSArray *)controllers;

//! Reorders the chat view controllers by first removing `controller`, and then inserting at the given index
- (void)moveChatViewController:(id <JVChatViewController>)controller toIndex:(NSUInteger)index;



// ------------------------------------------------
// Subclasses can override these
// ------------------------------------------------

- (void)willAddChatViewController:(id <JVChatViewController>)controller;
- (void)didAddChatViewController:(id <JVChatViewController>)controller;
- (void)willRemoveChatViewController:(id <JVChatViewController>)controller;
- (void)didRemoveChatViewController:(id <JVChatViewController>)controller;
- (void)chatViewControllerWillResignActive:(id <JVChatViewController>)controller;
- (void)chatViewControllerDidResignActive:(id <JVChatViewController>)controller;
- (void)chatViewControllerWillBecomeActive:(id <JVChatViewController>)controller;
- (void)chatViewControllerDidBecomeActive:(id <JVChatViewController>)controller;

//! Called after any one or more chat view controllers are added or removed from the window
- (void)chatViewControllersDidChange;











/*
 
 	Additional Subclassing Overrides
 
 */



//! Called when the window is key.
//! Subclasses can override to tweak menu bar menu items which depend on a chat window being active
- (void)claimMenuBarItems;

//! Called when the window will resign key.
//! Subclasses can override to tweak menu bar menu items which depend on a chat window being active
- (void)resignMenuBarItems;


//! Called when preferences changed, and the window should update whatever needs handling.
- (void)preferencesDidChange;






/*
 
 	Interface Actions
 
 */

- (IBAction)getInfo:(id)sender;
- (IBAction)joinRoom:(id)sender;
- (IBAction)closeCurrentPanel:(id)sender;
- (IBAction)detachCurrentPanel:(id)sender;
- (IBAction)selectPreviousPanel:(id)sender;
- (IBAction)selectPreviousActivePanel:(id)sender;
- (IBAction)selectNextPanel:(id)sender;
- (IBAction)selectNextActivePanel:(id)sender;





/*
 
 	Helpers
 
 */
- (void)showInspectorForObject:(id<JVInspection>)object;


@end








//! Posted whenever view controller info changes, which might be displayed and therefor needs redisplay.
extern NSString * const JVChatViewControllerInfoDidChangeNotificationName;

@protocol JVChatViewController <JVChatListItem>
@optional
- (id <JVChatViewController>) activeChatViewController;

@required
- (MVChatConnection *) connection;

- (JVChatWindowController *) windowController;
- (void) setWindowController:(JVChatWindowController *) controller;

- (NSView *) view;
- (NSResponder *) firstResponder;
- (NSString *) toolbarIdentifier;
- (NSString *) windowTitle;
- (NSString *) identifier;


@optional
- (void) willSelect;
- (void) didSelect;

- (void) willUnselect;
- (void) didUnselect;

- (void) willDispose;

//! Called at certain times when the view has been seen by the user (eg, the window becomes key while the view controller is visible) 
- (void)didGetNoticedByUser;
@end






// JVCatViewController, JVChatRoomMember
@protocol JVChatListItem <NSObject>
- (id <JVChatListItem>) parent;
- (NSImage *) icon;
- (NSString *) title;


@optional

- (BOOL) acceptsDraggedFileOfType:(NSString *) type;
- (void) handleDraggedFile:(NSString *) path;
- (IBAction) doubleClicked:(id) sender;
- (BOOL) isEnabled;

- (NSMenu *) menu;
- (NSString *) information;
- (NSString *) toolTip;
- (NSImage *) statusImage;

- (NSUInteger) numberOfChildren;
- (id) childAtIndex:(NSUInteger) index;
@end







@interface NSObject (MVChatPluginToolbarSupport)
- (NSArray *) toolbarItemIdentifiersForView:(id <JVChatViewController>) view;
- (NSToolbarItem *) toolbarItemForIdentifier:(NSString *) identifier inView:(id <JVChatViewController>) view willBeInsertedIntoToolbar:(BOOL) willBeInserted;
@end
