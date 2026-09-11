import SwiftUI

/// Role: Vine. Named colours and SF Pro. Hex lives only here: #FBF5F4 #FEFEFD #391F18 #CF3C17 #90655B.
enum TrellisInk {
    static let face = "SF Pro"

    enum Hex {
        static let background = "#FBF5F4"
        static let surface = "#FEFEFD"
        static let ink = "#391F18"
        static let accent = "#CF3C17"
        static let muted = "#90655B"
    }

    enum Palette {
        static let background = Color("background")
        static let surface = Color("surface")
        static let ink = Color("ink")
        static let accent = Color("pmtAccent")
        static let muted = Color("muted")
    }
}
