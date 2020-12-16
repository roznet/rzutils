//  MIT Licence
//
//  Created on 12/02/2016.
//
//  Copyright (c) 2016 Brice Rosenzweig.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//  

#import "RZRegressionManager.h"
#import "RZMacros.h"

@interface RZRegressionManager ()
@property (nonatomic,retain) NSString * testName;

@end

@implementation RZRegressionManager

#if ! __has_feature(objc_arc)
-(void)dealloc{
    [_testName release];
    [super dealloc];
}
#endif
+(instancetype)managerForTestClass:(Class)cl{
    RZRegressionManager * rv = RZReturnAutorelease([[RZRegressionManager alloc] init]);
    if (rv) {
        rv.testName = NSStringFromClass(cl);
    }
    return rv;
}
+(instancetype)managerForTestName:(NSString*)name{
    RZRegressionManager * rv = RZReturnAutorelease([[RZRegressionManager alloc] init]);
    if (rv) {
        rv.testName = name;
    }
    return rv;
}

-(id)retrieveReferenceObject:(NSObject<NSSecureCoding>*)object
                    forClasses:(NSSet<Class>*)cls
                    selector:(SEL)sel
                  identifier:(NSString*)ident
                       error:(NSError**)error{

    id rv = nil;

    NSFileManager * fileManager = [NSFileManager defaultManager];

    NSString * filepath = [self filePathForSelector:sel andIdentifier:ident];

    if (self.recordMode) {
        NSError * creationError = nil;
        BOOL didCreateDir = [fileManager createDirectoryAtPath:[filepath stringByDeletingLastPathComponent]
                                    withIntermediateDirectories:YES
                                                     attributes:nil
                                                          error:&creationError];
        if (didCreateDir) {
            //archivedDataWithRootObject:requiringSecureCoding:error
            BOOL success = false;
            if( error){
                *error = nil;
            }
            
            if( object ){
                success = [[NSKeyedArchiver archivedDataWithRootObject:object requiringSecureCoding:YES error:error] writeToFile:filepath atomically:YES];
                if( success ){
                    rv = object;
                }
            }
            if( success ){
                if (error && !*error) {
                    *error = [NSError errorWithDomain:@"RZRegressionManager" code:ENOENT userInfo:nil];
                }
            }
        }else{
            if (creationError) {
                if (error) {
                    *error = creationError;
                }
            }
        }

    }else{
        if( [fileManager fileExistsAtPath:filepath] ){
            if( @available(iOS 12.0, *)){
                
                NSData * data = [NSData dataWithContentsOfFile:filepath];
                
                rv = [NSKeyedUnarchiver unarchivedObjectOfClasses:cls fromData:data error:error];
            }

        }else{
            if (error) {
                *error = [NSError errorWithDomain:@"RZRegressionManager" code:ENOENT userInfo:nil];
            }
        }
    }

    return  rv;
}

-(NSString*)filePathForSelector:(SEL)selector andIdentifier:(NSString*)identifier{
    
    NSCharacterSet *specialCharactersToRemove = [NSCharacterSet characterSetWithCharactersInString:@":'#%^&{}[]/~|?"];
    NSString * filename = NSStringFromSelector(selector);
    if (identifier && identifier.length > 0) {
        filename = [filename stringByAppendingFormat:@"_%@.obj", identifier];
    }

    filename = [[filename componentsSeparatedByCharactersInSet:specialCharactersToRemove] componentsJoinedByString:@""];
    
    NSString * rv = [self referenceDirectory];
    rv = [rv stringByAppendingPathComponent:self.testName];
    rv = [rv stringByAppendingPathComponent:filename];

    return rv;
}

-(NSString*)referenceDirectory{
    NSString *envReferenceImageDirectory = [NSProcessInfo processInfo].environment[@"RZ_REFERENCE_OBJECT_DIR"];
    if (envReferenceImageDirectory) {
        return envReferenceImageDirectory;
    }
    return [[NSBundle bundleForClass:self.class].resourcePath stringByAppendingPathComponent:@"ReferenceObjects"];
}

@end
