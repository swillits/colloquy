#import "CQChatUserListViewController.h"

#import "CQChatController.h"
#import "CQColloquyApplication.h"
#import "CQChatRoomController.h"
#import "CQUserInfoController.h"
#import "CQUserInfoViewController.h"

#import <ChatCore/MVChatRoom.h>
#import <ChatCore/MVChatUser.h>
#import <ChatCore/MVChatConnection.h>

#import "UIActionSheetAdditions.h"

static NSString *membersSingleCountFormat;
static NSString *membersFilteredCountFormat;

#define UserIdleTime 600

@implementation CQChatUserListViewController
@synthesize chatUserDelegate = _chatUserDelegate;
@synthesize listMode = _listMode;

+ (void) initialize {
	membersSingleCountFormat = [NSLocalizedString(@"Members (%u)", @"Members with single count view title") retain];
	membersFilteredCountFormat = [NSLocalizedString(@"Members (%u of %u)", @"Members with filtered count view title") retain];
}

- (id) init {
	if (!(self = [super initWithStyle:UITableViewStylePlain]))
		return nil;

	_users = [[NSMutableArray alloc] init];
	_matchedUsers = [[NSMutableArray alloc] init];

	return self;
}

- (void) dealloc {
	_chatUserDelegate = nil;
	_searchBar.delegate = nil;
	_searchController.delegate = nil;

	[_users release];
	[_matchedUsers release];
	[_currentSearchString release];
	[_room release];
	[_searchBar release];
	[_searchController release];

	[super dealloc];
}

#pragma mark -

- (void) viewDidLoad {
	[super viewDidLoad];

	if (_listMode == CQChatUserListModeBan)
		return;
	_searchBar = [[UISearchBar alloc] initWithFrame:CGRectZero];
	_searchBar.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin);
	_searchBar.placeholder = NSLocalizedString(@"Search", @"Search placeholder text");
	_searchBar.accessibilityLabel = NSLocalizedString(@"Search Members", @"Voiceover search members label");
	_searchBar.tintColor = [UIColor colorWithRed:(190. / 255.) green:(199. / 255.) blue:(205. / 255.) alpha:1.]; 
	_searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
	_searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
	[_searchBar sizeToFit];

	self.tableView.tableHeaderView = _searchBar;

	_searchController = [[UISearchDisplayController alloc] initWithSearchBar:_searchBar contentsController:self];
	_searchController.searchResultsDataSource = self;
	_searchController.searchResultsDelegate = self;
	_searchController.delegate = self;

	UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Members", @"Members back button label") style:UIBarButtonItemStylePlain target:nil action:nil];
	self.navigationItem.backBarButtonItem = backButton;
	[backButton release];

	UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissFromDoneButton)];
	self.navigationItem.rightBarButtonItem = doneButton;
	[doneButton release];

	if ([[UIDevice currentDevice] isPadModel])
		[self resizeForViewInPopoverUsingTableView:self.tableView];
}

- (void) viewWillAppear:(BOOL) animated {
	NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];

	[super viewWillAppear:animated];

	[self.tableView reloadData];

	if (selectedIndexPath)
		[self.tableView selectRowAtIndexPath:selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
}

#pragma mark -

@synthesize users = _users;

- (void) setUsers:(NSArray *) users {
	[_users setArray:users];
	[_matchedUsers setArray:users];

	self.title = [NSString stringWithFormat:membersSingleCountFormat, users.count];

	[self.tableView reloadData];
}

@synthesize room = _room;

- (void) setRoom:(MVChatRoom *) room {
	id old = _room;
	_room = [room retain];
	[old release];

	[self.tableView reloadData];
}

#pragma mark -

- (NSUInteger) _indexForInsertedMatchUser:(MVChatUser *) user withOriginalIndex:(NSUInteger) index {
	NSInteger matchesIndex = NSNotFound;
	for (NSInteger i = (index - 1); i >= 0; --i) {
		MVChatUser *currentUser = [_users objectAtIndex:i];
		matchesIndex = [_matchedUsers indexOfObjectIdenticalTo:currentUser];
		if (matchesIndex != NSNotFound)
			break;
	}

	if (matchesIndex == NSNotFound)
		matchesIndex = -1;

	return ++matchesIndex;
}

