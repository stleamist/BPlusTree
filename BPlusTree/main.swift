
let tree = BPlusTree(elementsCapacity: 2)

for i in (1...5) {
    tree.add(element: i)
}

print(tree.allElements())
print()
tree.printTree()
print()
