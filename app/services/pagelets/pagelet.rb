module Pagelets
  class Pagelet
    attr_reader :name, :partial, :priority, :opts

    def initialize(name, partial, priority, opts)
      @name = name
      @partial = partial
      @priority = priority
      @opts = opts
    end

    def <=>(other)
      priority <=> other.priority
    end

    def id
      opts[:id] || 'pagelet-id-' + @name.gsub(/\s+/, "_").underscore
    end

    def method_missing(method_name, *arguments, &block)
      @opts[method_name]
    end
  end
end
