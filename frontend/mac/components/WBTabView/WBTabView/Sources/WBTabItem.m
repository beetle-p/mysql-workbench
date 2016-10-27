/*
 * Copyright (c) 2008, 2016, Oracle and/or its affiliates. All rights reserved.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; version 2 of the
 * License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
 * 02110-1301  USA
 */

#import "WBTabItem.h"
#import "CGColorUtilities.h"

#define TAB_ITEM_WIDTH (150)
#define TAB_ITEM_SMALL_WIDTH (70)

@implementation WBTabMenuLayer

- (BOOL) acceptsMouseDownAtPoint: (CGPoint) mouse;
{
  return YES;
}

- (ResponderLayer*) mouseDownAtPoint: (CGPoint) mouse;
{
  if ([[self delegate] respondsToSelector: @selector(tabViewMenuAction:)]) {
    [[self delegate] performSelector: @selector(tabViewMenuAction:)
                          withObject: self];
  }
  
  return self;
}

@end


@interface NSObject(TabDraggerDelegate)
- (void)tabViewDragged:(WBTabDraggerLayer*)sender atPoint:(CGPoint)p;
@end

@implementation WBTabDraggerLayer

- (BOOL) acceptsMouseDownAtPoint: (CGPoint) mouse;
{
  return YES;
}

- (ResponderLayer*) mouseDownAtPoint: (CGPoint) mouse;
{
  mDragged= NO;

  mLocation.x= self.frame.size.width - mouse.x;
  mLocation.y= self.frame.size.height - mouse.y;
  
  id delegate = self.delegate;
  if ([delegate respondsToSelector: @selector(tabViewDragged:atPoint:)])
    [delegate tabViewDragged: self atPoint: mLocation];

  return self;
}

- (void) mouseDraggedToPoint: (CGPoint) mouse
{  
  id delegate = self.delegate;
  if ([delegate respondsToSelector: @selector(tabViewDragged:atPoint:)])
    [delegate tabViewDragged: self atPoint: mLocation];
  
  mDragged= YES;
}

- (void)mouseUp
{
  if (!mDragged && [[self delegate] respondsToSelector: @selector(tabViewDraggerAction:)]) {
    [[self delegate] performSelector: @selector(tabViewDraggerAction:)
                          withObject: self];
  }
}

@end



@implementation WBTabArrow

- (BOOL) acceptsMouseDownAtPoint: (CGPoint) mouse;
{
  return YES;
}

- (ResponderLayer*) mouseDownAtPoint: (CGPoint) mouse;
{
  if ([[self delegate] respondsToSelector: @selector(tabViewArrowAction:)]) {
    [[self delegate] performSelector: @selector(tabViewArrowAction:)
                          withObject: self];
  }
  
  return self;
}

- (void) setEnabled: (BOOL) yn;
{
  CALayer* iconLayer = [self sublayers][0];
  [iconLayer setOpacity: (yn ? 1 : 0.4)];
  [self setShadowOpacity: (yn ? 0.5 : 0)];
}

- (void)setFrame:(CGRect)r
{
  [super setFrame:r];
}
@end



@implementation WBCustomTabItemView

- (void) drawRect: (NSRect) rect;
{
  if (mBackgroundColor == nil) 
  {
    mBackgroundColor = [NSColor colorWithCalibratedRed: 0.88
                                                 green: 0.88
                                                  blue: 0.88
                                                 alpha: 1];
  }
  
  [super drawRect: rect];
  
  if (mBackgroundColor != nil) 
  {
    [mBackgroundColor set];
    [NSBezierPath fillRect: rect];
  }
}

- (void)setBackgroundColor: (NSColor*)backgroundColor;
{
  mBackgroundColor = backgroundColor;
  [self setNeedsDisplay: YES];
}

@end

@implementation WBTabItem

