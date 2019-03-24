//
//  CircuitDocument.m
//  Circuitry
//
//  Created by Anthony Foster on 2/02/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import "CircuitDocument.h"
#import "AppDelegate.h"
#import "CircuitTest.h"
#import <AVFoundation/AVFoundation.h>

@interface CircuitDocument() <NSURLSessionTaskDelegate>
@property (nonatomic) NSData *originalScreenshotData;
@end

static NSString *screenshotPngPath = @"screenshot.png";

@implementation CircuitDocument
- (void) setProblemInfo:(ProblemSetProblemInfo *)problemInfo {
    _isProblem = problemInfo != nil;
    _problemInfo = problemInfo;
}
- (instancetype) initWithFileURL:(NSURL *)url {
    return [super initWithFileURL:url];
}
- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError **)outError {
    
    NSError *err;
    
    if ([typeName isEqualToString:@"public.json"]) {
        NSDictionary *full = [NSJSONSerialization JSONObjectWithData:contents options:0 error:&err];
        
        _circuit = [[Circuit alloc] initWithPackage:full items:full[@"items"]];
        if (err) return NO;
        return YES;
    }
    
    NSFileWrapper *wrapper = contents;
    NSDictionary *files = [wrapper fileWrappers];
    NSData *jsonData = [files[@"package.json"] regularFileContents];
    if (!jsonData) return NO;
    
    NSDictionary *package = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&err];
    if (err) return NO;
    
    NSArray *items = package[@"items"];
    
    if (!items) {
        items = [NSJSONSerialization JSONObjectWithData:[files[@"items.json"] regularFileContents] options:0 error:&err];
        if (err) return NO;
    }
    
    _originalScreenshotData = [files[screenshotPngPath] regularFileContents];
     
    _circuit = [[Circuit alloc] initWithPackage:package items: items];
    
    return YES;
}

- (void) useScreenshot:(UIImage *)image {
    UIImage *newImage;
    CGSize newSize = CGSizeMake(188, 188);
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0); {
        CGSize scaledSize = newSize;
        
        CGFloat x0 = 0;
        CGFloat y0 = 0;
        
        float aspect = image.size.width / image.size.height;
        
        if (image.size.width > image.size.height) {
            scaledSize.width = newSize.width * aspect;
            scaledSize.height = newSize.height;
            x0 = -(scaledSize.width - newSize.width) / 2;
        } else {
            scaledSize.width = newSize.width;
            scaledSize.height = newSize.height / aspect;
            y0 = -(scaledSize.height - newSize.height) / 2;
        }
        [image drawInRect:CGRectMake(x0, y0, scaledSize.width, scaledSize.height )];
        
        newImage = UIGraphicsGetImageFromCurrentImageContext();
    } UIGraphicsEndImageContext();

    _screenshot = newImage;
    
}

- (NSArray *) exportItems {
    
    NSMutableArray *items = [NSMutableArray array];
    [_circuit enumerateObjectsUsingBlock:^(CircuitObject *object, BOOL *stop) {
        
        NSMutableArray *outputs = [NSMutableArray arrayWithCapacity:object->type->numOutputs];
        for(int i = 0; i < object->type->numOutputs; i++) {
            NSMutableArray *linksFromOutlet = [NSMutableArray array];
            CircuitLink *link = object->outputs[i];
            while (link) {
                [linksFromOutlet addObject:@[[MongoID stringWithId:link->target->id], @(link->targetIndex)]];
                link = link->nextSibling;
            }
            [outputs addObject:linksFromOutlet];
        }
        
        NSString *name = nil;
        if (object->name != NULL) {
            name = [NSString stringWithUTF8String:object->name];
        }
        NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
        d[@"type"] = [NSString stringWithUTF8String:object->type->id];
        d[@"_id"]  = [MongoID stringWithId:object->id];
        d[@"pos"]  = @[@(object->pos.x), @(object->pos.y), @(object->pos.z)];
        d[@"name"] = name ?: @"";
        d[@"in"]   = @(object->in);
        d[@"out"]  = @(object->out);
        d[@"outputs"] = outputs;
        
        if (object->flags & CircuitObjectFlagLocked) {
            d[@"locked"] = @1;
        }
        
        
        [items addObject:d];
    }];
    return items;
}


- (NSDictionary *) exportPackageDictionaryWithoutItems {
    NSMutableArray *testsArray = [NSMutableArray arrayWithCapacity:_circuit.tests.count];
    [_circuit.tests enumerateObjectsUsingBlock:^(CircuitTest *test, NSUInteger idx, BOOL *stop) {
        [testsArray addObject:@{
                                @"name": test.name,
                                @"inputs": test.inputIds,
                                @"outputs": test.outputIds,
                                @"spec": test.spec
                                }];
    }];
    
    return @{
        @"_id": [MongoID stringWithId:_circuit.id],
        @"name": _circuit.name,
        @"version": _circuit.version,
        @"description": _circuit.userDescription,
        @"title": _circuit.title,
        @"author": _circuit.author,
        @"license": _circuit.license,
        @"engines": @{@"circuitry": @">=0.0"},
        @"tests" : testsArray,
        @"view": _circuit.viewDetails,
        @"meta": _circuit.meta
    };
    
}



- (id)contentsForType:(NSString *)typeName error:(NSError **)outError {
    if (self.isProblem) {
        [NSException raise:@"Attempted to modify problem" format:@""];
    }
//    if (!_circuit) {
//        *outError = [NSError errorWithDomain:@"au.id.af" code:501 userInfo:@{@"name": @"Circuit does not exist"}];
//        return nil;
//    }
    if ([typeName isEqualToString:@"public.json"]) {
        NSMutableDictionary *dict = [[self exportPackageDictionaryWithoutItems] mutableCopy];
        dict[@"items"] = [self exportItems];
        // Export the entire circuit into a single JSON object:
        return [NSJSONSerialization dataWithJSONObject:dict options:0 error:NULL];
    }
    
    NSJSONWritingOptions jsonOptions = 0;
    
#ifdef DEBUG
    jsonOptions = NSJSONWritingPrettyPrinted;
#endif

    NSDictionary<NSString *, NSFileWrapper *> *fileWrappers = [[NSDictionary alloc] init];
    NSFileWrapper *wrapper = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:fileWrappers];
    NSData *metaJson = [NSJSONSerialization dataWithJSONObject:[self exportPackageDictionaryWithoutItems] options:jsonOptions error:NULL];
    NSData *itemsJSON = [NSJSONSerialization dataWithJSONObject:[self exportItems] options:jsonOptions error:NULL];

    [wrapper addRegularFileWithContents:metaJson preferredFilename:@"package.json"];
    [wrapper addRegularFileWithContents:itemsJSON preferredFilename:@"items.json"];
    if (_screenshot) {
        [wrapper addRegularFileWithContents:UIImagePNGRepresentation(_screenshot) preferredFilename:screenshotPngPath];
    } else if (_originalScreenshotData) {
        [wrapper addRegularFileWithContents:_originalScreenshotData preferredFilename:screenshotPngPath];
    }
    return wrapper;
}

@end
