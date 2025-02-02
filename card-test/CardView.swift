import SwiftUI
import PDFKit

struct Card {
    var image: String
    var id: String
    var format: String
}

struct CardView: View {
    let fm = FileManager.default
    
    @State private var cardImage = UIImage()
    @State private var showSheet = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var hasDefaultImage = false
    
    private func resetImage(format: String)
    {
        let fm = FileManager.default
        
        do {
            try fm.removeItem(atPath: "/var/mobile/Library/Passes/Cards/" + card.id.replacingOccurrences(of: "pkpass", with: "cache") )
        } catch {
            print(error)
        }
        
        switch format
        {
        case "@2x.png":
            
            do {
                try fm.removeItem(atPath: "/var/mobile/Library/Passes/Cards/" + card.id + "/cardBackgroundCombined@2x.png")
                try fm.moveItem(atPath: "/var/mobile/Library/Passes/Cards/" + card.id + "/cardBackgroundCombined@2x.png.backup", toPath: "/var/mobile/Library/Passes/Cards/" + card.id + "/cardBackgroundCombined@2x.png")
            } catch {
                print(error)
            }
            
            hasDefaultImage = true
            UIDevice.current.respring()
        case ".pdf":
            do {
                try fm.removeItem(atPath: "/var/mobile/Library/Passes/Cards/" + card.id + "/cardBackgroundCombined.pdf")
                try fm.moveItem(atPath: "/var/mobile/Library/Passes/Cards/" + card.id + "/cardBackgroundCombined.pdf.backup", toPath: "/var/mobile/Library/Passes/Cards/" + card.id + "/cardBackgroundCombined.pdf")
            } catch {
                print(error)
            }
            
            hasDefaultImage = true
            UIDevice.current.respring()
        default:
            errorMessage = "Unknown file"
            showError = true
        }
    }
    
    private func setImage(image: UIImage, format: String)
    {
        switch format
        {
        case "@2x.png":
            if let data = image.pngData()
            {
                do {
                    let fm = FileManager.default
                    
                    try fm.moveItem(atPath: "/var/mobile/Library/Passes/Cards/" + card.id + "/cardBackgroundCombined@2x.png", toPath: "/var/mobile/Library/Passes/Cards/" + card.id + "/cardBackgroundCombined@2x.png.backup")
                    
                    try data.write(to: URL(fileURLWithPath: "/var/mobile/Library/Passes/Cards/" + card.id + "/cardBackgroundCombined@2x.png"))
                    
                    try fm.removeItem(atPath: "/var/mobile/Library/Passes/Cards/" + card.id.replacingOccurrences(of: "pkpass", with: "cache") )
                    
                    UIDevice.current.respring()
                    
                    
                } catch {
                    errorMessage = error.localizedDescription
                    showError = true
                    print(error)
                }
            }
            
        case ".pdf":
            
            let pdfDocument = PDFDocument()
            let pdfPage = PDFPage(image: image)
            pdfDocument.insert(pdfPage!, at: 0)
            let data = pdfDocument.dataRepresentation()
            let url = URL(fileURLWithPath: "")
            
            do {
                let fm = FileManager.default
                
                try fm.moveItem(atPath: "/var/mobile/Library/Passes/Cards/" + card.id + "/cardBackgroundCombined.pdf", toPath: "/var/mobile/Library/Passes/Cards/" + card.id + "/cardBackgroundCombined.pdf.backup")
                
                try! data!.write(to: url)
                
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }

        default:
            errorMessage = "Unknown Format, Contact Dev"
            showError = true
        }
    }
    
    var card: Card
    
    var body: some View {
        ZStack {
            Image(uiImage: UIImage(contentsOfFile: card.image)!).resizable().aspectRatio(contentMode: .fit).frame(width: 320).zIndex(0).cornerRadius(5).onTapGesture {
                showSheet = true
            }.sheet(isPresented: $showSheet) {
                ImagePicker(sourceType: .photoLibrary, selectedImage: self.$cardImage)
            }.onChange(of: self.cardImage)
            {
                newImage in setImage(image: newImage, format: card.format)
            }.alert(isPresented: $showError)
            {
                Alert(
                    title: Text("Error Occured"),
                    message: Text(errorMessage)
                )
            }
            
            if (fm.fileExists(atPath: "/var/mobile/Library/Passes/Cards/" + card.id + "/cardBackgroundCombined" + card.format + ".backup"))
            {
                Button {
                    resetImage(format: card.format)
                } label: {
                    Image(systemName: "arrow.counterclockwise.circle.fill").resizable().scaledToFit().frame(width: 40).foregroundColor(Color.red)
                }.zIndex(1).padding(.top, 265)
            }
        }
    }
}
