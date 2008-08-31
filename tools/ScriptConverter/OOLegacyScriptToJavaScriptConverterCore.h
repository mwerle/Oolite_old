//
//  OOLegacyScriptToJavaScriptConverterCore.h
//  ScriptConverter
//
//  Created by Jens Ayton on 2008-08-30.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import "OOCocoa.h"
#import "OOLegacyScriptToJavaScriptConverter.h"


@interface OOLegacyScriptToJavaScriptConverter (Private)

- (void) setMetadata:(NSDictionary *)metadata;
- (void) setProblemReporter:(id <OOProblemReportManager>)problemReporter;

- (NSString *) convertScript:(NSArray *)actions;


- (void) writeHeader;

- (void) append:(NSString *)string;
- (void) appendWithFormat:(NSString *)format, ...;
- (void) appendWithFormat:(NSString *)format arguments:(va_list)args;

- (void) indent;
- (void) outdent;

- (NSString *) legalizedVariableName:(NSString *)rawName;
- (NSString *) expandString:(NSString *)string;
- (NSString *) expandStringOrNumber:(NSString *)string;
- (NSString *) expandIntegerExpression:(NSString *)string;
- (NSString *) expandFloatExpression:(NSString *)string;
- (NSString *) expandPropertyReference:(NSString *)string;	// either .identifier or ["string expression"]

- (void) setInitializer:(NSString *)initializerStatement forKey:(NSString *)key;
- (void) setHelperFunction:(NSString *)function forKey:(NSString *)key;

@end


@interface OOLegacyScriptToJavaScriptConverter (ConverterCore)

- (void) convertActions:(NSArray *)actions;

@end
