####################################
# loading all packages here
###############
# if any of them is not installed on your current device, run
# using Pkg
# and then install like
# Pkg.add("Distributions")

using Distributions
using Parameters
using Interpolations
using LinearAlgebra
using FastGaussQuadrature
using CSV
using DataFrames


function crra_utility(c,γ)
    if c <= 0 
        throw(DomainError("consumption has to be positive with CRRA utility"))
    else
        if γ < 0
            throw(DomainError("γ has to be positive"))
        elseif γ == 1 # when γ is 1 and hence the usual formula is not well-defined, CRRA simplifies to log utility. Can prove using the Hopital-rule.
            return log(c)
        else
            return (c^(1-γ))/(1 - γ) # usual formula for CRRA
        end
    end    
end

function crra_utility_function(γ)
    return c -> crra_utility(c,γ) # returns a function, which to any consumption level, assigns the corresponding CRRA utility under risk aversion equal to γ
end

"""
This structure stores all parameters describing preferences and the economic environment
"""
@with_kw struct EconPars{S<:AbstractFloat} # here there is a new type annotation, telling us that this structure will contain objects of type S, which is some subtype of AbstractFloat.
    "discount factor"
    β::S = 0.962 # this line says β is of type S, with default 0.962 (in this case S will be Float64)
    "risk aversion of used CRRA utility function"
    γ::S = 2.0
    "interest rate on savings"
    r::S = 0.04
    "growth rate of real income"
    g::S = 0.015
    "standard deviation of individual fixed effect"
    σ_α::S = sqrt(0.2105)
    "autoregressive parameter of persistent income component z"
    ρ::S = 0.9989
    "standard deviation of shocks to persistent income component z"
    σ_η::S = sqrt(0.0166)
    "standard deviation of shocks to transitory income component ϵ"
    σ_ϵ::S = sqrt(0.0630)
    "replacement ratio - ratio of pension to average income"
    B::S = 0.75
    "age profile of mean, detrended log income"
    ks::Vector{S} = ageprofile(σ_α,σ_ϵ,σ_η,ρ) 
    # ks is a vector, containing type S elements
    # first is age 22 as STY, last is age 100
    "conditional survival probabilities"
    ξs::Vector{S} = survival_probs()
end

"""
Reads survival probabilities from a separate file. downloaded this from CDC's website.
"""
function survival_probs()
    mort =  CSV.read("mortality.csv", DataFrame)
    return 1.0 .- mort[23:101,2] # prob of survival is 1 - mortality rate
end

function ageprofile(σ_α,σ_ϵ,σ_η,ρ)
    ages =  CSV.read("age_fe.csv", DataFrame)
    raw_ks = ages[6:84,2] # raw age fixed effects read from saved values created in the other file

    # when not using default income risk parameters, we have to adjust fixed effects, if we want to keep mean income constant for each age group! why?
    # when Y = exp(y), then variance of y affects mean of Y, even if mean of y is kept constant. read about the log-normal disribution if interested in where the formulas below come from:
    
    varshift_new = vcat([σ_α^2/2 + σ_ϵ^2/2 + σ_η^2*(ρ^(2*t-2)-1)/(ρ^2-1)/2 for t in 1:44],fill(0.0,35))
    varshift_default = vcat([0.2105/2 + 0.0630/2 + 0.0166*(0.9989^(2*t-2)-1)/(0.9989^2-1)/2 for t in 1:44],fill(0.0,35))
    
    ks  = raw_ks + (varshift_default - varshift_new) # shift only if some risk parameter is not the default one
    return ks
end

"""
This structure stores all numerical parameters needed to solve the model

We use an evenly spaced grid for savings (not cash-on-hand as before).
"""
@with_kw struct NumPars{S<:AbstractFloat,T<:Integer}
    "maximum of savings grid"
    max_save::S = 500.0
    "number of points on savings grid"
    N_save::T = 100
    "number of points for α"
    N_α::T = 7
    "number of points for z"
    N_z::T = 17
    "number of points for ϵ"
    N_ϵ::T = 7
end

