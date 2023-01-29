import SwiftUI
import ACarousel

struct ContentView: View {
    
    @State private var showNoCardsError = false
    
    func checkAndEscape() -> Bool {
#if targetEnvironment(simulator)
#else
        var supported = false
        var needsTrollStore = false
        if #available(iOS 16.2, *) {
            supported = false
        } else if #available(iOS 16.0, *) {
            supported = true
            needsTrollStore = false
        } else if #available(iOS 15.7.2, *) {
            supported = false
        } else if #available(iOS 15.0, *) {
            supported = true
            needsTrollStore = false
        } else if #available(iOS 14.0, *) {
            supported = true
            needsTrollStore = true
        }
        
        if !supported {
            UIApplication.shared.alert(title: "Not Supported", body: "This version of iOS is not supported. Please close the app.")
            return false
        }
            
        do {
            // Check if application is entitled
            try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: "/var/mobile"), includingPropertiesForKeys: nil)
            return true
        } catch {
            if needsTrollStore {
                UIApplication.shared.alert(title: "Use TrollStore", body: "You must install this app with TrollStore for it to work with this version of iOS. Please close the app.")
                return false
            }
            // Use MacDirtyCOW to gain r/w
            var didSucceed = true
            grant_full_disk_access() { error in
                if (error != nil) {
                    UIApplication.shared.alert(body: "\(String(describing: error?.localizedDescription))\nPlease close the app and retry.")
                    didSucceed = false
                }
            }
            return didSucceed
        }
#endif
    }
    
    func getPasses() -> [String]
    {
        if !checkAndEscape() {
            return []
        }
        
        let fm = FileManager.default
        let path = "/var/mobile/Library/Passes/Cards/"
        var data = [String]()
        
        do {
            let passes = try fm.contentsOfDirectory(atPath: path).filter {
                $0.hasSuffix("pkpass");
            }
            
            for pass in passes {
                let files = try fm.contentsOfDirectory(atPath: path + pass)
                
                if (files.contains("cardBackgroundCombined.pdf") || files.contains("cardBackgroundCombined@2x.png"))
                {
                    data.append(pass)
                }
            }
            print(data)
            return data
            
        } catch {
            return []
        }
    }
    
    func getImage(id: String) -> (String, String)
    {
        let fm = FileManager.default
        let path = "/var/mobile/Library/Passes/Cards/" + id + "/cardBackgroundCombined"
        
        if (fm.fileExists(atPath: path + "@2x.png"))
        {
            return (path, "@2x.png")
        } else if (fm.fileExists(atPath: path + ".pdf"))
        {
            return (path, ".pdf")
        } else
        {
            showNoCardsError = true
            return ("","")
        }
    }
        
    var body: some View
    {
        ZStack
        {
            Color.black.ignoresSafeArea()
            Text("Tap a card to customize").font(.system(size: 25)).foregroundColor(.white).padding(.bottom, 350 )
            Text("Swipe to view different cards").font(.system(size: 15)).foregroundColor(.white).padding(.bottom, 300 )

            VStack
            {
                if (!getPasses().isEmpty)
                {
                    ACarousel(getPasses(), id: \.self)
                    {
                        i in
                        let imageData = getImage(id: i)
                        
                        if (!imageData.0.isEmpty)
                        {
                            CardView(card: Card(image: imageData.0, id: i, format: imageData.1))
                        }

                    }.alert(isPresented: $showNoCardsError)
                    {
                        Alert(title: Text("No Cards Were Found"))
                    }
                }
                else
                {
                    Text("No Cards Found").foregroundColor(.red)
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
