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

extension MotionObservableConvertible where T: UIGestureRecognizer {

  /** Only forwards the gesture recognizer if its state matches the provided value. */
  public func whenRecognitionState(is state: UIGestureRecognizerState) -> MotionObservable<T> {
    return _filter(#function, args: [state]) { value in
      return value.state == state
    }
  }

  /** Only forwards the gesture recognizer if its state matches any of the provided values. */
  public func whenRecognitionState(isAnyOf states: [UIGestureRecognizerState]) -> MotionObservable<T> {
    return _filter(#function, args: [states]) { value in
      return states.contains(value.state)
    }
  }

  public func asMotionState() -> MotionObservable<MotionState> {
    return _map(#function) { value in
      if let tap = value as? UITapGestureRecognizer {
        return (value.state == .recognized) ? .active : .atRest
      } else {
        return (value.state == .began || value.state == .changed) ? .active : .atRest
      }
    }
  }

  public func active() -> MotionObservable<Bool> {
    return _map(#function) { value in
      return value.state == .began || value.state == .changed
    }
  }

  public func atRest() -> MotionObservable<Bool> {
    return _map(#function) { value in
      return value.state != .began && value.state != .changed
    }
  }
}
