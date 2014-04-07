#import <Foundation/Foundation.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

@class Project;

@protocol APIClient <NSObject>

- (RACSignal *)projects;

- (RACSignal *)addProjectNamed:(NSString *)name;

- (RACSignal *)renameProject:(Project *)project to:(NSString *)newName;

- (RACSignal *)deleteProject:(Project *)project;

@end
