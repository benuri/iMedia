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


// Author: Peter Baumgartner


//----------------------------------------------------------------------------------------------------------------------


#pragma mark HEADERS

#import "IMBParser.h"
#import "NSWorkspace+iMedia.h"
#import "IMBNode.h"
#import "IMBObject.h"
#import "NSURL+iMedia.h"
//#import "IMBObjectsPromise.h"
//#import "IMBLibraryController.h"
//#import "NSString+iMedia.h"
//#import "NSData+SKExtensions.h"
//#import <Quartz/Quartz.h>
//#import <QTKit/QTKit.h>
//#import "NSURL+iMedia.h"


//----------------------------------------------------------------------------------------------------------------------


#pragma mark

@interface IMBParser ()

//+ (CGImageSourceRef) _imageSourceForURL:(NSURL*)inURL;
//+ (CGImageRef) _imageForURL:(NSURL*)inURL;

- (NSArray*) _identifiersOfPopulatedSubnodesOfNode:(IMBNode*)inNode;
- (void) _identifiersOfPopulatedSubnodesOfNode:(IMBNode*)inNode identifiers:(NSMutableArray*)inIdentifiers;
- (void) _populateNodeTree:(IMBNode*)inNode populatedNodeIdentifiers:(NSArray*)inPopulatedNodeIdentifiers error:(NSError**)outError;

@end


//----------------------------------------------------------------------------------------------------------------------


#pragma mark 

@implementation IMBParser

@synthesize identifier = _identifier;
@synthesize mediaType = _mediaType;
@synthesize mediaSource = _mediaSource;


//----------------------------------------------------------------------------------------------------------------------


#pragma mark 


- (id) init
{
	if (self = [super init])
	{
		self.identifier = nil;
		self.mediaType = nil;
		self.mediaSource = nil;
	}
	
	return self;
}


- (void) dealloc
{
	IMBRelease(_identifier);
	IMBRelease(_mediaSource);
	IMBRelease(_mediaType);
	[super dealloc];
}


//----------------------------------------------------------------------------------------------------------------------


#pragma mark 
#pragma mark Node Creation


// To be overridden by subclasses...

- (IMBNode*) unpopulatedTopLevelNode:(NSError**)outError
{
	return nil;
}


- (void) populateNode:(IMBNode*)inNode error:(NSError**)outError
{

}


//----------------------------------------------------------------------------------------------------------------------


// This generic implementation may be sufficient for most subclasses. First remember how deeply the node  
// tree was populated. Then recreate this node. Finally repopulate the node tree to the same depth...

- (IMBNode*) reloadNodeTree:(IMBNode*)inNode error:(NSError**)outError
{
	NSError* error = nil;
	IMBNode* newNode = nil;
	NSArray* identifiers = [self _identifiersOfPopulatedSubnodesOfNode:inNode];

	if (inNode.isTopLevelNode)
	{
		newNode = [self unpopulatedTopLevelNode:&error];
	}
	else
	{
		newNode = inNode;
	}
	
	if (newNode)
	{
		[self _populateNodeTree:newNode populatedNodeIdentifiers:identifiers error:&error];
	}
	
	if (outError) *outError = error;
	return newNode;
}


// Gather the identifiers of all populated subnodes...

- (NSArray*) _identifiersOfPopulatedSubnodesOfNode:(IMBNode*)inNode
{
	NSMutableArray* identifiers = [NSMutableArray array];
	[self _identifiersOfPopulatedSubnodesOfNode:inNode identifiers:identifiers];
	return (NSArray*)identifiers;
}

- (void) _identifiersOfPopulatedSubnodesOfNode:(IMBNode*)inNode identifiers:(NSMutableArray*)inIdentifiers
{
	if (inNode.isPopulated)
	{
		[inIdentifiers addObject:inNode.identifier];
		
		for (IMBNode* subnode in inNode.subnodes)
		{
			[self _identifiersOfPopulatedSubnodesOfNode:subnode identifiers:inIdentifiers];
		}
	}
}


// 
- (void) _populateNodeTree:(IMBNode*)inNode populatedNodeIdentifiers:(NSArray*)inPopulatedNodeIdentifiers error:(NSError**)outError
{
	NSError* error = nil;

	if ([inPopulatedNodeIdentifiers indexOfObject:inNode.identifier] != NSNotFound)
	{
		[inNode unpopulate];
		[self populateNode:inNode error:&error];
		
		if (error == nil)
		{
			for (IMBNode* subnode in inNode.subnodes)
			{
				[self _populateNodeTree:subnode populatedNodeIdentifiers:inPopulatedNodeIdentifiers error:&error];
				if (error) break;
			}
		}
	}
	
	if (outError) *outError = error;
}


