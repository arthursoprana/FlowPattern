using PackageCompiler

create_app(
   @__DIR__,
   join((@__DIR__, "Compiled")),
   precompile_execution_file="precompile_app.jl",
   audit=true, # Warn about eventual relocatability problems with the app
   force=false,
)
