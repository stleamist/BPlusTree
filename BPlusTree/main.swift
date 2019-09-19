
let tree = BPlusTree(elementsCapacity: 3)

for i in (1...10) {
    tree.add(element: i)
}

print(tree.allElements())
print()
tree.printTree()
print()
