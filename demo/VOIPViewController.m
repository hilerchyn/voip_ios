/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#include <arpa/inet.h>
#import <AVFoundation/AVAudioSession.h>
#import <UIKit/UIKit.h>
#import <voipengine/VOIPEngine.h>
#import <voipengine/VOIPRenderView.h>
#import "VOIPViewController.h"

#import <voipsession/VOIPSession.h>

#import "ReflectionView.h"
#import "UIView+Toast.h"


#define kBtnWidth  72
#define kBtnHeight 72

#define kBtnSqureWidth  200
#define kBtnSqureHeight 50

#define KheaderViewWH  100

#define kBtnYposition  (self.view.frame.size.height - 2.5*kBtnSqureHeight)

//RGB颜色
#define RGBCOLOR(r,g,b) [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f alpha:1]

@interface VOIPViewController ()<VOIPSessionDelegate, RTMessageObserver>

@property(nonatomic) UIButton *hangUpButton;
@property(nonatomic) UIButton *acceptButton;
@property(nonatomic) UIButton *refuseButton;

@property(nonatomic) UILabel *durationLabel;
@property(nonatomic) ReflectionView *headView;
@property(nonatomic) NSTimer *refreshTimer;

@property(nonatomic) NSTimer *pingTimer;

@property(nonatomic) UInt64  conversationDuration;

@property(nonatomic) AVAudioPlayer *player;

@property(nonatomic) BOOL isConnected;

@end

@implementation VOIPViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


-(void)dealloc {
    NSLog(@"voip view controller dealloc");
}

