import AVFoundation
import CoreGraphics

/// Synthetic codes for mouse buttons, living in a range that cannot
/// collide with real macOS CGKeyCode values (which stay well below 255).
/// These codes flow through `AudioEngine.play(macKeyCode:isDown:)` just
/// like keyboard codes; `MouseButtonMap` is consulted to resolve them
/// into the keyboard sample and spatial position they should borrow.
enum MouseButtonMap {
    static let mouseLeft: CGKeyCode    = 1000
    static let mouseRight: CGKeyCode   = 1001
    static let mouseMiddle: CGKeyCode  = 1002
    static let mouseBack: CGKeyCode    = 1003
    static let mouseForward: CGKeyCode = 1004

    /// Button number (as reported by `CGEvent.mouseEventButtonNumber`) →
    /// synthetic mouse code. Returns nil for unsupported buttons (e.g.
    /// extra side buttons beyond back/forward).
    static func syntheticCode(forButtonNumber n: Int64) -> CGKeyCode? {
        switch n {
        case 0: return mouseLeft
        case 1: return mouseRight
        case 2: return mouseMiddle
        case 3: return mouseBack
        case 4: return mouseForward
        default: return nil
        }
    }

    static func isMouseCode(_ code: CGKeyCode) -> Bool {
        code >= mouseLeft && code <= mouseForward
    }

    /// BDR-0009 fixed button-to-key map: which keyboard sample each mouse
    /// button borrows from the active profile.
    static func keyboardSampleCode(forMouseCode code: CGKeyCode) -> CGKeyCode {
        switch code {
        case mouseLeft:    return 49  // Space
        case mouseRight:   return 36  // Return
        case mouseMiddle:  return 48  // Tab
        case mouseBack:    return 51  // Backspace
        case mouseForward: return 53  // Escape
        default:           return 49  // fallback to Space
        }
    }

    /// BDR-0010 fixed volume multiplier: mouse gain relative to keyboard.
    static let relativeGain: Float = 0.50

    /// BDR-0011 fixed right-side spatial position, shared by all five
    /// mouse buttons. Same depth as KeyPositionMap so mouse and keyboard
    /// live on the same Z plane.
    static let spatialPosition = KeyPositionMap.Position(x: 0.55, y: -0.08, z: -0.25)
}