"""
This structure stores the solution. Each field is a matrix of interpolated functions. For example, cp[alphai,h,zi] is the optimal consumption policy function of an agent with the alphaith possible fixed effect, age group = h and persistent income equal to the zith possible value on the z grid. cp[2,3,1](0.8) would give optimal consumption of agents with second possible alpha value, age 24 (first possible age is 22) and the worst z state, who have 0.8 units of cash on hand.
"""
struct Solution{S<:AbstractArray}
    "value functions for all ages"
    vf::Array{S,3} # three-dimensional array of some type which is a subtype is AbstractArray (which includes the interpolated function thing generated by Interpolations) 
    "optimal consumption policies for all ages"
    cp::Array{S,3}
    "optimal saving policies for all ages"
    sp::Array{S,3}
end

"""
computes mean income among working age population
"""
function mean_income(ep::EconPars)
    @unpack_EconPars ep
    uncond_survival_probs = fill(0.0,79)
    uncond_survival_probs[1] = ξs[1]
    for t in 2:79
        uncond_survival_probs[t] = uncond_survival_probs[t-1] * ξs[t]
    end
    incs = [exp(g*t + ks[t] + σ_α^2/2 + σ_ϵ^2/2 + σ_η^2*(ρ^(2*t-2)-1)/(ρ^2-1)/2) for t in 1:44] # mean income for each working age. formula comes from log-normal distribution
    return sum(incs .* uncond_survival_probs[1:44])/sum(uncond_survival_probs[1:44]) # average over people who are alive -> older people get a bit less weight 
end


