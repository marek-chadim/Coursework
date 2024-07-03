using Plots
using Statistics
using DataFrames
using CSV
using Pkg; Pkg.add.(["FixedEffectModels","CategoricalArrays","LaTeXStrings"])
using FixedEffectModels
using CategoricalArrays
using LaTeXStrings
using NLsolve

cd("/Users/maurusgrond/Library/Mobile Documents/com~apple~CloudDocs/2_Uni/2_Spring 24/Inequality/Assignment 3")

###Part 1 ###

# Q2: Write a function in Julia, that takes a 4-element candidate vector of parameters and computes the corresponding moments from 1.1.
function calculate_covariances(params::Vector{Float64})
    σ_α, σ_ϵ, σ_η, ρ = params
    
    # Variance of u_{i,60}
    var_u60 = σ_α^2 + σ_ϵ^2 + σ_η^2 * sum(ρ^(2 * (j-22)) for j in 22:59)
    
    # Covariance between u_{i,60} and u_{i,58}
    cov_u60_u58 = σ_α^2 + ρ^2 * σ_η^2 * sum(ρ^(2 * (j-22)) for j in 22:57)
    
    # Covariance between u_{i,60} and u_{i,56}
    cov_u60_u56 = σ_α^2 + ρ^4 * σ_η^2 * sum(ρ^(2 * (j-22)) for j in 22:55)
    
    # Covariance between u_{i,60} and u_{i,30}
    cov_u60_u30 =σ_α^2 + ρ^30 * σ_η^2 * sum(ρ^(2 * (j-22)) for j in 22:29)
    
    return var_u60, cov_u60_u58, cov_u60_u56, cov_u60_u30
end

params = [0.25, 1, -0.2, 0.01]  # Replace with your parameters
var_u60, cov_u60_u58, cov_u60_u56, cov_u60_u30 = calculate_covariances(params)

#Q2: Compute these same moments in PSID.
psid =  CSV.read("/Users/maurusgrond/Library/Mobile Documents/com~apple~CloudDocs/2_Uni/2_Spring 24/Inequality/Assignment 3/psid_final.csv", DataFrame)

# hh income is head labor income + spouse labor income + hh transfer income 
psid.income = psid.labor_inc .+ coalesce.(psid.labor_inc_spouse,0.0) .+ coalesce.(psid.transfer_inc,0.0)
unique(psid.marital_status)
psid[coalesce.(psid.marital_status .== "Married or perm. cohabiting",false),"income"] = psid[coalesce.(psid.marital_status .== "Married or perm. cohabiting",false),"income"] ./ 2

psid = psid[psid.rel_head .== "head",:]

psid = psid[:,["id_ind", "year", "age", "income"]]
psid.cohort = psid.year- psid.age

# drop observations with 0 income and missing age
psid = psid[coalesce.(psid.income.!= 0.0,false) .&& .!ismissing(psid.age),:]
# drop very old people
psid = psid[coalesce.(psid.age .< 101,false),:]

psid_income = psid[:,["id_ind", "year", "income"]]
# create wide format panel
# each row is one individual
# not an (individual,year) pair as before
psid_income = unstack(psid_income, "id_ind", "year", "income")

which_cohort = 1943
ids_cohort = psid[coalesce.(psid.cohort .== which_cohort,false), "id_ind"] # ids of people belonging to chosen cohort

inc_paths = psid_income[psid_income.id_ind .∈ [ids_cohort[1:20]],Not("id_ind")]

psid.age = categorical(psid.age)

age_reg = reg(psid, @formula(log(income) ~ age + fe(cohort)), save = :residuals)

display(age_reg)

# transform such that mean log for a chosen age (42) is the same as data
age_fe = coef(age_reg) .+ mean(log.(psid[psid.age .== 42,"income"])) .- coef(age_reg)[28]
#CSV.write("./julia/classes/age_fe.csv", DataFrame(age = 17:100, fe = age_fe)) # save FEs

psid."income_residual" = residuals(age_reg)

psid_residual = psid[:,["id_ind", "age", "income_residual"]]
psid_residual = unstack(psid_residual, "id_ind", "age", "income_residual", combine = last)

# wide format:
covs_w_lag = [cov(Array(dropmissing(DataFrame(a = psid_residual[:,"60"], b = psid_residual[:,string(y)]))); dims = 1)[1,2] for y in [30, 56, 58, 60]]

#1.4, 1.5