//----------------------------------------------------------------------------------------------------------------------


// Optional methods that do nothing in the base class and can be overridden in subclasses, e.g. to   
// updateor get rid of cached data...

/*
- (void) willStartUsingParser
{

}


- (void) didStopUsingParser
{

}
*/

//----------------------------------------------------------------------------------------------------------------------


#pragma mark
#pragma mark Object Access


// The default implementation create a thumbnail for local image files. If inObject does not represent a local
// image file, then this method MUST be overridden in the subclass...

- (id) thumbnailForObject:(IMBObject*)inObject error:(NSError**)outError
{
//	if (outError) *outError = nil;
//	return nil;

	return (id)[self thumbnailFromLocalImageFileForObject:inObject error:outError];

//	NSError* error = nil;
//	CGImageRef thumbnail = NULL;
//	NSURL* url = [inObject imageLocation] ? [inObject imageLocationURL] : [inObject URL];
//	CGImageSourceRef source = NULL;
//    
//    source = CGImageSourceCreateWithURL((CFURLRef)url,NULL);
//	
//	if (source)
//	{
//        if ([inObject imageLocation])
//        {
//            thumbnail = CGImageSourceCreateImageAtIndex(source,0,NULL);
//        } 
//		else 
//		{
//            NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:
//                                     (id)kCFBooleanTrue,kCGImageSourceCreateThumbnailFromImageIfAbsent,
//                                     (id)[NSNumber numberWithInteger:256],kCGImageSourceThumbnailMaxPixelSize,
//                                     (id)kCFBooleanTrue,kCGImageSourceCreateThumbnailWithTransform,
//                                     nil];
//            
//            thumbnail = CGImageSourceCreateThumbnailAtIndex(source,0,(CFDictionaryRef)options);
//        }
//        CFRelease(source);
//	} 
//	else 
//	{
//        NSString* description = [NSString stringWithFormat:@"URL not found: %@",url];
//        NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:description,NSLocalizedDescriptionKey,nil];
//        error = [NSError errorWithDomain:kIMBErrorDomain code:fnfErr userInfo:info];
//    }
//    
//    if (thumbnail)
//    {
//        [NSMakeCollectable(thumbnail) autorelease];
//    } 
//	else 
//	{
//        NSString* description = [NSString stringWithFormat:@"Could not create image from URL: %@",url];
//        NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:description,NSLocalizedDescriptionKey,nil];
//        error = [NSError errorWithDomain:kIMBErrorDomain code:0 userInfo:info];
//    }
//	
//	if (outError) *outError = error;
//	return (id)thumbnail;
}


//----------------------------------------------------------------------------------------------------------------------


// To be overridden by subclasses...

- (NSDictionary*) metadataForObject:(IMBObject*)inObject error:(NSError**)outError
{
	if (outError) *outError = nil;
	return nil;
}


//----------------------------------------------------------------------------------------------------------------------


// This is a generic implementation for creating a security scoped bookmark oflocal media files. If assumes  
// that the url to the local file is stored in inObject.location. May be overridden by subclasses...

- (NSData*) bookmarkForObject:(IMBObject*)inObject error:(NSError**)outError
{
	NSError* error = nil;
	NSURL* baseURL = inObject.bookmarkBaseURL;
	NSURL* fileURL = inObject.URL;
	NSData* bookmark = nil;
	
	if ([fileURL isFileURL])
	{
		bookmark = [fileURL 
			bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
			includingResourceValuesForKeys:nil
			relativeToURL:baseURL 
			error:&error];
	}
	else
	{
        NSString* description = [NSString stringWithFormat:@"Could not create bookmark for non file URL: %@",fileURL];
        NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:description,NSLocalizedDescriptionKey,nil];
        error = [NSError errorWithDomain:kIMBErrorDomain code:paramErr userInfo:info];
	}
	
	if (outError) *outError = error;
	return bookmark;
}


//----------------------------------------------------------------------------------------------------------------------

