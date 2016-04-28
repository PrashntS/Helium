//
//  ViewController.swift
//  Helium
//
//  Created by Jaden Geller on 4/9/15.
//  Copyright (c) 2015 Jaden Geller. All rights reserved.
//

import Cocoa
import WebKit

class WebViewController: NSViewController, WKNavigationDelegate {
    private var uneditedURL:String = ""

    // MARK: View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addTrackingRect(view.bounds, owner: self, userData: nil, assumeInside: false)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(WebViewController.loadURLObject(_:)), name: "HeliumLoadURL", object: nil)
        
        // Layout webview
        view.addSubview(webView)
        webView.frame = view.bounds
        webView.autoresizingMask = [NSAutoresizingMaskOptions.ViewHeightSizable, NSAutoresizingMaskOptions.ViewWidthSizable]
        
        // Allow plug-ins such as silverlight
        webView.configuration.preferences.plugInsEnabled = true
        
        // Custom user agent string for Netflix HTML5 support
        webView._customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_4) AppleWebKit/600.7.12 (KHTML, like Gecko) Version/8.0.7 Safari/600.7.12"
        
        // Setup magic URLs
        webView.navigationDelegate = self
        
        // Allow zooming
        webView.allowsMagnification = true
        
        // Alow back and forth
        webView.allowsBackForwardNavigationGestures = true
        
        // Listen for load progress
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: NSKeyValueObservingOptions.New, context: nil)
        
        clear()
    }
    
    // MARK: Actions
    override func validateMenuItem(menuItem: NSMenuItem) -> Bool{
        switch menuItem.title {
        case "Back":
            return webView.canGoBack
        case "Forward":
            return webView.canGoForward
        default:
            return true
        }
    }
    
    @IBAction func backPress(sender: AnyObject) {
        webView.goBack()
    }
    
    @IBAction func forwardPress(sender: AnyObject) {
        webView.goForward()
    }
    
    private func zoomIn() {
        webView.magnification += 0.1
    }
    
    private func zoomOut() {
        webView.magnification -= 0.1
    }
    
    private func resetZoom() {
        webView.magnification = 1
    }
    
    @IBAction private func reloadPress(sender: AnyObject) {
        requestedReload()
    }
    
    @IBAction private func clearPress(sender: AnyObject) {
        clear()
    }
    
    @IBAction private func resetZoomLevel(sender: AnyObject) {
        resetZoom()
    }
    @IBAction private func zoomIn(sender: AnyObject) {
        zoomIn()
    }
    @IBAction private func zoomOut(sender: AnyObject) {
        zoomOut()
    }
    
    internal func loadAlmostURL(text: String) {
        var text = text
        if !(text.lowercaseString.hasPrefix("http://") || text.lowercaseString.hasPrefix("https://")) {
            text = "http://" + text
        }
        
        if let url = NSURL(string: text) {
            loadURL(url)
        }
        
        self.uneditedURL = text
    }
    
    // MARK: Loading
    
    internal func loadURL(url:NSURL) {
        webView.loadRequest(NSURLRequest(URL: url))
    }
    
    func loadURLObject(urlObject : NSNotification) {
        if let url = urlObject.object as? NSURL {
            loadAlmostURL(url.absoluteString);
        }
    }
    
    private func requestedReload() {
        webView.reload()
    }
    
    // MARK: Webview functions
    func clear() {
        // Reload to home page (or default if no URL stored in UserDefaults)
        if let homePage = NSUserDefaults.standardUserDefaults().stringForKey(UserSetting.HomePageURL.userDefaultsKey) {
            loadAlmostURL(homePage)
        }
        else{
            loadURL(NSURL(string: "https://netflix.com")!)
        }
    }

    var webView = WKWebView()
    var shouldRedirect: Bool {
        get {
            return !NSUserDefaults.standardUserDefaults().boolForKey(UserSetting.DisabledMagicURLs.userDefaultsKey)
        }
    }
    
    // Redirect Hulu and YouTube to pop-out videos
    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        
        decisionHandler(WKNavigationActionPolicy.Allow)
    }
    
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation) {
//        if let pageTitle = webView.title {
//            let title = pageTitle;
//            //if title.isEmpty { title = "Helium" }
//            let notif = NSNotification(name: "HeliumUpdateTitle", object: "");
//            NSNotificationCenter.defaultCenter().postNotification(notif)
//        }

        let notif = NSNotification(name: "HeliumUpdateTitle", object: "");
        NSNotificationCenter.defaultCenter().postNotification(notif)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        
        if object as! NSObject == webView && keyPath == "estimatedProgress" {
            if let progress = change?["new"] as? Float {
                let percent = progress * 100
                var title = NSString(format: "Loading... %.2f%%", percent)
                if percent == 100 {
                    title = "Helium"
                }
                
                let notif = NSNotification(name: "HeliumUpdateTitle", object: title);
                NSNotificationCenter.defaultCenter().postNotification(notif)
            }
        }
    }

}

