# typed: strict

module VisualizePacks
  # This stores graphviz-independent views of our package graph.
  # It should be optimized for fast lookup (leveraging internal indexes, which are stable due to the immutability of the package nodes)
  # A `TeamGraph` should be able to consume this and basically just create a reduced version
  # Lastly, each one should implement a common interface, and graphviz should use that interface and take in either types of graph via the interface
  module GraphInterface
    extend T::Sig
    extend T::Helpers
    interface!

    sig { abstract.returns(T::Set[NodeInterface]) }
    def nodes
    end
  end
end
