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
        RACSignal *addProject = [client addProjectNamed:@"Example Project"];
        RACSignal *projects = [[client projects:query] flattenMap:^RACStream *(NSArray *projectSignals) {
            return [[RACSignal combineLatest:projectSignals] map:^NSArray *(RACTuple *tuple) {
                return tuple.allObjects;
            }];
        }];

        [[projects zipWith:addProject] subscribeNext:^(RACTuple *next) {
            RACTupleUnpack(NSArray *projects, Project *project) = next;
            expect(projects).to.equal(@[project]);
            done();
        }];
    });
});

SpecEnd