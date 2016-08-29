import UIKit
import Cartography
import Photos

class GridController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

  lazy var dropdownController: DropdownController = self.makeDropdownController()
  lazy var gridView: GridView = self.makeGridView()

  var items: [PHAsset] = []
  var selectedItems: [PHAsset] = []
  var albums: [PHAssetCollection] = []

  // MARK: - Life cycle

  override func viewDidLoad() {
    super.viewDidLoad()

    setup()

    gridView.collectionView.registerClass(ImageCell.self, forCellWithReuseIdentifier: String(ImageCell.self))

    LibraryAssets.fetch { assets in
      self.items = assets
      self.gridView.collectionView.reloadData()
    }

    dropdownController.items = LibraryAssets.fetchAlbums()
  }

  // MARK: - Setup

  func setup() {
    view.addSubview(gridView)
    gridView.translatesAutoresizingMaskIntoConstraints = false

    addChildViewController(dropdownController)
    gridView.insertSubview(dropdownController.view, belowSubview: gridView.topView)
    dropdownController.didMoveToParentViewController(self)

    constrain(gridView) {
      gridView in

      gridView.edges == gridView.superview!.edges
    }

    constrain(dropdownController.view, gridView.topView) {
      dropdown, topView in

      dropdown.left == dropdown.superview!.left
      dropdown.right == dropdown.superview!.right
      dropdown.height == dropdown.superview!.height - 40
      self.dropdownController.topConstraint = (dropdown.top == topView.bottom + self.view.frame.size.height ~ 999 )
    }

    gridView.closeButton.addTarget(self, action: #selector(closeButtonTouched(_:)), forControlEvents: .TouchUpInside)
    gridView.doneButton.addTarget(self, action: #selector(doneButtonTouched(_:)), forControlEvents: .TouchUpInside)
    gridView.arrowButton.addTarget(self, action: #selector(arrowButtonTouched(_:)), forControlEvents: .TouchUpInside)

    gridView.collectionView.dataSource = self
    gridView.collectionView.delegate = self
  }

  // MARK: - Action

  func closeButtonTouched(button: UIButton) {
    dismissViewControllerAnimated(true, completion: nil)
  }

  func doneButtonTouched(button: UIButton) {

  }

  func arrowButtonTouched(button: ArrowButton) {
    dropdownController.toggle()
    button.toggle(dropdownController.expanding)
  }

  // MARK: - UICollectionViewDataSource

  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return items.count
  }

  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(String(ImageCell.self), forIndexPath: indexPath)
                as! ImageCell

    LibraryAssets.resolveAsset(items[indexPath.item]) { image in
      cell.imageView.image = image
    }

    configureFrameView(cell, indexPath: indexPath)

    return cell
  }

  // MARK: - UICollectionViewDelegateFlowLayout

  func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {

    let size = (collectionView.bounds.size.width - 6) / 4
    return CGSize(width: size, height: size)
  }

  func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    let item = items[indexPath.item]

    if !selectedItems.contains(item) {
      selectedItems.append(item)
    }

    configureFrameViews()
  }

  func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
    let item = items[indexPath.item]

    if let index = selectedItems.indexOf(item) {
      selectedItems.removeAtIndex(index)
    }

    configureFrameViews()
  }

  func configureFrameViews() {
    for case let cell as ImageCell in gridView.collectionView.visibleCells() {
      if let indexPath = gridView.collectionView.indexPathForCell(cell) {
        configureFrameView(cell, indexPath: indexPath)
      }
    }
  }

  func configureFrameView(cell: ImageCell, indexPath: NSIndexPath) {
    let item = items[indexPath.item]

    if let index = selectedItems.indexOf(item) {
      cell.frameView.hidden = false
      cell.frameView.label.text = "\(index + 1)"
    } else {
      cell.frameView.hidden = true
    }
  }

  // MARK: - Controls

  func makeDropdownController() -> DropdownController {
    let controller = DropdownController()

    return controller
  }

  func makeGridView() -> GridView {
    let view = GridView()

    return view
  }
}
