//
//  ViewController.m
//  TestDemo
//
//  Created by bhb on 17/3/6.
//  Copyright © 2017年 huangzengquan. All rights reserved.
//

#import "ViewController.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <ReactiveCocoa/RACEXTScope.h>
#import <ReactiveCocoa/RACReturnSignal.h>

@interface ViewController ()
@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) RACCommand *command;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    UITextField *textField = [[UITextField alloc] init];
    textField.frame = CGRectMake(0, 100, 300, 30);
    textField.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:textField];
   //target-action
    [[textField rac_signalForControlEvents:UIControlEventEditingChanged] subscribeNext:^(id x) {
        UITextField *textfield = (UITextField *)x;
        NSLog(@"---------%@",textfield.text);
    }];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] init];
    [[tapGestureRecognizer rac_gestureSignal] subscribeNext:^(id x) {
        NSLog(@"----------------触摸");
    }];
    [self.view addGestureRecognizer:tapGestureRecognizer];
    
    //代理
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"gogogo" message:@"gogogo" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
    [[self rac_signalForSelector:@selector(alertView:clickedButtonAtIndex:) fromProtocol:@protocol(UIAlertViewDelegate)] subscribeNext:^(RACTuple *tuple) {
        NSLog(@"%@",tuple.first);
        NSLog(@"%@",tuple.second);
    }];
    [alertView show];
    
    //通知
    [[[NSNotificationCenter defaultCenter] rac_addObserverForName:@"postData" object:nil] subscribeNext:^(NSNotification *notification) {
        NSLog(@"%@", notification.name);
        NSLog(@"%@", notification.object);
    }];
    NSMutableArray *dataArray = [[NSMutableArray alloc] initWithObjects:@"1", @"2", @"3", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"postData" object:dataArray];
    
    //KVO
    self.title = @"哈哈哈哈哈哈";
    [RACObserve(self, title) subscribeNext:^(id x) {
        NSLog(@"textchange---------%@",x);
    }];
    
    //创建信号，发送信号，订阅信号
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@1];
        [subscriber sendCompleted];
        return [RACDisposable disposableWithBlock:^{
            NSLog(@"信号被销毁");
        }];
    }];
    
    [signal subscribeNext:^(id x) {
        NSLog(@"接收到的数据%@",x);
    }];
    
    //创建 订阅 发送信号
    RACSubject *subject = [RACSubject subject];
    [subject subscribeNext:^(id x) {
        NSLog(@"我是第一个订阅者");
    }];
    [subject subscribeNext:^(id x) {
        NSLog(@"我是第二个订阅者%@",x);
    }];
    [subject sendNext:@"哈哈哈哈哈哈哈"];
    
    //RACTuple元组类
    NSArray *numbers = @[@1,@2,@3,@5];
    [numbers.rac_sequence.signal subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
    
    //RACSequece 替代集合类，nsarray nsdictonary
    NSArray *dictArr = [NSArray arrayWithObjects:@"fas",@"fafad",@"fafad",nil];
    
    NSMutableArray *flags = [NSMutableArray array];
    
    flags = flags;
    
    // rac_sequence注意点：调用subscribeNext，并不会马上执行nextBlock，而是会等一会。
    [dictArr.rac_sequence.signal subscribeNext:^(id x) {
        // 运用RAC遍历字典，x：字典
        
    }];
    
    //RACCommand
    // 1.创建命令
    RACCommand *command = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        NSLog(@"执行命令");
        // 创建空信号,必须返回信号
        //        return [RACSignal empty];
        
        // 2.创建信号,用来传递数据
        return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            
            [subscriber sendNext:@"---------------------------------请求数据"];
            
            // 注意：数据传递完，最好调用sendCompleted，这时命令才执行完毕。
            [subscriber sendCompleted];
            
            return nil;
        }];
        
    }];
    self.command = command;
    // 3.订阅RACCommand中的信号
    [command.executionSignals subscribeNext:^(id x) {
        
        [x subscribeNext:^(id x) {
            
            NSLog(@"%@",x);
        }];
        
    }];
    [self.command  execute:nil];
    
    //RACMuticastConnection 用于当一个信号，被多次订阅时候，为了保证创建信号时候被多次创建造成副作用
    // 1.创建信号
    RACSignal *createSignal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSLog(@"发送请求");
        [subscriber sendNext:@1];
        return nil;
    }];
    
    // 2.创建连接
    RACMulticastConnection *connect = [createSignal publish];
    
    // 3.订阅信号，
    // 注意：订阅信号，也不能激活信号，只是保存订阅者到数组，必须通过连接,当调用连接，就会一次性调用所有订阅者的sendNext:
    [connect.signal subscribeNext:^(id x) {
        
        NSLog(@"订阅者一信号");
        
    }];
    
    [connect.signal subscribeNext:^(id x) {
        
        NSLog(@"订阅者二信号");
        
    }];
    
    // 4.连接,激活信号
    [connect connect];

    //常用的宏定义
    //给某个对象的某个属性绑定
    RAC(self,title) = textField.rac_textSignal;
    //监听某个对象的某个属性
    [RACObserve(self, title) subscribeNext:^(id x) {
        
    }];
    //把参数中的数据包装成元组
    RACTuple *tuple = RACTuplePack(@"XXX" ,@20);
    //解包
    RACTupleUnpack(NSString *name , NSNumber *age) = tuple;
    NSLog(@"%@---%@",name ,age);
    
    //bind 绑定机制
    [[textField.rac_textSignal bind:^RACStreamBindBlock{
        return ^RACStream *(id value, BOOL *stop) {
            return [RACReturnSignal return:[NSString stringWithFormat:@"输出:%@",value]];
        };
    }] subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
    
    //映射 flattenMap Map 用于把信号映射成新的内容
    [[textField.rac_textSignal flattenMap:^RACStream *(id value) {
        return [RACReturnSignal return:[NSString stringWithFormat:@"输出:%@",value]];
    }] subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
    //MAP,不重新包装信号
    [[textField.rac_textSignal map:^id(id value) {
        return [NSString stringWithFormat:@"输出%@",value];
    }] subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
    
    //按一定顺序拼接信号，当多个信号发出的时候，有顺序的接收信号，只有第一个信号发送了complete，才能接收第二信号。。
    RACSignal *signalA = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@1];
        [subscriber sendCompleted];
        return nil;
    }];
    
    RACSignal *signalB = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        [subscriber sendNext:@2];
        
        return nil;
    }];
    
    RACSignal *concatSignal = [signalA concat:signalB];
    [concatSignal subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
    
    //then 用于连接两个信号 ，当地一个完成，才会链接then返回的信号
    [[[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        [subscriber sendNext:@1];
        [subscriber sendCompleted];
        return nil;
    }] then:^RACSignal *{
        return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            [subscriber sendNext:@2];
            return nil;
        }];
    }] subscribeNext:^(id x) {
        
        // 只能接收到第二个信号的值，也就是then返回信号的值
        NSLog(@"%@",x);
    }];
    
    //merge 吧多个型号合并为一个信号 ,任何一个信号发送数据都能监听到
    RACSignal *signalAa = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        [subscriber sendNext:@1];
        
        [subscriber sendCompleted];
        
        return nil;
    }];
    RACSignal *signalBb = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        [subscriber sendNext:@2];
        
        return nil;
    }];
    
    [[signalAa merge:signalBb] subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
    
    //zipwith 把两个信号压缩成一个信号，当两个信号同时发出信号时候，内容合并，才会触发next事件
    RACSignal *signalA3 = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        [subscriber sendNext:@1];
        
        
        return nil;
    }];
    RACSignal *signalB3 = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        [subscriber sendNext:@2];
        
        return nil;
    }];
    // 压缩信号A，信号B
    RACSignal *zipSignal = [signalA3 zipWith:signalB3];
    
    [zipSignal subscribeNext:^(id x) {
        
        NSLog(@"%@",x);
    }];
    
    //combineLast,把多个信号合并起来，并拿到每个信号的最新值，必须每个合并的signal至少有过一次sendnext，才会触发合并的信号。
    RACSignal *signalA4 = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        [subscriber sendNext:@1];
        
        return nil;
    }];
    RACSignal *signalB4 = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        [subscriber sendNext:@2];
        
        return nil;
    }];
    // 把两个信号组合成一个信号,跟zip一样，没什么区别
    RACSignal *combineSignal = [signalA4 combineLatestWith:signalB4];
    
    [combineSignal subscribeNext:^(id x) {
        
        NSLog(@"%@",x);
    }];

    //filter 过滤信号
    [textField.rac_textSignal filter:^BOOL(id value) {
        return YES;
    }];
    
    //ignor忽略信号
    [[textField.rac_textSignal ignore:@"1"] subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
    
    // 在开发中，刷新UI经常使用，只有两次数据不一样才需要刷新
    [[textField.rac_textSignal distinctUntilChanged] subscribeNext:^(id x) {
        
        NSLog(@"%@",x);
    }];
    
    //从开始一共取n次信号
    // 1、创建信号
    RACSubject *signalss = [RACSubject subject];
    
    // 2、take 只取前面的300个值
    [[signalss take:300] subscribeNext:^(id x) {
        
        NSLog(@"%@----------j--------------------------------jj-------------",x);
    }];
    // 3.发送信号
    [signalss sendNext:@1];
    
    [signalss sendNext:@2];
    
    ///takeLast 取最后n次的信号，前提条件，订阅者必须调用完成
    // 1、创建信号
    RACSubject *signaldnn = [RACSubject subject];
    
    // 2、处理信号，订阅信号
    [[signaldnn takeLast:1] subscribeNext:^(id x) {
        
        NSLog(@"%@",x);
    }];
    
    // 3.发送信号
    [signaldnn sendNext:@1];
    
    [signaldnn sendNext:@2];
    
    [signaldnn sendCompleted];
    
    //rective 操作秩序
    [[[[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@1];
        [subscriber sendCompleted];
        return nil;
    }] doNext:^(id x) {
        // 执行[subscriber sendNext:@1];之前会调用这个Block
        NSLog(@"doNext");;
    }] doCompleted:^{
        // 执行[subscriber sendCompleted];之前会调用这个Block
        NSLog(@"doCompleted");;
        
    }] subscribeNext:^(id x) {
        
        NSLog(@"%@",x);
    }];
    
    //reactivecocoa 操作之时间 time out 超时报错
    RACSignal *signaltime = [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        return nil;
    }] timeout:1 onScheduler:[RACScheduler currentScheduler]];
    
    [signaltime subscribeNext:^(id x) {
        
        NSLog(@"%@",x);
    } error:^(NSError *error) {
        // 1秒后会自动调用
        NSLog(@"%@",error);
    }];
    
    //interval 定时
    [[RACSignal interval:1 onScheduler:[RACScheduler currentScheduler]] subscribeNext:^(id x) {
        
        NSLog(@"%@",x);
    }];
    
    //delay 延迟发送
   [[[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@1];
        return nil;
    }] delay:2] subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
    
