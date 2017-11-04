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

+ (NSArray<CQSendCommandAndArgs*> *)parseString:(NSAttributedString *)stringToSend
{
	NSMutableArray * results = [NSMutableArray array];
	NSRange chunkingRange = NSMakeRange(0, stringToSend.length);
	
	
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
		if ([chunk.string hasPrefix:@"/"]) {
			NSRange commandRange = [chunk.string rangeOfCharacterFromSet:NSCharacterSet.whitespaceAndNewlineCharacterSet options:0 range:NSMakeRange(1, chunk.string.length - 1)];
		
			NSString * command = [chunk.string substringWithRange:commandRange];
			if (command.length > 0) {
				NSAttributedString * args = nil;
				if (chunk.length >= NSMaxRange(commandRange) + 1) {
					args = [chunk attributedSubstringFromIndex:NSMaxRange(commandRange) + 1];
				}
				
				[results addObject:[CQSendCommandAndArgs command:command andArguments:args]];
			}
			
		// Plain message
		} else {
			
			// NOTE! We're throwing away the entire attributed string here. I'm not sure why,
			// but the original code did the same thing.
			[results addObject:[CQSendCommandAndArgs message:chunk.string]];
		}
	}
	
	return [results copy];
}


@end




@implementation CQSendCommandAndArgs

+ (instancetype)message:(NSString *)message
{
	CQSendCommandAndArgs * sc = [[CQSendCommandAndArgs alloc] init];
	sc.message = message;
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




