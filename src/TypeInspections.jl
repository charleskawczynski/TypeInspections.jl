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


"""
    whose_type_parameter(::Type{T}, ::Type{FindType})

Finds where a type, `FindType` exists in the type-parameter
space of a complicated (and potentially nested) type `T`.

# Example
```julia
struct ComplicatedAndMaybeNestedFoo{A,B,C} end
struct Bar end
struct Baz end
struct Bingo end
f = ComplicatedAndMaybeNestedFoo{Bar, Baz, Bingo}()
whose_type_parameter(typeof(f), Bingo) # returns [(ComplicatedAndMaybeNestedFoo, 3)]
```
"""
function whose_type_parameter(::Type{T}, ::Type{FindType}) where {T, FindType}
    candidates = []
    whose_type_parameter!(candidates, T, FindType)
    return candidates
end

function whose_type_parameter!(candidates, ::Type{T}, ::Type{FindType}) where {T, FindType}
    if isempty(T.parameters)
        return
    else
        for (i, param) in enumerate(T.parameters)
            if param isa Type
                if param == FindType
                    push!(candidates, (nameof(T), i))
                else
                    whose_type_parameter!(candidates, param, FindType)
                end
            end
        end
    end
end

end # module
