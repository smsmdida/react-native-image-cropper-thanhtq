//
//  ImageCroperManager.m
//  TOCropViewControllerExample
//
//  Created by Trương Thành on 2/15/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import "ImageCropperManager.h"
#import "TOCropViewController.h"
#import <React/RCTLog.h>
#import <React/RCTConvert.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import <React/RCTUtils.h>
#import "AppDelegate.h"

@interface ImageCropperManager () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, TOCropViewControllerDelegate>

@property (nonatomic, strong) UIImage *image;           // The image we'll be cropping
@property (nonatomic, strong) UIImageView *imageView;   // The image view to present the cropped image

@property (nonatomic, assign) TOCropViewCroppingStyle croppingStyle; //The cropping style
@property (nonatomic, assign) CGRect croppedFrame;
@property (nonatomic, assign) NSInteger angle;

@property (nonatomic, strong) RCTResponseSenderBlock callback;
@property (nonatomic, strong) NSDictionary *defaultOptions;
@property (nonatomic, retain) NSMutableDictionary *options, *response;
@property (nonatomic, strong) NSArray *customButtons;
@property (nonatomic, readonly) UIViewController *currentViewController;

@end

@implementation ImageCropperManager

// To export a module named ImageCroperManager
RCT_EXPORT_MODULE();

#pragma mark - Image Picker Delegate -
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    TOCropViewController *cropController = [[TOCropViewController alloc] initWithCroppingStyle:self.croppingStyle image:image];
    cropController.delegate = self;
    
    // Uncomment this if you wish to provide extra instructions via a title label
    //cropController.title = @"Crop Image";
    
    // -- Uncomment these if you want to test out restoring to a previous crop setting --
    //cropController.angle = 90; // The initial angle in which the image will be rotated
    //cropController.imageCropFrame = CGRectMake(0,0,2848,4288); //The initial frame that the crop controller will have visible.
    
    // -- Uncomment the following lines of code to test out the aspect ratio features --
    //cropController.aspectRatioPreset = TOCropViewControllerAspectRatioPresetSquare; //Set the initial aspect ratio as a square
    //cropController.aspectRatioLockEnabled = YES; // The crop box is locked to the aspect ratio and can't be resized away from it
    //cropController.resetAspectRatioEnabled = NO; // When tapping 'reset', the aspect ratio will NOT be reset back to default
    //cropController.aspectRatioPickerButtonHidden = YES;
    
    // -- Uncomment this line of code to place the toolbar at the top of the view controller --
    //cropController.toolbarPosition = TOCropViewControllerToolbarPositionTop;
    
    // -- Uncomment this line of code to include only certain type of preset ratios
    //cropController.allowedAspectRatios = @[@(TOCropViewControllerAspectRatioPresetOriginal),
    //                                       @(TOCropViewControllerAspectRatioPresetSquare),
    //                                       @(TOCropViewControllerAspectRatioPreset3x2)];
    
    //cropController.rotateButtonsHidden = YES;
    //cropController.rotateClockwiseButtonHidden = NO;
    
    //cropController.doneButtonTitle = @"Title";
    //cropController.cancelButtonTitle = @"Title";
    
    // -- Uncomment this line of code to show a confirmation dialog when cancelling --
    //cropController.showCancelConfirmationDialog = YES;
    
    // Uncomment this if you wish to always show grid
    //cropController.cropView.alwaysShowCroppingGrid = YES;
    
    // Uncomment this if you do not want translucency effect
    //cropController.cropView.translucencyAlwaysHidden = YES;
    
    self.image = image;
}

- (UIImage *)decodeBase64ToImage:(NSString *)strEncodeData {
    NSData *data = [[NSData alloc]initWithBase64EncodedString:strEncodeData options:NSDataBase64DecodingIgnoreUnknownCharacters];
    return [UIImage imageWithData:data];
}

- (NSString *)encodeToBase64String:(UIImage *)image {
    return [UIImageJPEGRepresentation(image, .5) base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
}

RCT_EXPORT_METHOD(showViewCrop:(NSString *)urlImage options:(NSDictionary *)options callback:(RCTResponseSenderBlock)callback){
    self.callback = callback; // Save the callback so we can use it from the delegate methods
    self.options = options;
    //NSString *urlBase64 = [self.options valueForKey:@"urlBase64Image"];
    //UIImage *image = [self decodeBase64ToImage:urlBase64];
    NSString *path = [self.options valueForKey:@"path"];
    NSURL *localurl = [NSURL URLWithString:path];
    NSData *data = [NSData dataWithContentsOfURL:localurl];
    UIImage *image = [[UIImage alloc] initWithData:data];
    self.croppingStyle = TOCropViewCroppingStyleDefault;
    
    TOCropViewController *cropController = [[TOCropViewController alloc] initWithCroppingStyle:self.croppingStyle image:image];
    cropController.title = @"Crop Image";
    cropController.allowedAspectRatios = @[@(TOCropViewControllerAspectRatioPresetSquare)];
    cropController.aspectRatioPreset = TOCropViewControllerAspectRatioPresetSquare; //Set the initial aspect ratio as a square
    // -- Uncomment this line of code to place the toolbar at the top of the view controller --
    //cropController.toolbarPosition = TOCropViewControllerToolbarPositionTop;
    BOOL aspectRatioPickerButtonHidden = [[self.options objectForKey:@"aspectRatioPickerButtonHidden"] boolValue] ? YES: NO;
    cropController.aspectRatioPickerButtonHidden = aspectRatioPickerButtonHidden;
    // The crop box is locked to the aspect ratio and can't be resized away from it
    BOOL aspectRatioLockEnabled = [[self.options objectForKey:@"aspectRatioLockEnabled"] boolValue] ? YES: NO;
    cropController.aspectRatioLockEnabled = aspectRatioLockEnabled;
    cropController.delegate = self;
    AppDelegate *share = (AppDelegate *)[UIApplication sharedApplication].delegate;
    UINavigationController *nav = (UINavigationController *) share.window.rootViewController;
    UIViewController *current = [self currentViewController];
    dispatch_async(dispatch_get_main_queue(), ^{
        [nav presentViewController:cropController animated:YES completion:nil];
        //[self presentViewController:cropController animated:YES completion:nil];
    });
}

- (UIViewController *)currentViewController
{
    UIViewController *current = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (current.presentedViewController && ![current.presentedViewController isKindOfClass:UIAlertController.class]) {
        current = current.presentedViewController;
    }
    return current;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Cropper Delegate -
- (void)cropViewController:(TOCropViewController *)cropViewController didCropToImage:(UIImage *)image withRect:(CGRect)cropRect angle:(NSInteger)angle
{
    self.croppedFrame = cropRect;
    self.angle = angle;
    NSString *check = [self encodeToBase64String:image];
    if(check){
        self.callback(@[check]);
    } else {
        self.callback(@[@{@"error": @"Crop error"}]);
    }
    [self updateImageViewWithImage:image fromCropViewController:cropViewController];
}

- (void)cropViewController:(TOCropViewController *)cropViewController didCropToCircularImage:(UIImage *)image withRect:(CGRect)cropRect angle:(NSInteger)angle
{
    self.croppedFrame = cropRect;
    self.angle = angle;
    [self updateImageViewWithImage:image fromCropViewController:cropViewController];
}

- (void)updateImageViewWithImage:(UIImage *)image fromCropViewController:(TOCropViewController *)cropViewController
{
    [cropViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
