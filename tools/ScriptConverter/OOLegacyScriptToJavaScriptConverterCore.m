//
//  OOLegacyScriptToJavaScriptConverterCore.m
//  ScriptConverter
//
//  Created by Jens Ayton on 2008-08-30.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import "OOLegacyScriptToJavaScriptConverterCore.h"
#import "NSScannerOOExtensions.h"
#import "OOCollectionExtractors.h"


#define COMMENT_SELECTOR		0


typedef enum
{
	kComparisonEqual,
	kComparisonNotEqual,
	kComparisonLessThan,
	kComparisonGreaterThan,
	kComparisonOneOf,
	kComparisonUndefined
} OOComparisonType;


typedef enum
{
	kTypeInvalid,
	kTypeString,
	kTypeNumber,
	kTypeBool
} OOOperandType;


static NSMutableArray *ScanTokensFromString(NSString *values);


@interface OOLegacyScriptToJavaScriptConverter (ConverterCorePrivate)

- (void) convertConditional:(NSDictionary *)conditional;

- (void) convertOneAction:(NSString *)action;

- (NSString *) convertOneCondition:(NSString *)condition;
- (NSString *) convertQuery:(NSString *)query gettingType:(OOOperandType *)outType;
- (NSString *) convertStringCondition:(OOComparisonType)comparator comparatorString:(NSString *)comparatorString lhs:(NSString *)lhs rhs:(NSString *)rhs;
- (NSString *) convertNumberCondition:(OOComparisonType)comparator comparatorString:(NSString *)comparatorString lhs:(NSString *)lhs rhs:(NSString *)rhs;
- (NSString *) convertBoolCondition:(OOComparisonType)comparator comparatorString:(NSString *)comparatorString lhs:(NSString *)lhs rhs:(NSString *)rhs;

- (NSString *) stringifyBooleanExpression:(NSString *)expr;

@end


@implementation OOLegacyScriptToJavaScriptConverter (ConverterCore)

- (void) convertActions:(NSArray *)actions
{
	OOUInteger				i, count;
	id						action;
	
	count = [actions count];
	
	for (i = 0; i != count; ++i)
	{
		action = [actions objectAtIndex:i];
		
		if ([action isKindOfClass:[NSString class]])
		{
			[self convertOneAction:action];
		}
		else if ([action isKindOfClass:[NSDictionary class]])
		{
			[self convertConditional:action];
		}
		else
		{
			[_problemReporter addStopIssueWithKey:@"invalid-type"
										   format:@"Expected string (action) or dictionary (conditional), but found %@.", [action class]];
			[self appendWithFormat:@"<** Invalid object of class %@ **>", [action class]];
			_validConversion = NO;
		}
	}
}

@end


@implementation OOLegacyScriptToJavaScriptConverter (ConverterCorePrivate)

- (void) convertConditional:(NSDictionary *)conditional
{
	NSArray					*conditions = nil;
	NSArray					*ifTrue = nil;
	NSArray					*ifFalse = nil;
	OOUInteger				i, count;
	NSString				*cond = nil;
	BOOL					flipCondition = NO;
	
	conditions = [conditional arrayForKey:@"conditions"];
	ifTrue = [conditional arrayForKey:@"do"];
	ifFalse = [conditional arrayForKey:@"else"];
	
	if (ifTrue == nil && ifFalse == nil)
	{
		[_problemReporter addWarningIssueWithKey:@"empty-conditional-action"
										  format:@"Conditional expression with neither \"do\" clause nor \"else\" clause, ignoring."];
		return;
	}
	
	if ([ifTrue count] == 0)
	{
		flipCondition = YES;
		ifTrue = ifFalse;
		ifFalse = nil;
	}
	
	count = [conditions count];
	if (count == 0)
	{
		[_problemReporter addWarningIssueWithKey:@"empty-conditions"
										  format:@"Empty or invalid conditions array, treating as always true."];
		ifFalse = nil;
		// Treat as always-true for backwards-compatibility
	}
	else
	{
		[self append:@"if ("];
		if (flipCondition)  [self append:@"!("];
		
		for (i = 0; i != count; ++i)
		{
			if (i != 0)
			{
				[self append:@" &&\n\t"];
				if (flipCondition)  [self append:@"  "];
			}
			
			cond = [self convertOneCondition:[conditions objectAtIndex:i]];
			if (cond == nil)
			{
				if (_validConversion)
				{
					[_problemReporter addBugIssueWithKey:@"unreported-error"
												  format:@"An error occurred while converting a condition, but no appropriate message was generated."];
					_validConversion = NO;
				}
				cond = @"<** invalid **>";
			}
			
			if (count != 1)  cond = [NSString stringWithFormat:@"(%@)", cond];
			
			[self append:cond];
		}
		
		if (flipCondition)  [self append:@")"];
		[self append:@")\n{\n"];
	}
	
	[self indent];
	[self convertActions:ifTrue];
	[self outdent];
	[self append:@"}\n"];
	if (ifFalse != nil)
	{
		[self append:@"else\n{\n"];
		[self indent];
		[self convertActions:ifFalse];
		[self outdent];
		[self append:@"}\n"];
	}
}


