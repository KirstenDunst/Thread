//
//  ViewController.m
//  Thread
//
//  Created by CSX on 2017/3/19.
//  Copyright © 2017年 宗盛商业. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self test8];
    
    
}

#pragma mark----------延时
- (void)yanshi{
    [NSThread sleepForTimeInterval:5];  //当前线程休眠5s
}
- (void)GCDyanshi{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //延时5秒之后执行的部分
    });
}

#pragma mark----------在多个线程都执行之后才执行下一步    GCD组队列
- (void)dealWithOtherThreadForNewDeal{
    __block int i = 0;
    //利用GCD并行多个线程并且等待所有线程结束之后再执行其它任务
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_async(group, dispatch_get_global_queue(0,0), ^{
        // 并行执行的线程一
        NSLog(@"线程一");
        i+=3;
    });
    dispatch_group_async(group, dispatch_get_global_queue(0,0), ^{
        // 并行执行的线程二
        NSLog(@"线程二");
        i+=5;
    });
    
//        notify可以在后台使用
//        在组队列完成的时候回调用该block回调
    dispatch_group_notify(group, dispatch_get_global_queue(0,0), ^{
        // 汇总结果
        
        NSLog(@"最后执行的结果%d",i);
    });
    
    //wait最好不要在主线程使用
//        阻塞group线程，等待group完成所有子队列
//        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
//        NSLog(@"---组队列完成");
    
}

#pragma mark------------dispatch_semaphore信号量
- (void)semaphore{
/*
 创建了一个初使值为10的semaphore，每一次for循环都会创建一个新的线程，线程结束的时候会发送一个信号，线程创建之前会信号等待，所以当同时创建了10个线程之后，for循环就会阻塞，等待有线程结束之后会增加一个信号才继续执行，如此就形成了对并发的控制，如上就是一个并发数为10的一个线程队列。
 */
    
    dispatch_group_t group = dispatch_group_create();
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(10);
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
//    for (int i = 0; i < 100; i++)
//    {
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        //block块
        dispatch_group_async(group, queue, ^{
//            NSLog(@"第一个循环%i",i);
            NSLog(@"第一个循环");
            sleep(2);
            dispatch_semaphore_signal(semaphore);
        });
//    }
//    for (int i = 0; i < 100; i++)
//    {
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        //block块
        dispatch_group_async(group, queue, ^{
//            NSLog(@"第二个循环%i",i);
            NSLog(@"第二个循环");
                        sleep(2);
            dispatch_semaphore_signal(semaphore);
        });
//    }

    
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    
    NSLog(@"所有实现了");
    //MRC里面要实现释放
//    dispatch_release(group);
//    dispatch_release(semaphore);
}

#pragma mark----------GCD队列
- (void)test0{
    
    /*
     1.在实际项目中，除了DISPATCH_TARGET_QUEUE_DEFAULT，我们几乎不使用其他的优先级选项。
     2. dispatch_get_global_queue(<#long identifier#>, <#unsigned long flags#>) 将返回一个队列，支持数百个线程的执行
     3.在同一个后台队列上执行开销庞大的操作，那么可以使用 dispatch_queue_create 创建自己的队列，dispatch_queue_create 带两个参数，第一个是需要指定的队列名，第二个说明是串行队列还是并发队列。
     4. DISPATCH_QUEUE_SERIAL 代表串行队列
     5. DISPATCH_QUEUE_CONCURRENT 代表并行队列
     */
   
    dispatch_queue_t serialQueue = dispatch_queue_create("queue", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t concurrentQueue = dispatch_queue_create("queue", DISPATCH_QUEUE_CONCURRENT);
    
    
    //    4.注意每次调用使用的是 dispatch_async（异步） 而不是 dispatch_sync（同步）。
    //    5.dispatch_async将在 block 执行前立即返回，而 dispatch_sync 则会等到 block 执行完毕后才返回。
    //    6.内部的调用可以使用 dispatch_sync（因为不在乎什么时候返回），但是外部的调用必须是 dispatch_async（否则主线程会被阻塞）
    //
    
    //下面是一个网络数据请求模型，并行队列请求数据，主线程更新UI
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        id something = @"something";
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *str = (NSString *)something;
            NSLog(@"%@",str);
            
        });
    });

}

