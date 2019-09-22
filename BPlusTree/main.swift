
let tree = BPlusTree(elementsCapacity: 3)

for i in [1, 4, 16, 25, 9, 20, 13, 15, 10, 11, 12] {
    tree.add(element: i)
}
tree.printTree()
print()
print()

for i in [13, 15, 1] {
    tree.remove(element: i)
    tree.printTree()
    print()
}
