#import "InMemoryAPIClient.h"
#import "Project.h"

@interface InMemoryAPIClient ()
@property (nonatomic, strong) NSMutableArray *projects;
@property (readonly) int32_t nextID;
@end

@implementation InMemoryAPIClient {
    int32_t _nextID;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.projects = [NSMutableArray array];
        _nextID = 0;
    }
    return self;
}

- (RACSignal *)projects:(RACSignal *)query
{
    return [RACSignal return:self.projects];
}

- (RACSignal *)addProjectNamed:(NSString *)name
{
    return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSNumber *ID = [NSNumber numberWithInt:self.nextID];
        Project *project = [[Project alloc] initWithID:ID name:name];

        [self.projects addObject:project];

        [subscriber sendNext:project];
        [subscriber sendCompleted];

        return nil;
    }] replayLazily];
}

- (int32_t)nextID
{
    return OSAtomicIncrement32(&_nextID);
}

@end
