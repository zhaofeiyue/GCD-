//
//  ViewController.m
//  信号量 dispatch_group
//
//  Created by 赵飞跃 on 15/9/13.
//  Copyright © 2015年 赵飞跃. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self signal_dispacth];
    [self barrier];
    [self concunrrent_queue2];
    // Do any additional setup after loading the view, typically from a nib.
}
// group的用法
/*
 >1 队列和线程的区别：
 队列：是管理线程的，相当于线程池,能管理线程什么时候执行。
 队列分为串行队列和并行队列
 
 串行队列：队列中的线程按顺序执行（不会同时执行）
 并行队列：队列中的线程会并发执行，可能会有一个疑问，队列不是先进先出吗，如果后面的任务执行完了，怎么出去的了。这里需要强调下，任务执行完毕了，不一定出队列。只有前面的任务执行完了，才会出队列。
 
 >2 主线程队列和GCD创建的队列也是有区别的。
 
 主线程队列和GCD创建的队列是不同的。在GCD中创建的队列优先级没有主队列高，所以在GCD中的串行队列开启同步任务里面没有嵌套任务是不会阻塞主线程，只有一种可能导致死锁，就是串行队列里，嵌套开启任务，有可能会导致死锁。
 主线程队列中不能开启同步，会阻塞主线程。只能开启异步任务，开启异步任务也不会开启新的线程，只是降低异步任务的优先级，让cpu空闲的时候才去调用。而同步任务，会抢占主线程的资源，会造成死锁。
 
 3> 线程：里面有非常多的任务（同步，异步）
 
 同步与异步的区别：
 同步任务优先级高，在线程中有执行顺序，不会开启新的线程。
 异步任务优先级低，在线程中执行没有顺序，看cpu闲不闲。在主队列中不会开启新的线程，其他队列会开启新的线程。
 */


/**
 *  主线程队列注意：
 下面代码执行顺序
 1111
 2222
 主队列异步 <NSThread: 0x8e12690>{name = (null), num = 1}
 
 在主队列开启异步任务，不会开启新的线程而是依然在主线程中执行代码块中的代码。为什么不会阻塞线程？
 > 主队列开启异步任务，虽然不会开启新的线程，但是他会把异步任务降低优先级，等闲着的时候，就会在主线程上执行异步任务。
 
 在主队列开启同步任务，为什么会阻塞线程？
 > 在主队列开启同步任务，因为主队列是串行队列，里面的线程是有顺序的，先执行完一个线程才执行下一个线程，而主队列始终就只有一个主线程，主线程是不会执行完毕的，因为他是无限循环的，除非关闭应用程序。因此在主线程开启一个同步任务，同步任务会想抢占执行的资源，而主线程任务一直在执行某些操作，不肯放手。两个的优先级都很高，最终导致死锁，阻塞线程了。
 
 */
- (void)main_queue_deadlock
{
    
    dispatch_queue_t q = dispatch_get_main_queue();
    
    NSLog(@"1111");
    
    dispatch_async(q, ^{
        NSLog(@"主队列异步 %@", [NSThread currentThread]);
    });
    
    NSLog(@"2222");
    
    // 下面会造成线程死锁
    //    dispatch_sync(q, ^{
    //        NSLog(@"主队列同步 %@", [NSThread currentThread]);
    //    });
    
}

/**
 *  并行队列里开启同步任务是有执行顺序的，只有异步才没有顺序
 */
