import CoreGraphics

/// Maps macOS CGKeyCode → Mechvibes scancode (PS/2 Set 1, used in config.json defines)
enum KeycodeMap {
    static let macToScancode: [CGKeyCode: Int] = [
        // Letters
        0: 30,   // A
        11: 48,  // B
        8: 46,   // C
        2: 32,   // D
        14: 18,  // E
        3: 33,   // F
        5: 34,   // G
        4: 35,   // H
        34: 23,  // I
        38: 36,  // J
        40: 37,  // K
        37: 38,  // L
        46: 50,  // M
        45: 49,  // N
        31: 24,  // O
        35: 25,  // P
        12: 16,  // Q
        15: 19,  // R
        1: 31,   // S
        17: 20,  // T
        32: 22,  // U
        9: 47,   // V
        13: 17,  // W
        7: 45,   // X
        16: 21,  // Y
        6: 44,   // Z

        // Digits
        29: 11,  // 0
        18: 2,   // 1
        19: 3,   // 2
        20: 4,   // 3
        21: 5,   // 4
        23: 6,   // 5
        22: 7,   // 6
        26: 8,   // 7
        28: 9,   // 8
        25: 10,  // 9

        // Function row
        53: 1,    // Escape
        122: 59,  // F1
        120: 60,  // F2
        99: 61,   // F3
        118: 62,  // F4
        96: 63,   // F5
        97: 64,   // F6
        98: 65,   // F7
        100: 66,  // F8
        101: 67,  // F9
        109: 68,  // F10
        103: 87,  // F11
        111: 88,  // F12

        // Modifiers
        56: 42,   // Left Shift
        60: 54,   // Right Shift
        59: 29,   // Left Control
        62: 3613, // Right Control (E0+1D)
        58: 56,   // Left Option (Alt)
        61: 3640, // Right Option (Alt) (E0+38)
        55: 3675, // Left Command (E0+5B)
        54: 3676, // Right Command (E0+5C)
        57: 58,   // Caps Lock
        63: 3653, // Fn (E0+45 / mapped)

        // Special
        36: 28,   // Return
        48: 15,   // Tab
        49: 57,   // Space
        51: 14,   // Delete (Backspace)
        117: 3667,// Forward Delete (E0+53)
        76: 3612, // Numpad Enter (E0+1C)

        // Navigation
        126: 57416, // Up Arrow (E0+48)
        125: 57424, // Down Arrow (E0+50)
        123: 57419, // Left Arrow (E0+4B)
        124: 57421, // Right Arrow (E0+4D)
        115: 3655,  // Home (E0+47)
        119: 3663,  // End (E0+4F)
        116: 3657,  // Page Up (E0+49)
        121: 3665,  // Page Down (E0+51)

        // Punctuation
        50: 41,   // Backtick `
        27: 12,   // Minus -
        24: 13,   // Equal =
        33: 26,   // Left Bracket [
        30: 27,   // Right Bracket ]
        42: 43,   // Backslash
        41: 39,   // Semicolon ;
        39: 40,   // Quote '
        43: 51,   // Comma ,
        47: 52,   // Period .
        44: 53,   // Slash /
    ]

    static func scancode(for macKeyCode: CGKeyCode) -> Int? {
        return macToScancode[macKeyCode]
    }
}
