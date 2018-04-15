require "spec"
require "../src/myst/**"

# An environment variable to be able to test if we're running in
# unit tests or in production (prod. declaration in src/myst.cr)
ENV["MYST_ENV"] = "test"

include Myst

# Run the Myst parser on the given source code, returning the AST that the
# parser generates for it.
def parse_program(source : String) : Expressions
  parser = Parser.new(IO::Memory.new(source), File.join(Dir.current, "test_source.mt"))
  parser.parse
end

# Return the list of tokens generated by lexing the given source. Parsing is
# not performed, so semantically-invalid sequences are allowed by this method.
def tokenize(source : String, in_context : Lexer::Context? = nil)
  lexer = Lexer.new(IO::Memory.new(source), File.join(Dir.current, "test_source.mt"))
  if in_context
    lexer.push_context(in_context)
  end
  lexer.lex_all
  lexer.tokens
end

# Assert that the given source causes a syntax error
def assert_syntax_error(source : String)
  expect_raises(SyntaxError) do
    tokenize(source)
  end
end

# Assert that given source is accepted by the parser. The given source will not
# be executed by this method.
# Currently, this method just invokes the parser to ensure no errors occur.
def assert_valid(source)
  parse_program(source)
end

# Inverse of `assert_valid`: Assert that the given source causes a ParseError.
def assert_invalid(source)
  expect_raises(ParseError) do
    parse_program(source)
  end
end

# Parse and run the given program, returning the interpreter that ran the
# program to be used for making assertions.
def parse_and_interpret(source, interpreter=Interpreter.new, capture_errors=true)
  program = parse_program(source)
  interpreter.run(program, capture_errors: capture_errors)
  interpreter
end

# Same as `parse_and_interpret`, but force errors to propogate out.
def parse_and_interpret!(source, interpreter=Interpreter.new)
  parse_and_interpret(source, interpreter, capture_errors: false)
end
