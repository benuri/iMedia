/*
 iMedia Browser Framework <http://karelia.com/imedia/>
 
 Copyright (c) 2005-2012 by Karelia Software et al.
 
 iMedia Browser is based on code originally developed by Jason Terhorst,
 further developed for Sandvox by Greg Hulands, Dan Wood, and Terrence Talbot.
 The new architecture for version 2.0 was developed by Peter Baumgartner.
 Contributions have also been made by Matt Gough, Martin Wennerberg and others
 as indicated in source files.
 
 The iMedia Browser Framework is licensed under the following terms:
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in all or substantial portions of the Software without restriction, including
 without limitation the rights to use, copy, modify, merge, publish,
 distribute, sublicense, and/or sell copies of the Software, and to permit
 persons to whom the Software is furnished to do so, subject to the following
 conditions:
 
 Redistributions of source code must retain the original terms stated here,
 including this list of conditions, the disclaimer noted below, and the
 following copyright notice: Copyright (c) 2005-2012 by Karelia Software et al.
 
 Redistributions in binary form must include, in an end-user-visible manner,
 e.g., About window, Acknowledgments window, or similar, either a) the original
 terms stated here, including this list of conditions, the disclaimer noted
 below, and the aforementioned copyright notice, or b) the aforementioned
 copyright notice and a link to karelia.com/imedia.
 
 Neither the name of Karelia Software, nor Sandvox, nor the names of
 contributors to iMedia Browser may be used to endorse or promote products
 derived from the Software without prior and express written permission from
 Karelia Software or individual contributors, as appropriate.
 
 Disclaimer: THE SOFTWARE IS PROVIDED BY THE COPYRIGHT OWNER AND CONTRIBUTORS
 "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
 LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE,
 AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY, WHETHER IN AN ACTION OF
 CONTRACT, TORT, OR OTHERWISE, ARISING FROM, OUT OF, OR IN CONNECTION WITH, THE
 SOFTWARE OR THE USE OF, OR OTHER DEALINGS IN, THE SOFTWARE.
 */


// Author: Jörg Jacobsen


//----------------------------------------------------------------------------------------------------------------------


#import "IMBFaceNodeObject.h"
#import "NSObject+iMedia.h"
#import "IMBAppleMediaParser.h"
#import "IMBParserMessenger.h"

@interface IMBFaceNodeObject ()

@property(retain) NSString *currentImageKey;
@property(retain) NSNumber *currentFaceIndex;

@end


@implementation IMBFaceNodeObject

@synthesize currentImageKey = _currentImageKey;
@synthesize currentFaceIndex = _currentFaceIndex;


- (id) initWithCoder:(NSCoder*)inCoder
{
	if (self = [super initWithCoder:inCoder])
	{
		self.currentImageKey = [inCoder decodeObjectForKey:@"currentImageKey"];
		self.currentFaceIndex = [inCoder decodeObjectForKey:@"currentFaceIndex"];
	}
	
	return self;
}


- (void) encodeWithCoder:(NSCoder*)inCoder
{
	[super encodeWithCoder:inCoder];
	
	[inCoder encodeObject:self.currentImageKey forKey:@"currentImageKey"];
	[inCoder encodeObject:self.currentFaceIndex forKey:@"currentFaceIndex"];
}


#pragma mark - IMBSkimmableObject must subclass


- (void) setCurrentSkimmingIndex:(NSUInteger)skimmingIndex
{
    [super setCurrentSkimmingIndex:skimmingIndex];
    
    if (skimmingIndex != NSNotFound)
    {
        // We are currently skimming on the image
        
        _currentImageKey = [[self.preliminaryMetadata objectForKey:@"KeyList"] objectAtIndex:skimmingIndex];
        
        // Get the metadata of the nth image in which this face occurs 
        NSDictionary* imageFaceMetadata = [[[self preliminaryMetadata] objectForKey:@"ImageFaceMetadataList"] objectAtIndex:skimmingIndex];
        
        // What is the number of this face inside of this image?
        _currentFaceIndex = [imageFaceMetadata objectForKey:@"face index"];
        
    } else {
        // We just initialized the object or left the image while skimming and thus restore the key image
        
        _currentImageKey = [self.preliminaryMetadata objectForKey:@"KeyPhotoKey"];
        
        // What is the number of this face inside of this image?
        _currentFaceIndex = [[self preliminaryMetadata] objectForKey:@"key image face index"];
    }
}


