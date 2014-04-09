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

        RACSignal *listProjects = [[[client
            projects]
            flatten]
            scanWithStart:[NSSet set]
            reduce:^NSSet *(NSSet *running, Project *project) {
                return [running setByAddingObject:project];
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

        RACSignal *projects = [client projects];
        RACSignal *createProject = [client addProjectNamed:@"Example Project"];

        [[[[projects
            zipWith:createProject]
            flattenMap:^RACStream *(RACTuple *next) {
                RACTupleUnpack(RACSignal *projectSignal, Project *project) = next;
                RACSignal *updateProject = [client renameProject:project to:@"Updated Project"];

                return [[projectSignal skip:1] zipWith:updateProject];
            }]
            deliverOn:RACScheduler.mainThreadScheduler]
            subscribeNext:^(RACTuple *next) {
                RACTupleUnpack(Project *updatedProject) = next;
                expect(updatedProject.name).to.equal(@"Updated Project");
            }
            completed:^{
                done();
            }];
    });

    it(@"completes listed signals when projects are deleted", ^AsyncBlock {
        id<APIClient> client = [[InMemoryAPIClient alloc] init];

        RACSignal *projects = [client projects];
        RACSignal *createProject = [client addProjectNamed:@"Example Project"];

        [[[projects
            zipWith:createProject]
            flattenMap:^RACStream *(RACTuple *next) {
                RACTupleUnpack(RACSignal *projectSignal, Project *project) = next;
                RACSignal *deleteProject = [client deleteProject:project];

                return [[projectSignal skip:1] zipWith:deleteProject];
            }]
            subscribeCompleted:^{
                done();
            }];
    });
});

SpecEnd