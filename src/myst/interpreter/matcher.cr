require "./exceptions.cr"

module Myst
  class Interpreter
    def match(pattern : Node, value : Value)
      case pattern
      when ListLiteral
        match_list(pattern, value)
      when MapLiteral
        match_map(pattern, value)
      when Literal
        # All other literal types are simple value matches
        match_value(pattern, value)
      when ValueInterpolation
        match_value(pattern, value)
      when Var, Underscore
        # Vars are always assigned in the current scope.
        current_scope.assign(pattern.name, value)
      when IVar
        # Vars are always assigned in the current scope.
        current_self.ivars.assign(pattern.name, value)
      when Const
        # Constants can't be re-assigned, so they are matched as if they were
        # literal values
        match_value(pattern, value)
      else
        __raise_runtime_error(MatchError.new(callstack))
      end
    end

    # For simplicity and efficiency, the equality of values according to a
    # match operation is determined by the native equality of the values, not
    # by any override of `==`.
    private def match_value(pattern : Node, right : Value)
      visit(pattern)
      left = stack.pop
      success =
        if left.is_a?(TType) && !right.is_a?(TType)
          # For types, check that `right` is either an instance of that type, or
          # the type itself.
          left == __typeof(right)
        else
          left == right
        end

      success || __raise_runtime_error(MatchError.new(callstack))
    end

    private def match_list(pattern : ListLiteral, value : Value)
      __raise_runtime_error(MatchError.new(callstack)) unless value.is_a?(TList)

      left, splat, right = chunk_list_pattern(pattern)

      value_elements = value.elements.dup
      left.each { |element_pattern| match(element_pattern, value_elements.shift)  }
      right.each{ |element_pattern| match(element_pattern, value_elements.pop)    }
      if splat.is_a?(Splat)
        match(splat.value, TList.new(value_elements))
      else
        unless value_elements.empty?
          __raise_runtime_error(MatchError.new(callstack))
        end
      end
    end

    private def match_map(pattern : MapLiteral, value : Value)
      __raise_runtime_error(MatchError.new(callstack)) unless value.is_a?(TMap)

      pattern.entries.each do |entry|
        visit(entry.key)
        pattern_key = stack.pop

        if right_value = value.entries[pattern_key]?
          match(entry.value, right_value)
        else
          __raise_runtime_error(MatchError.new(callstack))
        end
      end
    end


    # Return a 3-tuple representing the segments of a List pattern in the
    # format `{pre-splat, splat-collector, post-splat}`. The splat collector
    # will be the single splat collector in the List literal. If more than
    # one splat exists in the literal, an error will be raised.
    private def chunk_list_pattern(pattern : ListLiteral)
      left  = [] of Node
      splat = nil
      right = [] of Node

      past_splat = false
      pattern.elements.each do |el|
        # Checking for more than one Splat in the parameter List is done by
        # the parser. Because of that guarantee, this code does not need to
        # check for multiple Splats.
        if el.is_a?(Splat)
          splat = el
          past_splat = true
        elsif past_splat
          right.unshift(el)
        else
          left.push(el)
        end
      end

      {left, splat, right}
    end
  end
end
