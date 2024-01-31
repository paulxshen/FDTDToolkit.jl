function plotstep!(f, u::AbstractArray, p, configs, monitor_instances=[];
    s=1, umax=maximum(abs, u), bipolar=!all(u .>= 0), title="",
    elevation=nothing,
    azimuth=nothing)
    # colormap = [(:blue, 1), (:red, 1)]
    # colormap = :seismic
    colormap = bipolar ? :seismic : [(:white, 0), (:orange, 1)]
    colorrange = bipolar ? (-1, 1) : (0, 1)
    algorithm = bipolar ? :absorption : :mip
    u ./= umax
    # if bipolar
    #     u = (u .+ 1) ./ 2
    # end
    d = ndims(u)
    "plot field"
    if d == 1
        #   heatmap!
    elseif d == 2
        pl! = heatmap!
        pl = heatmap(f, u; axis=(; title, aspect=1), colormap, colorrange)
    else
        pl! = volume!
        ax, __ = volume(f, u; axis=(; type=Axis3, title), algorithm, colormap, colorrange)
        !isnothing(elevation) && (ax.elevation[] = elevation)
        !isnothing(azimuth) && (ax.azimuth[] = azimuth)
    end
    # Colorbar(f)

    if !isnothing(p)
        "plot geometry"
        pl!(f, p, colormap=[(:white, 0), (:gray, 0.2)])#, colorrange=(ϵ1, ϵ2))
    end
    "plot monitors"
    if !isempty(monitor_instances)
        a = zeros(size(u))
        for (i, m) = enumerate(monitor_instances)
            a[first(m.idxs)...] .= 1
            text = isempty(m.label) ? "m$i" : m.label
            text!(f, first(m.centers)..., ; text, align=(:center, :center))
        end
        pl!(f, a, colormap=[(:white, 0), (:teal, 0.2)])#, colorrange=(ϵ1, ϵ2))
        # # save("temp/$t.png", fig)
    end
    "plot sources"
    for (i, s) = enumerate(configs.source_effects)
        pl!(f, first(values(s._g)), colormap=[(:white, 0), (:yellow, 0.2)])
        text = isempty(s.label) ? "s$i" : s.label
        text!(f, first(values(s.center))..., ; text, align=(:center, :center))
    end
    # # save("temp/$t.png", fig)
end
# rotate_cam!(ax.scene, (45, 0, 0))

function recordsim(sol, p, fdtd_configs, fn, monitor_instances=[];
    s=0.1,
    umax=s * maximum(abs, sol[round(Int, length(sol) / 2)]),
    bipolar=true,
    title="",
    playback=1, frameat=fdtd_configs.dt,
    framerate=playback / frameat,
    elevation=nothing,
    azimuth=nothing,
)
    @unpack dt, = fdtd_configs
    n = length(sol)
    T = dt * (n - 1)
    t = 0:frameat:T

    fig = Figure()

    r = record(fig, fn, t; framerate) do t
        i = round(Int, t / dt + 1)
        empty!(fig)
        # ax = Axis(fig[1, 1];)
        u = sol[i]

        plotstep!(fig[1, 1], u, p, fdtd_configs, monitor_instances; bipolar, umax, title="t = $t\n$title", elevation, azimuth)
    end
    println("saved simulation recording to $fn")
    r
end