#pragma mark--------GCD单利
- (void)test1{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //这里的内容只走一次
    });
}



#pragma mark-------GCD dispatch_apply重复队列
- (void)test2{
    
    //重复队列中的队列参数请不要使用串行队列，否则会阻塞线程，甚至会导致死锁
    dispatch_apply(10, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t index) {
        
        NSLog(@"%zu",index);
    });
    
    //重复队列是同步函数，会阻塞当前线程直到所有循环迭代完成，循环内的线程由第二个参数queue决定
    NSLog(@"---内重复队列完成");
    
    
    //若有需要可以在外围加一个异步线程，可以防止主线程阻塞
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_apply(10, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t index) {
            NSLog(@"%zu",index);
        });
        
        //重复队列是同步参数，会阻塞当前线程直到所有循环迭代完成，循环内的线程由第二个参数queue决定
        NSLog(@"----内重复队列完成");
    });
    
    NSLog(@"----外重复队列完成");
    
}

#pragma mark-----dispatch_suspend暂停队列 
//暂停队列，使得队列中后续任务停止服务，直到恢复队列
- (void)test5{
    
    dispatch_queue_t queue = dispatch_queue_create("queue", DISPATCH_QUEUE_SERIAL);
    NSLog(@"暂停队列开始计时");
    
    //提交第一个block，延时5s打印
    dispatch_async(queue, ^{
        [NSThread sleepForTimeInterval:5];
        NSLog(@"第一个block，延时5s");
    });
    
    //提交第二个block，也是延时5s打印
    dispatch_async(queue, ^{
        [NSThread sleepForTimeInterval:5];
        NSLog(@"第二个block，延时5s");
    });
    
    //延时1s
    NSLog(@"睡眠1s");
    [NSThread sleepForTimeInterval:1];
    //挂起队列
    NSLog(@"suspend队列");
    dispatch_suspend(queue);
    
    //延时10s
    NSLog(@"睡眠10s");
    [NSThread sleepForTimeInterval:10];
    
    //恢复队列
    NSLog(@"resume队列");
    dispatch_resume(queue);
    
    //从结果可以看出，第一个请求从开始计时后正好延时5s；
    //而第二个队列则是恢复队列计时延时5s。
    //所以结论是，暂停队列智能暂停队列中的后续任务，当前任务的block体中代码还是会继续执行
    
}




#pragma mark-------dispatch_barrier_async 插入队列
- (void)test6{
    //1.将任务插入队列中，会等待当前任务block体代码执行完毕，
    //2.然后执行插入队列中的block体，并且暂停队列中的后续任务，
    //3.等待插入队列的代码走完，会继续执行后续队列
    //4.插入队列，提交完block体中的代码会继续执行后续代码，不会阻塞线程。
    //5.不过智能用于自己创建的并行队列
    //6.若用串行队列，和全局并行队列，则相当于dispatch_async函数
    
    dispatch_queue_t queue = dispatch_queue_create("queue", DISPATCH_QUEUE_CONCURRENT);
    //提交第一个block，延时5s打印。
    
    NSLog(@"加入第一个队列");
    dispatch_async(queue, ^{
        NSLog(@"第一个block");
    });
    
    NSLog(@"加入第二个队列");
    //提交第二个block，也是延时2s打印
    dispatch_async(queue, ^{
        NSLog(@"第二个block开始");
        [NSThread sleepForTimeInterval:2];
        NSLog(@"第二个block结束");
    });
    
    NSLog(@"插入block插入");
    dispatch_barrier_async(queue, ^{
        NSLog(@"这是插入的一个block");
        [NSThread sleepForTimeInterval:2];
        NSLog(@"睡眠2s完成");
    });
    
    NSLog(@"加入第三个队列");
    //提交第三个block
    dispatch_async(queue, ^{
        NSLog(@"第三个block");
    });
    
    NSLog(@"加入第四个队列");
    //提交第四个block
    dispatch_async(queue, ^{
        NSLog(@"第四个block");
    });
    
}