# Define a function that calculates the differences between theoretical and empirical moments
function moment_differences(params::Vector{Float64})
    # Calculate theoretical moments
    var_u60_theoretical, cov_u60_u58_theoretical, cov_u60_u56_theoretical, cov_u60_u30_theoretical = calculate_covariances(params)
    
    # Calculate empirical moments
    var_u60_empirical = cov(Array(dropmissing(DataFrame(a = psid_residual[:,"60"], b = psid_residual[:,"60"]))))[1,2]
    cov_u60_u58_empirical = cov(Array(dropmissing(DataFrame(a = psid_residual[:,"60"], b = psid_residual[:,"58"]))))[1,2]
    cov_u60_u56_empirical = cov(Array(dropmissing(DataFrame(a = psid_residual[:,"60"], b = psid_residual[:,"56"]))))[1,2]
    cov_u60_u30_empirical = cov(Array(dropmissing(DataFrame(a = psid_residual[:,"60"], b = psid_residual[:,"30"]))))[1,2]
    
    # Return the vector of differences between theoretical and empirical moments
    return [var_u60_theoretical - var_u60_empirical,
            cov_u60_u58_theoretical - cov_u60_u58_empirical,
            cov_u60_u56_theoretical - cov_u60_u56_empirical,
            cov_u60_u30_theoretical - cov_u60_u30_empirical]
end

# Initial guess for the parameters
initial_guess = [0.458, 0.251, 0.12, 0.99] #Initial guesses taken from STY, see pg 616 (pg 8 of pdf)

println(moment_differences(initial_guess))

# Find parameters that make theoretical moments equal to empirical ones
result = nlsolve(moment_differences, initial_guess)
params_estimated = result.zero

println(params_estimated)

vars_age = [var(psid[psid.age .== a, "income_residual"]) for a in 22:75] #from 40_Income_empirics.jl

variances_by_age = zeros(54)
σ_α, σ_ϵ, σ_η, ρ = params_estimated
for i in 22:75
    var_u = σ_α^2 + σ_ϵ^2 + σ_η^2 * sum(ρ^(2 * (j-22)) for j in 22:i)
    variances_by_age[i-21]=var_u
end

scatter(22:75, variances_by_age, xlabel = "Age", title = "Variance of log income residual", label = "")
savefig("Fig_1.5.png")

age_fe = coef(age_reg) .+ mean(log.(psid[psid.age .== 42,"income"])) .- coef(age_reg)[28]

psid."income_residual" = residuals(age_reg)

psid_residual = psid[:,["id_ind", "year", "income_residual"]]
psid_residual = unstack(psid_residual, "id_ind", "year", "income_residual")
# wide format

covs_w_lag = [cov(Array(dropmissing(DataFrame(a = psid_residual[:,"1970"], b = psid_residual[:,string(y)]))); dims = 1)[1,2] for y in 1970:1989]

scatter(22:75, vars_age, xlabel = "Age", title = "Variance of log income residual", label = "")
savefig("1.5_2.png")

### Part 3 ###

import Roots: solve
include("41_inheritance_solve.jl")

# Problem 3.1

# numerical parameters
np = NumPars(N_z = 11, N_α = 11, N_ϵ = 11)

# First solve the model with default parameters

ep_bequest_bm = EconPars(β = 0.9313, ρ_α = 0.6, Φ_1 = -55.0, τ_c = 0.3)
#τ_bequest_bm = find_τ_l(ep_bequest_bm, np, N = 10000, M = 20) # For default model
#τ_bequest_alt = find_τ_l(ep_bequest, np, N = 10000, M = 20) # For alternative model 
τ_bequest_bm = 0.15472793579101562 # Budget balancing labor tax rate for default setting
# Budget balancing labor tax rate for no capital income tax

sol_bequest_bm = solve(ep_bequest_bm,np, τ_bequest_bm)

(cohs_bequest,incomes_bequest,saves_bequest,conss_bequest,survives_bequest,death_now_bequest) = simulate(ep_bequest_bm, np, sol_bequest_bm, τ_bequest_bm, M = 20, N = 10000)
sum(saves_bequest[:,:,end][survives_bequest[:,:,end]])/sum(incomes_bequest[:,:,end][survives_bequest[:,:,end]]) # wealth to income ratio - should be close to 3


# Now for the alternative model:
ep_bequest_alt = EconPars(β = 0.9313, ρ_α = 0.6, Φ_1 = -55.0, τ_c = 0.0)

#τ_bequest_alt = find_τ_l(ep_bequest_alt, np, N = 10000, M = 20)
τ_bequest_alt = 0.20930862426757812

