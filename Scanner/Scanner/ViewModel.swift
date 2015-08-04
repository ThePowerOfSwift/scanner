//
//  BaseViewModel.swift
//  Scanner
//
//  Created by Tamás Zahola on 04/08/15.
//  Copyright (c) 2015 Tamás Zahola. All rights reserved.
//

import Foundation

protocol ViewModelObserver : class {
    
    func viewModelChanged(viewModel: ViewModel) -> Void
    
}

class ViewModel {
    
    class ObserverToken : Equatable {
        
        private unowned let observer:ViewModelObserver
        
        private init(_ observer:ViewModelObserver) {
            self.observer = observer
        }
        
    }
    
    private var observers:[ObserverToken] = []
    
    func addObserver(observer: ViewModelObserver) -> ObserverToken {
        let entry = ObserverToken(observer)
        self.observers.append(entry)
        return entry
    }
    
    func removeObserver(observer: ObserverToken) -> Void {
        self.observers.removeAtIndex(find(self.observers, observer)!)
    }
    
    func notifyObservers() -> Void {
        for observer in self.observers {
            observer.observer.viewModelChanged(self)
        }
    }
    
}

func ==(lhs: ViewModel.ObserverToken, rhs: ViewModel.ObserverToken) -> Bool {
    return lhs === rhs
}
