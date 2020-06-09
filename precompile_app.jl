using FlowPattern

function copy_files_from_external_folder(source_dir, app_dir)
    target_externalpath = joinpath(app_dir, "external")
    source_external_path = joinpath(source_dir, "external")
    mkpath(target_externalpath)
    for file in readdir(source_external_path)
        cp(joinpath(source_external_path, file), joinpath(target_externalpath, file))
    end
end

copy_files_from_external_folder(
    @__DIR__,
    join((@__DIR__, "Compiled")),
)

push!(ARGS, "--quiet")
FlowPattern.julia_main()
