require 'binding_of_caller'

module Fluent
  module Trace
    def self.trace(target, tag, skip=[])
      if tag != "fluent.digraph"
        source = (0..Float::INFINITY).lazy
        .map{|i| binding.of_caller(i).eval('self') rescue nil}
        .select{|v| Input === v || Output === v || v.nil?}
        .reject{|v| v && skip.pop == v}.first

        if source
          Engine.emit('fluent.digraph', Engine.now, {
            tag: tag,
            source: {id: source.object_id, label: source.config['type']},
            target: {id: target.object_id, label: target.config['type']}})
        end
      end
    end
  end
end
