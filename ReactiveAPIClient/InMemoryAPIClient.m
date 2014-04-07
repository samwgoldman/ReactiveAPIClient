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

        [[self.addedProjects
            bufferWithTime:0.1
            onScheduler:RACScheduler.scheduler]
            subscribeNext:^(RACTuple *buffer) {
                NSMutableArray *projectSignals = [NSMutableArray arrayWithCapacity:buffer.count];

                for (Project *project in buffer) {
                    RACBehaviorSubject *subject = [RACBehaviorSubject behaviorSubjectWithDefaultValue:project];
                    [projectSubjects setObject:subject forKey:project.ID];
                    [projectSignals addObject:subject];
                }

                [subscriber sendNext:projectSignals];
            }];

        [self.editedProjects subscribeNext:^(Project *project) {
            RACSubject *subject = [projectSubjects objectForKey:project.ID];
            [subject sendNext:project];
        }];

        [self.deletedProjects subscribeNext:^(Project *project) {
            RACSubject *subject = [projectSubjects objectForKey:project.ID];
            [subject sendCompleted];
            [projectSubjects removeObjectForKey:project.ID];
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
