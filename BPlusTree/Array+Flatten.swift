extension Array {
    func flatten() -> [Any] {
        return (self as [Any]).reduce([]) { result, element in
            if let array = element as? [Any] {
                return result + array.flatten()
            } else {
                return result + [element]
            }
        }
    }
}
