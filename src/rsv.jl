## single agent-based model for Respiratory syncytial virus (RSV)
## Developed by Shokoofeh & Affan

module rsv
using Distributions
using StatsBase
using StaticArrays
using Random
using Parameters

#---------------------------------------------------
# Construct agent's types as an object
#---------------------------------------------------
mutable struct Human
    idx::Int64
    health::Int64       # 0 = susc, 1 = infected
    age::Int64          # in months
    agegroup::Int64    # G1 = 0-2, G2= 3-5, G3= 6-11, G4= 12-23, G5= 24-35, G6= 5:19 years, G7=19+ years
    preterm::Bool     # true/false is faster
    houseid::Int64    # what house they belong in....
    Human() = new()
end

mutable struct Dwelling
    idx::Int64    ## does a dwelling need an index???? i don't think so
    hasadult::Bool
    totalsize::Int64
    availsize::Int64
    Dwelling() = new()
end

#----------------------------------------------------
# Global variables and parameters. 
#-----------------------------------------------------
# age populations are downloaded from Census Canada 2016
# data organized in file 'parameters_Shokoofeh.xlsx'
const population_size = 13198 # total population of Nunavik
const total_houses = 5000 #???????

# categorical probability distribution of discrete age_groups
const agedist_Nuk =  Categorical(@SVector[0.006819215,0.007576906,0.008183058,0.026140324,0.026140324,0.026140324,0.022730717,0.310653129,0.565616002])
const agebraks_Nuk = @SVector[0:2, 3:5, 6:11, 12:23, 24:35, 36:47, 48:59, 60:227, 228:1200] #age_groups in months

const humans = Array{Human}(undef, population_size)
const dwells = Array{Dwelling}(undef, total_houses)
export humans, dwells 

# infection parameters
const inf_range = @SVector[100:400]
const SAR_Nuk = @SVector[0.63,0.63,0.63,0.40,0.27] # Nunavik: secondary attack rate for < 1 , 2, 3 yearsold kids

## setting up agent 'humans'
function init_humans()
    @inbounds for i = 1:population_size
        humans[i] = Human()              ## create an empty human
        humans[i].idx = i
        humans[i].health = 0
        humans[i].age = 0
        humans[i].agegroup = 0
        humans[i].preterm = false
        humans[i].houseid = 0
    end
end
export init_humans

## randomly assigns age, age_group, preterm < 1
function apply_charectristics(x::Human)
    _agegp = rand(agedist_Nuk)::Int64
    x.agegroup = _agegp
    x.age = rand(agebraks_Nuk[_agegp])

    # assign preterm if < 1 years old, 
    # parameter values extracted from ???
    if _agegp == 1
        if rand() < 0.033333333 
            x.preterm = true
        end       
    elseif _agegp == 2
        if rand() < 0.09
            x.preterm = true
        end
    elseif _agegp == 3
        if rand() < 0.021296296
            x.preterm = true
        end
    end
    return _agegp
end
export apply_charectristics

###### Assign charectristics to humans: initial populations
function init_population()
    @inbounds for i = 1:population_size
        apply_charectristics(humans[i]) 
    end
end
export init_population


@inline function find_a_house()
    available_house = findall(d -> d.availsize >= 1, dwells) 
    return rand(available_house)
end
export find_a_house

function apply_housing()
    # reset everyone's housing 
    for x in humans
        x.houseid = 0
    end

    # reset dwellings
    my_dwellings()

    ## get all the empty houses that has no adult.  
    ## distribute some of the adults in these houses.
    empty_houses = findall(d -> d.hasadult == false && d.availsize >= 1, dwells)
    _ad = findall(x -> x.agegroup == 9 && x.houseid == 0, humans)
    adults_get_a_house = sample(_ad, length(empty_houses), replace=false)
    
    for (hid, xid) in zip(empty_houses, adults_get_a_house)
        humans[xid].houseid = hid
        dwells[hid].availsize -= 1 ## reduce the available size in the house
    end

    ## distribute the rest of the population in random housing. 
    _td = findall(x -> x.houseid == 0, humans)
    for xid in _td
        hid = find_a_house()
        humans[xid].houseid = hid
        dwells[hid].availsize -= 1 
    end
end 
export apply_housing

function my_dwellings()
    ## THIS IS MANUAL. need to think of a way to automate this faster. 
    ## dwells_householdsize = [755,595,555,585,1135]
    ## cumsum of dwellings [755, 1350, 1905, 2490, 3625]
    # each bin represents number of dwellings with population size 1, 2, 3, 4, 5+.
    bins = [1:755, 756:1350, 1351:1905, 1906:2490, 2491:3625]

    for (s, b) in enumerate(bins)
        for idx in b
            dwells[idx] = Dwelling()  ## create an empty house
            dwells[idx].idx = idx
            if s == 5 ## the fifth bin ie.. 5+ people....
                dwells[idx].totalsize = 100 ## assign arbitrary large to fit all of humans
                dwells[idx].availsize = 100 
            else 
                dwells[idx].totalsize = s ## assign the size 
                dwells[idx].availsize = s ## assign the size 
            end
            dwells[idx].hasadult = false
        end
    end

    ## write unit test: check whether a house has no capacity and also no adult.
end
export my_dwellings

function housing_stats()
    hw = length(findall(x -> x.houseid != 0, humans))
    fj = length(findall(x -> x.availsize > 0, dwells))
    dw = length(findall(x -> x.availsize < 0, dwells))
    println("number of people without a house: $hw")
    println("number of available housing: $fj")
    println("number of illegal housing (BUG if >0): $dw")
end

end # module
