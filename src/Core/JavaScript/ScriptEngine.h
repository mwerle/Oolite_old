#ifndef SCRIPTENGINE_H_SEEN
#define SCRIPTENGINE_H_SEEN

#import <Foundation/Foundation.h>
#import <Universe.h>
#import <PlayerEntity.h>
#import <jsapi.h>

@interface ScriptEngine : NSObject
{
	JSRuntime *rt;
	JSContext *cx;
	JSObject *glob;
	JSBool builtins;
}

- (id) initWithUniverse: (Universe *) universe;
- (void) dealloc;

- (JSContext *) context;

@end

#endif
