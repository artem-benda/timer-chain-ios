//
//  TimerChainsViewController.swift
//  TimerChain
//
//  Created by Artem Benda on 09.02.2021.
//

import UIKit
import CoreData

class TimerChainsViewController: UIViewController, DataViewController {
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var collectionViewOperations: [BlockOperation] = []
    
    var dataController: DataController!
    var fetchedResultController: NSFetchedResultsController<Chain>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let columnLayout = ColumnFlowLayout(
                    cellsPerRow: 1,
                    minimumInteritemSpacing: 10,
                    minimumLineSpacing: 10,
                    sectionInset: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
                )
        collectionView.setCollectionViewLayout(columnLayout, animated: true)
        collectionView.dragInteractionEnabled = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFetchedResultController()

        if let indexPaths = collectionView.indexPathsForSelectedItems, !indexPaths.isEmpty {
            indexPaths.forEach { (indexPath) in
                collectionView.deselectItem(at: indexPath, animated: true)
            }
            collectionView.reloadItems(at: indexPaths)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultController = nil
    }
    
    private func setupFetchedResultController() {
        print("setupFetchedResultController, start")
        let fetchRequest: NSFetchRequest<Chain> = Chain.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "orderIndex", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        if let searchText = searchBar.text, !searchText.isEmpty {
            print("setupFetchedResultController, predicate with search text = \(searchText)")
            let predicate = NSPredicate(format: "(name CONTAINS[cd] %@)", searchText)
            fetchRequest.predicate = predicate
        }
        
        NSFetchedResultsController<Chain>.deleteCache(withName: "chains")
        fetchedResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "chains")
        fetchedResultController.delegate = self
        
        do {
            try fetchedResultController.performFetch()
            collectionView.reloadData()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    /// Display an alert prompting the user to name a new timer chain. Calls
    /// `addChain(name:)`.
    @IBAction func presentNewChainAlert() {
        let alert = UIAlertController(title: "New Timer Chain", message: "Enter a name for this Chain", preferredStyle: .alert)

        // Create actions
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] action in
            if let name = alert.textFields?.first?.text {
                self?.addChain(name: name)
            }
        }
        saveAction.isEnabled = false

        // Add a text field
        alert.addTextField { textField in
            textField.placeholder = "Name"
            NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: textField, queue: .main) { notif in
                if let text = textField.text, !text.isEmpty {
                    saveAction.isEnabled = true
                } else {
                    saveAction.isEnabled = false
                }
            }
        }

        alert.addAction(cancelAction)
        alert.addAction(saveAction)
        present(alert, animated: true, completion: nil)
    }

    /// Adds a new timer chain to the database
    func addChain(name: String) {
        print("addChain(start) name = \(name)")
        // Returning if the request is not performed
        guard let fetchedObjects = fetchedResultController.fetchedObjects else { return }
        
        print("Adding new Timer Chain")
        let chain = Chain(context: dataController.viewContext)
        chain.name = name
        chain.createdAt = Date()
        // Set orderIndex, so it would be last element
        chain.orderIndex = Int64(fetchedObjects.count)
        try? dataController.viewContext.save()
    }

    /// Deletes the timer chain at the specified index path
    func deleteChain(at indexPath: IndexPath) {
        let chainToDelete = fetchedResultController.object(at: indexPath)
        dataController.viewContext.delete(chainToDelete)
        try? dataController.viewContext.save()
    }
    
    deinit {
        for o in collectionViewOperations { o.cancel() }
        collectionViewOperations.removeAll()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "editTimerChainSegue":
            let chain = sender as! Chain
            let viewController = segue.destination as! EditTimerChainViewController
            viewController.chain = chain
            viewController.dataController = dataController
        default:
            break
        }
    }

}

extension TimerChainsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let fetchedObjects = fetchedResultController.fetchedObjects
        guard fetchedObjects != nil, indexPath.row < fetchedObjects!.count else { return }
        if let chain = fetchedResultController.fetchedObjects?[indexPath.row] {
            performSegue(withIdentifier: "editTimerChainSegue", sender: chain)
        }
    }
}

