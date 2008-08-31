//
//  OOProblemReportManager.h
//  ScriptConverter
//
//  Created by Jens Ayton on 2007-11-24.
//  Copyright 2007 Jens Ayton. All rights reserved.
//

#import <Cocoa/Cocoa.h>


typedef enum
{
	kOOProblemSeverityNone,
	kOOProblemSeverityNote,
	kOOProblemSeverityWarning,
	kOOProblemSeverityStop,
	kOOProblemSeverityBug
} OOProblemSeverity;


@protocol OOProblemReportManager <NSObject>

- (void) addNoteIssueWithKey:(NSString *)key format:(NSString *)format, ...;
- (void) addWarningIssueWithKey:(NSString *)key format:(NSString *)format, ...;
- (void) addStopIssueWithKey:(NSString *)key format:(NSString *)format, ...;
- (void) addBugIssueWithKey:(NSString *)key format:(NSString *)format, ...;

- (OOProblemSeverity) highestSeverity;

@end