"""
Solves a simplified version of the model by STY
# Arguments:
 - economic parameters
 - numerical parameters
# Return a Solution structure with the value function and optimal consumption and saving policies.

# Note: This is still not fastest way to solve the model, but a faster code would be harder to read.
"""
function solve(ep::EconPars, np::NumPars)
    @unpack_EconPars ep
    @unpack_NumPars np

    Ybar = mean_income(ep) # average income of non-retired

    tiny = 10^-7 # very small number that we sometimes add to lowest grid point, to avoid getting -infinities.

    (z_grid, z_mat) = rouwenhorst(N_z, 0.0, ρ, σ_η) # grid and transition matrix for z
    #if today you have the ith possible z (i.e. z_grid[i]), then the probability of having z_grid[j] in the next period is z_mat[i,j]

    ϵ_grid, ϵ_ps = discretize_normal(0, σ_ϵ, N_ϵ)
    # grid and probabilities for ϵ
    #having the ith possible ϵ (i.e. ϵ_grid[i]) has probability ϵ_ps[i]

    α_grid, α_ps = discretize_normal(0, σ_α, N_α)

    u = crra_utility_function(γ) # this code works for crra utility only

    saves = max_save .* range(0, 1, length=N_save) .^ 5 # grid for end-of-period savings (wealth) values. NOT evenly spaced anymore! More dense on the bottom 

    # initialize containers of value and policy functions with empty containers of interpolated function objects. these will be overwritten!
    # there are 79 time periods (ages 22-100)
    cp = fill(linear_interpolation([0.0,1.0], [0.0,1.0], extrapolation_bc=Linear()), N_α, 79, N_z)
    sp = fill(linear_interpolation([0.0,1.0], [0.0,1.0], extrapolation_bc=Linear()), N_α, 79, N_z)
    vf = fill(linear_interpolation([0.0,1.0], [0.0,1.0], extrapolation_bc=Linear()), N_α, 79, N_z)

    # setting initial guesses for policies and the value function. In this case, we choose the policies of eating everything and saving nothing as a starting point. Therefore our guess for the value function will equal the utility from eating everything
    # have to do it for all z and alpha states separately!
    for zi in 1:N_z
        for αi in 1:N_α
            cp[αi, 79, zi] = linear_interpolation(saves, saves, extrapolation_bc=Linear()) # interpolate identity function: for any cash-on-hand level, you eat it all.
            sp[αi, 79, zi] = linear_interpolation(saves, fill(0.0, N_save), extrapolation_bc=Linear())# interpolate 0: for any cash-on-hand level, you save nothing.
            vf[αi, 79, zi] = linear_interpolation(saves .+ tiny, u.(saves .+ tiny), extrapolation_bc=Linear()) # since you eat everything, value = u
        end
    end

    # current income if α is the αjth possible value, time is t, z is the zjth possible value and ϵ is the ϵjth possible value NOW
    # normalize everything with Ybar, to avoid large numbers
    function income(αj, t, zj, ϵj)
        if t > 44 # retired
            return B
        else
            return exp(α_grid[αj] + g * t + ks[t] + z_grid[zj] + ϵ_grid[ϵj]) / Ybar
        end
    end

    for t in 78:-1:1 # t goes from T-1 to 1 !BACKWARDS!
        for zi in 1:N_z # for all possible current persistent income states
            for αi in 1:N_α  # for all possible fixed effects

                #initialize vectors that will hold values and policies corresponding to each grid point. we will overwrite these 0s in the for loop below
                cs = fill(0.0, N_save) # consumption
                as = fill(0.0, N_save) # end of asset
                vs = fill(0.0, N_save) # value
                cohs = fill(0.0, N_save) # cash-on-hand

                function value(c, a) # define a function that to a given level of current consumption and savings, computes value, using already computed value functions for the next period. This comes from two sources
                    value_now = u(c) # utility from eating c now
                    value_future = 0.0
                    for ϵj in 1:N_ϵ # add expected value from next period for each possible FUTUREvalue of ϵ
                        for zj in 1:N_z # add expected value from next period for each possible FUTURE value of z
                        # zi is current z, zj is future zj 
                            coh_future = (1 + r) * a + income(αi, t + 1, zj, ϵj)
                            value_future = value_future + ϵ_ps[ϵj] * z_mat[zi, zj] * vf[αi, t+1, zj](coh_future)
                        end
                    end
                    return value_now + β * ξs[t] * value_future
                end

                for i in eachindex(saves) # i runs through all indices of the possible savings values

                    # compute RHS of Euler equation for a given savings grid point. we apply cp_guess in the next period
                    RHS_of_euler = 0.0
                    for ϵj in 1:N_ϵ
                        for zj in 1:N_z
                            coh_future = (1 + r) * saves[i] + income(αi, t + 1, zj, ϵj)
                            RHS_of_euler = RHS_of_euler + ϵ_ps[ϵj] * z_mat[zi, zj] * (cp[αi, t+1, zj](coh_future))^(-γ)
                        end
                    end

                    RHS_of_euler = β * ξs[t] * (1 + r) * RHS_of_euler # RHS of Euler-equation is computed

                    c = RHS_of_euler^(-1 / γ) # compute current consumption from Euler-equation

                    cohs[i] = c + saves[i] # cash-on-hand is either used for consumption or savings today, so it must be the sum of the two.

                    cs[i] = c
                    as[i] = saves[i]
                    vs[i] = value(c, saves[i]) # we just evaluate the above defined function to get the value from the c today and corresponding saving.
                end

                smallest_income = income(αi, t, zi, 1) # we cannot have less coh than this income level in the current state

                if cohs[1] > max(tiny,smallest_income) # if the coh level corresponding to minimal saving is too high to cover all interesting coh levels,
                # then we add more grid points to capture the eat-everything policy of very poor agents.
                # need more points for accurate value function!
                    for extra in collect(range(cohs[1], max(tiny,smallest_income), length=50))[2:end] 
                        pushfirst!(cohs, extra) 
                        pushfirst!(as, 0) # save nothing
                        pushfirst!(cs, extra) # and eat everything            
                        pushfirst!(vs, value(extra, 0))
                    end
                end

                # and now we can interpolate the value and policy functions for the considered α,t,z
                cp[αi, t, zi] = linear_interpolation(cohs, cs, extrapolation_bc=Linear())
                sp[αi, t, zi] = linear_interpolation(cohs, as, extrapolation_bc=Linear())
                vf[αi, t, zi] = linear_interpolation(cohs, vs, extrapolation_bc=Linear())
            end
        end
        println("age $(t+21) is done")
    end

    return Solution(vf, cp, sp)
end

