//
//  Transitions.swift
//  RxSwiftPlus
//
//  Created by Brady Svedin on 4/14/22.
//

import Foundation
import UIKit

public enum SlideDirection{
    case LEFT
    case RIGHT
    case UP
    case DOWN
}

public protocol UsesCustomTransition{
    var transition:StackTransition { get }
}

public typealias TransitionGenerator = (UIView) -> Void

public class TransitionGenerators{
    public class Companion {
        private init() {}
        public static let INSTANCE = Companion()
        public let none: TransitionGenerator = {_ in }
        public let fade: TransitionGenerator = {view in
            view.alpha = 0
        }
        public let growFade: TransitionGenerator = {view in
            view.alpha = 0
            view.transform = CGAffineTransform.init(scaleX: 0.75, y: 0.75).concatenating(CGAffineTransform.init(translationX: 0, y: 50))
        }
        public let shrinkFade: TransitionGenerator = {view in
            view.alpha = 0
            view.transform = CGAffineTransform.init(scaleX: 1.33, y: 1.33).concatenating(CGAffineTransform.init(translationX: 0, y: -50))
        }
        public func slide(direction: SlideDirection) -> TransitionGenerator {
            switch(direction){
            case .LEFT:
                return { view in
                    if let parent = view.superview {
                        view.transform = CGAffineTransform.init(translationX: -parent.frame.width, y: 0)
                    }
                }
            case .RIGHT:
                return { view in
                    if let parent = view.superview {
                        view.transform = CGAffineTransform.init(translationX: parent.frame.width, y: 0)
                    }
                }
            case .UP:
                return { view in
                    if let parent = view.superview {
                        view.transform = CGAffineTransform.init(translationX: 0, y: -parent.frame.height)
                    }
                }
            case .DOWN:
                return { view in
                    if let parent = view.superview {
                        view.transform = CGAffineTransform.init(translationX: 0, y: parent.frame.height)
                    }
                }
            }
        }
    }
}


public class TransitionTriple{
    public let enter: TransitionGenerator
    public let exit: TransitionGenerator
    
    public init(
        enter: @escaping TransitionGenerator,
        exit: @escaping TransitionGenerator
    ){
        self.enter = enter
        self.exit = exit
    }
    
    public class Companion {
        private init() {}
        public static let INSTANCE = Companion()
        public let PUSH: TransitionTriple = TransitionTriple(enter: TransitionGenerators.Companion.INSTANCE.slide(direction: .RIGHT), exit: TransitionGenerators.Companion.INSTANCE.slide(direction: .LEFT))
        public let POP: TransitionTriple = TransitionTriple(enter: TransitionGenerators.Companion.INSTANCE.slide(direction: .LEFT), exit: TransitionGenerators.Companion.INSTANCE.slide(direction: .RIGHT))
        public let PULL_DOWN: TransitionTriple = TransitionTriple(enter: TransitionGenerators.Companion.INSTANCE.slide(direction: .UP), exit: TransitionGenerators.Companion.INSTANCE.slide(direction: .DOWN))
        public let PULL_UP: TransitionTriple = TransitionTriple(enter: TransitionGenerators.Companion.INSTANCE.slide(direction: .DOWN), exit: TransitionGenerators.Companion.INSTANCE.slide(direction: .UP))
        public let FADE: TransitionTriple = TransitionTriple(enter: TransitionGenerators.Companion.INSTANCE.fade, exit: TransitionGenerators.Companion.INSTANCE.fade)
        public let NONE: TransitionTriple = TransitionTriple(enter: TransitionGenerators.Companion.INSTANCE.none, exit: TransitionGenerators.Companion.INSTANCE.none)
        public let GROW_FADE: TransitionTriple = TransitionTriple(enter: TransitionGenerators.Companion.INSTANCE.growFade, exit: TransitionGenerators.Companion.INSTANCE.growFade)
        public let SHRINK_FADE: TransitionTriple = TransitionTriple(enter: TransitionGenerators.Companion.INSTANCE.shrinkFade, exit:TransitionGenerators.Companion.INSTANCE.shrinkFade)
    }
}


/**
 * A combination of three [TransitionTriple]s to choose animations based on pushing and popping.
 */
public class StackTransition{
    public let push: TransitionTriple
    public let pop: TransitionTriple
    public let neutral: TransitionTriple
    
    public init(
        push: TransitionTriple,
        pop: TransitionTriple,
        neutral: TransitionTriple
    ){
        self.push = push
        self.pop = pop
        self.neutral = neutral
    }
    
    public class Companion {
        private init() {}
        public static let INSTANCE = Companion()
        
        /**
         * A normal push/pop transition style.
         */
        public let PUSH_POP = StackTransition(push: TransitionTriple.Companion.INSTANCE.PUSH, pop: TransitionTriple.Companion.INSTANCE.POP, neutral: TransitionTriple.Companion.INSTANCE.FADE)
        
        /**
         * Push and pop, but vertical.
         */
        public let PULL_UP = StackTransition(push: TransitionTriple.Companion.INSTANCE.PULL_UP, pop: TransitionTriple.Companion.INSTANCE.PULL_DOWN, neutral: TransitionTriple.Companion.INSTANCE.FADE)
        
        /**
         * Only use fades.
         */
        public let FADE_IN_OUT = StackTransition(push: TransitionTriple.Companion.INSTANCE.FADE, pop: TransitionTriple.Companion.INSTANCE.FADE, neutral: TransitionTriple.Companion.INSTANCE.FADE)
        
        /**
         * A modal-y transition, where the view fades in and grows.
         */
        public let MODAL = StackTransition(push: TransitionTriple.Companion.INSTANCE.GROW_FADE, pop: TransitionTriple.Companion.INSTANCE.GROW_FADE, neutral: TransitionTriple.Companion.INSTANCE.GROW_FADE)
        
        /**
         * Don't animate.
         */
        public let NONE = StackTransition(push: TransitionTriple.Companion.INSTANCE.NONE, pop: TransitionTriple.Companion.INSTANCE.NONE, neutral: TransitionTriple.Companion.INSTANCE.NONE)
    }
}

