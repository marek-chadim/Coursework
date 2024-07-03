using Plots
using Statistics

pwd()

cd("assignments")

include("41_inheritance_solve.jl")

# numerical parameters
np = NumPars(N_z = 11, N_α = 11, N_ϵ = 11)

# benchmark: no link between generations - fully redistributed accidental bequests, no inheritence of abilities 
ep_nolink = EconPars(β = 0.9645, τ_b = 0.9999, Φ_1 = -10^-9, ρ_α = 0.0)

# if interested in how much lifecycle income profile matters, run with flat income profile
# ep_nolink = EconPars(β = 0.9665, τ_b = 0.9999, Φ_1 = -10^-9, ρ_α = 0.0,ks = fill(0.0,79))

#τ_nolink = find_τ_l(ep_nolink, np, N = 10000, M = 20) 
τ_nolink = 0.1567

# solve
sol_nolink = solve(ep_nolink,np, τ_nolink)

################
# with bequest motive

ep_bequest = EconPars(β = 0.9349, ρ_α = 0.0, Φ_1 = -55.0)
#τ_bequest = find_τ_l(ep_bequest, np, N = 10000, M = 20) 
τ_bequest = 0.1606

sol_bequest = solve(ep_bequest,np, τ_bequest)


# 2.1
cohgrid = 0.0:0.5:20.0 # establish a grid for cash-on-hand values

optcons_nolink = sol_nolink.cp[6,1,6].(cohgrid)
plot(cohgrid, optcons_nolink, label = "Optimimal Consumption", xlabel = "Cash-on-hand", ylabel = "Consumption", title = "Optimal Consumption")
savefig("P2.1.pdf")

# 2.2
optcons_nolink_loα = sol_nolink.cp[1,1,6](cohgrid)
optcons_nolink_hiα = sol_nolink.cp[6,1,1](cohgrid)
plot(cohgrid, optcons_nolink, label = "Optimimal Consumption, middle α & z", xlabel = "Cash-on-hand", ylabel = "Consumption", title = "Optimal Consumption")
plot!(cohgrid, optcons_nolink_loα, label = "Optimal Consumption, low α, middle z")
plot!(cohgrid, optcons_nolink_hiα, label = "Optimal Consumption, middle α, low z")
savefig("P2.2.pdf")

# 2.3
ages = [1,11,21,41,61]
plot() # need to clear the plot environment
plot_legend = []
for age in ages
    optcons_nolink_age = sol_nolink.cp[6, age, 6].(cohgrid)
    plot!(cohgrid, optcons_nolink_age, label = "Age $(age+21)")
    push!(plot_legend, "Age $age")
end
plot!(xlabel = "Cash-on-hand", ylabel = "Consumption", title = "Optimal Consumption")
savefig("P2.3.pdf")

# 2.4
plot() # need to clear the plot environment
plot_legend_b = []
for age in ages
    optcons_beq_age = sol_bequest.cp[6, age, 6].(cohgrid)
    plot!(cohgrid, optcons_beq_age, label = "Age $(age+21)")
    push!(plot_legend, "Age $age")
end
plot!(xlabel = "Cash-on-hand", ylabel = "Consumption", title = "Optimal Consumption with Bequests")
savefig("P2.4.pdf")

# 2.5
nolink_shocks = simulate_shocks(ep_nolink, np, M = 20, N = 10000)
nolink_decisions = simulate_decisions(ep_nolink, np, sol_nolink, nolink_shocks[1], nolink_shocks[2], nolink_shocks[3], nolink_shocks[4], nolink_shocks[5], τ_nolink)

dif = 1e-6 # Small number 

nolink_conss_dif_nl = fill(0.0, 10000, 79, 20)

for n in 1:10000
    for h in 1:79
        for m in 1:20
            nolink_conss_dif_nl[n,h,m]=sol_nolink.cp[nolink_shocks[1][n,m],h,nolink_shocks[2][n,h,m]].(nolink_decisions[1][n,h,m]+dif)
        end
    end
end

diff_original_nl = nolink_decisions[3]

differences_nl = (nolink_conss_dif_nl - diff_original_nl)/dif

ageaverages_nl = [mean(differences_nl[:,h,20]) for h in 1:79]

plot(ageaverages_nl, label = "MPC in nolink case", xlabel = "Age", ylabel = "MPC", title = "MPC No Links")
savefig("P2.5.pdf")

# 2.6
bequest_shocks = simulate_shocks(ep_bequest, np, M = 20, N = 10000)
bequest_decisions = simulate_decisions(ep_bequest, np, sol_bequest, bequest_shocks[1], bequest_shocks[2], bequest_shocks[3], bequest_shocks[4], bequest_shocks[5], τ_bequest)

bequest_conss_dif = fill(0.0, 10000, 79, 20)

for n in 1:10000
    for h in 1:79
        for m in 1:20
            bequest_conss_dif[n,h,m]=sol_bequest.cp[bequest_shocks[1][n,m],h,bequest_shocks[2][n,h,m]].(bequest_decisions[1][n,h,m]+dif)
        end
    end
end

diff_original_bq = bequest_decisions[3]

differences_bq = (bequest_conss_dif - diff_original_bq)/dif

ageaverages_bq = [mean(differences_bq[:,h,20]) for h in 1:79]

plot(ageaverages_bq, label = "MPC in bequest case", xlabel = "Age", ylabel = "MPC", title = "MPC Bequest Case")
savefig("P2.6.pdf")

plot(ageaverages_bq, label = "MPC in bequest case", xlabel = "Age", ylabel = "MPC", title = "Marginal Propensity to Consume")
plot!(ageaverages_nl, label = "MPC in nolink case")
savefig("P2.5_2.6.pdf")