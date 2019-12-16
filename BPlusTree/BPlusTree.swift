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
    
    func remove(element: Element) {
        // 루트 노드는 remove()의 반환값을 따지지 않고 직접 루트 노드만의 언더플로우를 아래에서 확인한다.
        rootNode.remove(element: element)
        
        if let nonLeafRootNode = rootNode as? NonLeafNode {
            if nonLeafRootNode.children.count < 2 {
                rootNode = nonLeafRootNode.children[0]
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
    
    #if DEBUG
    func printTreeManually() {
        print(rootNode.elements)
        print((rootNode as! NonLeafNode).children.map({ $0.elements }))
        print((rootNode as! NonLeafNode).children.map({ ($0 as! NonLeafNode).children.map({ $0.elements }) }))
        print((rootNode as! NonLeafNode).children.map({ ($0 as! NonLeafNode).children.map({ ($0 as! NonLeafNode).children.map({ $0.elements }) }) }))
    }
    
    func printTreeManually2() {
        print(rootNode.elements)
        print((rootNode as! NonLeafNode).children.map({ $0.elements }))
        print((rootNode as! NonLeafNode).children.flatMap({ ($0 as! NonLeafNode).children }).map({ $0.elements }))
        print((rootNode as! NonLeafNode).children.flatMap({ ($0 as! NonLeafNode).children }).flatMap({ ($0 as! NonLeafNode).children }).map({ $0.elements }))
    }
    #endif
}

protocol Node {
    
    var capacity: Int { get }
    var elements: [Element] { get set }
    
    func add(element: Element) -> SplitResult?
    func find(element: Element) -> Bool
    func find(in range: ClosedRange<Element>) -> [Element]
    @discardableResult func remove(element: Element) -> Bool
    
    var isOverflow: Bool { get }
    var isUnderflow: Bool { get }
    var canRedistribute: Bool { get }
}

class NonLeafNode: Node {
    
    let capacity: Int
    
    var elements: [Element] = []
    var children: [Node] = []
    
    var isOverflow: Bool { elements.count > self.capacity }
    var isUnderflow: Bool { elements.count < (self.capacity / 2) }
    var canRedistribute: Bool { (elements.count - 1) >= (self.capacity / 2) }
    
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
            
            if isOverflow {
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
    
    // MARK: Remove
    
    @discardableResult func remove(element: Element) -> Bool {
        let childrenIndexToRemove = elements.firstIndex(where: { $0 > element }) ?? elements.count
        let childrenToRemove = self.children[childrenIndexToRemove]
        let leftSibling = self.children[safe: childrenIndexToRemove - 1]
        let rightSibling = self.children[safe: childrenIndexToRemove + 1]
        let underflowed = self.children[childrenIndexToRemove].remove(element: element)
        
        if underflowed {
            // 중요! 넌리프 노드는 리프 노드가 아니므로 실제 리프 노드의 데이터를 반영할 필요 없다. 바이너리 트리에서의 인덱스 역할만 하면 되므로 리프 노드에 없는 숫자가 키로 존재할 수 있다.
            
            if let childrenToRemove = childrenToRemove as? LeafNode {
                if let leftSibling = leftSibling as? LeafNode, leftSibling.canRedistribute {
                    let borrowed = leftSibling.elements.removeLast()
                    childrenToRemove.elements.insert(borrowed, at: 0)
                    self.elements[childrenIndexToRemove - 1] = borrowed
                } else if let rightSibling = rightSibling as? LeafNode, rightSibling.canRedistribute {
                    let borrowed = rightSibling.elements.removeFirst()
                    childrenToRemove.elements.append(borrowed)
                    if let newKey = rightSibling.elements.first {
                        self.elements[childrenIndexToRemove] = newKey
                    }
                }
                else if let leftSibling = leftSibling as? LeafNode {
                    leftSibling.elements += childrenToRemove.elements
                    leftSibling.next = childrenToRemove.next
                    
                    self.children.remove(at: childrenIndexToRemove)
                    self.elements.remove(at: childrenIndexToRemove - 1)
                } else if let rightSibling = rightSibling as? LeafNode {
                    childrenToRemove.elements += rightSibling.elements
                    childrenToRemove.next = rightSibling.next
                    
                    self.children.remove(at: childrenIndexToRemove + 1)
                    self.elements.remove(at: childrenIndexToRemove)
                }
            } else if let childrenToRemove = childrenToRemove as? NonLeafNode {
                if let leftSibling = leftSibling as? NonLeafNode, leftSibling.canRedistribute {
                    childrenToRemove.elements.insert(self.elements[childrenIndexToRemove - 1], at: 0)
                    self.elements[childrenIndexToRemove - 1] = leftSibling.elements.last!
                    leftSibling.elements.removeLast()
                    
                    childrenToRemove.children.insert(leftSibling.children.removeLast(), at: 0)
                } else if let rightSibling = rightSibling as? NonLeafNode, rightSibling.canRedistribute {
                    childrenToRemove.elements.append(self.elements[childrenIndexToRemove])
                    self.elements[childrenIndexToRemove] = rightSibling.elements.first!
                    rightSibling.elements.removeFirst()
                    
                    childrenToRemove.children.append(rightSibling.children.removeFirst())
                }
                else if let leftSibling = leftSibling as? NonLeafNode {
                    leftSibling.elements.append(self.elements.last!)
                    leftSibling.elements += childrenToRemove.elements
                    leftSibling.children += childrenToRemove.children
                    
                    self.children.remove(at: childrenIndexToRemove)
                    self.elements.remove(at: childrenIndexToRemove - 1)
                } else if let rightSibling = rightSibling as? NonLeafNode {
                    childrenToRemove.elements.append(self.elements[0])
                    childrenToRemove.elements += rightSibling.elements
                    childrenToRemove.children += rightSibling.children
                    
                    self.children.remove(at: childrenIndexToRemove + 1)
                    self.elements.remove(at: childrenIndexToRemove)
                }
            }
        }
        
        return self.isUnderflow
    }
}

class LeafNode: Node {
    
    let capacity: Int
    
    var elements: [Element]
    var next: LeafNode?
    
    // TODO: NonLeafNode에서 부등호가 살짝 다름. 왜 그런지 이유 찾기
    var isOverflow: Bool { elements.count > self.capacity }
    var isUnderflow: Bool { elements.count <= (self.capacity / 2) }
    var canRedistribute: Bool { (elements.count - 1) > (self.capacity / 2) }
    
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
        
        if isOverflow {
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
    
    // MARK: Remove
    
    // return 값의 의미는 이 노드에서 언더플로우가 일어났기 때문에 부모 노드에서 이를 처리해주어야 한다는 뜻이다.
    @discardableResult func remove(element: Element) -> Bool {
        self.elements.removeAll(where: { $0 == element })
        if self.isUnderflow {
            // TODO: 첫 번째 요소를 삭제했을 경우 부모 키를 바꿔야 함
            return true
        } else {
            return false
        }
    }
}
