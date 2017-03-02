/*
 Copyright 2016-present The Material Motion Authors. All Rights Reserved.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Foundation

/**
 Create a core animation spring system for a Spring plan.

 Only works with Subtractable types due to use of additive animations.
 */
@available(iOS 9.0, *)
public func coreAnimation<T>(_ spring: SpringShadow<T>) -> (MotionObservable<T>) where T: Subtractable, T: Zeroable, T: Equatable {
  let initialVelocityStream = spring.initialVelocity.asStream()
  return MotionObservable(Metadata("Core Animation Spring", args: [spring.enabled, spring.state, spring.initialValue, spring.initialVelocity, spring.destination, spring.tension, spring.friction, spring.mass, spring.suggestedDuration, spring.threshold])) { observer in
    var animationKeys: [String] = []

    var to: T?
    var activeAnimations = Set<String>()

    var initialVelocity: T?

    let initialVelocitySubscription = initialVelocityStream.subscribe {
      initialVelocity = $0
    }

    let checkAndEmit = {
      guard let to = to, spring.enabled.value else { return }

      let animation = CASpringAnimation()

      animation.damping = spring.friction.value
      animation.stiffness = spring.tension.value
      animation.mass = spring.mass.value

      animation.isAdditive = true

      let from = spring.initialValue.value
      let delta = from - to
      animation.fromValue = delta
      animation.toValue = T.zero()

      if spring.suggestedDuration.value != 0 {
        animation.duration = spring.suggestedDuration.value
      } else {
        animation.duration = animation.settlingDuration
      }

      if delta != T.zero() as! T {
        observer.next(to)

        let key = NSUUID().uuidString
        activeAnimations.insert(key)
        animationKeys.append(key)

        spring.state.value = .active

        observer.coreAnimation?(.add(animation, key, initialVelocity: initialVelocity, timeline: nil, completionBlock: {
          activeAnimations.remove(key)
          if activeAnimations.count == 0 {
            spring.state.value = .atRest
          }
        }))

        initialVelocity = nil
      }
    }

    let destinationSubscription = spring.destination.subscribe { value in
      to = value
      checkAndEmit()
    }

    var wasDisabled = false
    let activeSubscription = spring.enabled.asStream().dedupe().subscribe { enabled in
      if enabled {
        if wasDisabled {
          wasDisabled = false
          checkAndEmit()
        }
      } else {
        wasDisabled = true
        for key in animationKeys {
          observer.coreAnimation?(.remove(key))
        }
        activeAnimations.removeAll()
        animationKeys.removeAll()
        spring.state.value = .atRest
      }
    }

    return {
      for key in animationKeys {
        observer.coreAnimation?(.remove(key))
      }
      destinationSubscription.unsubscribe()
      activeSubscription.unsubscribe()
      initialVelocitySubscription.unsubscribe()
    }
  }
}