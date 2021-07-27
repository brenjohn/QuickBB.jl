# QuickBB.jl

A standard algorithm for finding vertex elimination orders, whose treewidth provides a good upper
bound for the minimal treewidth of a graph, is known as the QuickBB algorithm.
It was first proposed by Vibhav Gogate and Rina Dechter in their 2004 paper "A complete 
Anytime Algorithm for Treewidth". The paper along with a binary implementation of the 
algorithm is provided [here](http://www.hlt.utdallas.edu/~vgogate/quickbb.html). 
Here we provide a julia wrapper for their binary which requires a linux OS.