- (void) convertOneAction:(NSString *)action
{
	NSMutableArray		*tokens = nil;
	NSString			*selectorString = nil;
	unsigned			tokenCount;
	BOOL				takesParam;
	NSString			*valueString = nil;
	SEL					selector = NULL;
	NSString			*converted = nil;
	
	tokens = ScanTokensFromString(action);
	
	tokenCount = [tokens count];
	if (tokenCount < 1)
	{
		// This is a hard error in the interpreter, so it's a failure here.
		[_problemReporter addStopIssueWithKey:@"no-tokens"
									   format:@"Invalid or empty script action \"%@\"", action];
		_validConversion = NO;
	}
	
	selectorString = [tokens objectAtIndex:0];
	takesParam = [selectorString hasSuffix:@":"];
	
	if (takesParam && tokenCount > 1)
	{
		if (tokenCount == 2) valueString = [tokens objectAtIndex:1];
		else
		{
			[tokens removeObjectAtIndex:0];
			valueString = [tokens componentsJoinedByString:@" "];
		}
	}
	
	selector = NSSelectorFromString([@"convertAction_" stringByAppendingString:selectorString]);
	if ([self respondsToSelector:selector])
	{
		if (takesParam)
		{
			converted = [self performSelector:selector withObject:valueString];
		}
		else
		{
			converted = [self performSelector:selector];
		}
		
		if (converted == nil && _validConversion)
		{
			[_problemReporter addBugIssueWithKey:@"unreported-error"
										  format:@"An error occurred while converting an action, but no appropriate message was generated (selector: \"%@\").", selectorString];
			_validConversion = NO;
			converted = @"<** unknown error **>";
		}
		
#if COMMENT_SELECTOR
		converted = [NSString stringWithFormat:@"%@\t\t// %@", converted, selectorString];
#endif
	}
	else
	{
		converted = [NSString stringWithFormat:@"<%@>\t\t// *** UNKNOWN ***", action];
		[_problemReporter addStopIssueWithKey:@"unknown-selector"
									   format:@"Could not convert unknown action selector \"%@\".", selectorString];
		_validConversion = NO;
	}
	
	[self appendWithFormat:@"%@\n", converted];
}


