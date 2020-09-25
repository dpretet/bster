# Information

## What's a binary tree?

Sources:
- [Wikipedia](https://en.wikipedia.org/wiki/Binary_tree)
- [cs.cmu.edu](https://www.cs.cmu.edu/~adamchik/15-121/lectures/Trees/trees.html)

A binary tree is a data structure, represented by a graph, in which each node
has at most two children, which are referred to as the left child and the right
child. Each node of tree contains a data element and two pointers, on for the
left and one for the right element. A binary tree is rooted, ordered, can be
empty, and considered as undirected.

Terminology:

* The depth of a node is the number of edges from the root to the node.
* The height of a node is the number of edges from the node to the deepest leaf.
* The height of a tree is a height of the root.
* A full binary tree is a binary tree in which each node has exactly zero or two children.
* A complete binary tree is a binary tree, which is completely filled, with the possible
  exception of the bottom level, which is filled from left to right.

## Advantages

* Trees reflect structural relationships in the data
* Trees are used to represent hierarchies
* Trees provide an efficient insertion and searching
* Trees are very flexible data, allowing to move subtrees around with minumum effort

## Binary tree operations

A binary search algorithm tree provides three operations: search, insert,
delete. Insert and delete operations always maintain an ordered data structure.
Since a tree is a nonlinear data structure, there is no unique search (or
traversal) method. Search operation can depth-first or breadth-first.

There are three different types of depth-first traversals :

* PreOrder traversal - visit the parent first and then left and right children;
* InOrder traversal - visit the left child, then the parent and the right child;
* PostOrder traversal - visit left child, then the right child and then the parent;

There is only one kind of breadth-first traversal: the level order traversal.
This traversal visits nodes by levels from top to bottom and from left to
right.

