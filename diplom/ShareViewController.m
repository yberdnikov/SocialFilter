//
//  ShareViewController.m
//  Share
//
//  Created by admin on 08.01.13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "ShareViewController.h"

@interface ShareViewController()

@property (strong, nonatomic) IBOutlet UILabel *testlabel;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) IBOutlet MKMapView *map;
@property (strong, nonatomic) IBOutlet UITextView *textView;
@property (strong, nonatomic) IBOutlet UIView *viewWithImgTxt;
@property (nonatomic) CLLocationCoordinate2D currentLocation;
@property (strong, nonatomic) IBOutlet UIImageView *imagePreview;
@property (strong, nonatomic) Vkontakte *vkontakte;
@property (strong, nonatomic) IBOutlet UIButton *fbShare;
@property (strong, nonatomic) IBOutlet UIButton *vkShare;
@property (strong,nonatomic) NSString *idFbPlace;
@property (weak, nonatomic) IBOutlet UITableView *tableViewForFbPlaces;
@property (strong,nonatomic) NSArray *fbPlaces;
@property (strong, nonatomic) MBProgressHUD *hud;

-(void)sendImageToSocialNetworks;

@end

@implementation ShareViewController

#pragma mark - View lifecycle

-(void)viewWillDisappear:(BOOL)animated{
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [super viewWillDisappear:animated];
}

-(void) viewWillAppear:(BOOL)animated{
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [super viewWillAppear:animated];
}

- (void)viewDidLoad{
    [super viewDidLoad];
    _imagePreview.image = _imageForPreview;
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    _locationManager.distanceFilter = 30.0;
    _currentLocation = CLLocationCoordinate2DMake(0, 0);
}
- (IBAction)sendButton:(id)sender {
    [self sendImageToSocialNetworks];
}

-(void) showHud:(BOOL)boolean erorr:(NSError *)erorr{
    if (boolean){
        _hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
        [self.navigationController.view addSubview:_hud];
        _hud.dimBackground = YES;
        _hud.delegate = self;
        _hud.labelText = @"Отправка";
        [_hud show:YES];
    }
    else{
        _hud.mode = MBProgressHUDModeAnnularDeterminate;
        if (erorr)
            _hud.labelText = erorr.localizedDescription;
        else
            _hud.labelText = @"Успешно";
        
        double delayInSeconds = 2.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [_hud hide:YES];
            [_hud removeFromSuperview];
            _hud = nil;
        });
        
    }
}


-(void)sendImageToSocialNetworks{
    [_textView resignFirstResponder];
    diplomAppDelegate *delegate = [UIApplication sharedApplication].delegate;
    if (delegate.internet){
    [self showHud:YES erorr:nil];
    if (_vkShare.selected){
        if ([_textView.text isEqualToString:@"Текст сообщения"])
            [_vkontakte postImageToWall:_imageForPreview text:@"" link:nil location:_currentLocation];
        else
            [_vkontakte postImageToWall:_imageForPreview text:_textView.text link:nil location:_currentLocation];
    }
    if (_fbShare.selected){
        NSMutableDictionary *parameters = [NSMutableDictionary new];
        if (_map.showsUserLocation)
            [parameters setObject:_idFbPlace forKey:@"place"];
        if (![_textView.text isEqual:@""] && ![_textView.text isEqualToString:@"Текст сообщения"])
            [parameters setObject:_textView.text forKey:@"message"];
        [parameters setObject:_imageForPreview forKey:@"source"];
        
            [FBRequestConnection startWithGraphPath:@"me/photos" parameters:parameters HTTPMethod:@"POST" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                [self showHud:NO erorr:error];
            }];
    }
    else
        [self showHud:NO erorr:nil];
    }
    else{
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Ошибка"
                                                            message:@"Отсутствует интернет подключение"
                                                           delegate:nil
                                                  cancelButtonTitle:@"Ok"
                                                  otherButtonTitles:nil];
        [alertView show];
    }
}

-(void)textViewDidBeginEditing:(UITextView *)textView{
    if ([_textView.text isEqualToString:@"Текст сообщения"])
        _textView.text = @"";
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    if([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    return YES;
}
 
- (IBAction)manageLocation:(UISwitch *)sender{
    if (_map.showsUserLocation)
        _currentLocation = CLLocationCoordinate2DMake(0, 0);
    _map.showsUserLocation=!_map.showsUserLocation;
    if (_fbShare.selected && _map.showsUserLocation){
        double delayInSeconds = 4.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self showTableViewWithFbPlaces];
        });
    }
}

