import AVFoundation
import CoreGraphics

/// Maps CGKeyCode → 3D position for spatial audio
/// X: left-right (-0.8 to +0.8), Y: row height (±0.1), Z: -0.25 (close, 25cm in front)
enum KeyPositionMap {
    struct Position {
        let x: Float
        let y: Float
        let z: Float

        var avAudio3DPoint: AVAudio3DPoint {
            AVAudio3DPoint(x: x, y: y, z: z)
        }
    }

    private static let depth: Float = -0.25

    static let positions: [CGKeyCode: Position] = {
        var map = [CGKeyCode: Position]()

        func addRow(_ keys: [CGKeyCode], y: Float) {
            let count = keys.count
            for (i, key) in keys.enumerated() {
                let normalized = count > 1 ? Float(i) / Float(count - 1) : 0.5
                let x = -0.8 + normalized * 1.6  // -0.8 to +0.8
                map[key] = Position(x: x, y: y, z: depth)
            }
        }

        // Escape + F-keys
        addRow([53, 122, 120, 99, 118, 96, 97, 98, 100, 101, 109, 103, 111], y: 0.10)

        // Number row: ` 1 2 3 4 5 6 7 8 9 0 - = delete
        addRow([50, 18, 19, 20, 21, 23, 22, 26, 28, 25, 29, 27, 24, 51], y: 0.06)

        // QWERTY row: tab Q W E R T Y U I O P [ ] backslash
        addRow([48, 12, 13, 14, 15, 17, 16, 32, 34, 31, 35, 33, 30, 42], y: 0.02)

        // Home row: capslock A S D F G H J K L ; ' return
        addRow([57, 0, 1, 2, 3, 5, 4, 38, 40, 37, 41, 39, 36], y: -0.02)

        // Bottom row: lshift Z X C V B N M , . / rshift
        addRow([56, 6, 7, 8, 9, 11, 45, 46, 43, 47, 44, 60], y: -0.06)

        // Space row: fn ctrl opt cmd space cmd opt arrows
        addRow([63, 59, 58, 55, 49, 54, 61, 123, 125, 124], y: -0.10)

        // Arrow cluster
        map[126] = Position(x: 0.70, y: -0.06, z: depth)  // Up
        map[125] = Position(x: 0.70, y: -0.10, z: depth)  // Down
        map[123] = Position(x: 0.60, y: -0.10, z: depth)  // Left
        map[124] = Position(x: 0.80, y: -0.10, z: depth)  // Right

        return map
    }()

    static let defaultPosition = Position(x: 0, y: 0, z: depth)

    static func position(for keyCode: CGKeyCode) -> Position {
        return positions[keyCode] ?? defaultPosition
    }
}
