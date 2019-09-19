typealias Element = Int
typealias SplitResult = (newElement: Element, leftChild: Node, rightChild: Node)

class BPlusTree {
    
    let elementsCapacity: Int
    
    var rootNode: Node
    
    init(elementsCapacity: Int) {
        self.elementsCapacity = elementsCapacity
        self.rootNode = LeafNode(capacity: elementsCapacity)
    }
    
    func add(element: Element) {
        if let result = rootNode.add(element: element) {
            self.rootNode = NonLeafNode(capacity: elementsCapacity, elements: [result.newElement], children: [result.leftChild, result.rightChild])
        }
    }
    
    func find(element: Element) -> Bool {
        return self.rootNode.find(element: element)
    }
}

protocol Node {
    
    var capacity: Int { get }
    var elements: [Element] { get set }
    
    func add(element: Element) -> SplitResult?
    func find(element: Element) -> Bool
}

class NonLeafNode: Node {
    
    let capacity: Int
    
    var elements: [Element] = []
    var children: [Node] = []
    
    init(capacity: Int, elements: [Element] = [], children: [Node] = []) {
        self.capacity = capacity
        self.elements = elements
        self.children = children
    }
    
    func add(element: Element) -> SplitResult? {
        let childrenIndexToAdd = elements.firstIndex(where: { $0 > element }) ?? elements.count
        if let result = children[childrenIndexToAdd].add(element: element) {
            let indexToInsert = elements.firstIndex(where: { $0 > result.newElement }) ?? elements.count
            self.elements.insert(result.newElement, at: indexToInsert)
            self.children[indexToInsert] = result.leftChild
            self.children.insert(result.rightChild, at: indexToInsert + 1)
            
            if elements.count > self.capacity {
                return splitted()
            }
        }
        return nil
    }
    
    private func splitted() -> SplitResult {
        let splitKeyIndex = elements.count / 2
        let splitKey = elements[splitKeyIndex]
        
        let rightChild = NonLeafNode(capacity: capacity, elements: Array(elements[(splitKeyIndex + 1)...]), children: Array(children[(splitKeyIndex + 1)...]))
        let leftChild = NonLeafNode(capacity: capacity, elements: Array(elements[..<splitKeyIndex]), children: Array(children[...splitKeyIndex]))
        
        return (splitKey, leftChild, rightChild)
    }
    
    func find(element: Element) -> Bool {
        let indexToFind = elements.firstIndex(where: { $0 > element }) ?? elements.count
        return children[indexToFind].find(element: element)
    }
}

class LeafNode: Node {
    
    let capacity: Int
    
    var elements: [Element]
    var next: LeafNode?
    
    init(capacity: Int, elements: [Element] = [], next: LeafNode? = nil) {
        self.capacity = capacity
        self.elements = elements
        self.next = next
    }
    
    func add(element: Element) -> SplitResult? {
        let indexToInsert = elements.firstIndex(where: { $0 > element }) ?? elements.count
        
        self.elements.insert(element, at: indexToInsert)
        
        if elements.count > self.capacity {
            return splitted()
        }
        
        return nil
    }
    
    private func splitted() -> SplitResult {
        let splitKeyIndex = elements.count / 2
        let splitKey = elements[splitKeyIndex]
        
        let rightChild = LeafNode(capacity: capacity, elements: Array(elements[splitKeyIndex...]), next: next)
        let leftChild = LeafNode(capacity: capacity, elements: Array(elements[..<splitKeyIndex]), next: rightChild)
        
        return (splitKey, leftChild, rightChild)
    }
    
    func find(element: Element) -> Bool {
        return elements.contains(element)
    }
}
