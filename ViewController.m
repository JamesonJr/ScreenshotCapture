//
//  ViewController.m
//  ScreenshotCapture
//
//  Created by Eugenie Tyan on 26.01.18.
//  Copyright © 2018 Eugenie Tyan. All rights reserved.
//

#import "ViewController.h"


@implementation ViewController

@synthesize takeScreen;


//  this is a cute function for creating CGImageRef from NSImage.
//  I found it somewhere on SO but I do not remember the link, I am sorry..
CGImageRef CGImageCreateWithNSImage(NSImage *image) {
    NSSize imageSize = [image size];
    
    CGContextRef bitmapContext = CGBitmapContextCreate(NULL, imageSize.width, imageSize.height, 8, 0, [[NSColorSpace genericRGBColorSpace] CGColorSpace], kCGBitmapByteOrder32Host|kCGImageAlphaPremultipliedFirst);
    
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithGraphicsPort:bitmapContext flipped:NO]];
    [image drawInRect:NSMakeRect(0, 0, imageSize.width, imageSize.height) fromRect:NSZeroRect operation:NSCompositingOperationCopy fraction:1.0];
    [NSGraphicsContext restoreGraphicsState];
    
    CGImageRef cgImage = CGBitmapContextCreateImage(bitmapContext);
    CGContextRelease(bitmapContext);
    return cgImage;
}

NSImage* NSImageFromScreenWithRect(CGRect rect){
    
    //  copy screenshot to clipboard, works on OS X only..
    system("screencapture -c -x");
    
    //  get NSImage from clipboard..
    NSImage *imageFromClipboard=[[NSImage alloc]initWithPasteboard:[NSPasteboard generalPasteboard]];
    
    //  get CGImageRef from NSImage for further cutting..
    CGImageRef screenShotImage=CGImageCreateWithNSImage(imageFromClipboard);
    
    //  cut desired subimage from fullscreen screenshot..
    CGImageRef screenShotCenter=CGImageCreateWithImageInRect(screenShotImage,rect);
    
    //  create NSImage from CGImageRef..
    NSImage *resultImage=[[NSImage alloc]initWithCGImage:screenShotCenter size:rect.size];
    
    //  release CGImageRefs cause ARC has no effect on them..
    CGImageRelease(screenShotCenter);
    CGImageRelease(screenShotImage);
    
    return resultImage;
}
/*- (void)awakeFromNib {
    
    //Start from bottom left corner
    
    int x = 100; //possition x
    int y = 100; //possition y
    
    int width = 130;
    int height = 40;
    
    NSButton *myButton = [[NSButton alloc] initWithFrame:NSMakeRect(x, y, width, height)];
    [[windowOutlet contentView] addSubview: myButton];
    [myButton setTitle: @"Screenshot"];
    [myButton setButtonType:NSMomentaryLightButton]; //Set what type button You want
    [myButton setBezelStyle:NSRoundedBezelStyle]; //Set what style You want
    
    [myButton setTarget:self];
    [myButton setAction:@selector(buttonPressed)];
}*/
-(CGImageRef)appendMouseCursor:(CGImageRef)pSourceImage{
    // get the cursor image
    NSPoint mouseLoc;
    mouseLoc = [NSEvent mouseLocation]; //get cur
    
    // get the mouse image
    NSImage *overlay    =   [[[NSCursor arrowCursor] image] copy];
    
    int x = (int)mouseLoc.x;
    int y = (int)mouseLoc.y;
    int w = (int)[overlay size].width;
    int h = (int)[overlay size].height;
    int org_x = x;
    int org_y = y;
    
    size_t height = CGImageGetHeight(pSourceImage);
    size_t width =  CGImageGetWidth(pSourceImage);
    unsigned long bytesPerRow = CGImageGetBytesPerRow(pSourceImage);
    
    unsigned int * imgData = (unsigned int*)malloc(height*bytesPerRow);
    
    // have the graphics context now,
    CGRect bgBoundingBox = CGRectMake (0, 0, width,height);
    
    CGContextRef context =  CGBitmapContextCreate(imgData, width,
                                                  height,
                                                  8, // 8 bits per component
                                                  bytesPerRow,
                                                  CGImageGetColorSpace(pSourceImage),
                                                  CGImageGetBitmapInfo(pSourceImage));
    
    // first draw the image
    CGContextDrawImage(context,bgBoundingBox,pSourceImage);
    
    // then mouse cursor
    CGContextDrawImage(context,CGRectMake(0, 0, width,height),pSourceImage);
    
    // then mouse cursor
    CGContextDrawImage(context,CGRectMake(org_x, org_y, w,h),[overlay CGImageForProposedRect: NULL context: NULL hints: NULL] );
    
    
    // assuming both the image has been drawn then create an Image Ref for that
    
    CGImageRef pFinalImage = CGBitmapContextCreateImage(context);
    
    CGContextRelease(context);
    
    return pFinalImage; /* to be released by the caller */
}

- (IBAction)buttonPressed:(id)sender {
    system("screencapture -c -x");
    NSImage *imageFromClipboard=[[NSImage alloc]initWithPasteboard:[NSPasteboard generalPasteboard]];
    CGImageSourceRef source;
    source = CGImageSourceCreateWithData((CFDataRef)[imageFromClipboard TIFFRepresentation], NULL);
    CGImageRef imageRef =  CGImageSourceCreateImageAtIndex(source, 0, NULL);
    imageRef = [self appendMouseCursor: imageRef];
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *rawData = (unsigned char*) calloc(height * width * 4, sizeof(unsigned char));
    NSMutableArray *finalResult = [[NSMutableArray alloc]init];
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    
    // Now your rawData contains the image data in the RGBA8888 pixel format.
    NSUInteger byteIndex = 0;
    for (int i = 0 ; i < width*height; ++i)
    {
        CGFloat alpha = ((CGFloat) rawData[byteIndex + 3] ) / 255.0f;
        CGFloat red   = ((CGFloat) rawData[byteIndex]     ) / alpha;
        CGFloat green = ((CGFloat) rawData[byteIndex + 1] ) / alpha;
        CGFloat blue  = ((CGFloat) rawData[byteIndex + 2] ) / alpha;
        byteIndex += bytesPerPixel;
        [finalResult addObject: [NSNumber numberWithFloat: blue]];
        [finalResult addObject: [NSNumber numberWithFloat: green]];
        [finalResult addObject: [NSNumber numberWithFloat: red]];
    }
    
    free(rawData);
    

    //NSBitmapImageRep *imgRep = [[imageFromClipboard representations] objectAtIndex: 0];
    NSData *data = [imageFromClipboard TIFFRepresentation];
    //NSLog(@"%lu", (unsigned long)data.length);
    //NSLog(@"%lu", (unsigned long) finalResult.count);
    [data writeToFile: @"/Users/eugenietyan/Desktop/screen.jpeg" atomically: NO];
}
@end