-(void) mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation{
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(userLocation.location.coordinate, 250, 250);
    [_map setRegion:region animated:YES];
    _currentLocation = userLocation.location.coordinate;
}
- (IBAction)vkButton:(UIButton *)sender {

    if (!sender.selected)  {
        _vkontakte = [Vkontakte sharedInstance];
        _vkontakte.delegate = self;
        if (![_vkontakte isAuthorized]) {
            [_vkontakte authenticate];
        }else{
            sender.selected = !sender.selected;
        }
        
    }
    else{
        sender.selected = !sender.selected;
    }
}

-(void) showTableViewWithFbPlaces{
    if (FBSession.activeSession.isOpen) {
    [FBRequestConnection startForPlacesSearchAtCoordinate:_currentLocation radiusInMeters:1000 resultsLimit:15 searchText:nil completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if(!error){
            _fbPlaces = [[NSArray alloc] initWithArray:[result objectForKey:@"data"]];
            [UIView beginAnimations:nil context:nil];
            _map.hidden = YES;
            [UIView setAnimationDuration:0.4];
            [UIView setAnimationCurve:UIViewAnimationCurveLinear];
            [UIView setAnimationBeginsFromCurrentState:YES];
            _tableViewForFbPlaces.frame = CGRectMake(22 , 193, 276, 145);
            _tableViewForFbPlaces.alpha = 1.0f;
            [UIView commitAnimations];
            [_tableViewForFbPlaces reloadData];
        }
    }];}
    else{
        NSArray * permissions = [[NSArray alloc] initWithObjects:@"offline_access",@"publish_stream",@"user_photos", nil];
        [FBSession openActiveSessionWithPublishPermissions:permissions defaultAudience:FBSessionDefaultAudienceEveryone allowLoginUI:YES completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
            [self sessionStateChanged:session state:status error:error];
        }];
    }
}

- (IBAction)fbButton:(UIButton *)sender{
    sender.selected = !sender.selected;
    if (FBSession.activeSession.isOpen) {
        if (_map.showsUserLocation && sender.selected){
            [self showTableViewWithFbPlaces];
        }
    }
    else {
        NSArray * permissions = [[NSArray alloc] initWithObjects:@"offline_access",@"publish_stream",@"user_photos", nil];
        [FBSession openActiveSessionWithPublishPermissions:permissions defaultAudience:FBSessionDefaultAudienceEveryone allowLoginUI:YES completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
            [self sessionStateChanged:session state:status error:error];
        }];
    }
}

-(void)mapView:(MKMapView *)mapView didFailToLocateUserWithError:(NSError *)error{
    UIAlertView *view = [[UIAlertView alloc] initWithTitle:@"Ошибка" message:@"Невозможно определить местоположение" delegate:nil cancelButtonTitle:@"Отмена" otherButtonTitles: nil];
    [view show];
}

- (void)sessionStateChanged:(FBSession *)session
                      state:(FBSessionState) state
                      error:(NSError *)error{
    switch (state) {
        case FBSessionStateOpen: {
            if (_map.showsUserLocation)
            [self showTableViewWithFbPlaces];
        }

            break;
        case FBSessionStateClosed:
        case FBSessionStateClosedLoginFailed:
            
            
            [FBSession.activeSession closeAndClearTokenInformation];
            
            break;
        default:
            break;
    }
    
    if (error) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Error"
                                  message:error.localizedDescription
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
    }
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [_fbPlaces count];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *CellIdentifier = @"DefaultCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];}
  
    cell.textLabel.text =_fbPlaces[indexPath.row][@"name"];
    
      
    
    return cell;
}
- (IBAction)changeMapType:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex == 0) {
        _map.mapType = MKMapTypeStandard;
    }
     else if (sender.selectedSegmentIndex == 1) {
        _map.mapType = MKMapTypeHybrid;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    _idFbPlace = _fbPlaces[indexPath.row][@"id"];
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.2];
    [UIView setAnimationCurve:UIViewAnimationCurveLinear];
    [UIView setAnimationBeginsFromCurrentState:YES];
    _tableViewForFbPlaces.frame = CGRectMake(22 , 338, 276, 0);
    _tableViewForFbPlaces.alpha = 0.0f;
    [UIView commitAnimations];
    _map.hidden = NO;
    NSLog(@"%@", _idFbPlace);
}

- (void)vkontakteDidFailedWithError:(NSError *)error{
    NSLog(@"vkontakte did failed with error %@",[error localizedDescription]);
}
- (void)showVkontakteAuthController:(UIViewController *)controller{
}
- (void)vkontakteAuthControllerDidCancelled{
}

@end
