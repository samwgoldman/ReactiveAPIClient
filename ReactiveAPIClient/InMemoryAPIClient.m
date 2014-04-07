#import "InMemoryAPIClient.h"
#import "Project.h"

@interface InMemoryAPIClient ()
@property (nonatomic, strong) RACSubject *addedProjects;
@property (readonly) int32_t nextID;
@end

@implementation InMemoryAPIClient {
    int32_t _nextID;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.addedProjects = [RACSubject subject];
        _nextID = 0;
    }
    return self;
}

- (RACSignal *)projects:(RACSignal *)query
{
    return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [self.addedProjects subscribeNext:^(NSArray *projects) {
            NSMutableArray *projectSignals = [NSMutableArray arrayWithCapacity:projects.count];

            for (Project *project in projects) {
                [projectSignals addObject:[RACSignal return:project]];
            }

            [subscriber sendNext:projectSignals];
        }];

        return nil;
    }] replayLazily];
}

- (RACSignal *)addProjectNamed:(NSString *)name
{
    return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSNumber *ID = [NSNumber numberWithInt:self.nextID];
        Project *project = [[Project alloc] initWithID:ID name:name];

        [self.addedProjects sendNext:@[project]];

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
