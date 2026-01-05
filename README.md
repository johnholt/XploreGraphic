#  Explore Graphics
This projects explores the use of graphics to display and explore an 
undirected graph.  The data model is a list of items that are tagged
with zero or more tags.  The tags represent topics and the items represent 
papers or articles.

## Components
### Data Generation
The GeneratedData class will generate data matching supplied distribution parameters.  

The numbers of *Tag* and *Item* records to generated are supplied as parameters,
but the number of *Tag* records generated can be larger than requested if needed
inorder to satisfy the .  The **averageTagFreq** parameter.

numItems
: Number of items
numTags
: Number of tags
forceUnusedTags
: Reserve 2 of the tags from assignment so that there are unused tags in the data collection.
pctItemTable
: The percent of items that have a matching cardinality of tags.  For example, {0.1, 0.4, 0.3, 0.2}
 specifies that 10% have 0 tags, 40% has 1 tag assigned, 30% have 2 tags assigned, and 20% has 3 tags assigned.
avgTagFreq
: average tag frequency.  Note that this may cause the number of tags to increase.
maxTagFreq
: maximum tag frequency.

###  Undirected Graph
The UndirectredGraph class captures the *Tag* instances as graph nodes and the *Item* instances
as edges.  The class will determine the paths and the minimum distance between each pair of nodes.  

### Tag Network
The TagNetwork value type determines the 2D graph layout of the data.

### Tests
There are unit tests and UI tests provided.

## Operation
There are two phases of operation.  The first phase is the generation of test data 
and the second phase is the exploration of the graph.  

The data generation phase shows a frequency graph of the generated data and supports 
browsing the generated data.

The graph exploration phase shows histograms of path statistics and adjacency statistics 
of the graph; and a 2D graphical representation of the graph.  

The 2D representation supports magnification and drag so that clipped regions can be displayed.

The tags are represented as circles on the graph, and the edges are lines on the graph connecting
tags that co-occur.  

When a tag (circle) is tapped, a popover appears displaying information about the tag.  This is
accomplished by mapping the screen co-ordinates into the co-ordinate system used by TagNetwork to
layout the graphic.  


## Developer notes
In GraphNetworkView, the co-ordinate space was explicitly stated.  It appears that using the default (.local)
would have been sufficient.

The order of the objects in the graph is influenced by the position of objects in dictionaries.  A repeatable
placement would have required keeping an ordered copy of the objects and iterating through the ordered copy
instead of iterating through a dictionary.

A Format Style for a list of integer tuples is needs to display the dictionary contents in the GraphDataView.

All of the work is performed in the main thread.  Moving some of the UndirectedGraph operations to another
thread should be done for larger networks.


