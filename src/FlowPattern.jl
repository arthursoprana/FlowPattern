module FlowPattern

using Blink
using Plots
using Interact

const default_exec_file = joinpath(@__DIR__, "..\\external\\Flowpat.exe")

function calculate_flow_pattern(;
    USᴳ = 0.070, # [m/s]
    USᴸ = 51.70, # [m/s]
    μᴳ = 0.000018, # [Pa.s]
    μᴸ = 0.005, # [Pa.s]
    ρᴳ = 2.8833234073128, # [kg/m³]
    ρᴸ = 997.950268197708, # [kg/m³]
    D = 0.0508, # [m]
    ε = 0, # [m]
    σ = 7.40500030517578E-02, # [N/m]
    θ = 0, # [°]
    exec_file = default_exec_file,
)
    flowpat = `$exec_file`
    input = open("Input.txt", "w")
    flowpat_mode = 2
    println(input, "$flowpat_mode\tMode 1-Transition Lines, 2-FlowPattern Prediction")
    println(input, "$USᴸ\t$USᴳ\t$ρᴸ\t$μᴸ\t$ρᴳ\t$μᴳ\t$σ\t$D\t$θ\t$ε")
    close(input)
    run(flowpat)
    flow_pattern_id, error_code = parse.(Int, split(read("Output.txt", String))[end-1:end])

    if error_code > 0
        return nothing
    end

    flowpattern = ("SS", "SW", "A", "DB", "B", "SL")
    return flowpattern[flow_pattern_id]
end

function calculate_flow_pattern_transitions(
    μᴳ,
    μᴸ,
    ρᴳ,
    ρᴸ,
    D,
    ε,
    σ,
    θ,
    interface;
    exec_file = default_exec_file,
)
    n_transitions = 5
    flowpat = `$exec_file`
    input = open("Input.txt", "w")
    flowpat_mode = 1
    println(input, "$flowpat_mode\tMode 1-Transition Lines, 2-FlowPattern Prediction")
    println(input, "$ρᴸ\tLiquid Density [Kg/m^3]")
    println(input, "$μᴸ\tLiquid Viscosity [Pa s]")
    println(input, "$σ\tSurface Tension [N/m]")
    println(input, "$ρᴳ\tGas Density [Kg/m^3]")
    println(input, "$μᴳ\tGas Viscosity [Pa s]")
    println(input, "$D\tPipe Diameter [m]")
    println(input, "$θ\tPipe inclination  Angle [deg]")
    println(input, "$ε\tPipe Roughness [m]")
    println(input, "$interface\tInterface 1-Smooth, 2-Wavy")
    close(input)
    run(flowpat)

    function init_xy(size)
        x = Vector{Vector{Float64}}()
        y = Vector{Vector{Float64}}()
        for i = 1:size
            push!(x, Vector{Float64}())
            push!(y, Vector{Float64}())
        end
        return x, y
    end

    x, y = init_xy(n_transitions)
    function push_if_available_sync!(arr_x, arr_y, val_x, val_y)
        if val_x > -999 && val_y > -999
            push!(arr_x, val_x)
            push!(arr_y, val_y)
        end
    end
    open("Output.txt") do file
        for (i, ln) in enumerate(eachline(file))
            result = parse.(Float64, split(ln))'
            for j = 1:n_transitions
                push_if_available_sync!(x[j], y[j], result[2j-1], result[2j])
            end
        end
    end

    return x, y
end

function plot_flow_pattern_transitions(θ, D, ρᴳ, ρᴸ, μᴳ, μᴸ, σ, ε, interface)
    x, y = calculate_flow_pattern_transitions(μᴳ, μᴸ, ρᴳ, ρᴸ, D, ε, σ, θ, interface)
    p = plot(
        x,
        y,
        xlabel = "USᴳ [m/s]",
        ylabel = "USᴸ [m/s]",
        xlims = (1e-3, 100),
        ylims = (1e-3, 100),
        xaxis = :log,
        yaxis = :log,
        label = ["Stratified" "Annular" "Wavy" "Dispersed-Bubble" "Bubble"],
        legend = :outertopright,
        grid = :all,
        minorgrid = true,
        formatter = string, # A method which converts a number to a string for tick labeling.
    )
end

function flowpattern_main()
    ##
    # Create sliders and plot
    θ_slider = widget(0:0.5:90, label = "θ [°]"; value = 0.0)
    D_slider = widget(0.01:0.01:1, label = "D [m]"; value = 0.1)
    ρᴳ_slider = widget(0.5:0.1:1100, label = "ρᴳ [kg/m³]"; value = 1.0)
    ρᴸ_slider = widget(0.5:0.1:1100, label = "ρᴸ [kg/m³]"; value = 1000.0)
    μᴳ_slider = widget(1e-5:1e-5:1e-1, label = "μᴳ [Pa.s]"; value = 1e-5)
    μᴸ_slider = widget(1e-5:1e-5:1e-1, label = "μᴸ [Pa.s]"; value = 1e-3)
    σ_slider = widget(1e-3:1e-3:1, label = "σ [N/m]"; value = 1e-2)
    ε_slider = widget(0:1e-5:1e-2, label = "ε [m]"; value = 0)
    interface_selector = widget(Dict("Stratified" => 1, "Wavy" => 2), label = "Interface")

    interactive_plot = map(
        plot_flow_pattern_transitions,
        θ_slider,
        D_slider,
        ρᴳ_slider,
        ρᴸ_slider,
        μᴳ_slider,
        μᴸ_slider,
        σ_slider,
        ε_slider,
        interface_selector,
    )

    ## Create UI layout
    el1 = hbox(
        vbox(θ_slider, ρᴳ_slider, μᴳ_slider, ε_slider),
        vbox(D_slider, ρᴸ_slider, μᴸ_slider, σ_slider),
    )
    el2 = interface_selector
    el3 = Interact.hline()
    el4 = interactive_plot

    ui = vbox(el1, el2, el3, el4)

    ## Create final window
    w = Window()
    size(w, 700, 700)
    title(w, "Flow Pattern Map Calculator")
    body!(w, ui)

    if "--quiet" in ARGS
        close(w)
    else
        # Workaround for keeping Blink window alive when calling `julia <my_script>.jl`
        while active(w)
            sleep(1)
        end
    end
end

function julia_main()
    try
        flowpattern_main()
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
        return 1
    end
    return 0
end

end # module FlowPattern
