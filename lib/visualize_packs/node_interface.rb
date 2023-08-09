# typed: strict

module VisualizePacks
  module NodeInterface
    extend T::Sig
    extend T::Helpers
    interface!

    sig { abstract.returns(String) }
    def name
    end

    sig { abstract.returns(String) }
    def group_name
    end

    sig { abstract.returns(T::Hash[String, Integer]) }
    def violations_by_node_name
    end

    sig { abstract.returns(T::Array[String]) }
    def dependencies
    end

    sig { abstract.params(node_name: String).returns(T::Boolean) }
    def depends_on?(node_name)
    end
  end
end
