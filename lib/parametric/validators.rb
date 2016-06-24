module Parametric
  module Policies
    class Policy
      def message
        'is invalid'
      end

      def exists?(value, key, payload)
        true
      end

      def coerce(value, key, context)
        value
      end

      def valid?(value, key, payload)
        true
      end
    end

    class Format < Policy
      attr_reader :message

      def initialize(fmt, msg = 'invalid format')
        @message = msg
        @fmt = fmt
      end

      def exists?(value, key, payload)
        payload.key?(key)
      end

      def valid?(value, key, payload)
        !payload.key?(key) || !!(value.to_s =~ @fmt)
      end
    end
  end

  # Default validators
  EMAIL_REGEXP = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i.freeze

  Parametric.policy :array do
    message do |actual|
      "expects an array, but got #{actual.inspect}"
    end

    validate do |value, key, payload|
      !payload.key?(key) || value.is_a?(Array)
    end
  end

  Parametric.policy :object do
    message do |actual|
      "expects a hash, but got #{actual.inspect}"
    end

    validate do |value, key, payload|
      !payload.key?(key) ||
        value.respond_to?(:[]) &&
        value.respond_to?(:key?)
    end
  end

  Parametric.policy :format, Policies::Format
  Parametric.policy :email, Policies::Format.new(EMAIL_REGEXP, 'invalid email')

  Parametric.policy :required do
    message do |*|
      "is required"
    end

    validate do |value, key, payload|
      payload.key? key
    end
  end

  Parametric.policy :present do
    message do |*|
      "is required and value must be present"
    end

    validate do |value, key, payload|
      case value
      when String
        value.strip != ''
      when Array, Hash
        value.any?
      else
        !value.nil?
      end
    end
  end

  Parametric.policy :gt do
    message do |num, actual|
      "must be greater than #{num}, but got #{actual}"
    end

    validate do |num, actual, key, payload|
      !payload[key] || actual.to_i > num.to_i
    end
  end

  Parametric.policy :lt do
    message do |num, actual|
      "must be less than #{num}, but got #{actual}"
    end

    validate do |num, actual, key, payload|
      !payload[key] || actual.to_i < num.to_i
    end
  end

  Parametric.policy :options do
    message do |options, actual|
      "must be one of #{options.join(', ')}, but got #{actual}"
    end

    exists do |options, actual, key, payload|
      ok? options, actual
    end

    validate do |options, actual, key, payload|
      !payload.key?(key) || ok?(options, actual)
    end

    def ok?(options, actual)
      [actual].flatten.all?{|v| options.include?(v)}
    end
  end
end
