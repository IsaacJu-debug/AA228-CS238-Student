using Pkg

packages = [
    "CSV",
    "Graphs",
    "GraphIO",
    "Compose",
    "GraphvizDotLang",
    "SpecialFunctions",
    "StatsBase",
    "DataFrames",
    "GraphPlot",
    "Cairo",
    "Fontconfig",
    "GraphRecipes",
    "PyCall"
]

println("Installing packages...")
Pkg.add(packages)

# Check for successful installation
for package in packages
    if haskey(Pkg.installed(), package)
        println("$package installed successfully.")
    else
        println("Failed to install $package. Please check for errors and try again.")
    end
end

# Configure PyCall to use your custom Python environment
# Replace "/path/to/your/private/env/bin/python" with the actual path to your Python interpreter
ENV["PYTHON"] = "/home/groups/smbenson/isaacju/01_env/ai_earth/bin/python"
Pkg.build("PyCall")

println("\nPackage installation complete. PyCall has been configured.")
println("You may need to restart your Julia session for changes to take effect.")