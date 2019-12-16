let tree = BPlusTree(elementsCapacity: 3)

for i in (1...100).shuffled() {
    tree.add(element: i)
}
tree.printTree()
print()

for i in (50...100).shuffled() {
    tree.remove(element: i)
}

tree.printTree()
