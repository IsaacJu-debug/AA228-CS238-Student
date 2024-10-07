import pandas as pd
import math
import numpy as np
import networkx as nx
import random
import scipy.special as sci
import time
from tqdm import tqdm

import os
from graph_utils import visualize_dag_graphviz

def learn_bayesian_network(file_name, alg_opt= 'vanilla', seed=42):
    start_time = time.time()
    input_path = os.path.join('./data', file_name + '.csv')
    df = pd.read_csv(input_path)
    variable_names = df.columns.tolist()
    data_array = df.to_numpy()
    
    # Learn network structure using K2 algorithm

    if alg_opt.lower() == "vanilla":
        learned_graph, best_score = k2_structure_learning(data_array, seed=seed)
    else:
        pass
    end_time = time.time()
    print('Execution time (minutes):', (end_time - start_time) / 60)
    print('Best Bayesian Score:', best_score)
    index_to_name = {idx: name for idx, name in enumerate(variable_names)}
    
    # Create results directory if it doesn't exist
    results_dir = './results'
    os.makedirs(results_dir, exist_ok=True)
    
    # Write results to files
    output_gph = os.path.join(results_dir, file_name + f'_{seed}.gph')
    output_gml = os.path.join(results_dir, file_name + f'_{seed}.gml')
    output_pdf = os.path.join(results_dir, file_name + f'_{seed}_graph.pdf')

    write_graph_structure(learned_graph, index_to_name, output_gph)
    nx.write_gml(learned_graph, output_gml)

    visualize_dag_graphviz(learned_graph, index_to_name=index_to_name, output_path=output_pdf)
    #visualize_dag(learned_graph, index_to_name, output_pdf)
    print(f"Output written to {output_gph} and {output_gml}")
    print(f"Graph visualization saved to {output_pdf}")

def k2_structure_learning(data, seed=42):

    random.seed(seed)
    num_variables = data.shape[1]
    variable_order = list(range(num_variables))
    random.shuffle(variable_order)
    
    graph = nx.DiGraph()
    graph.add_nodes_from(range(num_variables))
    
    for k, child in tqdm(enumerate(variable_order[1:]), total=num_variables - 1):
        current_score = calculate_bayesian_score(data, graph)
        while True:
            best_score, best_parent = -np.inf, None
            for potential_parent in variable_order[:k + 1]:
                if not graph.has_edge(potential_parent, child):
                    graph.add_edge(potential_parent, child)
                    new_score = calculate_bayesian_score(data, graph)
                    if new_score > best_score:
                        best_score, best_parent = new_score, potential_parent
                    graph.remove_edge(potential_parent, child)
            
            if best_score > current_score:
                current_score = best_score
                graph.add_edge(best_parent, child)
            else:
                break
    
    return graph, current_score

def calculate_statistics(data, graph):
    num_variables = data.shape[1]
    num_observations = data.shape[0]
    
    # Calculate r_i (number of possible values for each variable)
    r_values = [max(data[:, i]) for i in range(num_variables)]
    q_values = [math.prod([r_values[parent] for parent, _ in graph.in_edges(i)]) for i in range(num_variables)]
    M = [np.zeros((q_values[i], r_values[i])) for i in range(num_variables)]
    
    # Populate M
    for obs in range(num_observations):
        observation = data[obs, :]
        for i in range(num_variables):
            k = observation[i] - 1  # Adjust for 0-based indexing
            parents = [parent for parent, _ in graph.in_edges(i)]
            j = 0
            if parents:
                parent_values = [r_values[parent] for parent in parents]
                parent_observation = observation[parents] - 1  # Adjust for 0-based indexing
                j = np.ravel_multi_index(parent_observation, parent_values)
            M[i][j, k] += 1
    
    return M

def calculate_prior(data, graph):
    num_variables = data.shape[1]
    r_values = [max(data[:, i]) for i in range(num_variables)]
    q_values = [math.prod([r_values[parent] for parent, _ in graph.in_edges(i)]) for i in range(num_variables)]
    return [np.ones((q_values[i], r_values[i])) for i in range(num_variables)]

def calculate_bayesian_score_component(M, alpha):

    score = np.sum(sci.loggamma(alpha + M))
    score -= np.sum(sci.loggamma(alpha))
    score += np.sum(sci.loggamma(np.sum(alpha, axis=1)))
    score -= np.sum(sci.loggamma(np.sum(alpha, axis=1) + np.sum(M, axis=1)))
    return score

def calculate_bayesian_score(data, graph):
    
    num_variables = data.shape[1]
    alpha = calculate_prior(data, graph)
    M = calculate_statistics(data, graph)

    return sum(calculate_bayesian_score_component(M[i], alpha[i]) for i in range(num_variables))

def write_graph_structure(graph, index_to_name, filename):
    with open(filename, 'w') as f:
        for edge in graph.edges():
            f.write(f"{index_to_name[edge[0]]}, {index_to_name[edge[1]]}\n")

if __name__ == '__main__':

    #file_list = ['small']
    seed = 10
    alg_list = ['vanilla']
    file_list = ['small', 'medium', 'large']
    for file in file_list:
        for alg in alg_list:
            print(f"Processing {file} dataset with {alg}...")
            learn_bayesian_network(file, alg_opt=alg, seed=seed)