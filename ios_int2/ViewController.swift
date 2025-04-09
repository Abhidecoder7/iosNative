//
//  ViewController.swift
//  ios_int2
//
//  Created by Abhishek Vishwakarma on 11/03/25.
//

import UIKit
import CleverTapSDK
import SDWebImage

class ViewController: UIViewController, CleverTapDisplayUnitDelegate, CleverTapInboxViewControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    
    // MARK: - UI Elements
    @IBOutlet weak var inbox: UIButton!
    @IBOutlet weak var inApp: UIButton!
    @IBOutlet weak var event: UIButton!
    @IBOutlet weak var pushevent: UIButton!
    @IBOutlet weak var onuserlogin: UIButton!
    @IBOutlet weak var Native_Button: UIButton!
    @IBOutlet weak var NativeDisplay: UIImageView! // Original image view for single image display
    
    // MARK: - Properties
    var latestDisplayUnit: CleverTapDisplayUnit? // Stores the most recent display unit
    var imageURLs: [String] = [] // Array to store multiple image URLs
    var displayUnitID: String? // Stores the current display unit ID for tracking
    
    // Collection view for horizontal scrolling images
    var imageCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Register CleverTap Native Display Delegate to receive display unit updates
        CleverTap.sharedInstance()?.setDisplayUnitDelegate(self)
        
        // Setup collection view for horizontal image scrolling
        setupImageCollectionView()
    }
    
    /**
     Sets up the horizontal scrolling collection view for displaying multiple images
     - Creates a horizontal flow layout
     - Initializes the collection view with the same frame as NativeDisplay
     - Configures appearance and behavior
     - Registers cell for reuse
     */
    func setupImageCollectionView() {
        // Create layout for horizontal scrolling
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal // Enable horizontal scrolling
        layout.itemSize = CGSize(width: NativeDisplay.frame.width, height: NativeDisplay.frame.height) // Match existing image view size
        layout.minimumLineSpacing = 10 // Space between images
        
        // Create collection view with the same frame as NativeDisplay
        imageCollectionView = UICollectionView(frame: NativeDisplay.frame, collectionViewLayout: layout)
        imageCollectionView.backgroundColor = .clear
        imageCollectionView.showsHorizontalScrollIndicator = false // Hide scroll indicator for cleaner UI
        imageCollectionView.delegate = self
        imageCollectionView.dataSource = self
        
        // Register cell for image display
        imageCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "ImageCell")
        
        // Add to view and hide initially (will be shown when needed)
        view.addSubview(imageCollectionView)
        imageCollectionView.isHidden = true
    }

    // MARK: - Handle Native Display Data
    /**
     CleverTap Display Unit Delegate method called when new display units are available
     - Processes incoming display units
     - Extracts image URLs from content
     - Determines whether to show single image or collection view based on image count
     - Records impression event
     
     - Parameter displayUnits: Array of CleverTapDisplayUnit objects
     */
    func displayUnitsUpdated(_ displayUnits: [CleverTapDisplayUnit]) {
        print("🔹 Native Display Units Updated: \(displayUnits.count)")
        
        // Clear previous images to avoid mixing with new content
        imageURLs.removeAll()

        for unit in displayUnits {
            latestDisplayUnit = unit  // Store the latest unit for later reference

            if let unitID = unit.unitID {
                displayUnitID = unitID // Save for click tracking
                print("📢 Received Display Unit ID: \(unitID)")

                let contents = unit.contents ?? []
                // Extract all media URLs from the display unit contents
                for content in contents {
                    if let imageUrl = content.mediaUrl {
                        print("✅ Image URL: \(imageUrl)")
                        imageURLs.append(imageUrl) // Add to our collection of images
                    }
                }
                
                // Determine display mode and update UI on main thread
                DispatchQueue.main.async {
                    if self.imageURLs.count == 1 {
                        // Case: Single image - use the original UIImageView
                        self.imageCollectionView.isHidden = true
                        self.NativeDisplay.isHidden = false
                        self.NativeDisplay.sd_setImage(with: URL(string: self.imageURLs[0]), completed: nil)
                    } else if self.imageURLs.count > 1 {
                        // Case: Multiple images - use collection view for horizontal scrolling
                        self.NativeDisplay.isHidden = true
                        self.imageCollectionView.isHidden = false
                        self.imageCollectionView.reloadData() // Refresh with new images
                    }
                    
                    // Record impression (viewed) event for analytics
                    CleverTap.sharedInstance()?.recordDisplayUnitViewedEvent(forID: unitID)
                    print("📢 Notification Viewed Event Recorded for ID: \(unitID)")
                }
            }
        }
    }
    
    // MARK: - UICollectionView DataSource
    /**
     Returns the number of items (images) to display in the collection view
     */
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageURLs.count
    }
    
    /**
     Configures and returns a cell for the collection view
     - Creates an image view inside each cell
     - Loads the image using SDWebImage
     
     - Parameters:
        - collectionView: The collection view requesting the cell
        - indexPath: The index path for the cell
     
     - Returns: Configured UICollectionViewCell with image
     */
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath)
        
        // Remove any existing image views to prevent duplicates when cells are reused
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        
        // Create image view for the cell with proper sizing
        let imageView = UIImageView(frame: cell.contentView.bounds)
        imageView.contentMode = .scaleAspectFit // Maintain aspect ratio
        imageView.clipsToBounds = true
        
        // Load image from URL using SDWebImage
        if indexPath.item < imageURLs.count {
            imageView.sd_setImage(with: URL(string: imageURLs[indexPath.item]), completed: nil)
        }
        
        cell.contentView.addSubview(imageView)
        return cell
    }
    
    // MARK: - UICollectionView Delegate
    /**
     Handles selection of an image in the collection view
     - Records click event with CleverTap for analytics
     
     - Parameters:
        - collectionView: The collection view containing the selected cell
        - indexPath: The index path of the selected cell
     */
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let unitID = displayUnitID {
            // Record click event for the selected image
            CleverTap.sharedInstance()?.recordDisplayUnitClickedEvent(forID: unitID)
            print("📢 Notification Clicked Event Recorded for ID: \(unitID)")
        }
    }

    /**
     Handles tap on the original native display image view
     - Records click event with CleverTap for analytics
     
     - Parameter sender: The object that triggered the action
     */
    @IBAction func nativeDisplayTapped(_ sender: Any) {
        // Ensure we have a valid display unit before recording the click
        if let displayUnit = latestDisplayUnit, let unitID = displayUnit.unitID {
            CleverTap.sharedInstance()?.recordDisplayUnitClickedEvent(forID: unitID)
            print("📢 Notification Clicked Event Recorded for ID: \(unitID)")
        } else {
            print("⚠️ No Display Unit Available for Click Event")
        }
    }

    /**
     Handles Native Display button tap
     - Records event with CleverTap for triggering native display
     
     - Parameter sender: The object that triggered the action
     */
    @IBAction func Native_Button(_ sender: Any) {
        CleverTap.sharedInstance()?.recordEvent("Native Display")
    }

    // MARK: - CleverTap App Inbox
    /**
     Handles inbox button tap
     - Records event and opens CleverTap inbox UI
     
     - Parameter sender: The object that triggered the action
     */
    @IBAction func inbox(_ sender: Any) {
        CleverTap.sharedInstance()?.recordEvent("Inbox")

        // Configure inbox style
        let style = CleverTapInboxStyleConfig()
        style.title = "App Inbox"
        style.backgroundColor = .white
        style.messageTags = ["Slide1", "Slide2"]
        style.navigationBarTintColor = UIColor(red: 1.0, green: 0.7, blue: 0.4, alpha: 1.0)
        style.navigationTintColor = .black
        style.tabUnSelectedTextColor = .blue
        style.tabSelectedTextColor = .black
        style.tabSelectedBgColor = .white
        style.firstTabTitle = "My First Tab"

        // Create and present inbox view controller
        if let inboxController = CleverTap.sharedInstance()?.newInboxViewController(with: style, andDelegate: self) {
            let navigationController = UINavigationController(rootViewController: inboxController)
            self.present(navigationController, animated: true, completion: nil)
        }
    }

    // MARK: - CleverTap Event Triggers
    /**
     Handles in-app notification button tap
     - Records event to trigger in-app notification
     
     - Parameter sender: The object that triggered the action
     */
    @IBAction func inApp(_ sender: Any) {
        CleverTap.sharedInstance()?.recordEvent("In-app_2 Notification Triggered")
    }
    
    /**
     Handles event button tap
     - Records product viewed event
     
     - Parameter sender: The object that triggered the action
     */
    @IBAction func event(_ sender: Any) {
        CleverTap.sharedInstance()?.recordEvent("Product viewed")
    }
    
    /**
     Handles user login button tap
     - Creates user profile and logs in
     
     - Parameter sender: The object that triggered the action
     */
    @IBAction func onuserlogin(_ sender: Any) {
        // Create user profile with properties
        let profile: [String: AnyObject] = [
            "Name": "Abhishek" as AnyObject,
            "Email": "Abhishek@gmail.com" as AnyObject,
            "Identity": 224222 as AnyObject,
//            "Plan type": "Silver" as AnyObject,
//            "Favorite Food": "Pizza" as AnyObject
            "MSG-push":true as AnyObject
//            "MSG-push":true,
        ]
        CleverTap.sharedInstance()?.onUserLogin(profile)
    }
    
    /**
     Handles push event button tap
     - Records product viewed event for push notification
     
     - Parameter sender: The object that triggered the action
     */
    @IBAction func pushevent(_ sender: Any) {
        CleverTap.sharedInstance()?.recordEvent("Product viewed")
    }
}

//git commit
