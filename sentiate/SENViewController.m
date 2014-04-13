//
//  SENViewController.m
//  sentiate
//
//  Created by Robert Carlsen on 4/12/14.
//  Copyright (c) 2014 Robert Carlsen. All rights reserved.
//

#import "SENViewController.h"
#import "SENViewModel.h"



@interface SENViewController ()
<UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *connectButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *connectionIndicator;

@property (nonatomic, strong)SENViewModel *viewModel;
@end

@implementation SENViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.title = NSLocalizedString(@"Senti8", nil);
    self.connectButton.title = NSLocalizedString(@"Connect", nil);
    
    self.viewModel = [SENViewModel new];

    [RACObserve(self.viewModel, scentItems) subscribeNext:^(id x) {
        [[RACScheduler mainThreadScheduler] schedule:^{
            [self.tableView reloadData];
        }];
    }];

    [RACObserve(self.viewModel, isConnected) subscribeNext:^(id x) {
        BOOL isConnected = [x boolValue];
        if (isConnected) {
            [self.connectionIndicator stopAnimating];
        }
    }];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - UITableViewDataSoure protocol
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.viewModel.scentItems.count;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

    cell.textLabel.text = self.viewModel.scentItems[indexPath.row][kScentLabelKey];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    // this will enable the digital out (it will be automatically disabled after a short timeout)
    if (self.viewModel.isConnected) {
        // not exactly safe..should delegate this to the model
        NSDictionary *item = self.viewModel.scentItems[indexPath.row];
        [self.viewModel emitScentType:[item[kScentTypeKey] intValue]]; // maybe not type safe
    }
}


// Connect button will call to this
- (IBAction)btnScanForPeripherals:(id)sender
{
    if (self.viewModel.isConnected) {
        [self.viewModel disconnectFromPeripheral];
        [self.connectButton setTitle:@"Connect"];
        [self.connectionIndicator stopAnimating];
    }
    else {
        [self.connectButton setEnabled:false];
        [self.connectionIndicator startAnimating];

        [self.viewModel scanForPeripheralWithCallback:^(BOOL success) {
            if (success) {
                [self.connectButton setTitle:@"Disconnect"];

                // Next: connect to found peripheral
                [self.viewModel connectToPeripheral];
            }
            else {
                [self.connectButton setTitle:@"Connect"];
                [self.connectionIndicator stopAnimating];
            }

            [self.connectButton setEnabled:true];
        }];
    }
}

@end
