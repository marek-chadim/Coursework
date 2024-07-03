 include("30_ageprofile.jl")
 using Plots

 # 1.1 

# Define the models
modela = EconPars(ys = [1.0], pys = [1.0], bl = 7.0, β = 0.96)
modelb = EconPars(ys = [1.0], pys = [1.0], bl = 0.0, β = 0.96)
modelc = EconPars(ys = [0.8, 1.2], pys = [0.5, 0.5], bl = 0.0, β = 0.96)

# Set NumPars as recommended
np = NumPars(max_coh = 10.0, N_coh = 500)


# Plot the average consumption, income and wealth paths
solve_simul(modela, np)
solve_simul(modelb, np)
solve_simul(modelc, np)

# 1.2 

# Define some useful functions 

# Compute the difference matrices
function compute_difference_matrix(matrix::Matrix)
    num_individuals, num_periods = size(matrix)
    changes = zeros(num_individuals, num_periods - 1)

    for t in 1:num_periods - 1
        changes[:, t] = matrix[:, t + 1] - matrix[:, t]
    end

    return changes
end

# Compute a matrix of correlations between income change and consumption
function compute_correlations(income_changes::Matrix, consumptions::Matrix)
    num_individuals, num_periods = size(income_changes)
    correlations = zeros(num_individuals)

    #consumptions = consumptions[:,2:end] #remove first column from consumption matrix for dimension match

    for i in 1:num_individuals
        correlations[i] = cor(income_changes[i, :], consumptions[i, :])
    end

    return correlations
end

#Plot correlations on a histogram 
function plot_correlation_histogram(correlations::Vector{Float64})
    histogram(correlations, bins=40, xlabel="Correlation", ylabel="Frequency", title="Histogram of Correlations", legend=false, fillcolor=:lightblue)
end


# Solve the models
solve_a = solve(modela, np)
solve_b = solve(modelb, np)
solve_c = solve(modelc, np)

# Simulate 10000 individuals 
sim_a = simulate(modela, solve_a, 10000)
sim_b = simulate(modelb, solve_b, 10000)
sim_c = simulate(modelc, solve_c, 10000)

# Extract values
cohs_a, incomes_a, cons_a = sim_a[1][:, 1:40], sim_a[2][:, 1:40], sim_a[3][:, 1:40] 
cohs_b, incomes_b, cons_b = sim_b[1][:, 1:40], sim_b[2][:, 1:40], sim_b[3][:, 1:40]
cohs_c, incomes_c, cons_c = sim_c[1][:, 1:40], sim_c[2][:, 1:40], sim_c[3][:, 1:40]

# Compute income and consumption change matrices 
inc_change_a = compute_difference_matrix(incomes_a)
inc_change_b = compute_difference_matrix(incomes_b)
inc_change_c = compute_difference_matrix(incomes_c)

cons_change_a = compute_difference_matrix(cons_a)
cons_change_b = compute_difference_matrix(cons_b)
cons_change_c = compute_difference_matrix(cons_c)


# Compute correlation change matrices
correlations_a = compute_correlations(inc_change_a, cons_change_a)
correlations_b = compute_correlations(inc_change_b, cons_change_b)
correlations_c = compute_correlations(inc_change_c, cons_change_c)

# Plot correlations
plot_correlation_histogram(correlations_a)
plot_correlation_histogram(correlations_b)
plot_correlation_histogram(correlations_c)

# A potentially even more fun plot
function plot_correlation_histogram2(correlations::Vector{Float64}, line1::Real, line2::Real)
    hist = histogram(correlations, bins=40, xlabel="Correlation", ylabel="Frequency", title="Histogram of Correlations", fillcolor=:lightblue, label="Model C")
    vline!([line1], label="Model A", linestyle=:dash, color=:red)
    vline!([line2], label="Model B", linestyle=:dash, color=:green)
    return hist
end

plot_correlation_histogram2(correlations_c, correlations_a[1], correlations_b[1])