- (NSString *) convertOneCondition:(NSString *)condition
{
	NSArray				*tokens = nil;
	NSString			*comparisonString = nil;
	OOComparisonType	comparator = kComparisonUndefined;
	unsigned			tokenCount;
//	unsigned			i, count;
	NSString			*lhs = nil;
	OOOperandType		lhsType = kTypeInvalid;
	NSString			*rhs = nil;
	NSString			*result = nil;
	
	if (![condition isKindOfClass:[NSString class]])
	{
		[_problemReporter addStopIssueWithKey:@"invalid-condition"
									   format:@"Condition should be string, but found %@.", [condition class]];
		_validConversion = NO;
		return [NSString stringWithFormat:@"<** Invalid object of class %@ **>", [condition class]];
	}
	
	tokens = ScanTokensFromString(condition);
	tokenCount = [tokens count];
	if (tokenCount == 0)
	{
		// This is a hard error in the interpreter, so it's a failure here.
		[_problemReporter addStopIssueWithKey:@"no-tokens"
									   format:@"Invalid or empty script condition \"%@\"", condition];
		_validConversion = NO;
	}
	
	lhs = [self convertQuery:[tokens objectAtIndex:0] gettingType:&lhsType];
	
	if (tokenCount > 1)
	{
		comparisonString = [tokens objectAtIndex:1];
		
		if ([comparisonString isEqualToString:@"equal"])  comparator = kComparisonEqual;
		else if ([comparisonString isEqualToString:@"notequal"])  comparator = kComparisonNotEqual;
		else if ([comparisonString isEqualToString:@"lessthan"])  comparator = kComparisonLessThan;
		else if ([comparisonString isEqualToString:@"greaterthan"])  comparator = kComparisonGreaterThan;
		else if ([comparisonString isEqualToString:@"morethan"])  comparator = kComparisonGreaterThan;
		else if ([comparisonString isEqualToString:@"oneof"])  comparator = kComparisonOneOf;
		else if ([comparisonString isEqualToString:@"undefined"])  comparator = kComparisonUndefined;
		else
		{
			[_problemReporter addStopIssueWithKey:@"invalid-comparator"
										   format:@"Unknown comparison operator \"%@\".", comparisonString];
			_validConversion = NO;
			return @"<** unknown comparison operator **>";
		}
	}
	
	if (tokenCount == 3)
	{
		rhs = [self expandStringOrNumber:[tokens objectAtIndex:2]];
	}
	else if (tokenCount > 3)
	{
		rhs = @"<?\?>";
	}
	
	if (lhsType == kTypeString)  result = [self convertStringCondition:comparator comparatorString:comparisonString lhs:lhs rhs:rhs];
	else if (lhsType == kTypeNumber)  result = [self convertNumberCondition:comparator comparatorString:comparisonString lhs:lhs rhs:rhs];
	else if (lhsType == kTypeBool)  result = [self convertBoolCondition:comparator comparatorString:comparisonString lhs:lhs rhs:rhs];
	
	if (result == nil)  result = [NSString stringWithFormat:@"<%@ ?\?>", lhs];
	return result;
}


- (NSString *) convertStringCondition:(OOComparisonType)comparator comparatorString:(NSString *)comparatorString lhs:(NSString *)lhs rhs:(NSString *)rhs
{
	switch (comparator)
	{
		case kComparisonEqual:
			return [NSString stringWithFormat:@"%@ == %@", lhs, rhs];
			
		case kComparisonNotEqual:
			return [NSString stringWithFormat:@"%@ != %@", lhs, rhs];
			
		case kComparisonLessThan:
			[self setHelperFunction:
					@"this.parseFloatOrZero = function (string)\n{\n"
					"\tlet value = parseFloat(string);\n"
					"\tif (isNaN(value))  return 0;\n"
					"\telse  return value;\n}"
				forKey:@"parseFloatOrZero"];
			return [NSString stringWithFormat:@"this.parseFloatOrZero(%@) < this.parseFloatOrZero(%@)", lhs, rhs];
			
		case kComparisonGreaterThan:
			[self setHelperFunction:
					@"this.parseFloatOrZero = function (string)\n{\n"
					"\tlet value = parseFloat(string);\n"
					"\tif (isNaN(value))  return 0;\n"
					"\telse  return value;\n}"
				forKey:@"parseFloatOrZero"];
			return [NSString stringWithFormat:@"this.parseFloatOrZero(%@) > this.parseFloatOrZero(%@)", lhs, rhs];
			
		case kComparisonOneOf:
			[self setHelperFunction:
					@"this.oneOf = function (string, list)\n{\n"
					"\tlet items = list.split(\",\");\n"
					"\treturn items.indexOf(string) != -1;\n}"
				forKey:@"oneOf"];
			return [NSString stringWithFormat:@"this.oneOf(%@, %@)", lhs, rhs];
			
		case kComparisonUndefined:
			[self setHelperFunction:
					@"this.isUndefined = function (value)\n{\n"
					"\treturn value == undefined || value == null;\n}"
				forKey:@"isUndefined"];
			return [NSString stringWithFormat:@"this.isUndefined(%@)", lhs];
	}
	
	[_problemReporter addBugIssueWithKey:@"unhandled-comparator"
								  format:@"Don't know how to convert operator %@.", comparatorString];
	_validConversion = NO;
	return @"<** unhandled operator **>";
}