#pragma mark-----------线程通信
- (void)threadCommunication{
//    // 回到主线程（方法内为主线程）
//    [self performSelectorOnMainThread:@selector(downloadFinished:) withObject:image waitUntilDone:NO];
//    
//     [self performSelector:@selector(downloadFinished:) onThread:[NSThread mainThread] withObject:image waitUntilDone:YES];
//    
//    [self performSelectorInBackground:@selector(download) withObject:nil];
    
    
//    @synchronized(锁对象) { // 需要锁定的代码 }
    @synchronized (self) {
        // 需要锁定的代码
    }
}

#pragma mark-------------线程依赖
- (void)test7{
    // 1.创建一个队列
    // 一般情况下, 在做企业开发时候, 都会定义一个全局的自定义队列, 便于使用
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    
    // 2.添加一个操作下载第一张图片
    __block UIImage *image1 = nil;
    NSBlockOperation *op1 = [NSBlockOperation blockOperationWithBlock:^{
        NSURL *url  = [NSURL URLWithString:@"http://imgcache.mysodao.com/img2/M04/8C/74/CgAPDk9dyjvS1AanAAJPpRypnFA573_700x0x1.JPG"];
        NSData *data = [NSData dataWithContentsOfURL:url];
        image1 = [UIImage imageWithData:data];
    }];
    
    // 3.添加一个操作下载第二张图片
    __block UIImage *image2 = nil;
    NSBlockOperation *op2 = [NSBlockOperation blockOperationWithBlock:^{
        NSURL *url  = [NSURL URLWithString:@"http://imgcache.mysodao.com/img1/M02/EE/B5/CgAPDE-kEtqjE8CWAAg9m-Zz4qo025-22365300.JPG"];
        NSData *data = [NSData dataWithContentsOfURL:url];
        image2 = [UIImage imageWithData:data];
    }];
    // 4.添加一个操作合成图片
    NSBlockOperation *op3 = [NSBlockOperation blockOperationWithBlock:^{
        UIGraphicsBeginImageContext(CGSizeMake(200, 200));
        [image1 drawInRect:CGRectMake(0, 0, 100, 200)];
        [image2 drawInRect:CGRectMake(100, 0, 100, 200)];
        UIImage *res = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        // 5.回到主线程更新UI
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            //主线程更新UI
//            self.imageView.image = res;
        }];
    }];
    
    // 6.添加依赖
    
    [op3 addDependency:op1];
    [op3 addDependency:op2];
    
    // 7.添加操作到队列中
    [queue addOperation:op1];
    [queue addOperation:op2];
    [queue addOperation:op3];
    
}


#pragma mark------------取消一个正在执行的线程
- (void)test8{
    // 创建线程 -- 新建状态
    NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(demo) object:nil];
    // 将线程添加到可调度线程池中，等等CPU调度
    [thread start];
    // 睡会
    [NSThread sleepForTimeInterval:1.2];
    // 取消线程
    // cancel：方法仅仅是给线程标记为取消状态。但是要想真正取消线程的执行，必须在线程内部判断。
    [thread cancel];
}
// 一个方法内部的代码是在同一个线程中执行的
- (void)demo {
    NSLog(@"睡会 = %@",[NSThread currentThread]);
    if ([NSThread currentThread].isCancelled) {
        NSLog(@"1...88");
        return;
    }
    [NSThread sleepForTimeInterval:1.0];
    // 在关键节点判断线程是否被取消
    if ([NSThread currentThread].isCancelled) {
        NSLog(@"2...88");
        return;
    }
    for (NSInteger index = 0; index < 20; index ++) {
        if ([NSThread currentThread].isCancelled) {
            NSLog(@"3...88");
            return;
        }
        // 在满足某个条件的时候，再睡
        if (index == 10) {
            NSLog(@"再睡");
            // 睡到指定的时间
            [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
        }
        NSLog(@"%@--%zd",[NSThread currentThread],index);
    }
}


/*
 Q:如果某个ViewController里运行了一个线程，线程还没结束的时候，这个ViewController被pop了，
 线程不结束，viewController会一直保留不会被释放，
 这个时候再次进入这个viewController的时候会出现异常，
 现在的问题是：如何得到这个线程，然后关闭它。
 
 
 A:可以试试在 block 里用到 viewController 都用 weakSelf __weak typeof(self) weakSelf = self;，这样 block 不会持有这个 viewController，当 pop 出去的时候自然就变成 nil 了。不过如果是单例的话就没办法。
 */






- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