// Returns a sparse copy of self that carrys just enough data to load its thumbnail.
// Self must have a current image key and face index set because copy cannot provide thumbnail otherwise.
//
- (IMBSkimmableObject *)thumbnailProvider
{
    // Copy must have a current image key and face index set to be able to provide thumbnail
    NSAssert1(self.currentImageKey != nil, @"Must set current image key on skimmable object %@ before loading thumbnail", self);
    NSAssert1(self.currentFaceIndex != nil, @"Must set current face index on skimmable object %@ before loading thumbnail", self);
    
    IMBFaceNodeObject *copy = [[[IMBFaceNodeObject alloc] init] autorelease];
    copy.imageRepresentationType = self.imageRepresentationType;
    copy.currentImageKey = self.currentImageKey;
    copy.currentFaceIndex = self.currentFaceIndex;
    copy.parserIdentifier = self.parserIdentifier;
    
    return copy;
}


//----------------------------------------------------------------------------------------------------------------------
// Returns the image location that corresponds to the current skimming index

- (id) imageLocationForCurrentSkimmingIndex
{
	IMBAppleMediaParser *parser = (IMBAppleMediaParser *)[self.parserMessenger parserWithIdentifier:self.parserIdentifier];
    
    return [NSURL fileURLWithPath:[parser imagePathForFaceIndex:self.currentFaceIndex inImageWithKey:self.currentImageKey] isDirectory:NO];
}


//----------------------------------------------------------------------------------------------------------------------
// Returns the image location that corresponds to the skimming index provided

- (id) imageLocationAtSkimmingIndex:(NSUInteger)skimmingIndex
{
    NSString* imageKey = [[self.preliminaryMetadata objectForKey:@"KeyList"] objectAtIndex:skimmingIndex];
    IMBAppleMediaParser *parser = (IMBAppleMediaParser *)[self.parserMessenger parserWithIdentifier:self.parserIdentifier];
    
    // Get the metadata of the nth image in which this face occurs 
    NSDictionary* imageFaceMetadata = [[[self preliminaryMetadata] objectForKey:@"ImageFaceMetadataList"] objectAtIndex:skimmingIndex];
    
    // What is the number of this face inside of this image?
    NSNumber* faceIndex = [imageFaceMetadata objectForKey:@"face index"];
    
    // A clipped image of this face in this image is stored in the filesystem
    NSString* imagePath = [parser imagePathForFaceIndex:faceIndex inImageWithKey:imageKey];
    
    return [NSURL fileURLWithPath:imagePath isDirectory:NO];
}


//----------------------------------------------------------------------------------------------------------------------
// Returns the image location of the key image

- (id) keyImageLocation
{
	NSString* imageKey = [self.preliminaryMetadata objectForKey:@"KeyPhotoKey"];
	IMBAppleMediaParser *parser = (IMBAppleMediaParser *)[self.parserMessenger parserWithIdentifier:self.parserIdentifier];
	
    // What is the number of this face inside of this image?
    NSNumber* faceIndex = [[self preliminaryMetadata] objectForKey:@"key image face index"];
    
    // A clipped image of this face in this image is stored in the filesystem
    NSString* imagePath = [parser imagePathForFaceIndex:faceIndex inImageWithKey:imageKey];
    
    return [NSURL fileURLWithPath:imagePath isDirectory:NO];
}


- (NSUInteger) imageCount
{
	return [[self.preliminaryMetadata objectForKey:@"KeyList"] count];
}

@end
