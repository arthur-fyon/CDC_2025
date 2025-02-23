#=
This file contains functions to extract characteristics of the firing pattern
as well as some functions to plot complicated graphs
=#

using Statistics, Plots, StatsPlots, LaTeXStrings, Printf

## Functions extracting characteristics of the firing pattern

# This function extracts the spiking frequency of a spiking firing pattern
function extract_frequency(V, t)
    # Defining thresholds
    spike_up_threshold = 10.
    spike_down_threshold = 0.

    # Detecting spikes
    spike_detected = 0
    spike_times = []
    for i in 1:length(V)
        if V[i] > spike_up_threshold && spike_detected == 0 # Start of spike
            append!(spike_times, t[i])
            spike_detected = 1
        end
        if V[i] < spike_down_threshold && spike_detected == 1 # End of spike
            spike_detected = 0
        end
    end

    # If the neuron is silent
    if length(spike_times) < 2
        return NaN
    end

    # Calculating all interspike intervals
    ISI=[]
    for i in 2 : length(spike_times)
        append!(ISI, spike_times[i] - spike_times[i-1])
    end

    # If the neuron is silent
    if length(ISI) < 2
        return NaN
    end

    # Computing the spiking frequency
    T = mean(ISI) / 1000 # in seconds
    f = 1 / T # in Hz

    return f
end

# This function extracts characteristics of a bursting firing pattern
function extract_burstiness(V, t)
    # Defining thresholds
    spike_up_threshold = 10.
    spike_down_threshold = 0.

    # Detecting spikes
    spike_detected = 0
    spike_times = []
    for i in 1 : length(V)
        if V[i] > spike_up_threshold && spike_detected == 0 # Start of spike
            append!(spike_times, t[i])
            spike_detected = 1
        end
        if V[i] < spike_down_threshold && spike_detected == 1 # End of spike
            spike_detected = 0
        end
    end

    # If the neuron is silent
    if length(spike_times) < 3
        return NaN, NaN, NaN, NaN
    end

    # Calculating all interspike intervals
    ISI = []
    for i in 2 : length(spike_times)
        append!(ISI, spike_times[i] - spike_times[i-1])
    end

    # Defining a threshold to separate intraburst from interburst ISI
    max_ISI = maximum(ISI)
    min_ISI = minimum(ISI)
    half_ISI = (max_ISI+min_ISI)/2

    # If ISI too constant, neuron is spiking
    if max_ISI - min_ISI < 25
        return NaN, NaN, NaN, NaN
    end

    # Detecting the first spike of a burst
    first_spike_burst = findall(x -> x > half_ISI, ISI)

    # Computing the interburst frequency
    Ts = ISI[first_spike_burst]
    interburst_T = mean(Ts) / 1000 # in seconds
    interburst_f = 1 / interburst_T # in Hz

    # Computing the number of spikes per burst
    nb_spike_burst = []
    for i in 2 : length(first_spike_burst)
        append!(nb_spike_burst, first_spike_burst[i] - first_spike_burst[i-1])
    end

    # If spiking
    if length(nb_spike_burst) < 2
        return NaN, NaN, NaN, NaN
    end
    nb_spike_per_burst = round(mean(nb_spike_burst))

    # If no bursting
    if nb_spike_per_burst < 1.5 || nb_spike_per_burst > 500
        burstiness = NaN
        intraburst_f = NaN
        nb_spike_per_burst = NaN
        interburst_f = NaN
    else # Else, bursting: computing the intraburst frequency
        intra_spike_burst = findall(x -> x < half_ISI, ISI)
        Ts_intraburst = ISI[intra_spike_burst]
        T_intraburst = mean(Ts_intraburst) / 1000 # in seconds
        intraburst_f = 1 / T_intraburst # in Hz

        burstiness = (nb_spike_per_burst * intraburst_f) / interburst_T
    end

    return burstiness, nb_spike_per_burst, intraburst_f, interburst_f
end

# This function extracts characteristics of a bursting firing pattern
function extract_firstspike_times(V, t)
    # Defining thresholds
    spike_up_threshold = 10.
    spike_down_threshold = 0.

    # Detecting spikes
    spike_detected = 0
    spike_times = []
    for i in 1 : length(V)
        if V[i] > spike_up_threshold && spike_detected == 0 # Start of spike
            append!(spike_times, t[i])
            spike_detected = 1
        end
        if V[i] < spike_down_threshold && spike_detected == 1 # End of spike
            spike_detected = 0
        end
    end

    # If the neuron is silent
    if length(spike_times) < 3
        return NaN
    end

    # Detecting the first spike of a burst
    first_spike_burst = []
    for i = 1 : length(spike_times) - 1
        if spike_times[i+1] - spike_times[i] > 100
            append!(first_spike_burst, spike_times[i+1])
        end
    end

    return first_spike_burst
end

function computing_phases(ST1, ST2, ST3, ST4)
    phase2 = []
    t2 = []
    phase3 = []
    t3 = []
    phase4 = []
    t4 = []


    while ST2[1] < ST1[1]
        popfirst!(ST2)
    end

    while ST3[1] < ST1[1]
        popfirst!(ST3)
    end

    while ST4[1] < ST1[1]
        popfirst!(ST4)
    end

    while ST2[end] > ST1[end]
        pop!(ST2)
    end

    while ST3[end] > ST1[end]
        pop!(ST3)
    end

    while ST4[end] > ST1[end]
        pop!(ST4)
    end

    phase1 = zeros(length(ST1) - 1)
    t1 = ST1[1:end-1]

    for i = 1 : length(ST1) - 1
        st2 = ST2[findall(ST2 .> ST1[i] .&& ST2 .<= ST1[i+1])]
        st3 = ST3[findall(ST3 .> ST1[i] .&& ST3 .<= ST1[i+1])]
        st4 = ST4[findall(ST4 .> ST1[i] .&& ST4 .<= ST1[i+1])]

        if length(st2) == 0
            append!(phase2, NaN)
            append!(t2, t1[i])
        else
            phase_i = 360 * (st2[1] - ST1[i]) / (ST1[i+1] - ST1[i])
            if phase_i > 270
                phase_i = phase_i - 360
            end
            append!(phase2, phase_i)
            append!(t2, st2[1])
        end

        if length(st3) == 0
            append!(phase3, NaN)
            append!(t3, t1[i])
        else
            phase_i = 360 * (st3[1] - ST1[i]) / (ST1[i+1] - ST1[i])
            if phase_i > 270
                phase_i = phase_i - 360
            end
            append!(phase3, phase_i)
            append!(t3, st3[1])
        end

        if length(st4) == 0
            append!(phase4, NaN)
            append!(t4, t1[i])
        else
            phase_i = 360 * (st4[1] - ST1[i]) / (ST1[i+1] - ST1[i])
            if phase_i > 270
                phase_i = phase_i - 360
            end
            append!(phase4, phase_i)
            append!(t4, st4[1])
        end
    end

    return phase1, t1, phase2, t2, phase3, t3, phase4, t4
end
