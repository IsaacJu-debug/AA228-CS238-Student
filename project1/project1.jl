using CSV
using Random
using Graphs
using GraphIO
using Compose
using GraphRecipes, Plots
using MetaGraphs

using PyCall
using SpecialFunctions
using LinearAlgebra
using StatsBase
using Printf
using DataFrames
using GraphPlot
using Cairo
using Fontconfig

function learn_bayesian_network(file_name::String, alg_opt::String="vanilla", seed::Int=42)
    start_time = time()
    input_path = joinpath("./data", file_name * ".csv")
    df = CSV.read(input_path, DataFrame)
    variable_names = names(df)
    data_array = Matrix(df)
    
    if lowercase(alg_opt) == "vanilla"
        learned_graph, best_score = k2_structure_learning(data_array, seed)
    else
        error("Unsupported algorithm option")
    end

    end_time = time()
    @printf("Execution time (seconds): %.2f\n", (end_time - start_time))
    println("Best Bayesian Score: ", best_score)

    index_to_name = Dict(idx => name for (idx, name) in enumerate(variable_names))
    
    results_dir = "./new_results"
    mkpath(results_dir)
    
    output_gph = joinpath(results_dir, "$(file_name)_$(seed)_j.gph")
    output_gml = joinpath(results_dir, "$(file_name)_$(seed)_j.gml")
    output_pdf = joinpath(results_dir, "$(file_name)_$(seed)_graph_j.pdf")

    write_graph_structure(learned_graph, index_to_name, output_gph)
    save_graph_gml(learned_graph, index_to_name, output_gml)

    #call_python_visualize(learned_graph, index_to_name, output_pdf)
    #visualize_dag_gplot(learned_graph, index_to_name, output_pdf)
    #visualize_dag_graphplot(learned_graph, index_to_name, output_pdf)
    #println("Output written to $output_gph") 
end

function k2_structure_learning(data::Matrix{Int}, seed::Int=42)
    Random.seed!(seed)
    num_variables = size(data, 2)
    variable_order = shuffle(1:num_variables)
    
    graph = SimpleDiGraph(num_variables)
    current_score = 0.0
    for k in 1:num_variables-1
        child = variable_order[k+1]
        current_score = calculate_bayesian_score(data, graph)
        while true
            best_score, best_parent = -Inf, nothing
            for potential_parent in variable_order[1:k]
                if !has_edge(graph, potential_parent, child)
                    add_edge!(graph, potential_parent, child)
                    new_score = calculate_bayesian_score(data, graph)
                    if new_score > best_score
                        best_score, best_parent = new_score, potential_parent
                    end
                    rem_edge!(graph, potential_parent, child)
                end
            end
            
            if best_score > current_score
                current_score = best_score
                add_edge!(graph, best_parent, child)
            else
                break
            end
        end
    end
    
    return graph, current_score
end

function write_graph_structure(graph::SimpleDiGraph, index_to_name::Dict{Int, String}, filename::String)
    open(filename, "w") do f
        for edge in edges(graph)
            write(f, "$(index_to_name[src(edge)]), $(index_to_name[dst(edge)])\n")
        end
    end
end

function visualize_dag_graphplot(graph::SimpleDiGraph, 
    index_to_name::Dict{Int, String}, 
    output_file::String)

    # Prepare node labels
    labels = [get(index_to_name, v, string(v)) for v in vertices(graph)]
    nodesize = fill(0.15, nv(graph))

    # Create the plot
    p = gplot(graph,
        nodelabel = labels,
        nodesize = nodesize,
        nodefillc = "white",
        nodestrokec = "black",
        nodestrokelw = 1,
        edgestrokec = "gray",
        edgelinewidth = 1,
        NODELABELSIZE = 5,  # Adjust as needed
        layout = spring_layout)

    # Save the plot
    draw(PDF(output_file, 16cm, 16cm), p)
    println("Graph visualization saved to $output_file")
end


function save_graph_gml(graph::SimpleDiGraph, index_to_name::Dict{Int, String}, output_file::String)
    nx = pyimport("networkx")
    
    # Create a new NetworkX DiGraph
    G = nx.DiGraph()
    
    # Add nodes with labels and IDs (adjusting for 0-based indexing)
    for v in vertices(graph)
        label = get(index_to_name, v, string(v-1))
        G.add_node(v-1, label=label, julia_id=string(v), name=label)
    end
    
    # Add edges (adjusting for 0-based indexing)
    for e in edges(graph)
        G.add_edge(src(e)-1, dst(e)-1)
    end
    
    # Save the graph in GML format
    nx.write_gml(G, output_file)
    println("Graph saved in GML format to $output_file")

end
function visualize_dag_gplot(graph::SimpleDiGraph, 
                            index_to_name::Dict{Int, String}, 
                            output_file::String)

    labels = [string(get(index_to_name, v, v)) for v in vertices(graph)]
    
    p = graphplot(graph,
                  names = labels,
                  nodeshape = :ellipse,
                  nodecolor = :white,
                  method = :spring,
                  #nodesize = 0.15,
                  root = :top,
                  curves = false,
                  arrow = :head,
                  #arrowsize = 10,
                  linecolor = :gray,
                  linewidth = 1,
                  #fontsize = 8,
                  nodelinewidth = 1,
                  nodelinecolor = :black,
                  #size = (800, 600),  # Adjust size as needed
                  background_color = :white)

    # Add a title
    title!("Directed Acyclic Graph")

    # Save the plot
    Plots.pdf(p, output_file)
    println("Graph visualization saved to $output_file")
end


