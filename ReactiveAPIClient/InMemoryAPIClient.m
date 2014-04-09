#import "InMemoryAPIClient.h"
#import "Project.h"

@interface InMemoryAPIClient ()
@property (nonatomic, strong) RACSubject *addedProjects;
@property (nonatomic, strong) RACSubject *editedProjects;
@property (nonatomic, strong) RACSubject *deletedProjects;
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
        self.editedProjects = [RACSubject subject];
        self.deletedProjects = [RACSubject subject];
        _nextID = 0;
    }
    return self;
}

- (RACSignal *)projects
{
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSMutableDictionary *projectSubjects = [NSMutableDictionary dictionary];

        [self.addedProjects subscribeNext:^(Project *project) {
            __block volatile int32_t subscriberCount = 0;
            RACSubject *subject = [RACSubject subject];
            RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
                if (OSAtomicIncrement32Barrier(&subscriberCount) == 1) {
                    [projectSubjects setObject:subject forKey:project.ID];
                }

                [subscriber sendNext:project];
                RACDisposable *subjectDisposable = [subject subscribe:subscriber];

                RACCompoundDisposable *compoundDisposable = [RACCompoundDisposable compoundDisposable];
                [compoundDisposable addDisposable:subjectDisposable];
                [compoundDisposable addDisposable:[RACDisposable disposableWithBlock:^{
                    if (OSAtomicDecrement32Barrier(&subscriberCount) == 0) {
                        [projectSubjects removeObjectForKey:project.ID];
                    }
                }]];

                return compoundDisposable;
            }];

            [subscriber sendNext:signal];
        }];

        [self.editedProjects subscribeNext:^(Project *project) {
            RACSubject *subject = [projectSubjects objectForKey:project.ID];
            [subject sendNext:project];
        }];

        [self.deletedProjects subscribeNext:^(Project *project) {
            RACSubject *subject = [projectSubjects objectForKey:project.ID];
            [subject sendCompleted];
        }];

        return nil;
    }];
}

- (RACSignal *)addProjectNamed:(NSString *)name
{
    return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSNumber *ID = [NSNumber numberWithInt:self.nextID];
        Project *project = [[Project alloc] initWithID:ID name:name];

        usleep(arc4random_uniform(1000));

        [self.addedProjects sendNext:project];

        [subscriber sendNext:project];
        [subscriber sendCompleted];

        return nil;
    }] subscribeOn:RACScheduler.scheduler];
}

- (RACSignal *)renameProject:(Project *)project to:(NSString *)newName
{
    return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        Project *newProject = [[Project alloc] initWithID:project.ID name:newName];

        usleep(arc4random_uniform(1000));

        [self.editedProjects sendNext:newProject];

        [subscriber sendNext:newProject];
        [subscriber sendCompleted];

        return nil;
    }] subscribeOn:RACScheduler.scheduler];
}

- (RACSignal *)deleteProject:(Project *)project
{
    return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        usleep(arc4random_uniform(1000));

        [self.deletedProjects sendNext:project];

        [subscriber sendNext:project];
        [subscriber sendCompleted];

        return nil;
    }] subscribeOn:RACScheduler.scheduler];
}

- (int32_t)nextID
{
    return OSAtomicIncrement32(&_nextID);
}

@end
