//
//  The MIT License (MIT)
//  Copyright (c) 2014 Lemberg Solutions Limited
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//   The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//


#import "PostController.h"
#import "BlogPostPreview.h"
#import "BlogPost.h"
#import <Social/Social.h>


@interface PostController () <UIWebViewDelegate, UIActionSheetDelegate> {
    BOOL isActionSheetOpen;
}

@property (nonatomic) BlogPost *post;
@property (strong, nonatomic) IBOutlet UIWebView *webView;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end


@implementation PostController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    BlogPost *post = [BlogPost new];
    post.nid = self.postPreview.nid;
    [post pullFromServer:^(id result) {
        if (!result) {
            [[[UIAlertView alloc] initWithTitle:@"" message:[NSString stringWithFormat:@"Could not load post \"%@\"", self.postPreview.title] delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil] show];
            [self.activityIndicator stopAnimating];
            return;
        }
        self.post = result;
        
        NSString *path = [[NSBundle mainBundle] pathForResource:@"template" ofType:@"html"];
        NSMutableString *html = [NSMutableString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
            [html replaceOccurrencesOfString:@"%ARTICLE_IMAGE_URL%" withString:self.postPreview.field_file options:(NSLiteralSearch) range:NSMakeRange(0, html.length)];
        else
            [html replaceOccurrencesOfString:@"%ARTICLE_IMAGE_URL%" withString:@"" options:(NSLiteralSearch) range:NSMakeRange(0, html.length)];
        [html replaceOccurrencesOfString:@"%ARTICLE_TITLE%" withString:self.post.title options:(NSLiteralSearch) range:NSMakeRange(0, html.length)];
        NSString *body = [NSString stringWithFormat:@"<p style=\"color: #888;\">%@</p>%@", [self.postPreview dateAndAuthor], self.post.body[@"value"]];
        [html replaceOccurrencesOfString:@"%ARTICLE_BODY%" withString:body options:(NSLiteralSearch) range:NSMakeRange(0, html.length)];
        [self.webView loadHTMLString:html baseURL:nil];
    }];
    
    self.title = self.postPreview.field_blog_category;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(share)];
}


- (void)share
{
    if (isActionSheetOpen)
        return;
    isActionSheetOpen = YES;
    [[[UIActionSheet alloc] initWithTitle:@"Share" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Facebook", @"Twitter", nil] showFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
}


#pragma mark - UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self.activityIndicator stopAnimating];
}


#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        //  Facebook
        if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
            SLComposeViewController *postSheet = [SLComposeViewController
                                                   composeViewControllerForServiceType:SLServiceTypeFacebook];
            [postSheet setInitialText:[NSString stringWithFormat:@"%@ %@", self.post.title, self.post.field_blog_url[@"url"]]];
            [self presentViewController:postSheet animated:YES completion:nil];
        } else {           
            [[[UIAlertView alloc] initWithTitle:@"" message:@"Sharing through Facebook is not available!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }
    } else if (buttonIndex == 1) {
        // Twitter
        if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
            SLComposeViewController *tweetSheet = [SLComposeViewController
                                                   composeViewControllerForServiceType:SLServiceTypeTwitter];
            [tweetSheet setInitialText:[NSString stringWithFormat:@"%@ %@", self.post.title, self.post.field_blog_url[@"url"]]];
            [self presentViewController:tweetSheet animated:YES completion:nil];
        } else {
            [[[UIAlertView alloc] initWithTitle:@"" message:@"Sharing through Twitter is not available!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }
    }
    isActionSheetOpen = NO;
}


@end
