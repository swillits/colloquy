#import "JVDirectChatPanel.h"

@class JVChatRoomMember;
@class MVChatUser;

extern NSString * const MVFavoritesListDidUpdateNotification;
extern NSString * const JVChatRoomPanelMembersDidChangeNotification; 

COLLOQUY_EXPORT
@interface JVChatRoomPanel : JVDirectChatPanel {
	@protected
	NSMutableArray<JVChatRoomMember *> *_sortedMembers;
	NSMutableSet *_nextMessageAlertMembers;
	BOOL _kickedFromRoom;
	BOOL _banListSynced;
	NSUInteger _joinCount;
	NSRegularExpression *_membersRegex;
	NSImage * _customIcon;
	NSImage * _uniqueIcon;
}
- (void) joined;
- (void) parting;

- (void) joinChat:(id) sender;
- (void) partChat:(id) sender;

- (IBAction) toggleFavorites:(id) sender;

- (NSSet *) chatRoomMembersWithName:(NSString *) name;
- (JVChatRoomMember *) firstChatRoomMemberWithName:(NSString *) name;
- (JVChatRoomMember *) chatRoomMemberForUser:(MVChatUser *) user;
- (JVChatRoomMember *) localChatRoomMember;
- (void) resortMembers;

- (void) handleRoomMessageNotification:(NSNotification *) notification;


//! Returns the customIcon (if set), a unique one (if prefs set so), or the generic room icon
@property (readonly) NSImage * icon;

//! Returns a unique generated icon using a stable-across-launches color 
@property (readonly) NSImage * uniqueIcon;

//! A settable icon for the room
@property (readwrite, copy) NSImage * customIcon;

@end

@interface NSObject (MVChatPluginRoomSupport)
- (void) memberJoined:(JVChatRoomMember *) member inRoom:(JVChatRoomPanel *) room;
- (void) memberParted:(JVChatRoomMember *) member fromRoom:(JVChatRoomPanel *) room forReason:(NSAttributedString *) reason;
- (void) memberKicked:(JVChatRoomMember *) member fromRoom:(JVChatRoomPanel *) room by:(JVChatRoomMember *) by forReason:(NSAttributedString *) reason;

- (void) joinedRoom:(JVChatRoomPanel *) room;
- (void) partingFromRoom:(JVChatRoomPanel *) room;
- (void) kickedFromRoom:(JVChatRoomPanel *) room by:(JVChatRoomMember *) by forReason:(NSAttributedString *) reason;

- (void) userBricked:(MVChatUser *) user inRoom:(JVChatRoomPanel *) room;

- (void) topicChangedTo:(NSAttributedString *) topic inRoom:(JVChatRoomPanel *) room by:(JVChatRoomMember *) member;
@end
