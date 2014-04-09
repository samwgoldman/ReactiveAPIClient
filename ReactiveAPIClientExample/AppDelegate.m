#import "AppDelegate.h"
#import "InMemoryAPIClient.h"
#import "Project.h"

static NSString * const AddProjectToolbarItemIdentifier = @"AddProjectToolbarItemIdentifier";
static NSString * const DeleteProjectToolbarItemIdentifier = @"DeleteProjectToolbarItemIdentifier";

@interface AppDelegate () <NSTableViewDelegate, NSTableViewDataSource, NSToolbarDelegate>
@property (nonatomic, strong) id<APIClient> client;
@property (nonatomic, strong) NSMutableOrderedSet *projects;
@property (nonatomic, strong) NSTableView *tableView;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSView *contentView = self.window.contentView;

    NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"toolbar"];
    toolbar.displayMode = NSToolbarDisplayModeLabelOnly;
    toolbar.delegate = self;

    self.window.toolbar = toolbar;

    NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:contentView.bounds];
    scrollView.autoresizingMask = NSViewHeightSizable | NSViewWidthSizable;
    scrollView.borderType = NSNoBorder;
    scrollView.hasVerticalScroller = YES;
    scrollView.hasHorizontalScroller = YES;

    self.tableView = [[NSTableView alloc] init];
    self.tableView.autoresizingMask = NSViewHeightSizable | NSViewWidthSizable;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;

    NSTableColumn *IDColumn = [[NSTableColumn alloc] initWithIdentifier:@"ID"];
    [IDColumn.headerCell setStringValue:@"ID"];

    NSTableColumn *nameColumn = [[NSTableColumn alloc] initWithIdentifier:@"name"];
    [nameColumn.headerCell setStringValue:@"Name"];

    [self.tableView addTableColumn:IDColumn];
    [self.tableView addTableColumn:nameColumn];

    [scrollView setDocumentView:self.tableView];
    [contentView addSubview:scrollView];

    self.projects = [NSMutableOrderedSet orderedSet];

    self.client = [[InMemoryAPIClient alloc] init];

    [[[[[[self.client
        projects]
        map:^RACSignal *(RACSignal *projectSignal) {
            RACSignal *first = [projectSignal take:1];
            RACSignal *events = [projectSignal materialize];
            return [first combineLatestWith:events];
        }]
        flatten]
        bufferWithTime:0.1
        onScheduler:RACScheduler.scheduler]
        deliverOn:RACScheduler.mainThreadScheduler]
        subscribeNext:^(RACTuple *buffer) {
            for (RACTuple *update in buffer) {
                RACTupleUnpack(Project *project, RACEvent *event) = update;
                if (event.eventType == RACEventTypeNext) {
                    NSUInteger index = [self.projects indexOfObject:project];
                    if (index == NSNotFound) {
                        [self.projects addObject:event.value];
                    } else {
                        [self.projects setObject:event.value atIndex:index];
                    }
                } else if (event.eventType == RACEventTypeCompleted) {
                    [self.projects removeObject:project];
                }
            }

            [self.tableView reloadData];
        }];

    int numProjects = 100;
    NSMutableArray *addProjects = [NSMutableArray arrayWithCapacity:numProjects];
    for (int i = 0; i < numProjects; i ++) {
        NSString *name = [NSString stringWithFormat:@"Project %d", i];
        [addProjects addObject:[self.client addProjectNamed:name]];
    }

    [[RACSignal merge:addProjects] subscribeCompleted:^{
    }];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.projects.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return [self.projects[row] valueForKey:tableColumn.identifier];
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    Project *project = self.projects[row];

    [[self.client renameProject:project to:object] subscribeCompleted:^{
    }];
}

- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return [tableColumn.identifier isEqualToString:@"name"];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)identifier willBeInsertedIntoToolbar:(BOOL)flag
{
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:identifier];

    if ([identifier isEqualToString:AddProjectToolbarItemIdentifier]) {
        item.label = @"Add Project";
        item.target = self;
        item.action = @selector(addProject);
    } else if ([identifier isEqualToString:DeleteProjectToolbarItemIdentifier]) {
        item.label = @"Delete Project";
        item.target = self;
        item.action = @selector(deleteProject);
    }

    return item;
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
    return @[AddProjectToolbarItemIdentifier,
             DeleteProjectToolbarItemIdentifier];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
    return @[AddProjectToolbarItemIdentifier,
             DeleteProjectToolbarItemIdentifier];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)item
{
    return [item.itemIdentifier isEqualToString:AddProjectToolbarItemIdentifier]
        || self.tableView.selectedRow != -1;
}

- (void)addProject
{
    NSWindow *sheet = [[NSWindow alloc] init];
    NSView *contentView = sheet.contentView;

    NSForm *form = [[NSForm alloc] init];
    form.translatesAutoresizingMaskIntoConstraints = NO;
    form.autorecalculatesCellSize = YES;

    NSFormCell *nameField = [form addEntry:@"Name"];
    nameField.preferredTextFieldWidth = 200;

    NSButton *cancelButton = [[NSButton alloc] init];
    cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    cancelButton.bezelStyle = NSRoundedBezelStyle;
    cancelButton.title = @"Cancel";
    cancelButton.target = self;
    cancelButton.action = @selector(cancelAddProject:);

    NSButton *submitButton = [[NSButton alloc] init];
    submitButton.translatesAutoresizingMaskIntoConstraints = NO;
    submitButton.bezelStyle = NSRoundedBezelStyle;
    submitButton.title = @"Submit";
    submitButton.target = self;
    submitButton.action = @selector(createProject:);

    [cancelButton.cell setKeyEquivalent:@"\E"];
    [sheet setDefaultButtonCell:submitButton.cell];

    [contentView addSubview:form];
    [contentView addSubview:cancelButton];
    [contentView addSubview:submitButton];

    NSDictionary *views = @{ @"form": form, @"cancel": cancelButton, @"submit": submitButton };
    [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(20)-[form]-(20)-[cancel]-(20)-|"
                                                                        options:0
                                                                        metrics:nil
                                                                          views:views]];
    [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(20)-[form]-(20)-|"
                                                                        options:0
                                                                        metrics:nil
                                                                          views:views]];
    [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(>=20)-[cancel]-(8)-[submit]-(20)-|"
                                                                        options:NSLayoutFormatAlignAllTop | NSLayoutFormatAlignAllBottom
                                                                        metrics:nil
                                                                          views:views]];

    [self.window beginSheet:sheet completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSModalResponseOK) {
            NSString *name = nameField.stringValue;
            [[self.client addProjectNamed:name] subscribeCompleted:^{
            }];
        }
    }];
}

- (void)cancelAddProject:(NSButton *)cancelButton
{
    [self.window endSheet:cancelButton.window returnCode:NSModalResponseAbort];
}

- (void)createProject:(NSButton *)submitButton
{
    [self.window endSheet:submitButton.window returnCode:NSModalResponseOK];
}

- (void)deleteProject
{
    if (self.tableView.selectedRow != -1) {
        Project *project = self.projects[self.tableView.selectedRow];

        [[self.client deleteProject:project] subscribeCompleted:^{
        }];
    }
}

@end
