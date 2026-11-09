# typed: true

# The DSL instance_evals each block on a node of the bound type.

module Swagger::Blocks::ClassMethods
  private

  sig { params(inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::RootNode).void)).returns(T.untyped) }
  def swagger_root(inline_keys = T.unsafe(nil), &block); end

  sig { params(path: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::PathNode).void)).returns(T.untyped) }
  def swagger_path(path, &block); end

  sig { params(name: T.untyped, inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::SchemaNode).void)).returns(T.untyped) }
  def swagger_schema(name, inline_keys = T.unsafe(nil), &block); end

  sig { params(inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::ComponentNode).void)).returns(T.untyped) }
  def swagger_component(inline_keys = T.unsafe(nil), &block); end
end

class Swagger::Blocks::Nodes::AllOfNode < Swagger::Blocks::Node
  sig { params(inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::SchemaNode).void)).returns(T.untyped) }
  def schema(inline_keys = T.unsafe(nil), &block); end
end

class Swagger::Blocks::Nodes::CallbackDestinationNode < Swagger::Blocks::Node
  sig { params(method_name: T.untyped, inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::CallbackMethodNode).void)).returns(T.untyped) }
  def method(method_name, inline_keys = T.unsafe(nil), &block); end
end

class Swagger::Blocks::Nodes::CallbackMethodNode < Swagger::Blocks::Node
  sig { params(inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::RequestBodyNode).void)).returns(T.untyped) }
  def request_body(inline_keys = T.unsafe(nil), &block); end

  sig { params(resp: T.untyped, inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::ResponseNode).void)).returns(T.untyped) }
  def response(resp, inline_keys = T.unsafe(nil), &block); end
end

class Swagger::Blocks::Nodes::CallbackNode < Swagger::Blocks::Node
  sig { params(address: T.untyped, inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::CallbackDestinationNode).void)).returns(T.untyped) }
  def destination(address, inline_keys = T.unsafe(nil), &block); end
end

class Swagger::Blocks::Nodes::ComponentNode < Swagger::Blocks::Node
  sig { params(name: T.untyped, inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::SchemaNode).void)).returns(T.untyped) }
  def schema(name, inline_keys = T.unsafe(nil), &block); end

  sig { params(name: T.untyped, inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::LinkNode).void)).returns(T.untyped) }
  def link(name, inline_keys = T.unsafe(nil), &block); end

  sig { params(name: T.untyped, inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::ExampleNode).void)).returns(T.untyped) }
  def example(name, inline_keys = T.unsafe(nil), &block); end

  sig { params(name: T.untyped, inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::SecuritySchemeNode).void)).returns(T.untyped) }
  def security_scheme(name, inline_keys = T.unsafe(nil), &block); end

  sig { params(name: T.untyped, inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::ParameterNode).void)).returns(T.untyped) }
  def parameter(name, inline_keys = T.unsafe(nil), &block); end

  sig { params(name: T.untyped, inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::RequestBodyNode).void)).returns(T.untyped) }
  def request_body(name, inline_keys = T.unsafe(nil), &block); end

  sig { params(name: T.untyped, inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::ResponseNode).void)).returns(T.untyped) }
  def response(name, inline_keys = T.unsafe(nil), &block); end
end

class Swagger::Blocks::Nodes::ContentNode < Swagger::Blocks::Node
  sig { params(inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::SchemaNode).void)).returns(T.untyped) }
  def schema(inline_keys = T.unsafe(nil), &block); end

  sig { params(name: T.untyped, inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::ExampleNode).void)).returns(T.untyped) }
  def example(name = T.unsafe(nil), inline_keys = T.unsafe(nil), &block); end
end

class Swagger::Blocks::Nodes::ExampleNode < Swagger::Blocks::Node
  sig { params(inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::ValueNode).void)).returns(T.untyped) }
  def value(inline_keys = T.unsafe(nil), &block); end
end

class Swagger::Blocks::Nodes::FlowNode < Swagger::Blocks::Node
  sig { params(inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::ScopesNode).void)).returns(T.untyped) }
  def scopes(inline_keys = T.unsafe(nil), &block); end
end

class Swagger::Blocks::Nodes::HeaderNode < Swagger::Blocks::Node
  sig { params(inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::ItemsNode).void)).returns(T.untyped) }
  def items(inline_keys = T.unsafe(nil), &block); end

  sig { params(inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::SchemaNode).void)).returns(T.untyped) }
  def schema(inline_keys = T.unsafe(nil), &block); end
