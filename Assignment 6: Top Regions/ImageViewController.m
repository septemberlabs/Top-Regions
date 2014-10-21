//
//  ImageViewController.m
//  Assignment 5
//
//  Created by Will Smith on 7/4/14.
//  Copyright (c) 2014 September Labs. All rights reserved.
//

#import "ImageViewController.h"

@interface ImageViewController () <UIScrollViewDelegate, UISplitViewControllerDelegate>
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIImage *image;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@end

@implementation ImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.scrollView addSubview:self.imageView];
}

- (void)setImageURL:(NSURL *)imageURL {
    _imageURL = imageURL;
    //self.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:imageURL]];
    [self startDownloadingImage];
}

- (void)startDownloadingImage {
    
    self.image = nil;

    if (self.imageURL) {
        [self.spinner startAnimating];
        NSURLRequest *request = [NSURLRequest requestWithURL:self.imageURL];
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        //NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:nil delegateQueue:[NSOperationQueue mainQueue]];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
        NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request
            completionHandler:^(NSURL *localfile, NSURLResponse *response, NSError *error) {
                if (!error) {
                    if ([request.URL isEqual:self.imageURL]) {
                        UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:localfile]];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            self.image = image;
                        });
                    }
                }
                
                //NSHTTPURLResponse *responseHTTP = (NSHTTPURLResponse *)response;
                //NSLog(@"response: %@", [responseHTTP allHeaderFields]);
            }];
        [task resume];
    }
    
}

- (UIImage *)image {
    return self.imageView.image;
}

- (void)setImage:(UIImage *)image {
    
    self.scrollView.zoomScale = 1.0;
    self.imageView.image = image;
    [self.imageView sizeToFit];
    self.scrollView.contentSize = self.image ? self.image.size : CGSizeZero;
    if (image.size.width > image.size.height) {
        [self.scrollView zoomToRect:CGRectMake(0, 0, 1, image.size.height) animated:YES];
    }
    else {
        [self.scrollView zoomToRect:CGRectMake(0, 0, image.size.width, 1) animated:YES];
    }
    [self.spinner stopAnimating];
    
}

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.backgroundColor = [UIColor redColor];
    }
    return _imageView;
}

- (void)setScrollView:(UIScrollView *)scrollView {
    _scrollView = scrollView;
    _scrollView.minimumZoomScale = 0.2;
    _scrollView.maximumZoomScale = 2.0;
    _scrollView.delegate = self;
    self.scrollView.contentSize = self.image ? self.image.size : CGSizeZero;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

#pragma mark - UISplitViewControllerDelegate

- (void)awakeFromNib {
    self.splitViewController.delegate = self;
}

- (BOOL)splitViewController:(UISplitViewController *)svc
   shouldHideViewController:(UIViewController *)vc
              inOrientation:(UIInterfaceOrientation)orientation {
    
    return UIInterfaceOrientationIsPortrait(orientation);
    
}

/************** left back button not showing when launched in portrait, and when it does show, it show's "region", not "photo" ****************/

- (void)splitViewController:(UISplitViewController *)svc
     willHideViewController:(UIViewController *)aViewController
          withBarButtonItem:(UIBarButtonItem *)barButtonItem
       forPopoverController:(UIPopoverController *)pc
{
    // we set the back button to read the master VC's title that we specified in Xcode (which is actually the app's name).
    UIViewController *master = svc.viewControllers[0];
    barButtonItem.title = master.title; // this could also just be aViewController.title, since aViewController is the master
    
    // this only works in the detail VC and only if it was in a UINavigationController
    self.navigationItem.leftBarButtonItem = barButtonItem;
}

- (void)splitViewController:(UISplitViewController *)svc
     willShowViewController:(UIViewController *)aViewController
  invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem {
    
    // when turned back to landscape (method name means about to show master VC) we remove the left bar button item from the navigation controller since its only purpose is to show the master VC when it's otherwise hidden in portrait.
    self.navigationItem.leftBarButtonItem = nil;
    
}


@end