- (NSString *) convertNumberCondition:(OOComparisonType)comparator comparatorString:(NSString *)comparatorString lhs:(NSString *)lhs rhs:(NSString *)rhs
{
	const NSString *kOps[] = { @"==", @"!=", @"<", @">", @"oneOf", @"undefined" };
	
	
	switch (comparator)
	{
		case kComparisonEqual:
			return [NSString stringWithFormat:@"%@ == %@", lhs, rhs];
			
		case kComparisonNotEqual:
			return [NSString stringWithFormat:@"%@ != %@", lhs, rhs];
			
		case kComparisonLessThan:
			return [NSString stringWithFormat:@"%@ < %@", lhs, rhs];
			
		case kComparisonGreaterThan:
			return [NSString stringWithFormat:@"%@ > %@", lhs, rhs];
			
		case kComparisonOneOf:
			[self setHelperFunction:
					@"this.parseFloatOrZero = function (string)\n{\n"
					"\tlet value = parseFloat(string);\n"
					"\tif (isNaN(value))  return 0;\n"
					"\telse  return value;\n}"
				forKey:@"parseFloatOrZero"];
			[self setHelperFunction:
					 @"this.oneOfNumber = function (number, list)\n{\n"
					 "\tlet items = list.split(\",\");\n"
					 "\tfor (let i = 0; i < items.length; ++i)  if (number == parseFloatOrZero(list[i]))  return true;\n"
					 "\treturn false;\n}"
				 forKey:@"oneOfNumber"];
			return [NSString stringWithFormat:@"this.oneOfNumber(%@, %@)", lhs, rhs];
			
		case kComparisonUndefined:
			[_problemReporter addBugIssueWithKey:@"invalid-comparator"
										  format:@"Operator %@ is not valid for number expressions.", comparatorString];
	}
	
	return [NSString stringWithFormat:@"<%@ %@ %@>", lhs, kOps[comparator], rhs];
}


- (NSString *) convertBoolCondition:(OOComparisonType)comparator comparatorString:(NSString *)comparatorString lhs:(NSString *)lhs rhs:(NSString *)rhs
{
	switch (comparator)
	{
		case kComparisonEqual:
			if ([rhs isEqualToString:@"\"YES\""])  return lhs;
			if ([rhs isEqualToString:@"\"NO\""])  return [NSString stringWithFormat:@"!(%@)", lhs];
			return [NSString stringWithFormat:@"%@ == %@", [self stringifyBooleanExpression:lhs], rhs];
			
		case kComparisonNotEqual:
			if ([rhs isEqualToString:@"\"YES\""])  return [NSString stringWithFormat:@"!(%@)", lhs];
			if ([rhs isEqualToString:@"\"NO\""])  return lhs;
			return [NSString stringWithFormat:@"%@ != %@", [self stringifyBooleanExpression:lhs], rhs];
			
		case kComparisonLessThan:
		case kComparisonGreaterThan:
		case kComparisonOneOf:
		case kComparisonUndefined:
			[_problemReporter addBugIssueWithKey:@"invalid-comparator"
										  format:@"Operator %@ is not valid for boolean expressions.", comparatorString];
	}
	
	[_problemReporter addBugIssueWithKey:@"unhandled-comparator"
								  format:@"Don't know how to convert operator %@.", comparatorString];
	_validConversion = NO;
	return @"<** unhandled operator **>";
}


