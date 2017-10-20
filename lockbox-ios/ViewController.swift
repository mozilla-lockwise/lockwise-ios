import UIKit
import WebKit
import Foundation

class ViewController: UIViewController {
    var webView: WebView!
    var dataStore: DataStore!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let contentController = WKUserContentController()
        let webConfig = WKWebViewConfiguration()
        
        webConfig.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        webConfig.preferences.javaScriptEnabled = true
        webConfig.userContentController = contentController
        
        self.webView = WebView(frame: .zero, configuration: webConfig)
        
        self.view.addSubview(self.webView)
        
        self.dataStore = DataStore(webview: self.webView)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func initClicked(_ sender: Any) {
        self.dataStore.initialized { (value) in
            if !value {
                print("initializing!!")
                self.dataStore.initialize(password: "password")
            } else {
                print("already initialized!")
            }
        }
    }
    
    @IBAction func buttonClicked(_ sender: Any) {
        self.dataStore.locked(completionHandler: { (value) in
            if value {
                print("unlocking!")
                self.dataStore.unlock(password: "password")
            } else {
                print("unlocked!")
            }
        })
    }
    
    @IBAction func lockButtonClicked(_ sender: Any) {
        print("locking!")
        self.dataStore.lock()
    }
    
    @IBAction func addClicked(_ sender: Any) {
        let item = Item.Builder()
            .entry(ItemEntry.Builder().type("fart").build())
            .origins(["www.neopets.com"])
            .build()
        self.dataStore.addItem(item)
    }
    
    @IBAction func listButtonClicked(_ sender: Any) {
        self.dataStore.keyList { (array) in
            for item in array {
                print(item.origins)
            }
        }
    }
}