- (NSUInteger) _indexForRemovedMatchUser:(MVChatUser *) user {
	return [_matchedUsers indexOfObjectIdenticalTo:user];
}

- (void) _insertUser:(MVChatUser *) user atIndex:(NSUInteger) index withAnimation:(UITableViewRowAnimation) animation {
	NSParameterAssert(user != nil);
	NSParameterAssert(index <= _users.count);

	[_users insertObject:user atIndex:index];

	if (!_currentSearchString.length || [user.nickname hasCaseInsensitiveSubstring:_currentSearchString]) {
		NSInteger matchesIndex = [self _indexForInsertedMatchUser:user withOriginalIndex:index];

		[_matchedUsers insertObject:user atIndex:matchesIndex];

		NSArray *indexPaths = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:matchesIndex inSection:0]];
		[self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:animation];
	}

	if (_users.count == _matchedUsers.count)
		self.title = [NSString stringWithFormat:membersSingleCountFormat, _users.count];
	else self.title = [NSString stringWithFormat:membersFilteredCountFormat, _matchedUsers.count, _users.count];
}

- (void) _removeUserAtIndex:(NSUInteger) index withAnimation:(UITableViewRowAnimation) animation {
	NSParameterAssert(index <= _users.count);

	MVChatUser *user = [[_users objectAtIndex:index] retain];

	[_users removeObjectAtIndex:index];

	NSUInteger matchesIndex = [self _indexForRemovedMatchUser:user];
	if (matchesIndex != NSNotFound) {
		[_matchedUsers removeObjectAtIndex:matchesIndex];

		NSArray *indexPaths = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:matchesIndex inSection:0]];
		[self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:animation];
	}

	if (_users.count == _matchedUsers.count)
		self.title = [NSString stringWithFormat:membersSingleCountFormat, _users.count];
	else self.title = [NSString stringWithFormat:membersFilteredCountFormat, _matchedUsers.count, _users.count];

	[user release];
}

#pragma mark -

- (void) insertUser:(MVChatUser *) user atIndex:(NSUInteger) index {
	BOOL searchBarFocused = [_searchController isActive];
	[self _insertUser:user atIndex:index withAnimation:UITableViewRowAnimationLeft];

	if (searchBarFocused)
		[_searchController setActive:YES animated:YES];

	if ([[UIDevice currentDevice] isPadModel]) 
		[self resizeForViewInPopoverUsingTableView:self.tableView];
}

- (void) moveUserAtIndex:(NSUInteger) oldIndex toIndex:(NSUInteger) newIndex {
	if (oldIndex == newIndex)
		return;

	MVChatUser *user = [[_users objectAtIndex:oldIndex] retain];

	BOOL searchBarFocused = [_searchController isActive];

	NSInteger oldMatchesIndex = [self _indexForRemovedMatchUser:user];
	NSInteger newMatchesIndex = [self _indexForInsertedMatchUser:user withOriginalIndex:newIndex];

	if (newMatchesIndex > oldMatchesIndex)
		--newMatchesIndex;

	[self.tableView beginUpdates];

	if (oldMatchesIndex == newMatchesIndex) {
		[self _removeUserAtIndex:oldIndex withAnimation:UITableViewRowAnimationFade];
		[self _insertUser:user atIndex:newIndex withAnimation:UITableViewRowAnimationFade];
	} else {
		[self _removeUserAtIndex:oldIndex withAnimation:(newIndex > oldIndex ? UITableViewRowAnimationBottom : UITableViewRowAnimationTop)];
		[self _insertUser:user atIndex:newIndex withAnimation:(newIndex > oldIndex ? UITableViewRowAnimationTop : UITableViewRowAnimationBottom)];
	}

	[self.tableView endUpdates];

	if (searchBarFocused)
		[_searchController setActive:YES animated:YES];

	[user release];
}

- (void) removeUserAtIndex:(NSUInteger) index {
	BOOL searchBarFocused = [_searchController isActive];
	[self _removeUserAtIndex:index withAnimation:UITableViewRowAnimationRight];

	if (searchBarFocused)
		[_searchController setActive:YES animated:YES];

	if ([[UIDevice currentDevice] isPadModel])
		[self resizeForViewInPopoverUsingTableView:self.tableView];

}

