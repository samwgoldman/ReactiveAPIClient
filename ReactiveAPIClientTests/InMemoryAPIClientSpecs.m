#define EXP_SHORTHAND
#import "Specta.h"
#import "Expecta.h"
#import "InMemoryAPIClient.h"
#import "Project.h"

SpecBegin(InMemoryAPIClient)

describe(@"InMemoryAPIClient", ^{
    it(@"lists projects", ^AsyncBlock {
        id<APIClient> client = [[InMemoryAPIClient alloc] init];
        RACSubject *query = [RACBehaviorSubject behaviorSubjectWithDefaultValue:@""];
        RACSignal *addProjectOne = [client addProjectNamed:@"Example One"];
        RACSignal *addProjectTwo = [client addProjectNamed:@"Project Two"];

        RACSignal *projects = [[[[[client
            projects:query]
            scanWithStart:@[]
            reduce:^NSArray *(NSArray *acc, NSArray *projectSignals) {
                return [acc arrayByAddingObjectsFromArray:projectSignals];
            }]
            flattenMap:^RACStream *(NSArray *projectSignals) {
                return [RACSignal combineLatest:projectSignals];
            }]
            map:^NSArray *(RACTuple *tuple) {
                return tuple.allObjects;
            }]
            logAll];

        [[RACSignal combineLatest:@[projects, addProjectOne, addProjectTwo]] subscribeNext:^(RACTuple *next) {
            RACTupleUnpack(NSArray *projects, Project *projectOne, Project *projectTwo) = next;
            expect(projects).to.equal(@[projectOne, projectTwo]);
            done();
        }];
    });
});

SpecEnd