- (NSString *) convertQuery:(NSString *)query gettingType:(OOOperandType *)outType
{
	SEL					selector;
	NSString			*converted = nil;
	
	assert(outType != NULL);
	
	if ([query hasPrefix:@"mission_"] || [query hasPrefix:@"local_"])
	{
		// Variables in legacy engine are always considered strings.
		*outType = kTypeString;
		return [self legalizedVariableName:query];
	}
	
	if ([query hasSuffix:@"_string"])  *outType = kTypeString;
	else if ([query hasSuffix:@"_number"])  *outType = kTypeNumber;
	else if ([query hasSuffix:@"_bool"])  *outType = kTypeBool;
	else  *outType = kTypeInvalid;
	
	selector = NSSelectorFromString([@"convertQuery_" stringByAppendingString:query]);
	if ([self respondsToSelector:selector])
	{
		converted = [self performSelector:selector];
		if (converted == nil)
		{
			if (_validConversion)
			{
				[_problemReporter addBugIssueWithKey:@"unreported-error"
											  format:@"An error occurred while converting a condition, but no appropriate message was generated (selector: \"%@\").", query];
				_validConversion = NO;
			}
			converted = @"<** unknown error **>";
		}
	}
	else	
	{
		[_problemReporter addStopIssueWithKey:@"unknown-selector"
									   format:@"Could not convert unknown conditional selector \"%@\".", query];
		_validConversion = NO;
		converted = [NSString stringWithFormat:@"<** %@ **>", query];
	}
	
	return converted;
}


- (NSString *) stringifyBooleanExpression:(NSString *)expr
{
	[self setHelperFunction:
			@"this.boolToString = function (flag)\n{\n"
			"\t// Convert booleans to YES/NO for comparisons.\n"
			"\treturn flag ? \"YES\" : \"NO\";\n}"
		forKey:@"boolToString"];
	return [NSString stringWithFormat:@"this.boolToString(%@)", expr];
}


/*** Action handlers ***/

- (NSString *) convertAction_set:(NSString *)params
{
	NSMutableArray		*tokens = nil;
	NSString			*missionVariableString = nil;
	NSString			*valueString = nil;
	
	tokens = ScanTokensFromString(params);
	
	if ([tokens count] < 2)
	{
		[_problemReporter addStopIssueWithKey:@"set-syntax-error"
									   format:@"Bad syntax for set: -- expected mission_variable or local_variable followed by value expression, got \"%@\".", params];
		_validConversion = NO;
		return nil;
	}
	
	missionVariableString = [tokens objectAtIndex:0];
	[tokens removeObjectAtIndex:0];
	valueString = [tokens componentsJoinedByString:@" "];
	
	if ([missionVariableString hasPrefix:@"mission_"] || [missionVariableString hasPrefix:@"local_"])
	{
		return [NSString stringWithFormat:@"%@ = %@;", [self legalizedVariableName:missionVariableString], [self expandStringOrNumber:valueString]];
	}
	else
	{
		[_problemReporter addStopIssueWithKey:@"set-syntax-error"
									   format:@"Bad syntax for set: -- expected mission_variable or local_variable, got \"%@\".", missionVariableString];
		_validConversion = NO;
		return nil;
	}
}


- (NSString *) convertAction_reset:(NSString *)variable
{
	NSString *legalized = [self legalizedVariableName:variable];
	if (legalized == nil)  return nil;
	
	return [NSString stringWithFormat:@"%@ = null;", legalized];
}


- (NSString *) convertAction_commsMessage:(NSString *)string
{
	return [NSString stringWithFormat:@"player.commsMessage(%@);", [self expandString:string]];
}


- (NSString *) convertAction_setMissionImage:(NSString *)string
{
	return [NSString stringWithFormat:@"mission.setBackgroundImage(%@);", [self expandString:string]];
}


