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
    
    func find(in range: ClosedRange<Element>) -> [Element] {
        return self.rootNode.find(in: range)
    }
    
    func findLeastLeafNode() -> LeafNode {
        var node: Node = self.rootNode
        
        while true {
            if let nonLeafNode = node as? NonLeafNode {
                if let leftChild = nonLeafNode.children[safe: 0] {
                    node = leftChild
                }
            } else if let leafNode = node as? LeafNode {
                return leafNode
            }
        }
    }
    
    func allElements() -> [[Element]] {
        var result: [[Element]] = []
        
        var node: LeafNode = findLeastLeafNode()
        
        while true {
            result.append(node.elements)
            
            if let nextNode = node.next {
                node = nextNode
            } else {
                return result
            }
        }
    }
    
    func printTree() {
        var handler: (Node) -> [Any] = { $0.elements }
        
        while true {
            let elementsAtLevel = handler(self.rootNode)
            
            if elementsAtLevel.flatten().count == 0 {
                break
            } else {
                print(elementsAtLevel)
            }
            
            let oldHandler = handler
            handler = { ($0 as? NonLeafNode)?.children.map(oldHandler) ?? [] }
        }
    }
    
    func printTreeManually(_ node: Node) {
        print(node.elements)
        print((node as! NonLeafNode).children.map({ $0.elements }))
        print((node as! NonLeafNode).children.map({ ($0 as! NonLeafNode).children.map({ $0.elements }) }))
        print((node as! NonLeafNode).children.map({ ($0 as! NonLeafNode).children.map({ ($0 as! NonLeafNode).children.map({ $0.elements }) }) }))
    }
}

protocol Node {
    
    var capacity: Int { get }
    var elements: [Element] { get set }
    
    func add(element: Element) -> SplitResult?
    func find(element: Element) -> Bool
    func find(in range: ClosedRange<Element>) -> [Element]
}

class NonLeafNode: Node {
    
    let capacity: Int
    
    var elements: [Element] = []
    var children: [Node] = []
    
    // MARK: Initialization & Update
    
    init(capacity: Int, elements: [Element] = [], children: [Node] = []) {
        self.capacity = capacity
        self.elements = elements
        self.children = children
    }
    
    private func update(elements: [Element] = [], children: [Node] = []) {
        self.elements = elements
        self.children = children
    }
    
    // MARK: Add
    
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
        self.update(elements: Array(elements[..<splitKeyIndex]), children: Array(children[...splitKeyIndex]))
        
        return (splitKey, self, rightChild)
    }
    
    // MARK: Find
    
    func find(element: Element) -> Bool {
        let indexToFind = elements.firstIndex(where: { $0 > element }) ?? elements.count
        return children[indexToFind].find(element: element)
    }
    
    func find(in range: ClosedRange<Element>) -> [Element] {
        let indexToFind = elements.firstIndex(where: { $0 > range.lowerBound }) ?? elements.count
        return children[indexToFind].find(in: range)
    }
}

class LeafNode: Node {
    
    let capacity: Int
    
    var elements: [Element]
    var next: LeafNode?
    
    // MARK: Initialization & Update
    
    init(capacity: Int, elements: [Element] = [], next: LeafNode? = nil) {
        self.capacity = capacity
        self.elements = elements
        self.next = next
    }
    
    private func update(elements: [Element] = [], next: LeafNode? = nil) {
        self.elements = elements
        self.next = next
    }
    
    // MARK: Add
    
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
        // leftChild 인스턴스를 새로 생성하면 self를 next로 참조하는 LeafNode의 next 포인터를 변경할 수 없으므로 self를 변경해야 한다.
        self.update(elements: Array(elements[..<splitKeyIndex]), next: rightChild)
        
        return (splitKey, self, rightChild)
    }
    
    // MARK: Find
    
    func find(element: Element) -> Bool {
        return elements.contains(element)
    }
    
    func find(in range: ClosedRange<Element>) -> [Element] {
        var result: [Element] = []
        
        var node: LeafNode = self
        
        while true {
            for element in node.elements {
                if element < range.lowerBound {
                    continue
                } else if element > range.upperBound {
                    print(2)
                    return result
                } else {
                    result.append(element)
                }
            }
            
            if let nextNode = node.next {
                node = nextNode
            } else {
                return result
            }
        }
    }
}
