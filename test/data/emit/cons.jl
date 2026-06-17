using Test
using Moshi.Data: @data

@data SelfRefCons begin
    struct A
        a::Int
        b::Float64 = sin(a) + 1
    end
end

@test SelfRefCons.A(; a=1).b ≈ sin(1) + 1

# A field-less `struct` variant must not emit both a positional and a keyword
# zero-arg constructor: two identical `Empty()` methods are a method overwrite,
# which Julia rejects during module precompilation. Define the variant in a
# child process under `--warn-overwrite=yes` and assert no overwrite warning is
# produced (and that a field-bearing sibling's keyword constructor still works).
@testset "field-less variant has a single constructor" begin
    code = """
    module EmptyVariantCheck
        using Moshi.Data: @data
        @data EmptyVariant begin
            struct Empty
            end
            struct Full
                x::Int = 1
            end
        end
        @assert EmptyVariant.Empty() isa EmptyVariant.Type
        @assert EmptyVariant.Full(; x=2).x == 2
    end
    """
    proj = Base.active_project()
    cmd = `$(Base.julia_cmd()) --warn-overwrite=yes --startup-file=no --project=$proj -e $code`
    out = mktemp() do path, io
        run(pipeline(ignorestatus(cmd); stdout=io, stderr=io))
        flush(io)
        read(path, String)
    end
    @test !occursin("overwritten", out)
end