- (void) updateUserAtIndex:(NSUInteger) index {
	NSParameterAssert(index <= _users.count);

	MVChatUser *user = [_users objectAtIndex:index];
	NSUInteger matchesIndex = [_matchedUsers indexOfObjectIdenticalTo:user];
	if (matchesIndex == NSNotFound)
		return;

	BOOL searchBarFocused = [_searchController isActive];

	[self.tableView updateCellAtIndexPath:[NSIndexPath indexPathForRow:matchesIndex inSection:0] withAnimation:UITableViewRowAnimationFade];

	if (searchBarFocused)
		[_searchController setActive:YES animated:YES];
}

#pragma mark -

- (BOOL) searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *) searchString {
	if ([searchString isEqualToString:_currentSearchString])
		return NO;
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(filterUsers) object:nil];
	
	NSTimeInterval delay = (searchString.length ? (1. / (double)searchString.length) : (1. / 3.));
	[self performSelector:@selector(filterUsers) withObject:nil afterDelay:delay];
	
	return NO;
}

- (void) searchDisplayControllerWillEndSearch:(UISearchDisplayController *) controller {
	// The searching has probably ruined the _matchedUsers array, so rebuild it here when we display the main results table view/
	[_matchedUsers setArray:_users];
	[self.tableView reloadData];

	self.title = [NSString stringWithFormat:membersSingleCountFormat, _users.count];
}

#pragma mark -

- (void) filterUsers {
	[self filterUsersWithSearchString:_searchBar.text];
}

- (void) filterUsersWithSearchString:(NSString *) searchString {
	NSArray *previousUsersArray = [_matchedUsers retain];

	if (searchString.length) {
		id old = _matchedUsers;
		_matchedUsers = [[NSMutableArray alloc] init];
		[old release];

		NSArray *searchArray = (_currentSearchString && [searchString hasPrefix:_currentSearchString] ? previousUsersArray : _users);
		for (MVChatUser *user in searchArray) {
			if (![user.nickname hasCaseInsensitiveSubstring:searchString])
				continue;
			[_matchedUsers addObject:user];
		}
	} else {
		id old = _matchedUsers;
		_matchedUsers = [_users mutableCopy];
		[old release];
	}

	if (ABS((NSInteger)(previousUsersArray.count - _matchedUsers.count)) < 40) {
		NSSet *matchedUsersSet = [[NSSet alloc] initWithArray:_matchedUsers];
		NSSet *previousUsersSet = [[NSSet alloc] initWithArray:previousUsersArray];

		[_searchController.searchResultsTableView beginUpdates];

		NSUInteger index = 0;
		NSMutableArray *indexPaths = [[NSMutableArray alloc] init];

		for (MVChatUser *user in previousUsersArray) {
			if (![matchedUsersSet containsObject:user])
				[indexPaths addObject:[NSIndexPath indexPathForRow:index inSection:0]];
			++index;
		}

		[_searchController.searchResultsTableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];

		index = 0;

		[indexPaths release];
		indexPaths = [[NSMutableArray alloc] init];

		for (MVChatUser *user in _matchedUsers) {
			if (![previousUsersSet containsObject:user])
				[indexPaths addObject:[NSIndexPath indexPathForRow:index inSection:0]];
			++index;
		}

		[_searchController.searchResultsTableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];

		[_searchController.searchResultsTableView endUpdates];

		[indexPaths release];
		[previousUsersSet release];
		[matchedUsersSet release];
	} else {
		[_searchController.searchResultsTableView reloadData];
	}

	id old = _currentSearchString;
	_currentSearchString = [searchString copy];
	[old release];

	if (_users.count == _matchedUsers.count)
		self.title = [NSString stringWithFormat:membersSingleCountFormat, _users.count];
	else self.title = [NSString stringWithFormat:membersFilteredCountFormat, _matchedUsers.count, _users.count];

	[_searchBar becomeFirstResponder];

	[previousUsersArray release];
}

#pragma mark -

- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation) toInterfaceOrientation duration:(NSTimeInterval) duration {
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];

	if ([[UIDevice currentDevice] isPadModel])
		[self resizeForViewInPopoverUsingTableView:self.tableView];
}

#pragma mark -

- (NSInteger) tableView:(UITableView *) tableView numberOfRowsInSection:(NSInteger) section {
	return _matchedUsers.count;
}

