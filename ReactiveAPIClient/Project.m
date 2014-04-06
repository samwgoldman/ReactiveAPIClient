#import "Project.h"

@interface Project ()
@property (nonatomic, copy) NSNumber *ID;
@property (nonatomic, copy) NSString *name;
@end

@implementation Project

- (id)initWithID:(NSNumber *)ID name:(NSString *)name
{
    self = [super init];
    if (self) {
        self.ID = ID;
        self.name = name;
    }
    return self;
}

- (BOOL)isEqualToProject:(Project *)project
{
    return self.ID == project.ID;
}

- (BOOL)isEqual:(id)object
{
    return self == object
        || ([object isKindOfClass:[Project class]] && [object isEqualToProject:self]);
}

- (NSUInteger)hash
{
    return self.ID.hash;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

@end
