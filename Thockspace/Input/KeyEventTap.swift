import CoreGraphics
import Foundation

final class KeyEventTap {
    typealias KeyHandler = (_ keyCode: CGKeyCode, _ isDown: Bool) -> Void

    private let handler: KeyHandler
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var tapThread: Thread?

    init(handler: @escaping KeyHandler) {
        self.handler = handler
    }

    deinit {
        stop()
    }

    func start() {
        guard eventTap == nil else { return }

        tapThread = Thread { [weak self] in
            self?.runTapLoop()
        }
        tapThread?.name = "com.thockspace.eventtap"
        tapThread?.qualityOfService = .userInteractive
        tapThread?.start()
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource, let thread = tapThread {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
        tapThread?.cancel()
        tapThread = nil
    }

    private func runTapLoop() {
        let eventMask = (1 << CGEventType.keyDown.rawValue)
            | (1 << CGEventType.keyUp.rawValue)
            | (1 << CGEventType.flagsChanged.rawValue)

        let refcon = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { _, type, event, refcon -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
                let handler = Unmanaged<KeyEventTap>.fromOpaque(refcon).takeUnretainedValue()
                handler.handleEvent(type: type, event: event)
                return Unmanaged.passUnretained(event)
            },
            userInfo: refcon
        ) else {
            print("[Thockspace] Failed to create event tap. Check Input Monitoring permission.")
            return
        }

        self.eventTap = tap

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        self.runLoopSource = source

        let runLoop = CFRunLoopGetCurrent()
        CFRunLoopAddSource(runLoop, source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        CFRunLoopRun()
    }

    private func handleEvent(type: CGEventType, event: CGEvent) {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            // Re-enable tap
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return
        }

        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))

        switch type {
        case .keyDown:
            handler(keyCode, true)
        case .keyUp:
            handler(keyCode, false)
        case .flagsChanged:
            // For modifier keys, determine down/up from flags
            let flags = event.flags
            let isDown = isModifierDown(keyCode: keyCode, flags: flags)
            handler(keyCode, isDown)
        default:
            break
        }
    }

    private func isModifierDown(keyCode: CGKeyCode, flags: CGEventFlags) -> Bool {
        switch keyCode {
        case 56, 60: return flags.contains(.maskShift)       // Left/Right Shift
        case 59, 62: return flags.contains(.maskControl)     // Left/Right Control
        case 58, 61: return flags.contains(.maskAlternate)   // Left/Right Option
        case 55, 54: return flags.contains(.maskCommand)     // Left/Right Command
        case 57:     return flags.contains(.maskAlphaShift)  // Caps Lock
        case 63:     return flags.contains(.maskSecondaryFn) // Fn
        default:     return false
        }
    }
}
