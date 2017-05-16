//
//  SessionActionsViewController.swift
//  WWDC
//
//  Created by Guilherme Rambo on 06/05/17.
//  Copyright © 2017 Guilherme Rambo. All rights reserved.
//

import Cocoa
import PlayerUI
import ConfCore
import RxSwift
import RxCocoa

protocol SessionActionsViewControllerDelegate: class {
    
    func sessionActionsDidSelectFavorite(_ sender: NSView?)
    func sessionActionsDidSelectDownload(_ sender: NSView?)
    func sessionActionsDidSelectShare(_ sender: NSView?)
    
}

class SessionActionsViewController: NSViewController {

    init() {
        super.init(nibName: nil, bundle: nil)!
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var disposeBag = DisposeBag()
    
    var viewModel: SessionViewModel? = nil {
        didSet {
            updateBindings()
        }
    }
    
    weak var delegate: SessionActionsViewControllerDelegate?
    
    private lazy var favoriteButton: PUIButton = {
        let b = PUIButton(frame: .zero)
        
        b.image = #imageLiteral(resourceName: "favorite")
        b.alternateImage = #imageLiteral(resourceName: "favorite-filled")
        b.target = self
        b.action = #selector(toggleFavorite(_:))
        b.isToggle = true
        b.shouldAlwaysDrawHighlighted = true
        
        return b
    }()
    
    private lazy var downloadButton: PUIButton = {
        let b = PUIButton(frame: .zero)
        
        b.image = #imageLiteral(resourceName: "download")
        b.target = self
        b.action = #selector(download(_:))
        b.shouldAlwaysDrawHighlighted = true
        
        return b
    }()
    
    private lazy var downloadIndicator: NSProgressIndicator = {
        let pi = NSProgressIndicator(frame: NSRect(x: 0, y: 0, width: 24, height: 24))
        
        pi.style = .spinningStyle
        pi.isIndeterminate = false
        pi.minValue = 0
        pi.maxValue = 1
        pi.doubleValue = 0
        pi.translatesAutoresizingMaskIntoConstraints = false
        pi.widthAnchor.constraint(equalToConstant: 24).isActive = true
        pi.heightAnchor.constraint(equalToConstant: 24).isActive = true
        pi.isHidden = true
        
        return pi
    }()
    
    private lazy var shareButton: PUIButton = {
        let b = PUIButton(frame: .zero)
        
        b.image = #imageLiteral(resourceName: "share")
        b.target = self
        b.action = #selector(share(_:))
        b.shouldAlwaysDrawHighlighted = true
        
        return b
    }()
    
    private lazy var stackView: NSStackView = {
        let v = NSStackView(views: [self.favoriteButton, self.downloadButton, self.downloadIndicator, self.shareButton])
        
        v.orientation = .horizontal
        v.spacing = 22
        v.alignment = .centerY
        v.distribution = .equalSpacing
        v.autoresizingMask = [.viewWidthSizable, .viewHeightSizable]
        
        return v
    }()
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 122, height: 28))
        view.wantsLayer = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.widthAnchor.constraint(equalToConstant: 122).isActive = true
        view.heightAnchor.constraint(equalToConstant: 28).isActive = true
        
        stackView.frame = view.bounds
        view.addSubview(stackView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateBindings()
    }
    
    private func updateBindings() {
        self.disposeBag = DisposeBag()
        
        guard let viewModel = viewModel else { return }
        
        viewModel.rxIsFavorite.subscribe(onNext: { [weak self] isFavorite in
            self?.favoriteButton.state = isFavorite ? NSOnState : NSOffState
        }).addDisposableTo(self.disposeBag)
        
        let rxActiveDownload = viewModel.rxActiveDownloads.map({ $0.first })
        
        let rxHideDownloadButton = rxActiveDownload.map({ $0?.status == .downloading || $0?.status == .completed })
        
        rxHideDownloadButton.observeOn(MainScheduler.instance).bind(to: downloadButton.rx.isHidden).addDisposableTo(self.disposeBag)
        rxHideDownloadButton.observeOn(MainScheduler.instance).map({ !$0 }).bind(to: downloadIndicator.rx.isHidden).addDisposableTo(self.disposeBag)
        
        rxActiveDownload.subscribe(onNext: { [weak self] download in
            guard let download = download else {
                self?.downloadIndicator.doubleValue = 0
                return
            }
            
            switch download.status {
            case .downloading:
                self?.downloadIndicator.doubleValue = download.progress
            default: break
            }
        }).addDisposableTo(self.disposeBag)
    }
    
    @IBAction func toggleFavorite(_ sender: NSView?) {
        delegate?.sessionActionsDidSelectFavorite(sender)
    }
    
    @IBAction func download(_ sender: NSView?) {
        delegate?.sessionActionsDidSelectDownload(sender)
    }
    
    @IBAction func share(_ sender: NSView?) {
        delegate?.sessionActionsDidSelectShare(sender)
    }
    
}
