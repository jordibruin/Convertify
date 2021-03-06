//
//  ViewController.swift
//  Convertify
//
//  Created by Hayden Hong on 8/7/18.
//  Copyright © 2018 Hayden Hong. All rights reserved.
//

import Alamofire
import UIKit

class ViewController: UIViewController {
    private var appleMusic: MusicSearcher!
    private var spotify: MusicSearcher!

    private var link: String?

    // Mark: Properties

    @IBOutlet var convertButton: UIButton!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var activityMonitor: UIActivityIndicatorView!

    // Mark: Functions

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_: Bool) {
        super.viewDidAppear(true)
        initApp(link: link ?? "")
    }

    func initApp(link: String) {
        self.link = link
        activityMonitor.startAnimating()
        spotify = spotifySearcher(completion: { error in
            if error == nil {
                self.appleMusic = appleMusicSearcher()

                self.handleLink(link: self.link ?? "")
            } else {
                self.activityMonitor.stopAnimating()
                self.activityMonitor.isHidden = true
                self.updateAppearance(title: "Error getting Spotify credentials", color: UIColor.red, enabled: false)
                self.convertButton.isHidden = false
            }
        })
    }

    /// Animates the color conversion in the app
    ///
    /// - Parameters:
    ///   - title: Name to set the label to
    ///   - color: Color to set the background to
    ///   - enabled: Whether or not the convert button should be shown
    private func updateAppearance(title: String, color: UIColor, enabled: Bool) {
        convertButton.setTitle(title, for: .normal)
        // Animate color shift
        UIView.animate(withDuration: 3.0, delay: 0.0, animations: {
            self.titleLabel.textColor = UIColor.white
            self.view.backgroundColor = color
            self.convertButton.setTitleColor(UIColor.white, for: .normal)
        }, completion: nil)

        convertButton.isEnabled = enabled
    }

    /// "Connects" Apple Music and Spotify for searching between them. Finds matching
    /// data from opposite source and allows the user to open links in opposite app.
    ///
    /// - Parameter link: Link to handle
    func handleLink(link: String) {
        // Resets the label text while converting
        titleLabel.text = "Convertify"

        // Decides what to do with the link
        switch true {
        // Ignores playlists
        case link.contains("playlist"):
            updateAppearance(title: "I cannot convert playlists ☹️", color: UIColor.red, enabled: false)
            break
        // Ignores radio stations
        case link.contains("/station/"):
            updateAppearance(title: "I cannot convert radio stations ☹️", color: UIColor.red, enabled: false)
            break
        // Extracts Spotify data and searches for Apple Music links when it includes a Spotify link
        case link.contains(SearcherURL.spotify):
            // Get the Apple Music version if the link is Spotify, double check for Spotify login
            handleSearching(link: link, source: spotify, destination: appleMusic)
            break
        // Extracts Apple Music data and searches for Spotify links when it includes an Apple Music link
        case link.contains(SearcherURL.appleMusic):
            handleSearching(link: link, source: appleMusic, destination: spotify)
            break
        // Lets the user know I don't know how to handle whatever is in their clipboard
        default:
            updateAppearance(title: "No Spotify or Apple Music link found in clipboard", color: UIColor.gray, enabled: false)
            activityMonitor.stopAnimating()
            activityMonitor.isHidden = true
            convertButton.isHidden = false
        }
    }

    /// Handles searching between the source and destination
    ///
    /// - Parameters:
    ///   - link: link to search with
    ///   - source: Source service of the link
    ///   - destination: Destination to open the search result in
    private func handleSearching(link: String, source: MusicSearcher, destination: MusicSearcher) {
        activityMonitor.startAnimating()
        activityMonitor.isHidden = false
        convertButton.isHidden = true
        source.search(link: link)?
            .validate()
            .responseJSON { response in
                self.activityMonitor.stopAnimating()
                self.activityMonitor.isHidden = true
                self.convertButton.isHidden = false
                if response.error != nil {
                    self.titleLabel.text = "Error getting \(source.serviceName) data"
                    self.updateAppearance(title: "Link might be formatted incorrectly", color: UIColor.red, enabled: false)
                } else if response.result.value != nil {
                    if source.artist != nil {
                        self.titleLabel.text = source.name! + " by " + source.artist!
                    } else {
                        self.titleLabel.text = source.name!
                    }

                    destination.search(name: source.name! + " " + (source.artist ?? ""), type: source.type!, completion: { error in
                        if error == nil {
                            self.updateAppearance(title: "Open in \(destination.serviceName)", color: destination.serviceColor, enabled: true)
                        } else {
                            self.updateAppearance(title: "Error getting \(destination.serviceName) data", color: UIColor.red, enabled: false)
                        }
                    })
                }
            }
    }

    // Mark: Actions

    /// Opens the link in the opposite app
    @IBAction func openSong(_: Any) {
        if link?.contains(SearcherURL.spotify) ?? false {
            appleMusic.open()
        } else if link?.contains(SearcherURL.appleMusic) ?? false {
            spotify.open()
        }
    }
}
