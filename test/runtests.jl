using TypeInspections
const TI = TypeInspections
using Test

struct Foo{T}
    a::T
end

struct Bar{T}
    b::T
end

struct NestedFoo{TA,TB}
    a::TA
    b::TB
end

@testset "Apply" begin
    @show TI.apply(x->!TI.isconcretetype_params(x), Foo(Any[1]))

    @test isempty(TI.apply(x->!TI.isconcretetype_params(x), Foo((1,))))
    @test TI.apply(x->!TI.isconcretetype_params(x), Foo(Any[1]))[1][1] == Vector{Any}

    @test isempty(TI.apply(x->!TI.isconcretetype_params(x), NestedFoo(Foo((1,)), Foo((1,)))))
    @test TI.apply(x->!TI.isconcretetype_params(x), NestedFoo(Foo(Any[1]), Foo((1,))))[1][1] == Vector{Any}

    @test isempty(TI.apply(x->!TI.isconcretetype_params(x), NestedFoo(Bar(Foo((1,))), Bar(Foo((1,))))))
    @test TI.apply(x->!TI.isconcretetype_params(x), NestedFoo(Bar(Foo(Any[1])), Bar(Foo((1,)))))[1][1] == Vector{Any}

    match_list = TI.apply(NestedFoo(Bar(Foo((;a=1))), Bar(Foo((1,))))) do x
    # match_list = TI.apply(NestedFoo(Bar(Foo((;a=1, b=2,))), Bar(Foo((1,))))) do x
        !TI.isconcretetype_params(x)
    end
    @show match_list
end

@testset "warntype_param" begin
    TI.warntype_param(Foo((1,)))
    TI.warntype_param(Foo(Any[1]))

    TI.warntype_param(NestedFoo(Foo((1,)), Foo((1,))))
    TI.warntype_param(NestedFoo(Foo(Any[1]), Foo((1,))))

    TI.warntype_param(NestedFoo(Bar(Foo((1,))), Bar(Foo((1,)))))
    TI.warntype_param(NestedFoo(Bar(Foo(Any[1])), Bar(Foo((1,)))))
end

