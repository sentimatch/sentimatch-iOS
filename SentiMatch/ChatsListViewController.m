//
//  ChatsListViewController.m
//  SentiMatch
//
//  Created by Anas Bouzoubaa on 6/6/15.
//
//

#import "ChatsListViewController.h"
#import "SMBackEndAPI.h"
#import <SSKeychain/SSKeychain.h>
#import "SMChatViewController.h"
#import "SMFirebaseShared.h"

@interface ChatsListViewController ()

@property (strong, nonatomic) NSArray *users;
@property (strong, nonatomic) NSArray *userIDs;
@property (strong, nonatomic) NSArray *percentages;
@property (strong, nonatomic) NSString *userID;
@property (nonatomic) CGFloat sum;
@property (nonatomic) BOOL check;

@end

@implementation ChatsListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    self.sum = [[[NSUserDefaults standardUserDefaults] objectForKey:@"sum"] floatValue];
    self.check = NO;
    self.users = @[];
    
    self.userID = [SSKeychain passwordForService:@"twitter_login" account:@"twitter_account"];
    
    
    // Check out from venue
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"Leave" style:UIBarButtonItemStyleDone target:self action:@selector(checkoutFromVenue)];
    self.navigationItem.rightBarButtonItem = item;
    
    [self checkVenueAgain];
    
    // Receiving messages
    [[[SMFirebaseShared sharedFirebase] getRootRef] observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        NSDictionary *dict = snapshot.value;
            for (NSString *key in dict) {
            if ([key isEqualToString:self.userID]) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Chat" message:@"Someone wants to chat with you!" delegate:self cancelButtonTitle:@"Nope" otherButtonTitles:@"Okay!", nil];
                [alertView show];
            }
        }
    }];
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex != alertView.cancelButtonIndex) {
        NSLog(@"hello");
    }
}

- (void)checkVenueAgain
{
    [SMBackEndAPI checkVenueID:[self.venue objectForKey:@"id"] withCompletionHandler:^(BOOL successful, id result) {
        NSMutableDictionary *relativePersonalities = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *relativePersonalitiesUserID = [[NSMutableDictionary alloc] init];
        for (NSDictionary *person in result) {
            NSString *temp = person[@"email"];
            NSRange range = [temp rangeOfString:@"@"];
            NSString *currentID = [temp substringToIndex:range.location];
            if (![currentID isEqualToString:self.userID]) {
                CGFloat currentSum = [person[@"person_sum"] floatValue];
                CGFloat relativeSum = fabsf(currentSum - self.sum);
                [relativePersonalities setObject:@(relativeSum) forKey:person[@"name"]];
                [relativePersonalitiesUserID setObject:@(relativeSum) forKey:currentID];
            }
        }
        
        NSArray *sorted = [[relativePersonalities allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [[relativePersonalities objectForKey:obj1] compare:[relativePersonalities objectForKey:obj2]];
        }];
        
        NSArray *sorted2 = [[relativePersonalitiesUserID allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [[relativePersonalitiesUserID objectForKey:obj1] compare:[relativePersonalitiesUserID objectForKey:obj2]];
        }];
        
        NSMutableArray *percentageStuff = [[NSMutableArray alloc] init];
        for (NSString *key in sorted) {
            [relativePersonalities[key] floatValue];
            NSLog(@"key: %@, value: %@", key, relativePersonalities[key]);
            CGFloat numerator = [relativePersonalities[key] floatValue];
            CGFloat val = floorf(100 - ((numerator/self.sum) * 100));
            [percentageStuff addObject:@(val)];
        }
        self.percentages = [NSArray arrayWithArray:percentageStuff];
        
        self.users = sorted;
        self.userIDs = sorted2;
        [self.tableView reloadData];
        if (!self.check) {
            self.check = YES;
            // Poll the backend every 60 seconds
            NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(checkVenueAgain) userInfo:nil repeats:YES];
            [timer fire];
        }
        
    }];
}

- (void)checkoutFromVenue
{
    // nothing yet
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.users.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 30.f;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [NSString stringWithFormat:@"Checked in @ %@", [self.venue objectForKey:@"name"]];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"threadCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"threadCell"];
    }

    cell.textLabel.text = self.users[indexPath.row];
    cell.detailTextLabel.text = [self.percentages[indexPath.row] stringValue];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *selectedUser = self.userIDs[indexPath.row];
    SMChatViewController *chatVC = [[SMChatViewController alloc] initWithOtherName:selectedUser];
    [self.navigationController pushViewController:chatVC animated:YES];
}

@end
