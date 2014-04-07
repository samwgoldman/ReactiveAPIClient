#define EXP_SHORTHAND
#import "Specta.h"
#import "Expecta.h"
#import "InMemoryAPIClient.h"
#import "Project.h"

SpecBegin(InMemoryAPIClient)

describe(@"InMemoryAPIClient", ^{
    it(@"lists projects", ^AsyncBlock {
        id<APIClient> client = [[InMemoryAPIClient alloc] init];
        RACSignal *addProjectOne = [client addProjectNamed:@"Example One"];
        RACSignal *addProjectTwo = [client addProjectNamed:@"Project Two"];

        RACSignal *projects = [[[[client
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
            combineLatest:@[projects, addProjectOne, addProjectTwo]]
            deliverOn:RACScheduler.mainThreadScheduler]
            subscribeNext:^(RACTuple *next) {
                RACTupleUnpack(NSSet *projects, Project *projectOne, Project *projectTwo) = next;
                expect(projects).to.equal([NSSet setWithObjects:projectOne, projectTwo, nil]);
                done();
            }];
    });
});

SpecEnd