- (void)updateAppearance;
{
  [mIcon setOpacity: (mEnabled ? 1.0 : 0.7)];
  [mCloseButton setOpacity: (mEnabled ? 1.0 : 0.7)];
  [mTitleLayer setOpacity: (mEnabled ? 1.0 : 0.7)];
  
  CGColorRef c = NULL;
  if (mEnabled) {
    if (mState == NSOnState) {
      c = mColorActiveSelected;
    }
    else {
      c = mColorActiveNotSelected;
    }
  }
  else {
    if (mState == NSOnState) {
      c = mColorNotActiveSelected;
    }
    else {
      c = mColorNotActiveNotSelected;
    }
  }
  [self setBackgroundColor: c];
  
  if (mState == NSOnState) {
    [self setZPosition: -1];
    [self setShadowOpacity: 0.5];
    [self setShadowOffset: CGSizeMake(0, -0.5)];
    [self setShadowRadius: 3.0];
  }
  else {
    [self setZPosition: -3];
    [self setShadowOpacity: 0.5];
    [self setShadowOffset: CGSizeMake(0, -0.5)];
    [self setShadowRadius: 1];
  }
}



- (void) setState: (NSCellStateValue) value;
{
  NSAssert( (value == NSOffState || value == NSOnState), @"Bad argument for setState, should be NSOffState or NSOnState.");
  
  mState = value;
  [self updateAppearance];
}



- (void) setEnabled: (BOOL) enabled;
{
  mEnabled = enabled;
  [self updateAppearance];
}



- (void) setLabel: (NSString*) label;
{
  mLabel = label;
  [mTitleLayer setString: label];

  if (mTabSize == WBTabSizeLarge)
  {
    CGRect titleFrame = [mTitleLayer frame];
    titleFrame.size.width = [self preferredWidth] - 30;
    [mTitleLayer setFrame: titleFrame];
    
    CGRect frame = [self frame];
    frame.size.width = [self preferredWidth];
    [self setFrame: frame];
  }
}



- (void)setCloseButtonState: (NSCellStateValue) state;
{
  NSBundle * bundle = [NSBundle bundleForClass: self.class];
  if (state == NSOnState) {
    mCloseButtonImage = [bundle imageForResource: @"TabClose_Pressed"];
    mCloseButton.contents = mCloseButtonImage;
  }
  else if (state == NSOffState) {
    mCloseButtonImage = [bundle imageForResource: @"TabClose_Unpressed"];
    mCloseButton.contents = mCloseButtonImage;
  }
}



- (void) setDelegate: (id) delegate;
{
  NSAssert( [delegate conformsToProtocol: @protocol(WBTabItemDelegateProtocol)], @"Delegate must conform to TabItemDelegateProtocol.");
  
  [super setDelegate: delegate];
}



- (void) setIconImage: (NSImage*) image;
{
  mDocumentIconImage = image;
  
  if (image == nil)
  {
    [mIcon removeFromSuperlayer];
    mIcon = nil;
  
    CGRect titleFrame = [mTitleLayer frame];
    titleFrame.origin.x = 8;
    [mTitleLayer setFrame: titleFrame];
    [self setLabel: mLabel];
  }
  else
  {
    if (!mIcon)
    {
      mIcon = [CALayer layer];
      CGRect rect= mIcon.frame;
      mIcon.contents = mDocumentIconImage;
      rect.size= NSSizeToCGSize([image size]);
      [mIcon setFrame: rect];
      [self addSublayer: mIcon];

      CGRect titleFrame = [mTitleLayer frame];
      titleFrame.origin.x = CGRectGetMaxX(rect) + 6;
      [mTitleLayer setFrame: titleFrame];      
    }
    else
    {
      CGRect rect= mIcon.frame;
      mIcon.contents = mDocumentIconImage;
      rect.size= NSSizeToCGSize([image size]);
      [mIcon setFrame: rect];
      
      CGRect titleFrame = [mTitleLayer frame];
      titleFrame.origin.x = CGRectGetMaxX(rect) + 6;
      [mTitleLayer setFrame: titleFrame];      
    }
  }
}



- (id) identifier;
{
  return mIdentifier;
}



