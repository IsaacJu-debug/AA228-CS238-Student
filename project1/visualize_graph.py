import os
from graph_utils import read_gml_and_visualize

def process_gml_files(sizes, seed):
    base_dir = "./new_results/"
    
    for size in sizes:
        input_file = f"{size}_{seed}_j.gml"
        input_path = os.path.join(base_dir, input_file)
        
        if os.path.exists(input_path):
            output_file = f"{size}_{seed}_j.pdf"
            output_path = os.path.join(base_dir, output_file)
            
            print(f"Processing {input_file}...")
            read_gml_and_visualize(input_path, output_path)
            print(f"Visualization saved to {output_file}")
        else:
            print(f"File not found: {input_path}")

if __name__ == "__main__":
    sizes = ["small", "medium", "large"]
    seed = 10
    
    process_gml_files(sizes, seed)