extension TimerChainsViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let result = fetchedResultController.sections?[section].numberOfObjects ?? 0
        return result
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "timerChainsCell", for: indexPath) as! UICollectionViewListCell
        // Get model
        let fetchedObjects = fetchedResultController.fetchedObjects
        guard fetchedObjects != nil, indexPath.row < fetchedObjects!.count else { return cell }
        if let chain = fetchedResultController.fetchedObjects?[indexPath.row] {
            var content = cell.defaultContentConfiguration()
            // Configure content.
            content.image = UIImage(systemName: "star")
            content.text = chain.name
            // Customize appearance.
            content.imageProperties.tintColor = .purple
            cell.contentConfiguration = content
        }
        return cell
    }
}

extension TimerChainsViewController: UICollectionViewDragDelegate {
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        // TODO
        guard let fetchedObjects = fetchedResultController.fetchedObjects, indexPath.row < fetchedObjects.count else {
            print("Preventing dragging")
            return [UIDragItem]()
        }
        
        let chain = fetchedObjects[indexPath.row]
        let itemProvider = NSItemProvider(object: chain.objectID.uriRepresentation().absoluteString as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = chain
        return [dragItem]
    }
}

extension TimerChainsViewController: UICollectionViewDropDelegate {
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        if collectionView === self.collectionView {
            if collectionView.hasActiveDrag {
                return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
            } else {
                return UICollectionViewDropProposal(operation: .forbidden)
            }
        } else {
            if collectionView.hasActiveDrag {
                return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
            } else {
                return UICollectionViewDropProposal(operation: .copy, intent: .insertAtDestinationIndexPath)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard let fetchedObjects = fetchedResultController.fetchedObjects else { return }
        let destinationIndexPath: IndexPath
        if let indexPath = coordinator.destinationIndexPath {
            destinationIndexPath = indexPath
        } else {
            // Get last index path of table view.
            let section = collectionView.numberOfSections - 1
            let row = collectionView.numberOfItems(inSection: section)
            destinationIndexPath = IndexPath(row: row, section: section)
        }
        let dropItem = coordinator.items[0]
        let droppedChain = dropItem.dragItem.localObject as! Chain
        let sourceIndexPath = dropItem.sourceIndexPath!
        switch coordinator.proposal.operation {
        case .move:
            let backgroundContext = dataController.backgroundContext!
            backgroundContext.perform {
                var orderedObjects = fetchedObjects
                orderedObjects.remove(at: sourceIndexPath.row)
                orderedObjects.insert(droppedChain, at: destinationIndexPath.row)
                for (index, object) in orderedObjects.enumerated() {
                    if object.orderIndex != index {
                        let bgObject = backgroundContext.object(with: object.objectID) as! Chain
                        bgObject.orderIndex = Int64(index)
                    }
                }
                try? backgroundContext.save()
            }
        default: break
        }
    }
}

extension TimerChainsViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        setupFetchedResultController()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
    }
}

extension TimerChainsViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
            case .insert:
                collectionViewOperations.append(BlockOperation(block: { [weak self] in
                    self!.collectionView.insertItems(at: [newIndexPath!])
                }))
            case .delete:
                collectionViewOperations.append(BlockOperation(block: { [weak self] in
                    self!.collectionView.deleteItems(at: [indexPath!])
                }))
            case .update:
                collectionViewOperations.append(BlockOperation(block: { [weak self] in
                    self!.collectionView.reloadItems(at: [indexPath!])
                }))
            case .move:
                collectionViewOperations.append(BlockOperation(block: { [weak self] in
                    // self!.collectionView.moveItem(at: indexPath!, to: newIndexPath!)
                    self!.collectionView.deleteItems(at: [indexPath!])
                    self!.collectionView.insertItems(at: [newIndexPath!])
                }))
            default:
                break
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView.performBatchUpdates({ () -> Void in
            for op: BlockOperation in self.collectionViewOperations { op.start() }
        }, completion: { (finished) -> Void in self.collectionViewOperations.removeAll() })
    }
}
