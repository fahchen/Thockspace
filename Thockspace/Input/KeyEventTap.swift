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
        if let source = runLoopSource, tapThread != nil {
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
            | (1 << CGEventType.leftMouseDown.rawValue)
            | (1 << CGEventType.leftMouseUp.rawValue)
            | (1 << CGEventType.rightMouseDown.rawValue)
            | (1 << CGEventType.rightMouseUp.rawValue)
            | (1 << CGEventType.otherMouseDown.rawValue)
            | (1 << CGEventType.otherMouseUp.rawValue)

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

        switch type {
        case .keyDown:
            handler(keyCodeField(event), true)
        case .keyUp:
            handler(keyCodeField(event), false)
        case .flagsChanged:
            // For modifier keys, determine down/up from flags
            let code = keyCodeField(event)
            let isDown = isModifierDown(keyCode: code, flags: event.flags)
            handler(code, isDown)
        case .leftMouseDown, .rightMouseDown, .otherMouseDown:
            handleMouseEvent(event: event, isDown: true)
        case .leftMouseUp, .rightMouseUp, .otherMouseUp:
            handleMouseEvent(event: event, isDown: false)
        default:
            break
        }
    }

    private func keyCodeField(_ event: CGEvent) -> CGKeyCode {
        CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
    }

    private func handleMouseEvent(event: CGEvent, isDown: Bool) {
        let buttonNumber = event.getIntegerValueField(.mouseEventButtonNumber)
        guard let code = MouseButtonMap.syntheticCode(forButtonNumber: buttonNumber) else {
            return
        }
        handler(code, isDown)
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
