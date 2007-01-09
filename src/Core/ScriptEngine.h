#ifndef SCRIPTENGINE_H_SEEN
#define SCRIPTENGINE_H_SEEN

#import <Foundation/Foundation.h>
#import "Universe.h"
#import "PlayerEntity.h"
#import <jsapi.h>

@interface ScriptEngine : NSObject
{
	JSRuntime *rt;
	JSContext *cx;
	JSObject *glob;
	JSBool builtins;
	NSMutableArray *oxps;
}

- (id) initWithUniverse: (Universe *) universe;
- (void) dealloc;

- (void) doEvent: (NSString *) event;

@end

#endif
