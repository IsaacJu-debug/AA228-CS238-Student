import networkx as nx
import pygraphviz as pgv
import matplotlib.pyplot as plt
import pydot

def visualize_dag(graph, index_to_name, output_file):
    # Create a new graph with node labels
    labeled_graph = nx.relabel_nodes(graph, index_to_name)
    plt.figure(figsize=(12, 8))
    pos = nx.spring_layout(labeled_graph)

    nx.draw_networkx_nodes(labeled_graph,
                             pos,
                             node_size=100, 
                             node_color='lightblue')

    nx.draw_networkx_edges(labeled_graph, pos, 
                       arrows=True, 
                       arrowsize=40,
                       width=1.5,
                       alpha=0.7,
                       connectionstyle="arc3,rad=0.1")
    #nx.draw_networkx_labels(labeled_graph, pos, font_size=10, font_weight='bold')
    nx.draw_networkx(labeled_graph, pos = pos, with_labels = True)
    plt.axis('off')
    plt.title("Learned structures", fontsize=16)

    plt.tight_layout()
    plt.savefig(output_file, format='pdf')
    plt.close()

def visualize_dag_graphviz(G, index_to_name, output_path, format='pdf'):
    # Create a new PyGraphviz AGraph
    dot = pgv.AGraph(directed=True, strict=True)
    dot.graph_attr['rankdir'] = 'LR'  # Left to right layout
    dot.node_attr['shape'] = 'ellipse'
    dot.node_attr['style'] = 'filled'
    dot.node_attr['fillcolor'] = 'white'

    # Add nodes
    for node in G.nodes():
        dot.add_node(str(node), label=index_to_name[node])
    
    # Add edges
    for edge in G.edges():
        dot.add_edge(str(edge[0]), str(edge[1]))
    
    # Draw the graph
    dot.layout(prog='dot')  # Use dot layout algorithm
    
    # Save the graph
    dot.draw(f"{output_path}", format=format)