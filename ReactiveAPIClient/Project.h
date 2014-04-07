#import <Foundation/Foundation.h>

@interface Project : NSObject <NSCopying>

@property (readonly, copy) NSNumber *ID;
@property (readonly, copy) NSString *name;

- (id)initWithID:(NSNumber *)ID name:(NSString *)name;

- (BOOL)isEqualToProject:(Project *)project;

@end