/*
+ (id) loadThumbnailForObject:(IMBObject*)ioObject
{
	id imageRepresentation = nil;
	NSString* type = ioObject.imageRepresentationType;
	NSString* path = nil;
	NSURL* url = nil;
	
	// Get path/url location of our object...
	
	id location = ioObject.imageLocation;
	if (location == nil) location = ioObject.location;

	if ([location isKindOfClass:[NSString class]])
	{
		path = (NSString*)location;
		url = [NSURL fileURLWithPath:path];
	}	
	else if ([location isKindOfClass:[NSURL class]])
	{
		url = (NSURL*)location;
		path = [url path];
	}
	
	// Get the uti for out object...
	
	NSString* uti = [NSString imb_UTIForFileAtPath:path];
	
	// Path...
	
	if ([type isEqualToString:IKImageBrowserPathRepresentationType])
	{
		imageRepresentation = path;	
	}
	else if ([type isEqualToString:IKImageBrowserQTMoviePathRepresentationType])
	{
		imageRepresentation = path;	
	}
	else if ([type isEqualToString:IKImageBrowserIconRefPathRepresentationType])
	{
		imageRepresentation = path;	
	}
	else if ([type isEqualToString:IKImageBrowserQuickLookPathRepresentationType])
	{
		imageRepresentation = path;	
	}
	
	// URL...
	
	else if ([type isEqualToString:IKImageBrowserNSURLRepresentationType])
	{
		imageRepresentation = url;	
	}
	
	// NSImage...
	
	else if ([type isEqualToString:IKImageBrowserNSImageRepresentationType])
	{
		// If this is the type, we should already have an image representation, so let's try NOT 
		// doing this code that was here before.
		// So just leave the imageRepresentation here nil so it doesn't get set.
		if (!ioObject.imageRepresentation)
		{
			NSLog(@"##### %p Warning; IKImageBrowserNSImageRepresentationType with a nil imageRepresentation",ioObject);
		}
		
//		if (UTTypeConformsTo((CFStringRef)uti,kUTTypeImage))
//		{
//			imageRepresentation = [[[NSImage alloc] initByReferencingURL:url] autorelease];
//		}
//		else
//		{
//			imageRepresentation = [url imb_quicklookNSImage];
//		}	
	}
	
	// CGImage...
	
	else if ([type isEqualToString:IKImageBrowserCGImageRepresentationType])
	{
		if (UTTypeConformsTo((CFStringRef)uti,kUTTypeImage))
		{
			imageRepresentation = (id)[self _imageForURL:url];
		}
		else
		{
			imageRepresentation = (id)[url imb_quicklookCGImage];
		}
	}
	
	// CGImageSourceRef...
	
	else if ([type isEqualToString:IKImageBrowserCGImageSourceRepresentationType])
	{
		CGImageSourceRef source = [self _imageSourceForURL:url];
		imageRepresentation = (id)source;
	}
	
	// NSData...
	
	else if ([type isEqualToString:IKImageBrowserNSDataRepresentationType])
	{
		NSData* data = [NSData dataWithContentsOfURL:url];
		imageRepresentation = data;
	}
	
	// NSBitmapImageRep...
	
	else if ([type isEqualToString:IKImageBrowserNSBitmapImageRepresentationType])
	{
		if (UTTypeConformsTo((CFStringRef)uti,kUTTypeImage))
		{
			CGImageRef image = [self _imageForURL:url];
			imageRepresentation = [[[NSBitmapImageRep alloc] initWithCGImage:image] autorelease];
		}
		else
		{
			CGImageRef image = [url imb_quicklookCGImage];
			imageRepresentation = [[[NSBitmapImageRep alloc] initWithCGImage:image] autorelease];
		}
	}
	
	// QTMovie...
	
	else if ([type isEqualToString:IKImageBrowserQTMovieRepresentationType])
	{
		NSLog(@"loadThumbnailForObject: what do to with IKImageBrowserQTMovieRepresentationType");
	}

	// Return the result to the main thread...
	
	if (imageRepresentation)
	{
		[ioObject 
			performSelectorOnMainThread:@selector(setImageRepresentation:) 
			withObject:imageRepresentation 
			waitUntilDone:NO 
			modes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
	}
	
	return imageRepresentation;
}
*/

//----------------------------------------------------------------------------------------------------------------------


// This helper method makes sure that the new node tree is pre-populated as deep as the old one was. Obviously
// this is a recursive method that descends into the tree as far as necessary to recreate the state...

//- (void) populateNewNode:(IMBNode*)inNewNode likeOldNode:(const IMBNode*)inOldNode options:(IMBOptions)inOptions
//{
//	NSError* error = nil;
//	
//	if (inOldNode.isPopulated)
//	{
//		[self populateNode:inNewNode options:inOptions error:&error];
//		
//		for (IMBNode* oldSubnode in inOldNode.subnodes)
//		{
//			NSString* identifier = oldSubnode.identifier;
//			IMBNode* newSubnode = [inNewNode subnodeWithIdentifier:identifier];
//			[self populateNewNode:newSubnode likeOldNode:oldSubnode options:inOptions];
//		}
//	}
//}


