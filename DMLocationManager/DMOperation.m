//
//  DMOperation.h
//  DMLocationManagerExample
//
//  Created by Daniele Margutti (me@danielemargutti.com) on 11/10/12.
//  Copyright (c) 2012 http://www.danielemargutti.com. All rights reserved.
//  Distribuited under MIT License (http://opensource.org/licenses/MIT)
//

#import "DMOperation.h"

@interface DMOperation () {
    DMOperationState            state_;
    NSError*                    error;
}

@property (nonatomic,assign, readwrite)   DMOperationState                        state;

@end


@implementation DMOperation

@synthesize error;

- (id)init
{
    self = [super init];
    if (self) {
        assert(self.state == DMOperationStateInited);
    }
    return self;
}

- (DMOperationState) state {
    return state_;
}

- (void) setState:(DMOperationState) newState {
    @synchronized(self) {
        DMOperationState oldState = state_;
        
        // The following check is really important. The state of an operation can only go forward, and there should be no redundant
        // changes to the state (that is, newState must never be equal to self.state)
        if (newState > state_) {
        
            if ( (newState == DMOperationStateExecuting) || (oldState == DMOperationStateExecuting))
                [self willChangeValueForKey:@"isExecuting"];
        
            if ( newState == DMOperationStateFinished )
                [self willChangeValueForKey:@"isFinished"];
        
            state_ = newState;
        
            if (newState == DMOperationStateFinished)
                [self didChangeValueForKey:@"isFinished"];
        
            if ( (newState == DMOperationStateExecuting) || (oldState == DMOperationStateExecuting) )
                [self didChangeValueForKey:@"isExecuting"];
        }
    }
}


- (BOOL)isConcurrent {
    return YES;
}

- (BOOL)isExecuting {
    return self.state == DMOperationStateExecuting;
}

- (BOOL)isFinished {
    return self.state == DMOperationStateFinished;
}

- (void)start {
    assert(self.state == DMOperationStateInited);
    
    // We have to change the state here, otherwise isExecuting won't necessarily return
    // true by the time we return from -start.  Also, we don't test for cancellation
    // here because that would a) result in us sending isFinished notifications on a
    // thread that isn't our run loop thread, and b) confuse the core cancellation code,
    // which expects to run on our run loop thread.  Finally, we don't have to worry
    // about races with other threads calling -start.  Only one thread is allowed to
    // start us at a time.
    
    self.state = DMOperationStateExecuting;
    [self performSelector:@selector(startOnRunLoopThread)
                 onThread:[NSThread mainThread]
               withObject:nil
            waitUntilDone:NO
                    modes:[NSSet setWithObject:NSDefaultRunLoopMode]];
}

- (void)startOnRunLoopThread {
    // Starts the operation.  The actual -start method is very simple,
    // deferring all of the work to be done on the run loop thread by this method.
    assert(self.state == DMOperationStateExecuting);
    
    if ([self isCancelled])
        // We were cancelled before we even got running.  Flip the the finished state immediately.
        [self finishOperationWithError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil]];
    else
        [self operationDidStart];
}

- (void)finishOperationWithError:(NSError *)setError {
    self.error = setError;
    [self operationWillFinish];
    self.state = DMOperationStateFinished;
}

- (void) cancel {
    BOOL    oldValue;
    BOOL    runCancelOnRunLoopThread;
    @synchronized(self) {
        oldValue = [self isCancelled];
        // Call our super class so that isCancelled starts returning true immediately.
        [super cancel];
        runCancelOnRunLoopThread = ! oldValue && self.state == DMOperationStateExecuting;
    }
    if (runCancelOnRunLoopThread)
        [self performSelector:@selector(cancelOnRunLoopThread)
                     onThread:[NSThread mainThread]
                   withObject:nil
                waitUntilDone:YES
                        modes:[NSSet setWithObject:NSDefaultRunLoopMode]];
}

- (void)cancelOnRunLoopThread {    
    // We know that a) state was kQRunLoopOperationStateExecuting when we were
    // scheduled (that's enforced by -cancel), and b) the state can't go
    // backwards (that's enforced by -setState), so we know the state must
    // either be kQRunLoopOperationStateExecuting or kQRunLoopOperationStateFinished.
    // We also know that the transition from executing to finished always
    // happens on the run loop thread.  Thus, we don't need to lock here.
    // We can look at state and, if we're executing, trigger a cancellation.
    
    if (self.state == DMOperationStateExecuting)
        [self finishOperationWithError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil]];
}

- (void)operationDidStart { }
- (void)operationWillFinish { }

@end
