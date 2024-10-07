
from setuptools import setup, find_packages

setup(
    name="graph_utils",
    version="0.1",
    packages=find_packages(),
    install_requires=[
        'networkx',
        'pygraphviz',
        'matplotlib',
        'pydot',
    ],
)