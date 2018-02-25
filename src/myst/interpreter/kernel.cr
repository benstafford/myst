module Myst
  class Interpreter
    def create_kernel : TModule
      kernel = TModule.new("Kernel")
      kernel.scope.clear
      kernel = init_top_level(kernel)
      kernel.scope["Kernel"]    = kernel
      kernel.scope["Nil"]       = init_nil(kernel)
      kernel.scope["Boolean"]   = init_boolean(kernel)
      kernel.scope["Integer"]   = init_integer(kernel)
      kernel.scope["Float"]     = init_float(kernel)
      kernel.scope["String"]    = init_string(kernel)
      kernel.scope["Symbol"]    = init_symbol(kernel)
      kernel.scope["List"]      = init_list(kernel)
      kernel.scope["Map"]       = init_map(kernel)
      io_type = init_io(kernel)
      kernel.scope["IO"]        = io_type
      kernel.scope["TCPSocket"] = init_tcp_socket(kernel, io_type)
      kernel.scope["Time"]      = init_time(kernel)
      kernel.scope["Random"]    = init_random(kernel)
      kernel
    end
  end
end