-(BOOL)isP2P {
    if (self.voip.localNatMap.ip != 0 && self.voip.peerNatMap.ip != 0 ) {
        return YES;
    }

    return NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    
    self.conversationDuration = 0;
    
    // Do any additional setup after loading the view, typically from a nib.
    [self.view setBackgroundColor:[UIColor whiteColor]];
    

    
    UIImageView *imgView = [[UIImageView alloc]
                            initWithFrame:CGRectMake(0,0, KheaderViewWH,
                                                     KheaderViewWH)];
    

    imgView.image = [UIImage imageNamed:@"PersonalChat"];
    
    CALayer *imageLayer = [imgView layer];  //获取ImageView的层
    [imageLayer setMasksToBounds:YES];
    [imageLayer setCornerRadius:imgView.frame.size.width / 2];
    
    self.headView = [[ReflectionView alloc] initWithFrame:CGRectMake((self.view.frame.size.width-KheaderViewWH)/2,80, KheaderViewWH,KheaderViewWH)];
    self.headView.alpha = 0.9f;
    self.headView.reflectionScale = 0.3f;
    self.headView.reflectionGap = 1.0f;
    [self.headView addSubview:imgView];
    
    [self.view addSubview:self.headView];
    
    
    self.durationLabel = [[UILabel alloc] init];
    [self.durationLabel setFont:[UIFont systemFontOfSize:23.0f]];
    [self.durationLabel setTextAlignment:NSTextAlignmentCenter];
    [self.durationLabel sizeToFit];
    [self.durationLabel setTextColor: RGBCOLOR(11, 178, 39)];
    [self.durationLabel setHidden:YES];
    [self.view addSubview:self.durationLabel];
    [self.durationLabel setCenter:CGPointMake((self.view.frame.size.width)/2, self.headView.frame.origin.y + self.headView.frame.size.height + 50)];
    [self.durationLabel setBackgroundColor:[UIColor clearColor]];
    
    
    self.acceptButton = [UIButton buttonWithType:UIButtonTypeCustom];

    self.acceptButton.frame = CGRectMake(30.0f, self.view.frame.size.height - kBtnHeight - kBtnHeight, kBtnWidth, kBtnHeight);
    
    [self.acceptButton setBackgroundImage: [UIImage imageNamed:@"Call_Ans"] forState:UIControlStateNormal];
    
    [self.acceptButton setBackgroundImage:[UIImage imageNamed:@"Call_Ans_p"] forState:UIControlStateHighlighted];
    [self.acceptButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.acceptButton addTarget:self
                   action:@selector(acceptCall:)
         forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.acceptButton];
    [self.acceptButton setCenter:CGPointMake(self.view.frame.size.width/4, kBtnYposition)];
    
    
    self.refuseButton = [UIButton buttonWithType:UIButtonTypeCustom];

    self.refuseButton.frame = CGRectMake(0,0, kBtnWidth, kBtnHeight);
    
    [self.refuseButton setBackgroundImage:[UIImage imageNamed:@"Call_hangup"] forState:UIControlStateNormal];
    [self.refuseButton setBackgroundImage:[UIImage imageNamed:@"Call_hangup_p"] forState:UIControlStateHighlighted];
    [self.refuseButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.refuseButton addTarget:self
                   action:@selector(refuseCall:)
         forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.refuseButton];
    [self.refuseButton setCenter:CGPointMake(self.view.frame.size.width/4 + self.view.frame.size.width/2, kBtnYposition)];
    
    
    self.hangUpButton = [[UIButton alloc] initWithFrame:CGRectMake(0,0, kBtnSqureWidth, kBtnSqureHeight)];
    [self.hangUpButton setBackgroundImage:[UIImage imageNamed:@"refuse_nor"] forState:UIControlStateNormal];
    [self.hangUpButton setBackgroundImage:[UIImage imageNamed:@"refuse_pre"] forState:UIControlStateHighlighted];
    [self.hangUpButton setTitle:@"挂断" forState:UIControlStateNormal];
    [self.hangUpButton.titleLabel setFont:[UIFont systemFontOfSize:20.0f]];
    [self.hangUpButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.hangUpButton addTarget:self
                   action:@selector(hangUp:)
         forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.hangUpButton];
    [self.hangUpButton setCenter:CGPointMake(self.view.frame.size.width / 2, kBtnYposition)];

    if (self.isCaller) {
        self.acceptButton.hidden = YES;
        self.refuseButton.hidden = YES;
    } else {
        self.hangUpButton.hidden = YES;
    }
    
    
    if ([self isEmptyUUID:self.sessionID]) {
        CFUUIDRef theUUID = CFUUIDCreate(NULL);
        CFUUIDBytes uuid = CFUUIDGetUUIDBytes(theUUID);
        NSLog(@"gen session id:%@", theUUID);
        CFRelease(theUUID);
        self.sessionID = uuid;
    } else {
        CFUUIDRef theUUID = CFUUIDCreateFromUUIDBytes(NULL, self.sessionID);
        NSLog(@"session id:%@", theUUID);
        CFRelease(theUUID);
    }
    
    self.voip = [[VOIPSession alloc] init];
    self.voip.currentUID = self.currentUID;
    self.voip.peerUID = self.peerUID;
    self.voip.mode = self.mode;
    self.voip.sessionID = self.sessionID;
    self.voip.delegate = self;
    [self.voip holePunch];
    [[VOIPService instance] pushVOIPObserver:self.voip];
    [[VOIPService instance] addRTMessageObserver:self];
    
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        if (granted) {
            [[UIDevice currentDevice] setProximityMonitoringEnabled:YES];
            if (self.isCaller) {
                [self makeDialing:self.voip];
            } else {
                [self playDialIn];
            }
        } else {
            NSLog(@"can't grant record permission");
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self dismissViewControllerAnimated:NO completion:^{
                    [[VOIPService instance] popVOIPObserver:self.voip];
                    [[VOIPService instance] stop];
                }];
            });
        }
    }];
}

- (BOOL)isEmptyUUID:(CFUUIDBytes)uuid {
    return (uuid.byte0 == 0 && uuid.byte1 == 0 && uuid.byte2 == 0 && uuid.byte3 == 0 &&
            uuid.byte4 == 0 && uuid.byte5 == 0 && uuid.byte6 == 0 && uuid.byte7 == 0 &&
            uuid.byte8 == 0 && uuid.byte9 == 0 && uuid.byte10 == 0 && uuid.byte11 == 0 &&
            uuid.byte12 == 0 && uuid.byte13 == 0 && uuid.byte14 == 0 && uuid.byte15 == 0);
}

