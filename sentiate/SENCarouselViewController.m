//
//  SENCarouselViewController.m
//  sentiate
//
//  Created by Robert Carlsen on 4/13/14.
//  Copyright (c) 2014 Robert Carlsen. All rights reserved.
//

#import "SENCarouselViewController.h"
#import "SENViewModel.h"
#import <iCarousel/iCarousel.h>

@interface SENCarouselViewController ()
<iCarouselDataSource, iCarouselDelegate>

@property (nonatomic, strong)SENViewModel *viewModel;

@property (weak, nonatomic) IBOutlet iCarousel *carouselView;
@property (weak, nonatomic) IBOutlet UIView *selectedLineView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *connectButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *connectionIndicator;
@end

@implementation SENCarouselViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Senti8", nil);
    self.connectButton.title = NSLocalizedString(@"Connect", nil);

    self.viewModel = [[SENViewModel alloc] init];

    self.carouselView.type = iCarouselTypeCylinder;
    self.carouselView.vertical = YES;
    [self.carouselView reloadData];

    [RACObserve(self.viewModel, scentItems) subscribeNext:^(id x) {
        [[RACScheduler mainThreadScheduler] schedule:^{
            [self.carouselView reloadData];
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


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


#pragma mark - iCarousel protocol
- (NSUInteger)numberOfItemsInCarousel:(iCarousel *)carousel;
{
    return self.viewModel.scentItems.count;
}

- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSUInteger)index reusingView:(UIView *)view;
{
    UILabel *label = nil;

    //create new view if no view is available for recycling
    if (view == nil)
    {
        view = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 200.0f, 200.0f)];
        view.backgroundColor = [UIColor colorWithWhite:0.9 alpha:0.97];

        NSString *imageName = self.viewModel.scentItems[index][kScentImageKey];
        if (imageName) {
            ((UIImageView *)view).image = [UIImage imageNamed:imageName];
        }
        else {
            ((UIImageView *)view).image = nil;
        }

        view.contentMode = UIViewContentModeCenter;
        label = [[UILabel alloc] initWithFrame:CGRectMake(0, 200 - 40, view.bounds.size.width, 40)];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        label.tag = 1;
        [view addSubview:label];
    }
    else
    {
        //get a reference to the label in the recycled view
        label = (UILabel *)[view viewWithTag:1];
    }

    //set item label
    //remember to always set any properties of your carousel item
    //views outside of the `if (view == nil) {...}` check otherwise
    //you'll get weird issues with carousel item content appearing
    //in the wrong place in the carousel
    label.text = self.viewModel.scentItems[index][kScentLabelKey];

    return view;
}

- (CATransform3D)carousel:(iCarousel *)_carousel itemTransformForOffset:(CGFloat)offset baseTransform:(CATransform3D)transform
{
    //implement 'flip3D' style carousel
    transform = CATransform3DRotate(transform, M_PI / 8.0f, 0.0f, 1.0f, 0.0f);
    return CATransform3DTranslate(transform, 0.0f, 0.0f, offset * self.carouselView.itemWidth);
}

- (CGFloat)carousel:(iCarousel *)_carousel valueForOption:(iCarouselOption)option withDefault:(CGFloat)value
{
    //customize carousel display
    switch (option)
    {
        case iCarouselOptionSpacing:
        {
            //add a bit of spacing between the item views
            return value * 1.05f;
        }

        case iCarouselOptionArc:
            return value * 0.5f;

        default:
        {
            return value;
        }
    }
}

- (BOOL)carousel:(iCarousel *)carousel shouldSelectItemAtIndex:(NSInteger)index;
{
    if (index != carousel.currentItemIndex) {
        return NO;
    }
    return YES;
}

- (void)carousel:(iCarousel *)carousel didSelectItemAtIndex:(NSInteger)index
{
    NSLog(@"Tapped view number: %@", @(index));

    if (index != carousel.currentItemIndex) {
        return;
    }

    // this will enable the digital out (it will be automatically disabled after a short timeout)
    if (self.viewModel.isConnected) {
        NSLog(@"Sending emit scent command...");
        NSDictionary *item = self.viewModel.scentItems[index];
        [self.viewModel emitScentType:[item[kScentTypeKey] intValue]]; // maybe not type safe

        // just fake the selected time out
        self.selectedLineView.backgroundColor = [UIColor redColor];
        @weakify(self);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:2. animations:^{
                @strongify(self);
                self.selectedLineView.backgroundColor = [UIColor lightGrayColor];
            }];
        });
    }
}

@end
