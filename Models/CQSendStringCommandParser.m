//
//  CQSendStringCommandParser.m
//  Colloquy (Application)
//
//  Created by Seth Willits on 11/4/17.
//  Copyright © 2017 Colloquy Project. All rights reserved.
//

#import "CQSendStringCommandParser.h"
#import "JVChatWindowController.h"



@implementation CQSendStringCommandParser

+ (NSArray<CQSendCommandAndArgs*> *)parseString:(NSAttributedString *)stringToSend asAction:(BOOL)asAction
{
	NSMutableArray * results = [NSMutableArray array];
	NSRange chunkingRange = NSMakeRange(0, stringToSend.length);
	BOOL treatAsAction = asAction;
	
	while (chunkingRange.length > 0) {
		NSRange eolRange = [stringToSend.string rangeOfString:@"\n" options:0 range:chunkingRange];
		NSRange chunkRange = chunkingRange;
		
		if (eolRange.location != NSNotFound) {
			chunkRange.length = eolRange.location - chunkingRange.location;
			chunkingRange.location = NSMaxRange(eolRange);
			chunkingRange.length = stringToSend.length - chunkingRange.location;
		} else {
			chunkingRange.location = NSMaxRange(chunkingRange);
			chunkingRange.length = 0;
		}
		
		
		NSAttributedString * chunk = [stringToSend attributedSubstringFromRange:chunkRange]; 
		
		// Command?
		if ([chunk.string hasPrefix:@"/"] && ![chunk.string hasPrefix:@"//"]) {
			NSRange commandRange = [chunk.string rangeOfCharacterFromSet:NSCharacterSet.whitespaceAndNewlineCharacterSet options:0 range:NSMakeRange(1, chunk.string.length - 1)];
			if (commandRange.location == NSNotFound) {
				commandRange = NSMakeRange(0, chunk.length);
			}
		
			NSString * command = [chunk.string substringWithRange:NSMakeRange(1, commandRange.length - 1)];
			if (command.length > 0) {
				NSAttributedString * args = nil;
				if (chunk.length >= NSMaxRange(commandRange)) {
					args = [chunk attributedSubstringFromIndex:NSMaxRange(commandRange)];
				}
				
				[results addObject:[CQSendCommandAndArgs command:command andArguments:args]];
			}
			
		// Plain message
		} else {
			
			if ([chunk.string hasPrefix:@"//"]) {
				if (![[NSUserDefaults standardUserDefaults] boolForKey:@"JVSendDoubleSlashes"]) {
					chunk = [chunk attributedSubstringFromIndex:1];
				}
			}
			
			// Is the first word a natural language "verb" that we should then treat as a /me action?
			if (!treatAsAction && [CQSendStringCommandParser treatAsAction:chunk.string]) {
				// Treat all subsequent lines as actions as well
				treatAsAction = YES;
			}
			
			if (chunk.length > 0) {
				[results addObject:[CQSendCommandAndArgs message:chunk isAction:treatAsAction]];
			}
		}
	}
	
	return [results copy];
}


+ (BOOL)treatAsAction:(NSString *)string
{
	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"MVChatNaturalActions"]) {
		return NO;
	}
	
	
	static dispatch_once_t onceToken;
	static NSSet * actionVerbs = nil;
	dispatch_once(&onceToken, ^{
		NSArray *verbs = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"verbs" ofType:@"plist"]];
		actionVerbs = [[NSSet alloc] initWithArray:verbs];
	});
	
	
	NSString * word = nil;
	NSRange range = [string rangeOfCharacterFromSet:NSCharacterSet.whitespaceCharacterSet];
	if (range.location == NSNotFound) {
		word = string;
	} else {
		word = [string substringWithRange:NSMakeRange(0, range.location)];
	}
	
	return [actionVerbs containsObject:word.lowercaseString];
}


@end




@implementation CQSendCommandAndArgs

+ (instancetype)message:(NSAttributedString *)message isAction:(BOOL)isAction
{
	CQSendCommandAndArgs * sc = [[CQSendCommandAndArgs alloc] init];
	sc.message = message;
	sc.isAction = isAction;
	return sc;
}



+ (instancetype)command:(NSString *)command andArguments:(NSAttributedString *)arguments
{
	CQSendCommandAndArgs * sc = [[CQSendCommandAndArgs alloc] init];
	sc.message = nil;
	sc.command = command;
	sc.arguments = arguments;
	return sc;
}

@end


@implementation CQSendCommandAndArgs (NotTheRightPlace)

+ (BOOL)processUserCommand:(CQSendCommandAndArgs *)command toConnection:(MVChatConnection *)connection inView:(id <JVChatViewController>)view
{
	NSAssert(command.command != nil, @"command must have command string");
	
	NSMethodSignature *signature = [NSMethodSignature methodSignatureWithReturnAndArgumentTypes:@encode( BOOL ), @encode( NSString * ), @encode( NSAttributedString * ), @encode( MVChatConnection * ), @encode( id ), nil];
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
	
	NSString * commandString = command.command;
	NSAttributedString * argumentsString = command.arguments;
	
	[invocation setSelector:@selector( processUserCommand:withArguments:toConnection:inView: )];
	MVAddUnsafeUnretainedAddress(commandString, 2)
	MVAddUnsafeUnretainedAddress(argumentsString, 3)
	MVAddUnsafeUnretainedAddress(connection, 4)
	MVAddUnsafeUnretainedAddress(view, 5)
	
	NSArray * results = [MVChatPluginManager.defaultManager makePluginsPerformInvocation:invocation stoppingOnFirstSuccessfulReturn:YES];
	
	BOOL success = [results.lastObject boolValue];
	return success;
}

@end