- (enum SessionMode)mode {
    return SESSION_VOICE;
}

-(void)dismiss {
    [[UIDevice currentDevice] setProximityMonitoringEnabled:NO];

    [self.pingTimer invalidate];
    self.pingTimer = nil;
    [self dismissViewControllerAnimated:YES completion:^{
        [[VOIPService instance] popVOIPObserver:self.voip];
        [[VOIPService instance] removeRTMessageObserver:self];
        [[VOIPService instance] stop];
    }];
}

-(void)refuseCall:(UIButton*)button {
    [self.voip refuse:200];
    [self.player stop];
    self.player = nil;
    
    self.refuseButton.enabled = NO;
    self.acceptButton.enabled = NO;
}

-(void)acceptCall:(UIButton*)button {
    //关闭外方
    AVAudioSession *session = [AVAudioSession sharedInstance];
    
    [session setCategory:AVAudioSessionCategoryPlayAndRecord
                   error:nil];
    
    [session overrideOutputAudioPort:AVAudioSessionPortOverrideNone
                               error:nil];
    
    [self.player stop];
    self.player = nil;
    
    [self.voip accept];
    
    self.refuseButton.enabled = NO;
    self.acceptButton.enabled = NO;
}

-(void)hangUp:(UIButton*)button {
    [self.voip hangUp];
    if (self.isConnected) {
        self.conversationDuration = 0;
        if (self.refreshTimer && [self.refreshTimer isValid]) {
            [self.refreshTimer invalidate];
            self.refreshTimer = nil;
            
        }
        [self stopStream];
        
        [self dismiss];
    } else {
        [self.player stop];
        self.player = nil;

        
        [self dismiss];
    }
}




- (BOOL)isHeadsetPluggedIn
{
    AVAudioSessionRouteDescription *route = [[AVAudioSession sharedInstance] currentRoute];
    
    BOOL headphonesLocated = NO;
    for( AVAudioSessionPortDescription *portDescription in route.outputs )
    {
        headphonesLocated |= ( [portDescription.portType isEqualToString:AVAudioSessionPortHeadphones] );
    }
    return headphonesLocated;
}

-(void)dial {
    [self.voip dial];
}

- (void)startStream {
    
}


-(void)stopStream {
}


-(int)SetLoudspeakerStatus:(BOOL)enable {
    AVAudioSession* session = [AVAudioSession sharedInstance];
    NSString* category = session.category;
    AVAudioSessionCategoryOptions options = session.categoryOptions;
    // Respect old category options if category is
    // AVAudioSessionCategoryPlayAndRecord. Otherwise reset it since old options
    // might not be valid for this category.
    if ([category isEqualToString:AVAudioSessionCategoryPlayAndRecord]) {
        if (enable) {
            options |= AVAudioSessionCategoryOptionDefaultToSpeaker;
        } else {
            options &= ~AVAudioSessionCategoryOptionDefaultToSpeaker;
        }
    } else {
        options = AVAudioSessionCategoryOptionDefaultToSpeaker;
    }
    
    NSError* error = nil;
    [session setCategory:AVAudioSessionCategoryPlayAndRecord
             withOptions:options
                   error:&error];
    if (error != nil) {
        NSLog(@"set loudspeaker err:%@", error);
        return -1;
    }
    
    return 0;
}

#pragma mark - AVAudioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    NSLog(@"player finished");
    if (!self.isConnected) {
        [self.player play];
    }
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
    NSLog(@"player decode error");
}


-(void)playDialIn {
    [self SetLoudspeakerStatus:YES];
    NSString *path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"start.mp3"];
    NSURL *u = [NSURL fileURLWithPath:path];
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:u error:nil];
    [self.player setDelegate:self];
    
    [self.player play];
}

-(void)playDialOut {
    
    NSString *path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"CallConnected.mp3"];
    BOOL r = [[NSFileManager defaultManager] fileExistsAtPath:path];
    NSLog(@"exist:%d", r);
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    
    NSURL *u = [NSURL fileURLWithPath:path];
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:u error:nil];
    [self.player setDelegate:self];
    
    [self.player play];
}