- (void) setColorActiveSelected: (CGColorRef) colorActiveSelected
         colorActiveNotSelected: (CGColorRef) colorActiveNotSelected
         colorNotActiveSelected: (CGColorRef) colorNotActiveSelected
      colorNotActiveNotSelected: (CGColorRef) colorNotActiveNotSelected;
{
  CGColorRelease(mColorActiveSelected);
  mColorActiveSelected = CGColorRetain(colorActiveSelected);
  
  CGColorRelease(mColorActiveNotSelected);
  mColorActiveNotSelected = CGColorRetain(colorActiveNotSelected);
  
  CGColorRelease(mColorNotActiveSelected);
  mColorNotActiveSelected = CGColorRetain(colorNotActiveSelected);
  
  CGColorRelease(mColorNotActiveNotSelected);
  mColorNotActiveNotSelected = CGColorRetain(colorNotActiveNotSelected);
}


- (CGFloat) preferredWidth;
{
  return 100;
}



#pragma mark User interaction



- (BOOL) acceptsMouseDownAtPoint: (CGPoint) mouse;
{
  return YES;
}



- (ResponderLayer*) mouseDownAtPoint: (CGPoint) mouse;
{
  mMouseDownPoint = mouse;
  
  if (CGRectContainsPoint([mCloseButton frame], mouse)) {
    mClickInCloseBox = YES;
    mMouseInCloseBox = YES;
    [self setCloseButtonState: NSOnState];
  }
  else {
    mClickInCloseBox = NO;
    mMouseInCloseBox = NO;
    [(id)[self delegate] selectTab: self];
  }
  
  return self;
}



- (void) mouseDraggedToPoint: (CGPoint) mouse;
{
  if (mClickInCloseBox) {
    // Track mouse around close box.
    BOOL inside = (CGRectContainsPoint([mCloseButton frame], mouse));
    if (mMouseInCloseBox != inside) {
      [self setCloseButtonState: (inside ? NSOnState : NSOffState)];
    }
    mMouseInCloseBox = inside;
  }
}



- (void) mouseUp;
{
  if (mMouseInCloseBox) {
    [(id)[self delegate] closeTab: self];
    [self setCloseButtonState: NSOffState];
  }
}

#pragma mark Creation & Destruction

- (void) layout;
{
}

