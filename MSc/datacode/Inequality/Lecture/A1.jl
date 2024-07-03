# GROUP 10: Maurus Grond, Marleena Tamminen, Marek Chadim 

###############
# Task 2
###############

# load data and packages
using CSV, DataFrames, Statistics, Plots
psid = DataFrame(CSV.File("psid.csv"))

# build a variable for family-level income
psid."labor_inc_spouse" .= coalesce.(psid."labor_inc_spouse",0.0)
psid."labor_inc_family" = psid."labor_inc" .+ psid."labor_inc_spouse"

# keep only household heads
psid = psid[psid.rel_head.=="head",:]

# drop observations corresponding to times of changing family composition
# and keep only years when expenditure data is available
psid = psid[psid.year.>=1999 .&& psid.family_comp_change.==0,:]
psid."expenditure_family" .= coalesce.(psid."expenditure_family",0.0)
psid = psid[:,["id_ind","year", "expenditure_family", "labor_inc_family"]]

# build variables for changes (between neighboring 2 years) in expenditure and income
function lagby2!(df::DataFrame,id::String,time::String,tolag::String)
    sort!(df, [id, order(time, rev = true)])
    df[!,tolag*"_lag_2"] = missings(Float64, size(df,1))
    for i in 1:(size(df,1)-1)
        if df[i,id] == df[i+1,id] && df[i,time] == df[i+1,time] + 2 
            df[i,tolag*"_lag_2"] = df[i+1,tolag]
        end
    end
end

for tolag in ["expenditure_family", "labor_inc_family"]
    lagby2!(psid,"id_ind","year",tolag)
end

for col in ["expenditure_family", "labor_inc_family"]
    psid[:,col*"_change"] = psid[:,col] .- psid[:,col*"_lag_2"]
end

# 2.

# list of all ids that appear in PSID
ids = unique(psid[:,"id_ind"])
# initialize  vector
corr =fill(0.0,size(ids,1))
# fill it up in a for loop
for id in eachindex(ids)
    corr[id] = cor(Array(dropmissing(psid[psid."id_ind" .== ids[id], ["expenditure_family_change", "labor_inc_family_change"]])))[2,1]
end

#  3.

# plot the histogram of all these correlation values
histogram(corr, label=false,
title = "Correlation of income and expenditure changes ", 
xlabel = "Value", ylabel = "Frequency")
savefig("corr.png")


###############
# Task 3
###############
# import the model solution
include("21_borrowinglims_solve.jl")

# first we use the default economic parameters (bl=0) for 1. 
include("21_Zeldes.jl")

# we then allow debt by rewriting 
# ep = EconPars(bl=5) in 21_Zeldes.jl 
# and executing include("21_Zeldes.jl") for 2.

# test (i)

# Zeldes says income should be significantly negative in constrained sample
test_i_constrained = lm(@formula(log(consumption_growth) ~ age + log(income)), constrained_sample)
println(test_i_constrained)

# but should be 0 in unconstrained sample
test_i_unconstrained = lm(@formula(log(consumption_growth) ~ age + log(income)), unconstrained_sample)
println(test_i_unconstrained)

# test (ii)

# Estimate (1) for group 2 and store the parameter estimates
beta_intercept = coef(test_i_unconstrained)[1]
beta_age = coef(test_i_unconstrained)[2]
beta_log_income = coef(test_i_unconstrained)[3]

# Using the parameter estimates, compute the residuals in sample 1
xs = log.(constrained_sample.consumption_growth) .- (beta_intercept .*1 .+ beta_age .*constrained_sample.age .+ beta_log_income .* log.(constrained_sample.income))
residuals = DataFrame(xs = xs)

# If borrowing constraints are important for consumption behavior, then residuals should be positive (the Lagrangian multiplier should be positive), statistically significant, and quantitatively large.
test_ii = lm(@formula(xs ~ 1 ), residuals)
println(test_ii)

# test (iii)

# regress residuals from (ii) on log(income) for group 1 and test whether the sign is negative. 
residuals.income = constrained_sample.income
test_iii = lm(@formula(xs ~ 0 + log(income)), residuals)
# this tells us the sign of the correlation between the (rescaled) Lagrange multiplier and income
println(test_iii)

# check size of the constrained sample
println(size(constrained_sample,1)/size(data_sim,1))
println(size(constrained_sample,1))