"""
Simulates life-cycle paths of N agents.

It is assumed that everyone starts with 0 wealth

Returns five matrices:
 - first contains the simulated cash-on-hand values
 - second contains simulated income series
 - third contains simulated wealth (i.e. end-of-period savings) series
 - fourth contains simulated consumption series 
 - fifth contains a simulated survival series 
Every row is an individual, every column is an age group
"""
function simulate(ep::EconPars, np::NumPars, sol::Solution, N::Integer)
    @unpack_EconPars ep
    @unpack_NumPars np

    Ybar = mean_income(ep) # average income of non-retired

    ϵ_grid, ϵ_ps = discretize_normal(0, σ_ϵ, N_ϵ)
    z_grid, z_mat = rouwenhorst(N_z, 0.0, ρ, σ_η)

    z_dists = [Categorical(z_mat[i,:]) for i in 1:N_z]

    α_grid, α_ps = discretize_normal(0, σ_α, N_α)

    α_dist = Categorical(α_ps)
    ϵ_dist = Categorical(ϵ_ps)

    αis = rand(α_dist,N) # we draw a fixed effect for everybody, before starting the simulation
    # because α is fixed over the lifetime

    zis = fill(0,N,79)
    cohs = fill(0.0,N,79)
    saves = fill(0.0,N,79)
    conss = fill(0.0,N,79)
    incomes = fill(0.0,N,79)
    survives = fill(true,N,79)

    function income(αj, t, zj, ϵj)
        if t>44
            return B
        else
            return exp(α_grid[αj] + g * t + ks[t] + z_grid[zj] + ϵ_grid[ϵj])/Ybar
        end
    end
    
    for n in 1:N
        α = αis[n]
        z = round(Int64,(N_z+1)/2) # middle point of z_grid = 0 if N_z is an odd number
        zis[n,1] = z
        y = income(α, 1, z, rand(ϵ_dist))
        incomes[n,1] = y

        coh = y # at age = 1, coh = y, since there is no initial wealth
        cohs[n,1] = coh
        saves[n,1] = sol.sp[α,1,z](coh)
        conss[n,1] = sol.cp[α,1,z](coh)
    end
    for t in 2:79
        for n in 1:N
            α = αis[n]
            z = rand(z_dists[zis[n,t-1]]) # draw a new z. probabilities depend of z state from previous period!
            zis[n,t] = z
            y = income(α, t, z, rand(ϵ_dist))
            incomes[n,t] = y

            coh = y + (1 + r) * saves[n,t-1] # coh is current income + after-return savings from previous period
            cohs[n,t] = coh
            
            saves[n,t] = sol.sp[α,t,z](coh)
            conss[n,t] = sol.cp[α,t,z](coh)
            if !survives[n,t-1] || rand()>ξs[t-1] # if already dead in previous period OR draws death now
            # probability of dies = drawing a number higher than ξs[t-1] from a uniform [0,1] distribution
                survives[n,t-1] = false # set survive to false
            end
        end        
    end
    return (cohs,incomes,saves,conss,survives)
end


#################################
## Don't worry about the rest!
########

"""
Approximate an AR(1) process with drift y(t+1) = (1-ρ)*μ + ρ*y(t) + ε(t+1)
using the Rouwenhorst method

INPUTS
N (scalar): number of discretized states
μ (scalar): unconditional mean of the process
ρ (scalar): persistence of the process
σ (scalar): st.dev. of ε

OUTPUTS
grid (Nx1): grid of discretized states
PI (NxN): transition matrix
"""
function rouwenhorst(N::Integer,μ::T,ρ::T,σ::T) where T<:AbstractFloat
    sigma_y = σ/sqrt(1-ρ^2)
    p       = 0.5*(1+ρ)
    PI      = [p 1-p;1-p p]

    if N>=3
        for n in 3:N
            PI = p*[PI zeros(n-1,1); zeros(1,n)] +
            (1-p)*[zeros(n-1,1) PI; zeros(1,n)] +
            (1-p)*[zeros(1,n); PI zeros(n-1,1)] +
            p*[zeros(1,n); zeros(n-1,1) PI]
            PI[2:end-1,:] = PI[2:end-1,:]/2
        end
    end

    ψ       = sqrt(N-1)*sigma_y
    grid0    = range(-ψ,ψ,length = N)
    grid    = collect(grid0.+ μ)

    if N==1
        PI = reshape([1.0],1,1)
    end
    return (grid, PI)
end

function discretize_normal(μ, σ, N)
    grid, weights = gausshermite(N) # raw values, need to transform as below, trust me
    weights = weights ./ sqrt(pi)
    grid = grid .* sqrt(2) .* σ .+ μ
    return grid, weights
end