sol_bequest_alt = solve(ep_bequest_alt, np, τ_bequest_alt)
(cohs_bequest_alt,incomes_bequest_alt,saves_bequest_alt,conss_bequest_alt,survives_bequest_alt,death_now_bequest_alt) = simulate(ep_bequest_alt, np, sol_bequest_alt, τ_bequest_alt, M = 20, N = 10000)
sum(saves_bequest_alt[:,:,end][survives_bequest_alt[:,:,end]])/sum(incomes_bequest_alt[:,:,end][survives_bequest_alt[:,:,end]])


# Problem 3.2
γ = ep_bequest_bm.γ

function gain(coh::Real, t::Real, zi::Real, αi::Real, sol_bequest_bm::Solution, sol_bequest_alt::Solution)
    welfare_gain = ((sol_bequest_alt.vf[αi, t, zi](coh) / sol_bequest_bm.vf[αi, t, zi](coh))^(1/(1-γ)) - 1) * 100
    return welfare_gain
end

# Define an appropriate grid for coh values
coh_values = 0.00:0.01:10;

# Initialize an empty array to store the welfare gains
wf_gain = fill(0.0, length(coh_values), 1)

# Loop over the coh values and calculate the welfare gain for each value
for coh in 1:length(coh_values)
    wf_gain[coh] = gain(coh_values[coh], 1, 6, 6, sol_bequest_bm, sol_bequest_alt)
end

# Plot the welfare gains
plot(coh_values, wf_gain, title = "Welfare Gain", xlabel="Cash on Hand", ylabel="Welfare Gain", legend=false)
savefig("welfare_gain.pdf")

# Problem 3.3: Repeat for smallest and largest α states
wf_gain_low_α = fill(0.0, length(coh_values), 1)

# Loop over the coh values and calculate the welfare gain for each value
for coh in 1:length(coh_values)
    wf_gain_low_α[coh] = gain(coh_values[coh], 1, 6, 1, sol_bequest_bm, sol_bequest_alt)
end

welfare_gains_high_α = fill(0.0, length(coh_values), 1)

for coh in 1:length(coh_values)
    welfare_gains_high_α[coh] = gain(coh_values[coh], 1, 6, 11, sol_bequest_bm, sol_bequest_alt)
end

plot(coh_values,  welfare_gains_high_α, title = "Welfare Gain", xlabel="Cash on Hand", ylabel="Welfare Gain", label = "Max α", legend = :bottomright)
plot!(coh_values, wf_gain_low_α, label = "Min α", legend = :bottomright)
savefig("hilo_alpha.pdf")


# Problem 3.4: Compute the expected value of age 22 agents in each economy

function simulate_3_4(ep::EconPars, np::NumPars, sol::Solution, τ_l; N::Integer=10000, M::Integer=10)
    (αis, zis, incomes, survives, death_now) = simulate_shocks(ep, np; N, M)
    (cohs, saves, conss) = simulate_decisions(ep, np, sol, αis, zis, incomes, survives, death_now, τ_l)
    return (cohs,incomes,saves,conss,survives,death_now, αis, zis)
end

#Benchmark
(cohs_bequest,incomes_bequest,saves_bequest,conss_bequest,survives_bequest,death_now_bequest, alpha_bm, z_bm) = simulate_3_4(ep_bequest_bm, np, sol_bequest_bm, τ_bequest_bm, M = 20, N = 10000)

# Now for the alternative model:
(cohs_bequest_alt,incomes_bequest_alt,saves_bequest_alt,conss_bequest_alt,survives_bequest_alt,death_now_bequest_alt, alpha_alt, z_alt) = simulate_3_4(ep_bequest_alt, np, sol_bequest_alt, τ_bequest_alt, M = 20, N = 10000)

values_bm=zeros(10000) #initialize array to store welfare values for benchmark model for 10000 agents

for j in 10:20 # burn in for 10 periods
    for i in 1:10000
    values_bm[i] = sol_bequest_bm.vf[alpha_bm[i,j], 1, z_bm[i,1,j]](cohs_bequest[i,1,j])
    end
end

println(length(values_bm))
mean_bm = mean(values_bm)

values_alt=zeros(10000) #initialize array to store welfare values for alternative model for 10000 agents

for j in 10:20 # burn in for 10 periods
    for i in 1:10000
    values_alt[i] = sol_bequest_alt.vf[alpha_alt[i,j], 1, z_alt[i,1,j]](cohs_bequest_alt[i,1,j])
    end
end

println(length(values_alt))
mean_alt = mean(values_alt)

((mean_alt/mean_bm)^(1/(1-γ))-1)*100