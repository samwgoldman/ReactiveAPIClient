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
});

SpecEnd