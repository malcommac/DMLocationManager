//
//  DMOperation.h
//  DMLocationManagerExample
//
//  Created by Daniele Margutti (me@danielemargutti.com) on 11/10/12.
//  Copyright (c) 2012 http://www.danielemargutti.com. All rights reserved.
//  Distribuited under MIT License (http://opensource.org/licenses/MIT)
//

#import <Foundation/Foundation.h>

/*
 Theory of Operation
 -------------------
 Some critical points:
 
 1. By the time we're running on the run loop thread, we know that all further state
 transitions happen on the run loop thread.  That's because there are only three
 states (inited, executing, and finished) and run loop thread code can only run
 in the last two states and the transition from executing to finished is
 always done on the run loop thread.
 
 2. -start can only be called once.  So run loop thread code doesn't have to worry
 about racing with -start because, by the time the run loop thread code runs,
 -start has already been called.
 
 3. -cancel can be called multiple times from any thread.  Run loop thread code
 must take a lot of care with do the right thing with cancellation.
 
 Some state transitions:
 
 1. init -> dealloc
 2. init -> cancel -> dealloc
 XXX  3. init -> cancel -> start -> finish -> dealloc
 4. init -> cancel -> start -> startOnRunLoopThreadThread -> finish dealloc
 !!!  5. init -> start -> cancel -> startOnRunLoopThreadThread -> finish -> cancelOnRunLoopThreadThread -> dealloc
 XXX  6. init -> start -> cancel -> cancelOnRunLoopThreadThread -> startOnRunLoopThreadThread -> finish -> dealloc
 XXX  7. init -> start -> cancel -> startOnRunLoopThreadThread -> cancelOnRunLoopThreadThread -> finish -> dealloc
 8. init -> start -> startOnRunLoopThreadThread -> finish -> dealloc
 9. init -> start -> startOnRunLoopThreadThread -> cancel -> cancelOnRunLoopThreadThread -> finish -> dealloc
 !!! 10. init -> start -> startOnRunLoopThreadThread -> cancel -> finish -> cancelOnRunLoopThreadThread -> dealloc
 11. init -> start -> startOnRunLoopThreadThread -> finish -> cancel -> dealloc
 
 Markup:
 XXX means that the case doesn't happen.
 !!! means that the case is interesting.
 
 Described:
 
 1. It's valid to allocate an operation and never run it.
 2. It's also valid to allocate an operation, cancel it, and yet never run it.
 3. While it's valid to cancel an operation before it starting it, this case doesn't
 happen because -start always bounces to the run loop thread to maintain the invariant
 that the executing to finished transition always happens on the run loop thread.
 4. In this -startOnRunLoopThread detects the cancellation and finishes immediately.
 5. Because the -cancel can happen on any thread, it's possible for the -cancel
 to come in between the -start and the -startOnRunLoop thread.  In this case
 -startOnRunLoopThread notices isCancelled and finishes straightaway.  And
 -cancelOnRunLoopThread detects that the operation is finished and does nothing.
 6. This case can never happen because -performSelecton:onThread:xxx
 callbacks happen in order, -start is synchronised with -cancel, and -cancel
 only schedules if -start has run.
 7. This case can never happen because -startOnRunLoopThread will finish immediately
 if it detects isCancelled (see case 5).
 8. This is the standard run-to-completion case.
 9. This is the standard cancellation case.  -cancelOnRunLoopThread wins the race
 with finish, and it detects that the operation is executing and actually cancels.
 10. In this case the -cancelOnRunLoopThread loses the race with finish, but that's OK
 because -cancelOnRunLoopThread already does nothing if the operation is already
 finished.
 11. Cancellating after finishing still sets isCancelled but has no impact
 on the RunLoop thread code.
 */


enum {
    DMOperationStateInited,         // Allocated
    DMOperationStateExecuting,      // Executing state
    DMOperationStateFinished        // Ended
}; typedef NSUInteger DMOperationState;

@interface DMOperation : NSOperation {
    
}

@property (nonatomic,readonly)  DMOperationState    state;  // current operation state. You should not use it directly. To end the operation when subclass is done use finishOperationWithError:
@property (retain)              NSError*            error;  // last error occurred

// Override points

// A subclass will probably need to override -operationDidStart and -operationWillFinish
// to set up and tear down its run loop sources, respectively.  These are always called
// on the actual run loop thread.
//
// Note that -operationWillFinish will be called even if the operation is cancelled.
//
// -operationWillFinish can check the error property to see whether the operation was
// successful.  error will be NSCocoaErrorDomain/NSUserCancelledError on cancellation.
//
// -operationDidStart is allowed to call -finishWithError:.

- (void)operationDidStart;
- (void)operationWillFinish;

// To end the operation when subclass is done use finishOperationWithError:
- (void)finishOperationWithError:(NSError *)error;

@end