- (NSString *) convertAction_showShipModel:(NSString *)string
{
	return [NSString stringWithFormat:@"mission.showShipModel(%@);", [self expandString:string]];
}


- (NSString *) convertAction_checkForShips:(NSString *)string
{
	[self setInitializer:@"this.shipsFound = 0;" forKey:@"shipsFound"];
	return [NSString stringWithFormat:@"this.shipsFound = system.shipsWithPrimaryRole(%@).length;", [self expandString:string]];
}


- (NSString *) convertAction_awardCredits:(NSString *)string
{
	return [NSString stringWithFormat:@"player.credits += %@;", [self expandIntegerExpression:string]];
}


- (NSString *) convertAction_awardShipKills:(NSString *)string
{
	return [NSString stringWithFormat:@"player.score += %@;", [self expandIntegerExpression:string]];
}


- (NSString *) convertAction_setLegalStatus:(NSString *)string
{
	return [NSString stringWithFormat:@"player.bounty = %@;", [self expandIntegerExpression:string]];
}


- (NSString *) convertAction_addMissionText:(NSString *)string
{
	return [NSString stringWithFormat:@"mission.addMessageTextKey(%@);", [self expandString:string]];
}


- (NSString *) convertAction_setMissionChoices:(NSString *)string
{
	return [NSString stringWithFormat:@"mission.setChoicesKey(%@);", [self expandString:string]];
}


- (NSString *) convertAction_useSpecialCargo:(NSString *)string
{
	return [NSString stringWithFormat:@"mission.useSpecialCargo(%@);", [self expandString:string]];
}


- (NSString *) convertAction_consoleMessage3s:(NSString *)string
{
	return [NSString stringWithFormat:@"player.consoleMessage(%@);", [self expandString:string]];
}


- (NSString *) convertAction_consoleMessage6s:(NSString *)string
{
	return [NSString stringWithFormat:@"player.consoleMessage(%@, 6.0);", [self expandString:string]];
}


- (NSString *) convertAction_testForEquipment:(NSString *)string
{
	[self setInitializer:@"this.foundEqipment = false;" forKey:@"foundEqipment"];
	return [NSString stringWithFormat:@"this.foundEqipment = player.ship.hasEquipment(%@);", [self expandString:string]];
}


- (NSString *) convertAction_awardEquipment:(NSString *)string
{
	return [NSString stringWithFormat:@"player.ship.awardEquipment(%@);", [self expandString:string]];
}


- (NSString *) convertAction_removeEquipment:(NSString *)string
{
	return [NSString stringWithFormat:@"player.ship.removeEquipment(%@);", [self expandString:string]];
}


- (NSString *) convertAction_increment:(NSString *)string
{
	/*	A helper function is used to ensure correct (i.e. backwards-compatible)
		semantics when incrementing a variable which happens to be a string.
	*/
	[self setHelperFunction:
			@"this.increment = function (n)\n{\n"
			"\t// This handles the case where increment: is used on a variable that's currently a string.\n"
			"\tn = parseInt(n);\n"
			"\tif(isNaN(n))  n = 0;\n"
			"\treturn n + 1;\n}"
		forKey:@"increment"];
	
	NSString *varStr = [self legalizedVariableName:string];
	return [NSString stringWithFormat:@"%@ = this.increment(%@);", varStr, varStr];
}


- (NSString *) convertAction_decrement:(NSString *)string
{
	/*	A helper function is used to ensure correct (i.e. backwards-compatible)
		semantics when incrementing a variable which happens to be a string.
	*/
	[self setHelperFunction:
			@"this.decrement = function (n)\n{\n"
			"\t// This handles the case where increment: is used on a variable that's currently a string.\n"
			"\tn = parseInt(n);\n"
			"\tif(isNaN(n))  n = 0;\n"
			"\treturn n - 1;\n}"
		forKey:@"decrement"];
	
	NSString *varStr = [self legalizedVariableName:string];
	return [NSString stringWithFormat:@"%@ = this.decrement(%@);", varStr, varStr];
}


