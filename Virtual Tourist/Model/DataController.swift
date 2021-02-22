//
//  DataController.swift
//  Virtual Tourist
//
//  Created by Dylan Macalast on 06/10/2020.
//  Copyright © 2020 DylanMacalast. All rights reserved.
//

import Foundation
import CoreData

class DataController {
    //hold a persistent data instance
    let persistentContainer: NSPersistentContainer
    
    // help us access the context
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    let backgroundContext:NSManagedObjectContext!
    
    
    
    // init method to pass persistentContainer correct value
    init(modelFile: String) {
        persistentContainer = NSPersistentContainer(name: modelFile)
        backgroundContext = persistentContainer.newBackgroundContext()
    }
    
    // configure contexts
    func configureContexts() {
        viewContext.automaticallyMergesChangesFromParent = true
        backgroundContext.automaticallyMergesChangesFromParent = true
        
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    }
    
    //method to help us load the persistent store
    // completion handler to be called after loading store
    func load(completion: (() -> Void)? = nil) {
        persistentContainer.loadPersistentStores {
            storeDescription, error
            in
            guard error == nil else{
                fatalError(error!.localizedDescription)
            }
            // need to save the view context here
            self.configureContexts()
            completion?()
        }
    }
    
    static let shared = DataController(modelFile: "VirtualTourist")
    
    
    
}
