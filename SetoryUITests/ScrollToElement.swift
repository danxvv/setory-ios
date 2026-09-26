import XCTest

extension XCUIApplication {
    /// Lists virtualize offscreen rows. Reveal the content before asserting
    /// its value so behavior tests don't depend on a particular row height.
    func reveal(_ element: XCUIElement, swipingUp: Bool = true) -> Bool {
        for _ in 0..<6 {
            if element.exists && element.isHittable { return true }
            if swipingUp { swipeUp() } else { swipeDown() }
        }
        return element.exists && element.isHittable
    }
}