//----------------------------------------------------------------------------------------------------------------------


#pragma mark
#pragma mark Helpers


// This helper method can be used by subclasses to construct identifiers of form "classname://path/to/node"...
 
+ (NSString*) identifierForPath:(NSString*)inPath
{
	NSString* parserClassName = NSStringFromClass(self);
	return [NSString stringWithFormat:@"%@:/%@",parserClassName,inPath];
}


//----------------------------------------------------------------------------------------------------------------------


// This method makes sure that we have an image with a bitmap representation that can be archived...

- (NSImage*) iconForPath:(NSString*)inPath
{
	NSWorkspace* workspace = [NSWorkspace imb_threadSafeWorkspace];

	NSImage* image = [workspace iconForFile:inPath];
	[image setSize:NSMakeSize(16,16)];
	NSData* tiff = [image TIFFRepresentation];
//	NSBitmapImageRep* bitmap = [NSBitmapImageRep imageRepWithData:tiff];
	
	NSImage* icon = [[[NSImage alloc] initWithData:tiff] autorelease];
	[icon setSize:NSMakeSize(16,16)];
	return icon;
}


//----------------------------------------------------------------------------------------------------------------------


// Creates a thumbnail for local image files. Either location or imageLocation of inObject must contain a fileURL. 
// If imageLocation is set then the corresponding image is returned. Otherwise a downscaled image based on location 
// is returned...

- (CGImageRef) thumbnailFromLocalImageFileForObject:(IMBObject*)inObject error:(NSError**)outError
{
	NSError* error = nil;
	NSURL* url = nil;
	CGImageSourceRef source = NULL;
	CGImageRef thumbnail = NULL;
	BOOL shouldScaleDown = NO;
	
	// Choose the most appropriate file url and whether we should scale down to generate a thumbnail...
	
	if (error == nil)
	{
		if (inObject.imageLocation)
		{
			url = inObject.imageLocation;
			shouldScaleDown = NO;
		}
		else
		{
			url = inObject.URL;
			shouldScaleDown = YES;
		}
	}
	
	// Create an image source...
	
	if (error == nil)
	{
		source = CGImageSourceCreateWithURL((CFURLRef)url,NULL);
		
		if (source == nil)
		{
			NSString* description = [NSString stringWithFormat:@"Could find image file at %@",url];
			NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:description,NSLocalizedDescriptionKey,nil];
			error = [NSError errorWithDomain:kIMBErrorDomain code:fnfErr userInfo:info];
		}
	}

	// Render the thumbnail...
	
	if (error == nil)
	{
		if (shouldScaleDown)
		{
            NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:
				(id)kCFBooleanTrue,kCGImageSourceCreateThumbnailFromImageIfAbsent,
				(id)[NSNumber numberWithInteger:256],kCGImageSourceThumbnailMaxPixelSize,
				(id)kCFBooleanTrue,kCGImageSourceCreateThumbnailWithTransform,
				nil];
            
            thumbnail = CGImageSourceCreateThumbnailAtIndex(source,0,(CFDictionaryRef)options);
		}
		else
		{
            thumbnail = CGImageSourceCreateImageAtIndex(source,0,NULL);
		}
		
		if (thumbnail == nil)
		{
			NSString* description = [NSString stringWithFormat:@"Could not create image from URL: %@",url];
			NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:description,NSLocalizedDescriptionKey,nil];
			error = [NSError errorWithDomain:kIMBErrorDomain code:0 userInfo:info];
		}
	}
	
	// Cleanup...
	
	if (source) CFRelease(source);

	[NSMakeCollectable(thumbnail) autorelease];
	if (outError) *outError = error;
	return thumbnail;
}


//----------------------------------------------------------------------------------------------------------------------


// This generic method uses Quicklook to generate a thumbnail image. If can be used for any file...

- (CGImageRef) thumbnailFromQuicklookForObject:(IMBObject*)inObject error:(NSError**)outError
{
	NSError* error = nil;
	NSURL* url = inObject.URL;
	CGImageRef thumbnail = [url imb_quicklookCGImage];
	if (outError) *outError = error;
	return thumbnail;
}


//----------------------------------------------------------------------------------------------------------------------


@end