end

class Swagger::Blocks::Nodes::InfoNode < Swagger::Blocks::Node
  sig { params(inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::ContactNode).void)).returns(T.untyped) }
  def contact(inline_keys = T.unsafe(nil), &block); end

  sig { params(inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::LicenseNode).void)).returns(T.untyped) }
  def license(inline_keys = T.unsafe(nil), &block); end
end

class Swagger::Blocks::Nodes::ItemsNode < Swagger::Blocks::Node
  sig { params(inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::ItemsNode).void)).returns(T.untyped) }
  def items(inline_keys = T.unsafe(nil), &block); end

  sig { params(name: T.untyped, inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::PropertyNode).void)).returns(T.untyped) }
  def property(name, inline_keys = T.unsafe(nil), &block); end
end

class Swagger::Blocks::Nodes::LinkNode < Swagger::Blocks::Node
  sig { params(inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::LinkParameterNode).void)).returns(T.untyped) }
  def parameters(inline_keys = T.unsafe(nil), &block); end
end

class Swagger::Blocks::Nodes::OneOfNode < Swagger::Blocks::Node
  sig { params(inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::ItemsNode).void)).returns(T.untyped) }
  def items(inline_keys = T.unsafe(nil), &block); end
end

class Swagger::Blocks::Nodes::OperationNode < Swagger::Blocks::Node
  sig { params(inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::ParameterNode).void)).returns(T.untyped) }
  def parameter(inline_keys = T.unsafe(nil), &block); end

  sig { params(resp: T.untyped, inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::ResponseNode).void)).returns(T.untyped) }
  def response(resp, inline_keys = T.unsafe(nil), &block); end

  sig { params(inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::ExternalDocsNode).void)).returns(T.untyped) }
  def externalDocs(inline_keys = T.unsafe(nil), &block); end

  sig { params(inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::SecurityRequirementNode).void)).returns(T.untyped) }
  def security(inline_keys = T.unsafe(nil), &block); end

  sig { params(inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::RequestBodyNode).void)).returns(T.untyped) }
  def request_body(inline_keys = T.unsafe(nil), &block); end

  sig { params(event_name: T.untyped, inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::CallbackNode).void)).returns(T.untyped) }
  def callback(event_name, inline_keys = T.unsafe(nil), &block); end

  sig { params(inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::ServerNode).void)).returns(T.untyped) }
  def server(inline_keys = T.unsafe(nil), &block); end
end

class Swagger::Blocks::Nodes::ParameterNode < Swagger::Blocks::Node
  sig { params(inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::SchemaNode).void)).returns(T.untyped) }
  def schema(inline_keys = T.unsafe(nil), &block); end

  sig { params(inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::ItemsNode).void)).returns(T.untyped) }
  def items(inline_keys = T.unsafe(nil), &block); end

  sig { params(name: T.untyped, inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::ExampleNode).void)).returns(T.untyped) }
  def example(name, inline_keys = T.unsafe(nil), &block); end
end

class Swagger::Blocks::Nodes::PathNode < Swagger::Blocks::Node
  sig { params(op: T.untyped, inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::OperationNode).void)).returns(T.untyped) }
  def operation(op, inline_keys = T.unsafe(nil), &block); end

  sig { params(inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::ParameterNode).void)).returns(T.untyped) }
  def parameter(inline_keys = T.unsafe(nil), &block); end

  sig { params(inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::ServerNode).void)).returns(T.untyped) }
  def server(inline_keys = T.unsafe(nil), &block); end
end

class Swagger::Blocks::Nodes::PropertiesNode < Swagger::Blocks::Node
  sig { params(name: T.untyped, inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::PropertyNode).void)).returns(T.untyped) }
  def property(name, inline_keys = T.unsafe(nil), &block); end
end

class Swagger::Blocks::Nodes::PropertyNode < Swagger::Blocks::Node
  sig { params(inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::ItemsNode).void)).returns(T.untyped) }
  def items(inline_keys = T.unsafe(nil), &block); end

  sig { params(block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::OneOfNode).void)).returns(T.untyped) }
  def one_of(&block); end

  sig { params(name: T.untyped, inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::PropertyNode).void)).returns(T.untyped) }
  def property(name, inline_keys = T.unsafe(nil), &block); end
end

class Swagger::Blocks::Nodes::RequestBodyNode < Swagger::Blocks::Node
  sig { params(type: T.untyped, inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::ContentNode).void)).returns(T.untyped) }
  def content(type, inline_keys = T.unsafe(nil), &block); end
