#import <Foundation/Foundation.h>

@interface Project : NSObject <NSCopying>

- (id)initWithID:(NSNumber *)ID name:(NSString *)name;

- (BOOL)isEqualToProject:(Project *)project;

@end