- (NSString *) convertAction_setFuelLeak:(NSString *)string
{
	return [NSString stringWithFormat:@"player.ship.fuelLeakRate = %@;", [self expandFloatExpression:string]];
}


- (NSString *) convertAction_setSunNovaIn:(NSString *)string
{
	return [NSString stringWithFormat:@"system.sun.goNova(%@);", [self expandFloatExpression:string]];
}


- (NSString *) convertAction_addShips:(NSString *)params
{
	NSMutableArray		*tokens = nil;
	NSString			*roleString = nil;
	NSString			*numberString = nil;
	
	tokens = ScanTokensFromString(params);
	if ([tokens count] != 2)
	{
		[_problemReporter addStopIssueWithKey:@"addShips-syntax-error"
									   format:@"Bad syntax for addShips: -- expected role followed by count, got \"%@\".", params];
		_validConversion = NO;
		return nil;
	}
	
	roleString = [tokens objectAtIndex:0];
	numberString = [tokens objectAtIndex:1];
	
	return [NSString stringWithFormat:@"system.legacy_addShips(%@, %@);", [self expandString:roleString], [self expandIntegerExpression:numberString]];
}


- (NSString *) convertAction_addSystemShips:(NSString *)params
{
	NSMutableArray		*tokens = nil;
	NSString			*roleString = nil;
	NSString			*numberString = nil;
	NSString			*positionString = nil;
	
	tokens = ScanTokensFromString(params);
	if ([tokens count] != 3)
	{
		[_problemReporter addStopIssueWithKey:@"addSystemShips-syntax-error"
									   format:@"Bad syntax for addSystemShips: -- expected role followed by count and position, got \"%@\".", params];
		_validConversion = NO;
		return nil;
	}
	
	roleString = [tokens objectAtIndex:0];
	numberString = [tokens objectAtIndex:1];
	positionString = [tokens objectAtIndex:2];
	
	return [NSString stringWithFormat:@"system.legacy_addSystemShips(%@, %@, %@);", [self expandString:roleString], [self expandIntegerExpression:numberString], [self expandFloatExpression:positionString]];
}


- (NSString *) convertAction_awardCargo:(NSString *)params
{
	NSMutableArray		*tokens = nil;
	NSString			*quantityString = nil;
	NSString			*typeString = nil;
	
	tokens = ScanTokensFromString(params);
	if ([tokens count] != 2)
	{
		[_problemReporter addStopIssueWithKey:@"awardCargo-syntax-error"
									   format:@"Bad syntax for awardCargo: -- expected count followed by type, got \"%@\".", params];
		_validConversion = NO;
		return nil;
	}
	
	quantityString = [tokens objectAtIndex:0];
	typeString = [tokens objectAtIndex:1];
	
	if ([quantityString isEqualToString:@"1"])
	{
		return [NSString stringWithFormat:@"player.ship.awardCargo(%@);", [self expandString:typeString]];
	}
	else
	{
		return [NSString stringWithFormat:@"player.ship.awardCargo(%@, %@);", [self expandString:typeString], [self expandIntegerExpression:quantityString]];
	}
}


