#define EXP_SHORTHAND
#import "Specta.h"
#import "Expecta.h"
#import "InMemoryAPIClient.h"
#import "Project.h"

SpecBegin(InMemoryAPIClient)

describe(@"InMemoryAPIClient", ^{
    it(@"lists projects", ^AsyncBlock {
        id<APIClient> client = [[InMemoryAPIClient alloc] init];

        int numberOfProjects = 10;
        NSMutableArray *createSignals = [NSMutableArray arrayWithCapacity:numberOfProjects];
        for (int i = 0; i < numberOfProjects; i++) {
            NSString *name = [NSString stringWithFormat:@"Project %d", i];
            [createSignals addObject:[client addProjectNamed:name]];
        }

        RACSignal *createProjects = [[RACSignal
            combineLatest:createSignals]
            map:^NSSet *(RACTuple *tuple) {
                return [NSSet setWithArray:tuple.allObjects];
            }];

        RACSignal *listProjects = [[[[client
            projects]
            scanWithStart:@[]
            reduce:^NSArray *(NSArray *acc, NSArray *projectSignals) {
                return [acc arrayByAddingObjectsFromArray:projectSignals];
            }]
            flattenMap:^RACStream *(NSArray *projectSignals) {
                return [RACSignal combineLatest:projectSignals];
            }]
            map:^NSSet *(RACTuple *tuple) {
                return [NSSet setWithArray:tuple.allObjects];
            }];

        [[[RACSignal
            combineLatest:@[listProjects, createProjects]]
            deliverOn:RACScheduler.mainThreadScheduler]
            subscribeNext:^(RACTuple *next) {
                RACTupleUnpack(NSSet *listedProjects, NSSet *createdProjects) = next;
                expect(listedProjects).to.equal(createdProjects);
                done();
            }];
    });

    it(@"updates listed signals when projects are edited", ^AsyncBlock {
        id<APIClient> client = [[InMemoryAPIClient alloc] init];

        RACSignal *listProjects = [client projects];
        RACSignal *createProject = [client addProjectNamed:@"Example Project"];

        [[[[[RACSignal
            combineLatest:@[listProjects, createProject]]
            take:1]
            flattenMap:^RACStream *(RACTuple *update) {
                RACTupleUnpack(NSArray *projectSignals, Project *project) = update;
                RACSignal *projects = [RACSignal merge:projectSignals];
                RACSignal *updateProject = [client renameProject:project to:@"Updated Project"];

                return [projects combineLatestWith:updateProject];
            }]
            deliverOn:RACScheduler.mainThreadScheduler]
            subscribeNext:^(RACTuple *update) {
                RACTupleUnpack(Project *updatedProject) = update;
                expect(updatedProject.name).to.equal(@"Updated Project");
                done();
            }];
    });

    it(@"completes listed signals when projects are deleted", ^AsyncBlock {
        id<APIClient> client = [[InMemoryAPIClient alloc] init];

        RACSignal *listProjects = [client projects];
        RACSignal *createProject = [client addProjectNamed:@"Example Project"];

        [[[[RACSignal
            combineLatest:@[listProjects, createProject]]
            take:1]
            flattenMap:^RACStream *(RACTuple *update) {
                RACTupleUnpack(NSArray *projectSignals, Project *project) = update;
                RACSignal *projects = [RACSignal combineLatest:projectSignals];
                RACSignal *deleteProject = [client deleteProject:project];

                return [projects combineLatestWith:deleteProject];
            }]
            subscribeCompleted:^{
                done();
            }];
    });
});

SpecEnd