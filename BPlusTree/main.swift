
let tree = BPlusTree(elementsCapacity: 2)

for i in 1...4 {
    tree.add(element: i)
}

print(tree.rootNode)