- (instancetype) initWithIdentifier: (id) identifier
                              label: (NSString*) label
                          direction: (WBTabDirection) tabDirection
                          placement: (WBTabPlacement) tabPlacement
                               size: (WBTabSize) tabSize
                            hasIcon: (BOOL) hasIcon
                           canClose: (BOOL) canClose;
{
  self = [super init];
  
  if (self != nil) {
    mIdentifier = identifier;
    
    mTabDirection = tabDirection;
    mTabPlacement = tabPlacement;
    mTabSize = tabSize;
    
    mHasIcon = hasIcon;
    mCanClose = canClose;
    
    mState = -1;
    
    CGRect frame = CGRectZero;
    if (tabSize == WBTabSizeLarge)
      frame.size = CGSizeMake([self preferredWidth], 44);
    else
      frame.size = CGSizeMake(TAB_ITEM_SMALL_WIDTH, 32);
    [self setFrame: frame];
    
    CGFloat horizon = frame.size.height / 2;
    NSBundle* bundle = [NSBundle bundleForClass: self.class];

    if (mCanClose) {
      // Close button layer.
      mCloseButtonImage = [bundle imageForResource: @"TabClose_Unpressed"];
      
      mCloseButton = [CALayer layer];
      CGRect r = CGRectZero;
      r.size = NSSizeToCGSize([mCloseButtonImage size]);
      r.origin.x = frame.size.width - r.size.width - 6;
      if (mTabDirection == WBTabDirectionUp)
        r.origin.y = floor(horizon + (horizon / 2) - (r.size.height / 2));
      else 
        r.origin.y = floor((horizon / 2) - (r.size.height / 2));
      [mCloseButton setFrame: r];
      mCloseButton.contents = mCloseButtonImage;
      [mCloseButton setAutoresizingMask: kCALayerMinXMargin];
      [self addSublayer: mCloseButton];
    }
    
    if (mHasIcon) {
      // Icon layer.
      mDocumentIconImage = [bundle imageForResource: @"TabDocument"];
      
      mIcon = [CALayer layer];
      CGRect r = CGRectZero;
      r.size = NSSizeToCGSize([mDocumentIconImage size]);
      r.origin.x = 9;
      if (mTabDirection == WBTabDirectionUp)
        r.origin.y = floor(horizon + (horizon / 2) - (r.size.height / 2));
     else 
       r.origin.y = floor((horizon / 2) - (r.size.height / 2));
      [mIcon setFrame: r];
      mIcon.contents = mDocumentIconImage;
      [self addSublayer: mIcon];
    }
    
    {
      // Title layer.
      CGRect titleFrame = CGRectZero;
      if (mHasIcon) {
        CGRect r = [mIcon frame];
        titleFrame.origin.x = CGRectGetMaxX(r) + 6;
      }
      else {
        titleFrame.origin.x = 5;
      }
      
      titleFrame.size.height = 15;
      
      if (mHasIcon) {
        titleFrame.origin.y = [mIcon frame].origin.y - 1;
      }
      else {
        if (mTabDirection == WBTabDirectionUp) {
          titleFrame.origin.y = horizon - 1;
        }
        else {
          titleFrame.origin.y = horizon - 17;
        }
      }
      
      if (tabSize == WBTabSizeLarge)
        titleFrame.size.width = [self preferredWidth] - 50;
      else
        titleFrame.size.width = 100;
      
      mTitleLayer = [CATextLayer layer];
      [mTitleLayer setFrame: titleFrame];
      [mTitleLayer setAutoresizingMask: (kCALayerMaxXMargin | kCALayerMaxYMargin)];
      
      CGColorRef c = WB_CGColorCreateCalibratedRGB(0.1, 0.1, 0.1, 1.0);
      [mTitleLayer setForegroundColor: c];
      CGColorRelease(c);
      NSFont* font = [NSFont boldSystemFontOfSize: 0];
      [mTitleLayer setFont: (__bridge CFTypeRef _Nullable)(font)];
      if (mTabSize == WBTabSizeLarge) {
        [mTitleLayer setFontSize: 11.5];
        CGColorRef shadowColor = WB_CGColorCreateCalibratedRGB(1.0, 1.0, 1.0, 1.0);
        [mTitleLayer setShadowColor: shadowColor];
        CGColorRelease(shadowColor);
        [mTitleLayer setShadowOpacity: 1];
        [mTitleLayer setShadowOffset: CGSizeMake(0, -0.5)];
        [mTitleLayer setShadowRadius: 0.0];
      }
      else {
        [mTitleLayer setFontSize: 9];
      }
      
      [self addSublayer: mTitleLayer];
    }
    
    [self setLabel: label];
    
    frame.size.width = [self preferredWidth];
    [self setFrame: frame];
    
    [self setState: NSOffState];
    [self setEnabled: YES];
  }
  
  return self;
}

+ (WBTabItem*) tabItemWithIdentifier: (id) identifier
                               label: (NSString*) label
                           direction: (WBTabDirection) tabDirection
                           placement: (WBTabPlacement) tabPlacement
                                size: (WBTabSize) tabSize
                             hasIcon: (BOOL) hasIcon
                            canClose: (BOOL) canClose;
{
  return [[WBTabItem alloc] initWithIdentifier: identifier
                                         label: label
                                     direction: tabDirection
                                     placement: tabPlacement
                                          size: tabSize
                                       hasIcon: hasIcon
                                      canClose: canClose];
}

- (void) dealloc
{
  
  CGColorRelease(mColorActiveSelected);
  CGColorRelease(mColorActiveNotSelected);
  CGColorRelease(mColorNotActiveSelected);
  CGColorRelease(mColorNotActiveNotSelected);
}

@end


