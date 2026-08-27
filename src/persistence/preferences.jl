# src/persistence/preferences.jl
using Scratch

const _PREFS_SCHEMA_VERSION = "1.0"
const _PREFS_FILENAME = "preferences.toml"

# Built-in defaults, used when preferences.toml is absent or a field is missing.
function _default_preferences()::Dict{String,Any}
    return Dict{String,Any}(
        "schema_version"     => _PREFS_SCHEMA_VERSION,
        "default_linewidth"  => 1.5,
        "default_markersize" => 9.0,
        "default_colormap"   => "viridis",
        "palette"            => ["#4e79a7","#f28e2b","#e15759","#76b7b2","#59a14f",
                                  "#edc948","#af7aa1","#ff9da7","#9c755f","#bab0ab"],
    )
end

"""
    preferences_path() -> String

Path to the user's preferences.toml inside the MakieViews Scratch space.
"""
function preferences_path()::String
    dir = Scratch.@get_scratch!("preferences")
    return joinpath(dir, _PREFS_FILENAME)
end

"""
    load_preferences() -> Dict{String,Any}

Read preferences.toml from the Scratch space. If absent, returns built-in defaults
(and does not write a file). Missing fields are filled from defaults; unknown fields
are preserved. Never calls set_theme!.
"""
function load_preferences()::Dict{String,Any}
    path = preferences_path()
    defaults = _default_preferences()
    isfile(path) || return defaults
    raw = try
        TOML.parsefile(path)
    catch
        return defaults   # corrupt file -> fall back to defaults, do not crash
    end
    merged = merge(defaults, raw)   # raw overrides defaults; unknown keys preserved
    return merged
end

"""
    save_preferences(prefs::Dict{String,Any})

Write preferences to preferences.toml in the Scratch space. Ensures schema_version present.
"""
function save_preferences(prefs::Dict{String,Any})
    path = preferences_path()
    out = copy(prefs)
    out["schema_version"] = get(out, "schema_version", _PREFS_SCHEMA_VERSION)
    open(path, "w") do io
        TOML.print(io, out)
    end
end
