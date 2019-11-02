module rsv

mutable struct Human
    idx::Int64
    health::Int64       # 0 = susc, 1 = infected
    age::Int64          # in weeks 
    Human() = new()
end

mutable struct Dwelling
    idx::Int64
    humans::Array{Int64}
    Dwelling() = new()
end

const humans = Array{Human}(undef, 1000)
const dwells = Array{Dwelling}(undef, 1000)
export humans, dwells

function init_population()   
    @inbounds for i = 1:length(humans) 
        humans[i] = Human()              ## create an empty human
        humans[i].idx = i
        humans[i].health = 0
        humans[i].age = 0
    end
end
export init_population

function init_dwellings()   
    @inbounds for i = 1:length(dwells) 
        dwells[i] = Dwelling()              ## create an empty human
        dwells[i].idx = i
        dwells[i].humans = [1,2,3]
    end
end
export init_dwellings

end # module
