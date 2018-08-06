require "parametric"

module Parametric
  module DSL
    # Example
    #   class Foo
    #     include Parametric::DSL
    #
    #     schema do
    #       field(:title).type(:string).present
    #       field(:age).type(:integer).default(20)
    #     end
    #
    #      attr_reader :params
    #
    #      def initialize(input)
    #        @params = self.class.schema.resolve(input)
    #      end
    #   end
    #
    #   foo = Foo.new(title: "A title", nope: "hello")
    #
    #   foo.params # => {title: "A title", age: 20}
    #
    DEFAULT_SCHEMA_NAME = :schema

    def self.included(base)
      base.extend(ClassMethods)
      base.schemas = {DEFAULT_SCHEMA_NAME => Parametric::Schema.new}
    end

    module ClassMethods
      def schema=(sc)
        @schemas[DEFAULT_SCHEMA_NAME] = sc
      end

      def schemas=(sc)
        @schemas = sc
      end

      def inherited(subclass)
        subclass.schemas = @schemas.each_with_object({}) do |(key, sc), hash|
          hash[key] = sc.merge(Parametric::Schema.new)
        end
      end

      def schema(*args, &block)
        options = args.last.is_a?(Hash) ? args.last : {}
        key = args.first.is_a?(Symbol) ? args.first : DEFAULT_SCHEMA_NAME
        current_schema = @schemas[key]
        return current_schema unless options.any? || block_given?

        new_schema = Parametric::Schema.new(options, &block)
        @schemas[key] = current_schema ? current_schema.merge(new_schema) : new_schema
        after_define_schema(@schemas[key])
      end

      def after_define_schema(sc)
        # noop hook
      end
    end
  end
end