- (void)concurrent_queue
{
    dispatch_queue_t q = dispatch_queue_create("cn.itcast.gcddemo", DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_sync(q, ^{
        NSLog(@"同步任务 %@1111111", [NSThread currentThread]);
        dispatch_sync(q, ^{
            NSLog(@"同步任务 %@2222222", [NSThread currentThread]);
        });
        
        dispatch_sync(q, ^{
            NSLog(@"同步任务 %@333333", [NSThread currentThread]);
        });
        
    });
    
    dispatch_sync(q, ^{
        NSLog(@"同步任务 %@444444", [NSThread currentThread]);
    });
    
    dispatch_sync(q, ^{
        NSLog(@"同步任务 %@555555", [NSThread currentThread]);
    });
    dispatch_sync(q, ^{
        NSLog(@"同步任务 %@666666", [NSThread currentThread]);
    });
    
    
}
//异步并行
- (void)concunrrent_queue2
{
    dispatch_queue_t q = dispatch_queue_create("这里显示的是1", DISPATCH_QUEUE_CONCURRENT);
    for (int i =0; i<10; i++) {
        dispatch_async(q, ^{
            sleep(1);
            NSLog(@"异步%@-- %d",[NSThread currentThread],i);
            
        });
    }
    //    for (int i = 0; i<5; i++) {
    //        dispatch_sync(q, ^{
    //            NSLog( @"同步%@ -- %d",[NSThread currentThread],i);
    //        });
    //    }
    
}
/**
 *  串行队列开启异步任务，是有顺序的
 */
- (void)serial_queue
{
    dispatch_queue_t q = dispatch_queue_create("cn.itcast.gcddemo", DISPATCH_QUEUE_SERIAL);
    
    dispatch_async(q, ^{
        NSLog(@"异步任务 %@1111111", [NSThread currentThread]);
    });
    
    dispatch_async(q, ^{
        NSLog(@"异步任务 %@22222", [NSThread currentThread]);
    });
    
    dispatch_async(q, ^{
        NSLog(@"异步任务 %@3333", [NSThread currentThread]);
    });
    dispatch_async(q, ^{
        NSLog(@"异步任务 %@44444", [NSThread currentThread]);
    });
    
    
    
}

/**
 *  串行队列开启异步任务后嵌套同步任务造成死锁
 */
- (void)serial_queue_deadlock2
{
    dispatch_queue_t q = dispatch_queue_create("cn.itcast.gcddemo", DISPATCH_QUEUE_SERIAL);
    
    
    dispatch_async(q, ^{
        NSLog(@"异步任务 %@", [NSThread currentThread]);
        // 下面开启同步造成死锁：因为串行队列中线程是有执行顺序的，需要等上面开启的异步任务执行完毕，才会执行下面开启的同步任务。而上面的异步任务还没执行完，要到下面的大括号才算执行完毕，而下面的同步任务已经在抢占资源了，就会发生死锁。
        dispatch_sync(q, ^{
            NSLog(@"同步任务 %@", [NSThread currentThread]);
        });
        
    });
    
}

/**
 *  串行队列开启同步任务后嵌套同步任务造成死锁
 */
- (void)serial_queue_deadlock1
{
    dispatch_queue_t q = dispatch_queue_create("cn.itcast.gcddemo", DISPATCH_QUEUE_SERIAL);
    
    dispatch_sync(q, ^{
        NSLog(@"同步任务 %@", [NSThread currentThread]);
        // 下面开启同步造成死锁：因为串行队列中线程是有执行顺序的，需要等上面开启的同步任务执行完毕，才会执行下面开启的同步任务。而上面的同步任务还没执行完，要到下面的大括号才算执行完毕，而下面的同步任务已经在抢占资源了，就会发生死锁。
        dispatch_sync(q, ^{
            NSLog(@"同步任务 %@", [NSThread currentThread]);
        });
        
    });
    NSLog(@"同步任务 %@", [NSThread currentThread]);
}


/**
 *  串行队列开启同步任务后嵌套异步任务不造成死锁
 */
- (void)serial_queue1
{
    dispatch_queue_t q = dispatch_queue_create("cn.itcast.gcddemo", DISPATCH_QUEUE_SERIAL);
    
    dispatch_sync(q, ^{
        NSLog(@"同步任务 %@", [NSThread currentThread]);
        
        // 开启异步，就会开启一个新的线程,不会阻塞线程
        dispatch_async(q, ^{
            NSLog(@"异步任务 %@", [NSThread currentThread]);
        });
        
    });
    NSLog(@"同步任务 %@", [NSThread currentThread]);
}

- (void)signal_dispacth{
     dispatch_queue_t queue = dispatch_queue_create("cn.gcd-group.www", DISPATCH_QUEUE_CONCURRENT);
    dispatch_set_target_queue(queue, DISPATCH_QUEUE_PRIORITY_DEFAULT);
    //dispatch_queue_t queue1 = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_t group = dispatch_group_create();//创建一个线程队列 group
    
    dispatch_group_async(group, queue, ^{
        [NSThread sleepForTimeInterval:3];//每个异步并行的任务都在这个group的控制之下
        NSLog(@"group1");
    });
    dispatch_group_async(group, queue, ^{
        [NSThread sleepForTimeInterval:2];
        NSLog(@"group2");
    });
    dispatch_group_async(group, queue, ^{
        [NSThread sleepForTimeInterval:2];
        NSLog(@"group3");
    });
    dispatch_group_async(group, queue, ^{
        [NSThread sleepForTimeInterval:4];
        NSLog(@"group4");
    });
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        NSLog(@"updateUi，以上的任务执行完毕，进入主线程加载UI");  //dispatch_group_noyify  当group里面的所有任务执行完毕 就可以进执行此任务
    });  
    //dispatch_release(group);//arc的情况写不必要写;
}
- (void)barrier{
    dispatch_queue_t queue = dispatch_queue_create("com.example.queue", DISPATCH_QUEUE_CONCURRENT);
    
   dispatch_async(queue, ^{
       NSLog(@"----- 1");
   });
    dispatch_async(queue, ^{
        NSLog(@"----- 2");
    });
    dispatch_async(queue, ^{
        NSLog(@"----- 3");
    });
    dispatch_async(queue, ^{
        NSLog(@"----- 4");
    });
    dispatch_async(queue, ^{
        NSLog(@"----- 5");
    });
    dispatch_async(queue, ^{
        NSLog(@"----- 6");
    });
    dispatch_async(queue, ^{
        NSLog(@"----- 7");
    });
    dispatch_async(queue, ^{
        NSLog(@"----- 8");
    });
    dispatch_barrier_async(queue, ^{
        NSLog(@"这是一条神奇的分割线");
    });
    dispatch_async(queue, ^{
        NSLog(@"----- 15");
    });
    dispatch_async(queue, ^{
        NSLog(@"----- 16");
    });
    dispatch_async(queue, ^{
        NSLog(@"----- 17");
    });
    dispatch_async(queue, ^{
        NSLog(@"----- 18");
    });

    
    //dispatch_release(queue);
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
