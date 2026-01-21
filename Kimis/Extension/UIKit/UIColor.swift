//
//  UIColor.swift
//  mTale
//
//  Created by Lakr Aream on 2022/3/31.
//

import UIKit

private var accentColorCache: UIColor?

extension UIColor {
    static var myAccent: UIColor {
        if let cache = accentColorCache {
            return cache
        }
        let defaultAccent = UIColor(named: "AccentColor") ?? .systemPurple
        var light: UIColor = defaultAccent
        var dark: UIColor = defaultAccent
        if let lightHex = Int(AppConfig.current.accentColorLight, radix: 16),
           let get = UIColor(hex: lightHex)
        {
            light = get
        }
        if let darkHex = Int(AppConfig.current.accentColorDark, radix: 16),
           let get = UIColor(hex: darkHex)
        {
            dark = get
        }
        let ans = UIColor(light: light, dark: dark)
        accentColorCache = ans
        return ans
    }

    static var randomAsPudding: UIColor {
        let color: [UIColor] = [
            #colorLiteral(red: 0.9586862922, green: 0.660125792, blue: 0.8447988033, alpha: 1), #colorLiteral(red: 0.8714533448, green: 0.723166883, blue: 0.9342088699, alpha: 1), #colorLiteral(red: 0.7458761334, green: 0.7851135731, blue: 0.9899476171, alpha: 1), #colorLiteral(red: 0.595767796, green: 0.8494840264, blue: 1, alpha: 1), #colorLiteral(red: 0.4398113191, green: 0.8953480721, blue: 0.9796616435, alpha: 1), #colorLiteral(red: 0.3484552801, green: 0.933657825, blue: 0.9058339596, alpha: 1), #colorLiteral(red: 0.4113925397, green: 0.9645707011, blue: 0.8110389113, alpha: 1), #colorLiteral(red: 0.5567936897, green: 0.9780793786, blue: 0.6893508434, alpha: 1), #colorLiteral(red: 0.8850132227, green: 0.9840424657, blue: 0.4586077332, alpha: 1),
        ]
        return color.randomElement() ?? .white
    }

    static var platformBackground: UIColor {
        .init(light: .white, dark: UIColor(hex: 0x141414)!)
    }

    static var systemBlackAndWhite: UIColor {
        .init(light: .black, dark: .white)
    }

    static var systemWhiteAndBlack: UIColor {
        .init(light: .white, dark: .black)
    }

    static var separator: UIColor {
        .systemGray5
    }

    static var placeholder: UIColor {
        .systemGray5.withAlphaComponent(0.5)
    }
}

extension UIColor {
    convenience init?(red: Int, green: Int, blue: Int) {
        guard red >= 0, red <= 255 else { return nil }
        guard green >= 0, green <= 255 else { return nil }
        guard blue >= 0, blue <= 255 else { return nil }

        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }

    convenience init?(hex: Int) {
        self.init(
            red: (hex >> 16) & 0xFF,
            green: (hex >> 8) & 0xFF,
            blue: hex & 0xFF,
        )
    }
}
