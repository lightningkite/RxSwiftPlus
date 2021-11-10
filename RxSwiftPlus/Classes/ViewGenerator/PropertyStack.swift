//
//  PropertyStack.swift
//  RxSwift
//
//  Created by Joseph Ivie on 11/9/21.
//

import RxSwift

public extension HasValueSubject where Element == Array<ViewGenerator> {
    
    func push(_ viewGenerator: ViewGenerator) -> Void {
        self.value.append(viewGenerator)
    }
    
    func swap(_ viewGenerator: ViewGenerator) -> Void {
        var copy = self.value
        copy.remove(at: (copy.count - 1))
        copy.append(viewGenerator)
        self.value = copy
    }
    
    func pop() -> Bool {
        if self.value.count <= 1 {
            return false
        }
        self.value.remove(at: (self.value.count - 1))
        return true
    }
    
    func dismiss() -> Bool {
        if self.value.isEmpty {
            return false
        }
        self.value.remove(at: (self.value.count - 1))
        return true
    }
    
    func backPressPop() -> Bool {
        let last = self.value.last
        if let last = last as? HasBackAction, last.onBackPressed() { return true }
        return self.pop()
    }
    
    func backPressDismiss() -> Bool {
        let last = self.value.last
        if let last = last as? HasBackAction, last.onBackPressed() { return true }
        return self.dismiss()
    }
    
    func popTo(predicate: (ViewGenerator) -> Bool) -> Void {
        var found = false
        var copy = self.value
        for i in ((0...(copy.count - 1))){
            if found {
                copy.remove(at: (copy.count - 1))
            } else { if predicate(copy[i]) {
                    found = true
            } }
        }
        self.value = copy
    }
    
    func root() -> Void {
        self.value = [self.value[0]]
    }
    
    func reset(_ viewGenerator: ViewGenerator) -> Void {
        self.value = [viewGenerator]
    }
}