//    RAC冷热信号的转化
//    //replay 获取该信号的所有历史值,不急重复执行
//    __block int num = 0;
//    RACSignal *signal = [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
//        num ++;
//        [subscriber sendNext:@(num)];
//        return nil;
//    }] replay];
//    [signal subscribeNext:^(id x) {
//        NSLog(@"%@",x);
//    }];
//    [signal subscribeNext:^(id x) {
//        NSLog(@"%@",x);
//    }];
//    //replayLast 当源信号被订阅时，会立即发丝哦那个给订阅者最新的值，还会收到未来信号所有的值，不会重复执行代码
//    RACSubject *subject = [RACSubject subject];
//    RACSignal *signal2 = [subject replayLast];
//    [signal2 subscribeNext:^(id x) {
//        NSLog(@"111");
//    }];
//    [subject sendNext:@"A"];
//    [subject sendNext:@"B"];
//    [signal2 subscribeNext:^(id x) {
//        NSLog(@"%@",x);
//    }];
//    [subject sendNext:@"C"];
//    //　这replayLazily方法返回一个新的信号，当源信号被订阅时，会立即发送给订阅者全部历史的值，不会重复执行源信号中的订阅代码。跟replay不同的是，replayLazily被订阅生成新的信号之前是不会对源信号进行订阅的
//    //    ReactiveCocoa提供了这三个简便的方法允许多个订阅者订阅一个信号，却不会重复执行订阅代码，并且能给新加的订阅者提供订阅前的值。replay和replayLast使信号变成热信号，且会提供所有值(-replay) 或者最新的值(-replayLast) 给订阅者。 replayLazily返回一个冷的信号，会提供所有的值给订阅者。
//    // 冷信号 点播 ，订阅一次执行一次          热信号 直播，错过了，就不会收到
//    
//    //Racreplaysubject 过设置capacity来限定它接收重接收事件的数量
//    RACReplaySubject *replaySubject = [RACReplaySubject replaySubjectWithCapacity:2];
//    [RACReplaySubject subject];
//    [replaySubject sendNext:@(0)];
//    [replaySubject sendNext:@(1)];
//    [replaySubject sendNext:@(3)];
    
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
