//
//  DetailViewController.swift
//  GitHubSearch
//
//  Created by Tomohiro Nishimura on 2015/09/21.
//  Copyright © 2015年 Tomohiro Nishimura. All rights reserved.
//

import UIKit
import SafariServices

class DetailViewController: UIViewController {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var openButton: UIButton!

    var repository: Repository? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }

    func configureView() {
        // Update the user interface for the detail item.
        if let repository = self.repository {
            self.nameLabel?.text = repository.fullName
            self.openButton?.setTitle(repository.HTMLURL.absoluteString, forState: .Normal)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
    }

    @IBAction func onURLClick(sender: AnyObject) {
        if let repository = self.repository {
            let safariView = SFSafariViewController(URL: repository.HTMLURL)
            safariView.delegate = self
            presentViewController(safariView, animated: true, completion: nil)
        }
    }
}

extension DetailViewController : SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(controller: SFSafariViewController) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
}