- (UITableViewCell *) tableView:(UITableView *) tableView cellForRowAtIndexPath:(NSIndexPath *) indexPath {
	MVChatUser *user = [_matchedUsers objectAtIndex:indexPath.row];

	UITableViewCell *cell = [UITableViewCell reusableTableViewCellInTableView:tableView];
	cell.textLabel.text = user.nickname;

	if (_room) {
		unsigned long modes = [_room modesForMemberUser:user];

		if (user.serverOperator)
			cell.imageView.image = [UIImage imageNamed:@"userSuperOperator.png"];
		else if (modes & MVChatRoomMemberFounderMode)
			cell.imageView.image = [UIImage imageNamed:@"userFounder.png"];
		else if (modes & MVChatRoomMemberAdministratorMode)
			cell.imageView.image = [UIImage imageNamed:@"userAdmin.png"];
		else if (modes & MVChatRoomMemberOperatorMode)
			cell.imageView.image = [UIImage imageNamed:@"userOperator.png"];
		else if (modes & MVChatRoomMemberHalfOperatorMode)
			cell.imageView.image = [UIImage imageNamed:@"userHalfOperator.png"];
		else if (modes & MVChatRoomMemberVoicedMode)
			cell.imageView.image = [UIImage imageNamed:@"userVoice.png"];
		else cell.imageView.image = [UIImage imageNamed:@"userNormal.png"];
	} else {
		cell.imageView.image = [UIImage imageNamed:@"userNormal.png"];
	}

	if (_listMode == CQChatUserListModeRoom && ![[UIDevice currentDevice] isPadModel])
		cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;

	if (user.status == MVChatUserAwayStatus || user.idleTime >= UserIdleTime) {
		cell.imageView.alpha = .5;
		cell.textLabel.alpha = .5;
	} else {
		cell.imageView.alpha = 1.;
		cell.textLabel.alpha = 1.;
	}

	return cell;
}

- (NSIndexPath *) tableView:(UITableView *) tableView willSelectRowAtIndexPath:(NSIndexPath *) indexPath {
	[self endEditing];

	return indexPath;
}

- (void) tableView:(UITableView *) tableView didSelectRowAtIndexPath:(NSIndexPath *) indexPath {
	MVChatUser *user = [_matchedUsers objectAtIndex:indexPath.row];

	BOOL shouldPresentInformation = YES;
	if (_chatUserDelegate && [_chatUserDelegate respondsToSelector:@selector(chatUserListViewController:shouldPresentInformationForUser:)])
		shouldPresentInformation = [_chatUserDelegate chatUserListViewController:self shouldPresentInformationForUser:user];

	if (shouldPresentInformation) {
		UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];

		UIActionSheet *sheet = [UIActionSheet userActionSheetForUser:user inRoom:_room showingUserInformation:NO];
		sheet.title = cell.textLabel.text;

		[sheet associateObject:cell forKey:@"userInfo"];

		[[CQColloquyApplication sharedApplication] showActionSheet:sheet forSender:cell animated:YES];

		[tableView deselectRowAtIndexPath:indexPath animated:NO];
	}

	if (_chatUserDelegate && [_chatUserDelegate respondsToSelector:@selector(chatUserListViewController:didSelectUser:)])
		[_chatUserDelegate chatUserListViewController:self didSelectUser:user];
}

- (void) tableView:(UITableView *) tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *) indexPath {
	CQUserInfoViewController *userInfoViewController = [[CQUserInfoViewController alloc] init];
	userInfoViewController.user = [_matchedUsers objectAtIndex:indexPath.row];

	[self.navigationController pushViewController:userInfoViewController animated:YES];

	[userInfoViewController release];
}

- (BOOL) tableView:(UITableView *) tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *) indexPath {
	return YES;
}

- (BOOL) tableView:(UITableView *) tableView canPerformAction:(SEL) action forRowAtIndexPath:(NSIndexPath *) indexPath withSender:(id) sender {
	return (action == @selector(copy:));
}

- (void) tableView:(UITableView *) tableView performAction:(SEL) action forRowAtIndexPath:(NSIndexPath *) indexPath withSender:(id) sender {
	MVChatUser *user = [_matchedUsers objectAtIndex:indexPath.row];
	if (!user)
		return;

	if (action == @selector(copy:))
		[UIPasteboard generalPasteboard].string = user.nickname;
}

#pragma mark -

- (void) dismissFromDoneButton {
	[self dismissViewControllerAnimated:YES completion:NULL];
}
@end
