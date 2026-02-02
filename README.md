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
inorder to satisfy the **averageTagFreq** parameter.

The parameters are:

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
The UndirectredGraph class captures the *Tag* instances as graph vertices and the *Item* instances
as edges.  The class will determine the paths and the minimum distance between each pair of vertices.  

### Tag Network
The TagNetwork value type determines the 2D graph layout of the data.  The aspect ratio is an input parameter.

### Tests
There are unit tests and UI tests provided.

## Operation
There are two phases of operation.  The first phase is the generation of test data 
and the second phase is the exploration and display of the graph.  

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


## Programming notes
In GraphNetworkView, the co-ordinate space was explicitly stated.  It appears that using the default (.local)
would have been sufficient.

The order of the objects in the graph is influenced by the position of objects in dictionaries.  A repeatable
placement would have required keeping an ordered copy of the objects and iterating through the ordered copy
instead of iterating through a dictionary.

A Format Style for a list of tuples from enumerated() is needed to display the dictionary contents in the GraphDataView.
Unfortunately, this would require the ability to extend a tuple type which is experimental.  The work around was to create
functions that converted the two dictionsaries of interest into an array of strings.

All of the work is performed in the main thread.  Moving some of the UndirectedGraph operations to another
thread should be done for larger networks.

The drag and the animation for the drag needed to be done inside of the scale effect and the scale effect modifier
for the correct behavior on all platforms.  It is not clear why this would be the case.

A GeometryReader was used to wrap the Canvas so that the Canvas size information could be provided to some of the Canvas
modifier definitions.  This results in the same information held by the parameter value for the GeometryReader closure
and by the parameter value for the Canvas closure.  There should be a better way to do this.
