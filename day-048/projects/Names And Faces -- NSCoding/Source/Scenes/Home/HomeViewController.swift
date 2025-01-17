//
//  ViewController.swift
//  Names And Faces
//
//  Created by Brian Sipple on 1/23/19.
//  Copyright © 2019 Brian Sipple. All rights reserved.
//

import UIKit

class HomeViewController: UICollectionViewController {
    var people: [Person] = []
    
    lazy var imagePicker: UIImagePickerController = makeImagePicker()
    lazy var userDefaults = UserDefaults.standard
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadPeople()
    }
}


// MARK: - Data Source

extension HomeViewController {

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return people.count
    }
    
    
    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        
        guard let cell = collectionView
            .dequeueReusableCell(withReuseIdentifier: StoryboardID.personCell, for: indexPath) as? PersonCell
        else {
            fatalError("Unable to deque person cell")
        }
        
        let person = people[indexPath.item]
        
        cell.personImageView.image = UIImage(contentsOfFile: getURL(forFile: person.imageName).path)
        cell.personNameLabel.text = person.name
        
        setStyles(forCell: cell)
        
        return cell
    }
}


// MARK: - Collection View Delegate

extension HomeViewController {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let person = people[indexPath.item]
        
        promptForEditing(of: person)
    }
}


// MARK: - Event handling

extension HomeViewController {
    @IBAction func addNewPerson(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true)
    }
}


// MARK: - Private Helper Methods

private extension HomeViewController {
    func getDocumentsDirectoryURL() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    
    func getURL(forFile fileName: String) -> URL {
        return getDocumentsDirectoryURL().appendingPathComponent(fileName)
    }
    
    
    func loadPeople() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            self.people = self.getPeople(fromDefaults: self.userDefaults) ?? [Person]()
            
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }
    
    
    func setStyles(forCell cell: PersonCell) {
        cell.personImageView.layer.borderColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.3).cgColor
        cell.personImageView.layer.borderWidth = 2
        cell.personImageView.layer.cornerRadius = 3
        cell.layer.cornerRadius = 7
    }
    
    
    func promptForEditing(of person: Person) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "Edit", style: .default) {  (_) in
            self.promptForName(of: person)
        })
        
        alertController.addAction(UIAlertAction(title: "Delete", style: .default) { (_) in
            self.delete(person)
        })
        
        present(alertController, animated: true)
    }
    
    
    func promptForName(of person: Person) {
        let alertController = UIAlertController(title: "Who is this?", message: nil, preferredStyle: .alert)
        
        alertController.addTextField()
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        alertController.addAction(
            UIAlertAction(title: "OK", style: .default) { (_) in
                let newName = alertController.textFields![0].text!
                
                person.name = newName
                self.save(people: self.people, toDefaults: self.userDefaults)
                self.collectionView.reloadData()
            }
        )
        
        present(alertController, animated: true)
    }
    
    
    func makeImagePicker() -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            imagePicker.sourceType = .camera
        }
        
        return imagePicker
    }
    
    
    func delete(_ person: Person) {
        guard let personIndex = self.people.firstIndex(of: person) else { return }
        
        people.remove(at: personIndex)
        save(people: people, toDefaults: userDefaults)
        collectionView.reloadData()
    }
}


// MARK: - UIImagePickerControllerDelegate

extension HomeViewController: UIImagePickerControllerDelegate {
    /*
     Handles the completion of adding an image to the picker. Our flow:
     - Extract the image from the dictionary that is passed as a parameter.
     - Generate a unique filename for it.
     - Convert it to a JPEG
     - Write that JPEG to disk.
     - Dismiss the view controller.
     */
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
    ) {
        guard let imagePicked = info[.editedImage] as? UIImage else { return }
        
        let fileName = UUID().uuidString
        let imageURL = getURL(forFile: fileName)
        
        if let jpegData = imagePicked.jpegData(compressionQuality: 0.8) {
            try? jpegData.write(to: imageURL)
        }
        
        people.append(Person(name: "Unknown", imageName: fileName))
        
        save(people: people, toDefaults: userDefaults)
        collectionView.reloadData()
        
        picker.dismiss(animated: true)
    }
}


// MARK: - UINavigationControllerDelegate

extension HomeViewController: UINavigationControllerDelegate {
    
}