end

class Swagger::Blocks::Nodes::ResponseNode < Swagger::Blocks::Node
  sig { params(inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::SchemaNode).void)).returns(T.untyped) }
  def schema(inline_keys = T.unsafe(nil), &block); end

  sig { params(head: T.untyped, inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::HeaderNode).void)).returns(T.untyped) }
  def header(head, inline_keys = T.unsafe(nil), &block); end

  sig { params(type: T.untyped, inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::ContentNode).void)).returns(T.untyped) }
  def content(type, inline_keys = T.unsafe(nil), &block); end

  sig { params(name: T.untyped, inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::ExampleNode).void)).returns(T.untyped) }
  def example(name = T.unsafe(nil), inline_keys = T.unsafe(nil), &block); end

  sig { params(name: T.untyped, inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::LinkNode).void)).returns(T.untyped) }
  def link(name, inline_keys = T.unsafe(nil), &block); end
end

class Swagger::Blocks::Nodes::RootNode < Swagger::Blocks::Node
  sig { params(inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::InfoNode).void)).returns(T.untyped) }
  def info(inline_keys = T.unsafe(nil), &block); end

  sig { params(param: T.untyped, inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::ParameterNode).void)).returns(T.untyped) }
  def parameter(param, inline_keys = T.unsafe(nil), &block); end

  sig { params(resp: T.untyped, inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::ResponseNode).void)).returns(T.untyped) }
  def response(resp, inline_keys = T.unsafe(nil), &block); end

  sig { params(name: T.untyped, inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::SecuritySchemeNode).void)).returns(T.untyped) }
  def security_definition(name, inline_keys = T.unsafe(nil), &block); end

  sig { params(inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::SecurityRequirementNode).void)).returns(T.untyped) }
  def security(inline_keys = T.unsafe(nil), &block); end

  sig { params(inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::ExternalDocsNode).void)).returns(T.untyped) }
  def externalDocs(inline_keys = T.unsafe(nil), &block); end

  sig { params(inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::TagNode).void)).returns(T.untyped) }
  def tag(inline_keys = T.unsafe(nil), &block); end

  sig { params(inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::ServerNode).void)).returns(T.untyped) }
  def server(inline_keys = T.unsafe(nil), &block); end

  sig { params(name: T.untyped, inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::VendorExtensionNode).void)).returns(T.untyped) }
  def extension(name, inline_keys = T.unsafe(nil), &block); end
end

class Swagger::Blocks::Nodes::SchemaNode < Swagger::Blocks::Node
  sig { params(inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::ItemsNode).void)).returns(T.untyped) }
  def items(inline_keys = T.unsafe(nil), &block); end

  sig { params(block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::AllOfNode).void)).returns(T.untyped) }
  def allOf(&block); end

  sig { params(inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::XmlNode).void)).returns(T.untyped) }
  def xml(inline_keys = T.unsafe(nil), &block); end

  sig { params(inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::ExternalDocsNode).void)).returns(T.untyped) }
  def externalDocs(inline_keys = T.unsafe(nil), &block); end

  sig { params(inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::ExampleNode).void)).returns(T.untyped) }
  def example(inline_keys = T.unsafe(nil), &block); end

  sig { params(block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::OneOfNode).void)).returns(T.untyped) }
  def one_of(&block); end

  sig { params(name: T.untyped, inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::PropertyNode).void)).returns(T.untyped) }
  def property(name, inline_keys = T.unsafe(nil), &block); end
end

class Swagger::Blocks::Nodes::SecuritySchemeNode < Swagger::Blocks::Node
  sig { params(inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::ScopesNode).void)).returns(T.untyped) }
  def scopes(inline_keys = T.unsafe(nil), &block); end

  sig { params(name: T.untyped, inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::FlowNode).void)).returns(T.untyped) }
  def flow(name, inline_keys = T.unsafe(nil), &block); end
end

class Swagger::Blocks::Nodes::ServerNode < Swagger::Blocks::Node
  sig { params(name: T.untyped, inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::VariableNode).void)).returns(T.untyped) }
  def variable(name, inline_keys = T.unsafe(nil), &block); end
end

class Swagger::Blocks::Nodes::TagNode < Swagger::Blocks::Node
  sig { params(inline_keys: T.untyped, block: T.nilable(T.proc.bind(Swagger::Blocks::Nodes::ExternalDocsNode).void)).returns(T.untyped) }
  def externalDocs(inline_keys = T.unsafe(nil), &block); end
end
