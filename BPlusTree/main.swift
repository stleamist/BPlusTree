
let tree = BPlusTree(elementsCapacity: 2)

for i in (50...75).shuffled() {
    tree.add(element: i)
}

for i in 0...100 {
    print(tree.find(element: i), i)
}

print(tree.rootNode)
