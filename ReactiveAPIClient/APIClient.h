#import <Foundation/Foundation.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

@protocol APIClient <NSObject>

- (RACSignal *)projects:(RACSignal *)query;

- (RACSignal *)addProjectNamed:(NSString *)name;

@end