- (NSString *) convertAction_setPlanetinfo:(NSString *)params
{
	NSArray				*tokens = nil;
	NSString			*keyString = nil;
	NSString			*valueString = nil;
	
	tokens = [params componentsSeparatedByString:@"="];
	if ([tokens count] != 2)
	{
		[_problemReporter addStopIssueWithKey:@"setPlanetinfo-syntax-error"
									   format:@"Bad syntax for setPlanetinfo: -- expected key=value, got \"%@\".", params];
		_validConversion = NO;
		return nil;
	}
	
	keyString = [[tokens objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	valueString = [[tokens objectAtIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	
	return [NSString stringWithFormat:@"system.info%@ = %@;", [self expandPropertyReference:keyString], [self expandString:valueString]];
}


- (NSString *) convertAction_setSpecificPlanetInfo:(NSString *)params
{
	NSArray				*tokens = nil;
	NSString			*galaxyString = nil;
	NSString			*systemString = nil;
	NSString			*keyString = nil;
	NSString			*valueString = nil;
	
	tokens = [params componentsSeparatedByString:@"="];
	if ([tokens count] != 4)
	{
		[_problemReporter addStopIssueWithKey:@"setPlanetinfo-syntax-error"
									   format:@"Bad syntax for setPlanetinfo: -- expected galaxy=system=key=value, got \"%@\".", params];
		_validConversion = NO;
		return nil;
	}
	
	galaxyString = [[tokens objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	systemString = [[tokens objectAtIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	keyString = [[tokens objectAtIndex:2] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	valueString = [[tokens objectAtIndex:3] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	
	return [NSString stringWithFormat:@"System.infoForSystem(%@, %@)%@ = %@;", [self expandIntegerExpression:galaxyString], [self expandIntegerExpression:systemString], [self expandPropertyReference:keyString], [self expandString:valueString]];
}


- (NSString *) convertAction_sendAllShipsAway
{
	return @"system.sendAllShipsAway();";
}


- (NSString *) convertAction_launchFromStation
{
	return @"player.ship.launch();";
}


- (NSString *) convertAction_blowUpStation
{
	return @"system.mainStation.explode();";
}


- (NSString *) convertAction_removeAllCargo
{
	return @"player.ship.removeAllCargo();";
}


- (NSString *) convertAction_clearMissionScreen
{
	return @"mission.clearMissionScreen();";
}


- (NSString *) convertAction_setGuiToMissionScreen
{
	return @"mission.showMissionScreen();";
}


/*** Query handlers ***/

- (NSString *) convertQuery_dockedAtMainStation_bool
{
	return @"player.ship.dockedStation == system.mainStation";
}


- (NSString *) convertQuery_galaxy_number
{
	return @"galaxyNumber";
}


- (NSString *) convertQuery_planet_number
{
	return @"system.ID";
}


- (NSString *) convertQuery_score_number
{
	return @"player.score";
}


- (NSString *) convertQuery_d100_number
{
	return @"Math.floor(Math.random() * 100)";
}


- (NSString *) convertQuery_d256_number
{
	return @"Math.floor(Math.random() * 256)";
}


- (NSString *) convertQuery_sunWillGoNova_bool
{
	return @"system.sun.isGoingNova";
}


- (NSString *) convertQuery_sunGoneNova_bool
{
	return @"system.sun.hasGoneNova";
}


- (NSString *) convertQuery_status_string
{
	return @"player.ship.status";
}


- (NSString *) convertQuery_shipsFound_number
{
	[self setInitializer:@"this.shipsFound = 0;" forKey:@"shipsFound"];
	return @"this.shipsFound";
}


- (NSString *) convertQuery_foundEquipment_bool
{
	[self setInitializer:@"this.foundEqipment = false;" forKey:@"foundEqipment"];
	return @"this.foundEqipment";
}


- (NSString *) convertQuery_missionChoice_string
{
	return @"mission.choice";
}


- (NSString *) convertQuery_scriptTimer_number
{
	return @"clock.legacy_scriptTimer";
}

@end


static NSMutableArray *ScanTokensFromString(NSString *values)
{
	NSMutableArray			*result = nil;
	NSScanner				*scanner = nil;
	NSString				*token = nil;
	static NSCharacterSet	*space_set = nil;
	
	if (values == nil)  return [NSArray array];
	if (space_set == nil) space_set = [[NSCharacterSet whitespaceAndNewlineCharacterSet] retain];
	
	result = [NSMutableArray array];
	scanner = [NSScanner scannerWithString:values];
	
	while (![scanner isAtEnd])
	{
		[scanner ooliteScanCharactersFromSet:space_set intoString:NULL];
		if ([scanner ooliteScanUpToCharactersFromSet:space_set intoString:&token])
		{
			[result addObject:token];
		}
	}
	
	return result;
}
