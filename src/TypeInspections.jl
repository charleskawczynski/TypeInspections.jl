module TypeInspections

import Crayons

_apply!(f, ::T, match_list, j, parent_type) where {T} = nothing # sometimes we need this...

function _apply!(f, ::Type{T}, match_list, j = nothing, parent_type = nothing) where {T}
    if f(T)
        push!(match_list, (T, j, parent_type))
    end
    for (i, p) in enumerate(T.parameters)
        _apply!(f, p, match_list, i, T)
    end
end

"""
    apply(::T) where {T <: Any}

Recursively traverse type `T` and apply
`f` to the types (and type parameters).

Returns a list of matches where `f(T)` is true.
"""
apply(f, ::T) where {T} = apply(f, T)
function apply(f, ::Type{T}) where {T}
    match_list = []
    _apply!(f, T, match_list)
    return match_list
end

function isconcretetype_params(::Type{T}) where {T}
    params = T.parameters
    isempty(params) && return true
    return all(p-> isconcretetype(p), params)
end

ith_name(i::Int) =
    if i == 1;     return "$(i)st"
    elseif i == 2; return "$(i)nd"
    elseif i == 3; return "$(i)rd"
    elseif 4 <= i <= 20; return "$(i)th"
    else; error("This is probably too many type parameters...")
    end

"""
    warntype_param(::T) where {T <: Any}

Print the type, warn (and highlight)
and non-concrete type parameters.
"""
warntype_param(::T) where {T} = warntype_param(T)
function warntype_param(::Type{T}) where {T}
    match_list = apply(x->!isconcretetype_params(x), T)
    if isempty(match_list)
        println(T)
    else
        sT_colored = string(T)
        for (ml, j, pt) in match_list
            sml = string(ml)
            ml_red = Crayons.Box.RED_FG(sml)
            sT_colored = replace(sT_colored, sml => ml_red)
        end
        println(sT_colored)
        s = "Type instance is not recursively concrete. "
        s *= "Non-concrete types are:\n"
        for (ml, j, pt) in match_list
            s *= "$(nameof(pt))'s ($(ith_name(j))) type parameter has a non-concrete eltype: "
            s *= "$(Crayons.Box.RED_FG(string(ml))) \n"
        end
        @warn s
    end
end

end # module
