require 'binding_of_caller'

module Fluent
  module Trace
    EDGES = {}

    def self.trace(target, tag, es, skip=[])
      return if tag == "fluent.digraph"
      source = (0..Float::INFINITY).lazy
      .map{|i| binding.of_caller(i).eval('self') rescue nil}
      .select{|v| Input === v || Output === v || v.nil?}
      .reject{|v| v && skip.pop == v}.first

      return unless source

      key = [source, target]
      if EDGES.has_key? key
        s = EDGES[key]
      else
        s = EDGES[key] = Stats.new
      end

      n = es.repeatable? ? es.enum_for.to_a.size : 1
      s.count tag, n

      if s.ready?
        Engine.emit('fluent.digraph', Engine.now, {
          throughput: s.throughput,
          source: {id: source.object_id, label: source.config['type']},
          target: {id: target.object_id, label: target.config['type']}})
      end
    end

    class Stats
      def initialize
        @times = []
        @last = Time.now - 30
      end

      def throughput
        if @times.length > 1
          (@times.length - 1).quo(@times.first - @times.last)
        else
          0
        end
      end

      def ready?
        if Time.now - @last > 2 * rand || @times.length == 1
          @last = Time.now
          true
        else
          false
        end
      end

      def count(tag, n)
        n.times do
          @times.unshift Time.now
          @times.pop if @times.size > 20
        end
      end
    end
  end
end
