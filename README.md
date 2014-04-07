== Overview

This is a proof of concept for an API client using ReactiveCocoa. The main design idea is in `[APIClient -projects]`, which is a method that returns a signal of arrays of signals.

The outer signal updates when new projects have been added. Each inner signal updates when its associated project has been updated, and completes when its project has been deleted.

== Guide to the code

The client code is in the ReactiveAPIClient target. APIClient.h defines a protocol for APIClients.h. The only concrete implementation is an in-memory client that simulates network latency.

A small test suite exercises the main behaviors of the API client.

I have also provided an example app that shows how this kind of signal can be used to populate a user interface. The example app displays projects in a table view. The user can add and delete projects through the toolbar and edit projects by double-clicking on the project's name.

== Open questions

=== Use of `subscribeOn`

The API actions to create, update, and delete projects are all designed to simulate network latency by sleeping for a short time. In order to run these actions concurrently, they are scheduled on a background scheduler.

The ReactiveCocoa docs indicate that `subscribeOn` should be avoided, because the receivers side-effects maybe not be safe to run on another thread.

Indeed this is the case. In the example app, subscribers must observe on the main thread, or else UI updates can cause buggy behavior. Test examples also need to observe on the main thread or else expectation failures do not cause the test to fail.

Should the API client force `subscribeOn` or should the caller be responsible for determining the subscription scheduler?

Is there a cleaner way to have an asynchronous signal without changing the subscriber?

=== Maintaining project signals

When a project is modified or deleted, the inner signal for that project from any list should be updated or completed, respectively. In order to do this, the list signal maintains a dictionary RACBehaviorSubjects indexed by project ID.

The subjects themselves are the inner signals, and when a user updates or deletes a project through the API client, the client looks up the subject by project ID and sends an update or completes the subject, respectively.

Because the subjects are returned to the user directly as inner signals, the user could in theory mutate the signal using RACSubject methods.

Is there a way to hide the subjects and return signals instead?

=== Nested subscribers

In order to use a signal of arrays of signals effectively, I had to use nested subscribers, which are an anti-pattern.

ReactiveCocoa methods like `+merge:`, `+combineLatest:`, and `-flatten` are all useful for dealing with arrays of signals, but I couldn't not find any way to use them.

Consider a subscriber that wants to maintain a NSMutableDictionary that contains the latest version of every project.

```objective-c
NSMutableDictionary *projects = [NSMutableDictionary dictionary];
[[client projects] subscribeNext:^(NSArray *projectSignals) {
    for (RACSignal *signal in projectSignals) {
        Project *project = signal.first;
        projects[project.ID] = project;

        [signal subscribeNext:^(Project *update) {
            projects[update.ID] = update;
        } completed:^{
            [projects removeObjectForKey:project.ID];
        }];
    }
}];
```

How would I write the above code without nested subscribers?
