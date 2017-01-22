module Dry
  module Initializer
    require_relative "initializer/exceptions/default_value_error"
    require_relative "initializer/exceptions/type_constraint_error"
    require_relative "initializer/exceptions/params_order_error"

    require_relative "initializer/attribute"
    require_relative "initializer/param"
    require_relative "initializer/option"
    require_relative "initializer/builder"

    # rubocop: disable Style/ConstantName
    Mixin = self # for compatibility to versions below 0.12
    # rubocop: enable Style/ConstantName

    UNDEFINED = Object.new.tap do |obj|
      obj.define_singleton_method(:inspect) { "Dry::Initializer::UNDEFINED" }
    end.freeze

    class << self
      def extended(klass)
        super
        mixin   = klass.send(:__initializer_mixin__)
        builder = klass.send(:__initializer_builder__)

        builder.call(mixin)
        klass.include(mixin)
        klass.send(:define_method, :initialize) do |*args|
          __initialize__(*args)
        end
      end

      def define(fn = nil, &block)
        mixin = Module.new do
          def initialize(*args)
            __initialize__(*args)
          end
        end

        builder = Builder.new
        builder.instance_exec(&(fn || block))
        builder.call(mixin)
        mixin
      end

      def mixin(fn = nil, &block)
        define(fn, &block)
      end
    end

    def param(*args)
      __initializer_builder__.param(*args).call(__initializer_mixin__)
    end

    def option(*args)
      __initializer_builder__.option(*args).call(__initializer_mixin__)
    end

    private

    def __initializer_mixin__
      @__initializer_mixin__ ||= Module.new do
        def initialize(*args)
          __initialize__(*args)
        end
      end
    end

    def __initializer_builder__
      @__initializer_builder__ ||= Dry::Initializer::Builder.new
    end

    def inherited(klass)
      builder = @__initializer_builder__.dup
      mixin   = Module.new

      klass.instance_variable_set :@__initializer_builder__, builder
      klass.instance_variable_set :@__initializer_mixin__,   mixin

      builder.call(mixin)
      klass.include mixin

      super
    end
  end
end
