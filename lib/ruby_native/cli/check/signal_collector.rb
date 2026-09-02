module RubyNative
  class CLI
    class Check
      # Walks a parsed template and records every data-native-* attribute with
      # the lines it appears on. Attribute names built out of ERB cannot be
      # resolved statically and are skipped rather than guessed at.
      #
      # Subclasses Herb::Visitor, so this file is only loaded once `herb` is
      # known to be present.
      class SignalCollector < Herb::Visitor
        attr_reader :signals

        def initialize
          @signals = {}
          super
        end

        def visit_html_attribute_name_node(node)
          name = node.children.filter_map { |child| child.content if child.respond_to?(:content) }.join

          if name.start_with?("data-native-")
            (@signals[name] ||= []) << node.location.start.line
          end

          super
        end
      end
    end
  end
end