/**
 *  创建拨号
 *
 *  @param voip  VOIP
 */
-(void) makeDialing:(VOIPSession*)voip{
    self.pingTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(ping) userInfo:nil repeats:YES];
    [self.pingTimer fire];
    
    [self dial];
    [self playDialOut];
}

-(NSString*) getTimeStrFromSeconds:(UInt64)seconds{
    if (seconds >= 3600) {
        return [NSString stringWithFormat:@"%02lld:%02lld:%02lld",seconds/3600,(seconds%3600)/60,seconds%60];
    }else{
        return [NSString stringWithFormat:@"%02lld:%02lld",(seconds%3600)/60,seconds%60];
    }
}

/**
 *  显示通话中
 */
-(void) setOnTalkingUIShow{

    [self.durationLabel setHidden:NO];
    [self.durationLabel setText:[self getTimeStrFromSeconds:self.conversationDuration]];
    [self.durationLabel sizeToFit];
    [self.durationLabel setTextAlignment:NSTextAlignmentCenter];
    [self.durationLabel setCenter:CGPointMake((self.view.frame.size.width)/2, self.headView.frame.origin.y + self.headView.frame.size.height + 50)];
}

/**
 *  刷新时间显示
 */
-(void) refreshDuration{
    self.conversationDuration += 1;
    [self.durationLabel setText:[self getTimeStrFromSeconds:self.conversationDuration]];
    [self.durationLabel sizeToFit];
    [self.durationLabel setTextAlignment:NSTextAlignmentCenter];
    [self.durationLabel setCenter:CGPointMake((self.view.frame.size.width)/2, self.headView.frame.origin.y + self.headView.frame.size.height + 50)];
}

-(void)ping {
    RTMessage *rt = [[RTMessage alloc] init];
    rt.sender = self.currentUID;
    rt.receiver = self.peerUID;
    //自定义格式
    rt.content = @"ping";
    [[VOIPService instance] sendRTMessage:rt];
}

-(void)onRTMessage:(RTMessage *)rt {
    if (rt.sender == self.peerUID) {
        if ([rt.content isEqualToString:@"pong"]) {
            NSLog(@"对方在线");
            [self.pingTimer invalidate];
            self.pingTimer = nil;
        } else if ([rt.content isEqualToString:@"ping"]) {
            RTMessage *rt = [[RTMessage alloc] init];
            rt.sender = self.currentUID;
            rt.receiver = self.peerUID;
            rt.content = @"pong";
            [[VOIPService instance] sendRTMessage:rt];
        }
    }
}
#pragma mark - VOIPStateDelegate
-(void)onRefuse:(int)reason {
    NSLog(@"refuse reason:%d", reason);
    [self.player stop];
    self.player = nil;
    
    [self dismiss];
}

-(void)onHangUp {
    if (self.isConnected) {
        if (self.refreshTimer && [self.refreshTimer isValid]) {
            [self.refreshTimer invalidate];
            self.refreshTimer = nil;
        }
        [self stopStream];
        [self dismiss];
    } else {
        [self.player stop];
        self.player = nil;
        [self dismiss];
    }
}

-(void)onTalking {
    [self.player stop];
    self.player = nil;
    
    [self.view makeToast:@"对方正在通话中!" duration:2.0 position:@"center"];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self dismiss];
    });
}

-(void)onDialTimeout {
    [self.player stop];
    self.player = nil;
    
    [self.voip hangUp];
    [self dismiss];
}

-(void)onAcceptTimeout {
    [self dismiss];
}

-(void)onConnected {
    self.isConnected = YES;
    
    [self setOnTalkingUIShow];
    [self.player stop];
    self.player = nil;
    
    self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(refreshDuration) userInfo:nil repeats:YES];
    [self.refreshTimer fire];
    
    NSLog(@"call voip connected");
    [self startStream];
    
    
    self.hangUpButton.hidden = NO;
    self.acceptButton.hidden = YES;
    self.refuseButton.hidden = YES;
}

-(void)onRefuseFinished {
    [self dismiss];
}

@end
