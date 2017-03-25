//
//  TestViewController.m
//  TestDemo
//
//  Created by bhb on 17/3/15.
//  Copyright © 2017年 huangzengquan. All rights reserved.
//

#import "TestViewController.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <ReactiveCocoa/RACReturnSignal.h>

@interface TestViewController ()
@property (nonatomic ,copy)NSString *title;
@property (nonatomic ,strong)UIAlertView *alert;
@end

@implementation TestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //target-action
    UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(100, 100, 200, 56)];
    textField.backgroundColor = [UIColor grayColor];
    [self.view addSubview:textField];
    
    //target--action
    [[textField rac_textSignal] subscribeNext:^(UITextField *textField) {
        NSLog(@"%@",textField);
    }];
    [[textField rac_signalForControlEvents:UIControlEventEditingChanged] subscribeNext:^(UITextField *field) {
        NSLog(@"%@",field.text);
    }];
    
    //notification
    [[[NSNotificationCenter defaultCenter] rac_addObserverForName:@"111" object:nil] subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"111" object:@"111"];
    
    //kvo
    [RACObserve(self,title) subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
    self.title = @"xxxx";
    //delegate
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"gogogo" message:@"gogogo" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:nil];
    [[self rac_signalForSelector:@selector(alertView:clickedButtonAtIndex:) fromProtocol:@protocol(UIAlertViewDelegate)] subscribeNext:^(RACTuple *tuple) {
        NSLog(@"%@",tuple.first);
        NSLog(@"%@",tuple.second);
        NSLog(@"%@",tuple.third);
    }];
    [alertView show];
    
    //冷信号 创建信号 发送信号 订阅信号
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"发送值"];
        return [RACScopedDisposable disposableWithBlock:^{
            NSLog(@"被销毁");
        }];
    }];
    [signal subscribeNext:^(id x) {
        NSLog(@"接受到信号的值");
    }];
    
    //热信号 创建 订阅 发送信号
    RACSubject *subject = [RACSubject subject];
    [subject subscribeNext:^(id x) {
        NSLog(@"收到发送的信号");
    }];
    [subject subscribeNext:^(id x) {
        NSLog(@"收到发送的信号");
    }];
    [subject sendNext:@"11111"];
    
    //元组 遍历 效率太差 慎用
    NSArray *array = @[@"123",@"1234",@"2356"];
    [array.rac_sequence.signal subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
    
    //RACCOMMAND
    RACCommand *command = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            [subscriber sendNext:@"hhahahahah"];
            return [RACDisposable disposableWithBlock:^{
                
            }];
        }];
        return signal;
    }];
    [command execute:@"111"];
    
    //Racmuticastconnection
    RACSignal *signalA = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"hhahahahah"];
        return [RACDisposable disposableWithBlock:^{
            NSLog(@"-----");
        }];
        
    }];
    RACMulticastConnection *connection = [signalA publish];
    [connection.signal subscribeNext:^(id x) {
        NSLog(@"----------------x");
    }];
    [connection.signal subscribeNext:^(id x) {
        NSLog(@"-----------------x");
    }];
    [connection connect];
    
    //常用的宏定义
    [[RACObserve(self, title) replayLazily] subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
    //绑定
    RAC(self ,title) = [textField.rac_textSignal replayLazily];
    [textField.rac_textSignal subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
    
    [[[textField rac_textSignal] bind:^RACStreamBindBlock{
        return ^RACStream *(id value, BOOL *stop) {
            return [RACReturnSignal return:[NSString stringWithFormat:@"输出:%@",value]];
        };
    }] subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
    //MAP
    [[textField.rac_textSignal map:^id(id value) {
        return [NSString stringWithFormat:@"11111%@",value];
    }] subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
    /// faltenmap
    [[textField.rac_textSignal flattenMap:^RACStream *(id value) {
        return [RACReturnSignal return:value];
    }] subscribeNext:^(id x) {
        NSLog(@"dsdddd%@",x);
    }];
    //contact 先发送信号a ，型号a发送完成 才发送 signal
    RACSignal *signacContact = [signalA concat: signal];
    [signacContact subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
    //merge 多个信号合并为一个信号，任何一个信号有新值都会调用
    RACSignal *signacMerge = [signalA merge:signal];
    [signacMerge subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
    //zipwith 合并两个信号，并把两个信号内容合并为元组
    RACSignal *zipSignal = [signalA zipWith:signal];
    [zipSignal subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
    
    //过滤
    [textField.rac_textSignal filter:^BOOL(NSString *value) {
        return value.length > 3;
    }];
    [textField.rac_textSignal ignore:@"3"];
    [[textField.rac_textSignal distinctUntilChanged] subscribeNext:^(id x) {
        
    }];
    [[textField.rac_textSignal skip:3] subscribeNext:^(id x) {
        
    }];
    [[textField.rac_textSignal takeLast:3] subscribeNext:^(id x) {
        
    }];
    [textField.rac_textSignal takeUntil:signal];
    
    //秩序
    [[textField.rac_textSignal doNext:^(id x) {
        
    }] doCompleted:^{
        
    }];
    //多线程 racSchedule
    [[RACScheduler scheduler] afterDelay:0 schedule:^(void) {
        
    }];
    [[signal deliverOn:[RACScheduler scheduler]] subscribeNext:^(id x) {
        
    }];
    [signal subscribeOn:[RACScheduler scheduler]];
    //时间 timeout delay interval
    [textField.rac_textSignal timeout:0.01 onScheduler:[RACScheduler currentScheduler]];
    [textField.rac_textSignal delay:1.0];
    [textField.rac_textSignal subscribeError:^(NSError *error) {
        NSLog(@"error");
    }];
    [[RACSignal interval:1 onScheduler:[RACScheduler scheduler]] subscribeNext:^(id x) {
        NSLog(@"FDF");
    }];
    //RAC之重复 replay replaylazily
    RACSignal *signal_replay = [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"1111"];
        return nil;
    }] replayLazily];
    [signal_replay subscribeNext:^(id x) {
        NSLog(@"11111");
    }];
    [signal_replay subscribeNext:^(id x) {
        NSLog(@"11111");
    }];
    //replaylast
    RACSubject *subjectaaa = [RACSubject subject];
    RACSignal *signalaaaaa = [subjectaaa replayLast];
    [subjectaaa sendNext:@"1111"];
    [subjectaaa sendNext:@"33333"];
    [signalaaaaa subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
    [subjectaaa sendNext:@"333"];
    [signalaaaaa subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
    @weakify(self)
    [subjectaaa subscribeNext:^(id x) {
        @strongify(self);
    }];
    
    //RAC常见的坑
    //1.RACObserve 带来的循环引用
    [subjectaaa subscribeNext:^(id x) {
        @strongify(self)
        RACObserve(self, title);
    }];
    //RACSubject 进行了 map、filter、merge、combineLatest、flattenMap转换操作后，要发送complete ，不然无法释放
    [[subjectaaa map:^id(NSNumber *value) {
        return @([value integerValue] *3);
    }] subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
    [subjectaaa sendNext:@(123)];
    [subjectaaa sendCompleted];
    //signal造成的多次订阅问题,使用reply，replayLazily让subscriber里面的代码只被执行一次
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