function call_python_visualize(graph::SimpleDiGraph, 
                         index_to_name::Dict{Int, String}, 
                         output_file::String,
                         format::String="pdf")
    
    # Import required Python libraries
    pydot = pyimport("pydot")
    pgv = pyimport("pygraphviz")
    
    # Create a new PyGraphviz AGraph
    dot = pgv.AGraph(directed=true,  encoding="utf-8")
    dot.graph_attr["rankdir"] = "LR"  # Left to right layout
    dot.node_attr["shape"] = "ellipse"
    dot.node_attr["style"] = "filled"
    dot.node_attr["fillcolor"] = "white"
    dot.node_attr["fontname"] = "Arial"  # Use a common font

    # Add nodes
    for v in vertices(graph)
        label = get(index_to_name, v, string(v))
        dot.add_node(string(v-1))  # Adjust for 0-based indexing
        println(" node $(v-1) label $label")
    end

    # Add edges
    for e in edges(graph)
        dot.add_edge(string(src(e)-1), string(dst(e)-1))  # Adjust for 0-based indexing
    end

    # Draw the graph
    dot.layout(prog="dot")  # Use dot layout algorithm
    dot.draw(output_file, format=format)
    println("Graph visualization saved to $output_file")
end

function calculate_statistics(data::Matrix{Int}, graph::SimpleDiGraph)
    num_variables = size(data, 2)
    num_observations = size(data, 1)
    
    r_values = [maximum(data[:, i]) for i in 1:num_variables]
    q_values = [prod([r_values[src] for src in inneighbors(graph, i)]) for i in 1:num_variables]
    M = [zeros(Int, q_values[i], r_values[i]) for i in 1:num_variables]
    
    for obs in 1:num_observations
        observation = data[obs, :]
        for i in 1:num_variables
            k = observation[i]
            parents = inneighbors(graph, i)
            j = 1
            if !isempty(parents)
                parent_values = [r_values[parent] for parent in parents]
                parent_observation = observation[parents]
                j = calculate_parent_index(parent_observation, parent_values)
            end
            M[i][j, k] += 1
        end
    end
    
    return M
end

function calculate_parent_index(parent_observation, parent_values)
    index = 1
    multiplier = 1
    for i in 1:length(parent_observation)
        index += (parent_observation[i] - 1) * multiplier
        multiplier *= parent_values[i]
    end
    return index
end

function calculate_prior(data::Matrix{Int}, graph::SimpleDiGraph)
    num_variables = size(data, 2)
    r_values = [maximum(data[:, i]) for i in 1:num_variables]
    q_values = [prod([r_values[src] for src in inneighbors(graph, i)]) for i in 1:num_variables]
    return [ones(Float64, q_values[i], r_values[i]) for i in 1:num_variables]
end

function calculate_bayesian_score_component(M::Matrix{Int}, alpha::Matrix{Float64})
    score = sum(loggamma.(alpha .+ M))
    score -= sum(loggamma.(alpha))
    score += sum(loggamma.(sum(alpha, dims=2)))
    score -= sum(loggamma.(sum(alpha, dims=2) .+ sum(M, dims=2)))
    return score
end

function calculate_bayesian_score(data::Matrix{Int}, graph::SimpleDiGraph)
    num_variables = size(data, 2)
    alpha = calculate_prior(data, graph)
    M = calculate_statistics(data, graph)

    return sum(calculate_bayesian_score_component(M[i], alpha[i]) for i in 1:num_variables)
end


function learn_bayesian_network_with_sensitivity(file_name::String,
                                                 num_trials::Int=20, 
                                                 alg_opt::String="vanilla")
    best_score = -Inf  # Initialize with negative infinity as we're looking for the highest score
    best_seed = 0
    best_graph = nothing
    
    variable_names = nothing
    for _ in 1:num_trials
        seed = rand(1:10000)  # Generate a random seed
        
        input_path = joinpath("./data", file_name * ".csv")
        df = CSV.read(input_path, DataFrame)
        variable_names = names(df)
        data_array = Matrix(df)
        
        start_time = time()
        
        if lowercase(alg_opt) == "vanilla"
            learned_graph, current_score = k2_structure_learning(data_array, seed)
        else
            error("Unsupported algorithm option")
        end
        
        end_time = time()
        @printf("Execution time for seed %d (seconds): %.2f\n", seed, (end_time - start_time))
        
        if current_score > best_score
            best_score = current_score
            best_seed = seed
            best_graph = learned_graph
        end
    end
    
    println("Best Bayesian Score: ", best_score)
    println("Best Seed: ", best_seed)
    
    index_to_name = Dict(idx => name for (idx, name) in enumerate(variable_names))
    
    results_dir = "./sens_results"
    mkpath(results_dir)
    
    output_gph = joinpath(results_dir, "$(file_name).gph")
    write_graph_structure(best_graph, index_to_name, output_gph)
    println("Saved best graph to: $output_gph")
    
    return best_score, best_seed
end


# Main execution
#=
seed = 10
alg_list = ["vanilla"]
file_list = ["small", "medium", "large"]

for file in file_list
    for alg in alg_list
        println("Processing $file dataset with $alg with Julia")
        learn_bayesian_network(file, alg, seed)
    end
end
=#


file_list = ["small", "medium", "large"]
num_trials = 20  # Number of random seeds to try
best_scores = Dict()  # To store the best score for each dataset

for file in file_list
    println("Processing $file dataset")
    best_score, best_seed = learn_bayesian_network_with_sensitivity(file, num_trials)
    best_scores[file] = (score = best_score, seed = best_seed)
end

# Print overall results
println("\nOverall Best Scores:")
for (file, result) in best_scores
    println("$file dataset: Score = $(result.score), Seed = $(result.seed)")
end