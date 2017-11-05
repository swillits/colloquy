//
//  CQSendHistory.m
//  Colloquy (Application)
//
//  Created by Seth Willits on 11/4/17.
//  Copyright © 2017 Colloquy Project. All rights reserved.
//

#import "CQSendHistory.h"



// 0 index is the current string which has not yet been sent
// count - 1 is the oldest string sent

@implementation CQSendHistory
{
	NSMutableArray *_sendHistory;
	NSUInteger _historyIndex;
}


- (instancetype)init
{
	if (!(self = [super init])) {
		return nil;
	}
	
	_sendHistory = [NSMutableArray array];
	[_sendHistory insertObject:[[NSAttributedString alloc] initWithString:@""] atIndex:0];
	_historyIndex = 0;
	
	return self;
}



- (BOOL)isAtHead
{
	return _historyIndex == 0;
}


- (NSAttributedString *)currentString
{
	return _sendHistory[_historyIndex];
}


- (void)goToHead
{
	_historyIndex = 0;
}


- (void)goBack
{
	if (_historyIndex + 1 < _sendHistory.count) {
		_historyIndex += 1;
	}
}


- (void)goForward
{
	if (_historyIndex > 0) {
		_historyIndex -= 1;
	}
}


- (void)updateHead:(NSAttributedString *)string
{
	_sendHistory[0] = string;
}



- (void)addToHistory:(NSAttributedString *)string
{
	_historyIndex = 0;
	
	if ([_sendHistory count]) {
		[_sendHistory replaceObjectAtIndex:0 withObject:[[NSAttributedString alloc] initWithString:@""]];
	}
	
	[_sendHistory insertObject:string atIndex:1];
	
	if ([_sendHistory count] > [[[NSUserDefaults standardUserDefaults] objectForKey:@"JVChatMaximumHistory"] unsignedIntValue]) {
		[_sendHistory removeObjectAtIndex:[_sendHistory count] - 1];
	}
}


@end
