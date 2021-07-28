"""functions to draw the different graphs we can generate in the package, eg to debug"""
from typing import Dict, List

import matplotlib.pyplot as plt
import networkx as nx

from hdk.common.representation import intermediate as ir

IR_NODE_COLOR_MAPPING = {ir.Input: "blue", ir.Add: "red", ir.Sub: "yellow", ir.Mul: "green"}


def human_readable_layout(graph: nx.Graph, x_delta: float = 1.0, y_delta: float = 1.0) -> Dict:
    """
    Returns a pos to be used later with eg nx.draw_networkx_nodes, so that nodes
    are ordered by depth from input along the x axis and have a uniform
    distribution along the y axis

    Args:
        graph (nx.Graph): The graph that we want to draw
        x_delta (float): Parameter used to set the increment in x
        y_delta (float): Parameter used to set the increment in y

    Returns:
        pos (Dict): the argument to use with eg nx.draw_networkx_nodes

    """

    # FIXME: less variables
    # pylint: disable=too-many-locals

    nodes_depth = {node: 0 for node in graph.nodes()}
    input_nodes = [node for node in graph.nodes() if len(list(graph.predecessors(node))) == 0]

    # Init a layout so that unreachable nodes have a pos, avoids potential crashes wiht networkx
    # use a cheap layout
    pos = nx.random_layout(graph)

    curr_x = 0.0
    curr_y = -(len(input_nodes) - 1) / 2 * y_delta

    for in_node in input_nodes:
        pos[in_node] = (curr_x, curr_y)
        curr_y += y_delta

    curr_x += x_delta

    curr_nodes = input_nodes

    current_depth = 0
    while len(curr_nodes) > 0:
        current_depth += 1
        next_nodes_set = set()
        for node in curr_nodes:
            next_nodes_set.update(graph.successors(node))

        curr_nodes = list(next_nodes_set)
        for node in curr_nodes:
            nodes_depth[node] = current_depth

    nodes_by_depth: Dict[int, List[int]] = {}
    for node, depth in nodes_depth.items():
        nodes_for_depth = nodes_by_depth.get(depth, [])
        nodes_for_depth.append(node)
        nodes_by_depth[depth] = nodes_for_depth

    depths = sorted(nodes_by_depth.keys())

    for depth in depths:
        nodes_at_depth = nodes_by_depth[depth]

        curr_y = -(len(nodes_at_depth) - 1) / 2 * y_delta
        for node in nodes_at_depth:
            pos[node] = (curr_x, curr_y)
            curr_y += y_delta

        curr_x += x_delta

    # pylint: enable=too-many-locals
    return pos


def draw_graph(
    graph: nx.DiGraph, block_until_user_closes_graph: bool = True, draw_edge_numbers: bool = True
) -> None:
    """
    Draw a graph

    Args:
        graph (nx.DiGraph): The graph that we want to draw
        block_until_user_closes_graph (bool): if True, will wait the user to
            close the figure before continuing; False is useful for the CI tests
        draw_edge_numbers (bool): if True, add the edge number on the arrow
            linking nodes, eg to differentiate the x and y in a Sub coding
            (x - y). This option is not that useful for commutative ops, and
            may make the picture a bit too dense, so could be deactivated

    Returns:
        None

    """

    # FIXME: less variables
    # pylint: disable=too-many-locals

    # Positions of the node
    pos = human_readable_layout(graph)

    # Colors and labels
    color_map = [IR_NODE_COLOR_MAPPING[type(node)] for node in graph.nodes()]

    # For most types, we just pick the operation as the label, but for Input,
    # we take the name of the variable, ie the argument name of the function
    # to compile
    label_dict = {
        node: node.input_name if isinstance(node, ir.Input) else node.__class__.__name__
        for node in graph.nodes()
    }

    # Draw nodes
    nx.draw_networkx_nodes(
        graph,
        pos,
        node_color=color_map,
        node_size=1000,
        alpha=1,
    )

    # Draw labels
    nx.draw_networkx_labels(graph, pos, labels=label_dict)

    current_axes = plt.gca()

    # And draw edges in a way which works when we have two "equivalent edges",
    # ie from the same node A to the same node B, like to represent y = x + x
    already_done = set()

    for e in graph.edges:

        # If we already drew the different edges from e[0] to e[1], continue
        if (e[0], e[1]) in already_done:
            continue

        already_done.add((e[0], e[1]))

        edges = graph.get_edge_data(e[0], e[1])

        # Draw the different edges from e[0] to e[1], continue
        for which, edge in enumerate(edges.values()):
            edge_index = edge["input_idx"]

            # Draw the edge
            current_axes.annotate(
                "",
                xy=pos[e[0]],
                xycoords="data",
                xytext=pos[e[1]],
                textcoords="data",
                arrowprops=dict(
                    arrowstyle="<-",
                    color="0.5",
                    shrinkA=5,
                    shrinkB=5,
                    patchA=None,
                    patchB=None,
                    connectionstyle="arc3,rad=rrr".replace("rrr", str(0.3 * which)),
                ),
            )

            if draw_edge_numbers:
                # Print the number of the node on the edge. This is a bit artisanal,
                # since it seems not possible to add the text directly on the
                # previously drawn arrow. So, more or less, we try to put a text at
                # a position which is close to pos[e[1]] and which varies a bit with
                # 'which'
                a, b = pos[e[0]]
                c, d = pos[e[1]]
                const_0 = 1
                const_1 = 2

                current_axes.annotate(
                    str(edge_index),
                    xycoords="data",
                    xy=(
                        (const_0 * a + const_1 * c) / (const_0 + const_1),
                        (const_0 * b + const_1 * d + 0.1 * which) / (const_0 + const_1),
                    ),
                    textcoords="data",
                )

    plt.axis("off")

    # block_until_user_closes_graph is used as True for real users and False
    # for CI
    plt.show(block=block_until_user_closes_graph)

    # pylint: enable=too-many-locals
