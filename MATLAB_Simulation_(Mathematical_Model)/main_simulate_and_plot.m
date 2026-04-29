
%% CS255 Mini Project
%% Aadharsh Venkat - 241CS101
%% Amisha Vidya Diwakar - 241CS107

clear; clc;

%% Parameters taken (Values unchanged from paper) - Units
def_lambda = 3;        % packets/ms
def_vu     = 0.0001;   % gNBs/m^2
def_rus    = 100;      % m
def_Ru     = 100;      % Mbps
num_runs   = 10;       % Number of runs to average results of runs

%% Scenario 1: Varying Packet Arrival Rate (Figs 1 & 2)
disp('Running Scenario 1/4: Packet Arrival Rate...');
lambda_vec = logspace(-1,2,12);
tp_w_1 = zeros(size(lambda_vec)); tp_u_1 = zeros(size(lambda_vec));
del_w_1 = zeros(size(lambda_vec)); del_u_1 = zeros(size(lambda_vec));

for i = 1:length(lambda_vec)
    temp_tp_w = zeros(1, num_runs); temp_tp_u = zeros(1, num_runs);
    temp_del_w = zeros(1, num_runs); temp_del_u = zeros(1, num_runs);
    for r = 1:num_runs
        [temp_tp_w(r), temp_tp_u(r), temp_del_w(r), temp_del_u(r)] = sim_csma_event(lambda_vec(i), def_vu, def_rus, def_Ru);
    end
    tp_w_1(i) = mean(temp_tp_w); tp_u_1(i) = mean(temp_tp_u);
    del_w_1(i) = mean(temp_del_w); del_u_1(i) = mean(temp_del_u);
end

%% Scenario 2: Varying Density of NR-U gNBs (Figs 3 & 4)
disp('Running Scenario 2/4: Density of NR-U gNBs...');
vu_vec = linspace(1e-4, 5e-4, 12);
tp_w_2 = zeros(size(vu_vec)); tp_u_2 = zeros(size(vu_vec));
del_w_2 = zeros(size(vu_vec)); del_u_2 = zeros(size(vu_vec));

for i = 1:length(vu_vec)
    temp_tp_w = zeros(1, num_runs); temp_tp_u = zeros(1, num_runs);
    temp_del_w = zeros(1, num_runs); temp_del_u = zeros(1, num_runs);
    for r = 1:num_runs
        [temp_tp_w(r), temp_tp_u(r), temp_del_w(r), temp_del_u(r)] = sim_csma_event(def_lambda, vu_vec(i), def_rus, def_Ru);
    end
    tp_w_2(i) = mean(temp_tp_w); tp_u_2(i) = mean(temp_tp_u);
    del_w_2(i) = mean(temp_del_w); del_u_2(i) = mean(temp_del_u);
end

%% Scenario 3: Varying Sensing Distance of NR-U gNB (Figs 5 & 6)
disp('Running Scenario 3/4: Sensing Distance...');
rus_vec = linspace(90,160,12);
tp_w_3 = zeros(size(rus_vec)); tp_u_3 = zeros(size(rus_vec));
del_w_3 = zeros(size(rus_vec)); del_u_3 = zeros(size(rus_vec));

for i = 1:length(rus_vec)
    temp_tp_w = zeros(1, num_runs); temp_tp_u = zeros(1, num_runs);
    temp_del_w = zeros(1, num_runs); temp_del_u = zeros(1, num_runs);
    for r = 1:num_runs
        [temp_tp_w(r), temp_tp_u(r), temp_del_w(r), temp_del_u(r)] = sim_csma_event(def_lambda, def_vu, rus_vec(i), def_Ru);
    end
    tp_w_3(i) = mean(temp_tp_w); tp_u_3(i) = mean(temp_tp_u);
    del_w_3(i) = mean(temp_del_w); del_u_3(i) = mean(temp_del_u);
end

%% Scenario 4: Varying Channel TX Rate of NR-U (Figs 7 & 8)
disp('Running Scenario 4/4: NR-U Transmission Rate...');
Ru_vec = linspace(40,120,12);
tp_w_4 = zeros(size(Ru_vec)); tp_u_4 = zeros(size(Ru_vec));
del_w_4 = zeros(size(Ru_vec)); del_u_4 = zeros(size(Ru_vec));

for i = 1:length(Ru_vec)
    temp_tp_w = zeros(1, num_runs); temp_tp_u = zeros(1, num_runs);
    temp_del_w = zeros(1, num_runs); temp_del_u = zeros(1, num_runs);
    for r = 1:num_runs
        [temp_tp_w(r), temp_tp_u(r), temp_del_w(r), temp_del_u(r)] = sim_csma_event(def_lambda, def_vu, def_rus, Ru_vec(i));
    end
    tp_w_4(i) = mean(temp_tp_w); tp_u_4(i) = mean(temp_tp_u);
    del_w_4(i) = mean(temp_del_w); del_u_4(i) = mean(temp_del_u);
end
%% Plotting

% Fig 1
figure('Name', 'Throughput vs Arrival Rate');
semilogx(lambda_vec, tp_u_1, 'b-o', lambda_vec, tp_w_1, 'r-*', 'LineWidth', 1.5);
title('Throughput vs Arrival Rate'); 
xlabel('Arrival rate (packets/ms)'); ylabel('Throughput (Mbps)');
legend('NR-U', 'WiFi', 'Location', 'best'); 
grid on;

% Fig 2
figure('Name', 'Delay vs Arrival Rate');
semilogx(lambda_vec, del_u_1, 'b-o', lambda_vec, del_w_1, 'r-*', 'LineWidth', 1.5);
title('Delay vs Arrival Rate'); 
xlabel('Arrival rate (packets/ms)'); ylabel('Packet delay (ms)');
legend('NR-U', 'WiFi', 'Location', 'best'); 
grid on;

% Fig 3
figure('Name', 'Throughput vs NR-U Density');
plot(vu_vec, tp_u_2, 'b-o', vu_vec, tp_w_2, 'r-*', 'LineWidth', 1.5);
title('Throughput vs NR-U Density'); 
xlabel('Density of NR-U (gNBs/m^2)'); ylabel('Throughput (Mbps)');
legend('NR-U', 'WiFi', 'Location', 'best');
grid on;

% Fig 4
figure('Name', 'Delay vs NR-U Density');
plot(vu_vec, del_u_2, 'b-o', vu_vec, del_w_2, 'r-*', 'LineWidth', 1.5);
title('Delay vs NR-U Density'); 
xlabel('Density of NR-U (gNBs/m^2)'); ylabel('Packet delay (ms)');
legend('NR-U', 'WiFi', 'Location', 'best');
grid on;

% Fig 5
figure('Name', 'Throughput vs NR-U Sensing');
plot(rus_vec, tp_u_3, 'b-o', rus_vec, tp_w_3, 'r-*', 'LineWidth', 1.5);
title('Throughput vs NR-U Sensing'); 
xlabel('Sensing distance of NR-U (m)'); ylabel('Throughput (Mbps)');
legend('NR-U', 'WiFi', 'Location', 'best');
grid on;

% Fig 6
figure('Name', 'Delay vs NR-U Sensing');
plot(rus_vec, del_u_3, 'b-o', rus_vec, del_w_3, 'r-*', 'LineWidth', 1.5);
title('Delay vs NR-U Sensing'); 
xlabel('Sensing distance of NR-U (m)'); ylabel('Packet delay (ms)');
legend('NR-U', 'WiFi', 'Location', 'best');
grid on;

% Fig 7
figure('Name', 'Throughput vs NR-U Rate');
plot(Ru_vec, tp_u_4, 'b-o', Ru_vec, tp_w_4, 'r-*', 'LineWidth', 1.5);
title('Throughput vs NR-U Rate'); 
xlabel('TX Rate of NR-U (Mbps)'); ylabel('Throughput (Mbps)');
legend('NR-U', 'WiFi', 'Location', 'best');
grid on;

% Fig 8
figure('Name', 'Delay vs NR-U Rate');
plot(Ru_vec, del_u_4, 'b-o', Ru_vec, del_w_4, 'r-*', 'LineWidth', 1.5);
title('Delay vs NR-U Rate'); 
xlabel('TX Rate of NR-U (Mbps)'); ylabel('Packet delay (ms)');
legend('NR-U', 'WiFi', 'Location', 'best');
grid on;

disp('Simulation Complete.');

%% Simulator Function
%% We can vary 1 parameter and fix 3 parameters for plotting
function [tp_w, tp_u, del_w, del_u] = sim_csma_event(lambda_ms, v_u, r_us, R_u)
    
    % Simulation bounds
    Tsim_ms = 100000; 
    
    v_w = 0.0001; r_ws = 90; r_wt = 70; r_ut = 80;
    R_w = 54;
    payload_w = 12000; mac_hdr_w = 192; phy_hdr_w = 224;
    size_rts = 160 + phy_hdr_w; size_cts = 112 + phy_hdr_w; size_ack_w = 112 + phy_hdr_w;
    payload_u = 12000; size_ack_u = 300;
    
    Ts = 9; T_DIFS = 34; T_SIFS = 16;
    
    % We consider a case,
    % As r_us increases, NR-U defers to distant WiFi nodes unnecessarily, driving up its backoff times
    % We apply an exponential penalty multiplier based on the sensing radius.
    defer_multiplier = exp(0.035 * (r_us - 100)); 
    
    W_w0 = 16; m_w = 6; max_retx_w = 9;
    W_u0_default = 16; m_u = 6; max_retx_u = 9;
    W_u0 = max(4, round(W_u0_default * defer_multiplier)); 
    
    % Event Durations (in microseconds)
    T_RTS = ceil(size_rts / R_w);
    T_CTS = ceil(size_cts / R_w);
    T_DATA_W = ceil((payload_w + mac_hdr_w + phy_hdr_w) / R_w);
    T_ACK_W = ceil(size_ack_w / R_w);
    T_DATA_U = ceil(payload_u / R_u);
    T_ACK_U = ceil(size_ack_u / R_u);
    
    T_succ_w = T_RTS + T_SIFS + T_CTS + T_SIFS + T_DATA_W + T_SIFS + T_ACK_W;
    T_coll_w = T_RTS + T_SIFS + T_CTS;
    T_succ_u = T_DATA_U + T_SIFS + T_ACK_U;
    T_coll_u = T_DATA_U + T_SIFS + T_ACK_U; 

    % Nodal Densities in Contention Domain
    N_w = max(1, round(v_w * pi * r_ws^2));
    N_u = max(1, round(v_u * pi * r_us^2));
    
    % Asymmetrical Hidden Node Vulnerabilities 
    rho = min(1, lambda_ms * 0.1); 
    P_coll_h_w = rho * max(0, (160 - r_us)/60) * 0.05; 
    P_coll_h_u = rho * max(0, (160 - r_us)/60) * 0.35; 
    
    % State Vectors
    q_w = zeros(1, N_w); q_u = zeros(1, N_u);
    bo_w = -ones(1, N_w); bo_u = -ones(1, N_u);
    cw_w = ones(1, N_w) * W_w0; cw_u = ones(1, N_u) * W_u0;
    retx_w = zeros(1, N_w); retx_u = zeros(1, N_u);
    contention_start_w = zeros(1, N_w); contention_start_u = zeros(1, N_u);
    
    % Metrics
    succ_w = 0; succ_u = 0;
    total_delay_w = 0; total_delay_u = 0;
    sim_time = 0;
    
    lambda_us = lambda_ms / 1000;
    T_sim_us = Tsim_ms * 1000;
    
    % Time Loop
    while sim_time < T_sim_us
        
        % 1. Promote packets to MAC contention
        active_w = q_w > 0; active_u = q_u > 0;
        
        for i = 1:N_w
            if active_w(i) && bo_w(i) < 0
                bo_w(i) = randi([0, cw_w(i)-1]);
                contention_start_w(i) = sim_time;
            end
        end
        for i = 1:N_u
            if active_u(i) && bo_u(i) < 0
                bo_u(i) = randi([0, cw_u(i)-1]);
                contention_start_u(i) = sim_time;
            end
        end
        
        % 2. Find time until next transmission
        min_bo = inf;
        if any(active_w), min_bo = min(min_bo, min(bo_w(active_w))); end
        if any(active_u), min_bo = min(min_bo, min(bo_u(active_u))); end
        
        % If idle, jump to next potential arrival slot
        if min_bo == inf
            step_time = Ts;
            arr_w = poissrnd(lambda_us * step_time, 1, N_w);
            arr_u = poissrnd(lambda_us * step_time, 1, N_u);
            q_w = q_w + arr_w; q_u = q_u + arr_u;
            sim_time = sim_time + step_time;
            continue;
        end
        
        % 3. Leapfrog time forward by backoff duration
        step_time = min_bo * Ts;
        bo_w(active_w) = bo_w(active_w) - min_bo;
        bo_u(active_u) = bo_u(active_u) - min_bo;
        
        tx_w = active_w & (bo_w == 0);
        tx_u = active_u & (bo_u == 0);
        num_tx = sum(tx_w) + sum(tx_u);
        
        busy_dur = 0;
        
        % 4. Resolve Channel Access
        if num_tx == 1 
            % Single transmitter (Hidden Node Risk)
            if sum(tx_w) == 1
                idx = find(tx_w);
                if rand() < P_coll_h_w
                    busy_dur = T_coll_w;
                    retx_w(idx) = retx_w(idx) + 1;
                    if retx_w(idx) > max_retx_w
                        q_w(idx) = max(0, q_w(idx) - 1); retx_w(idx) = 0; cw_w(idx) = W_w0; bo_w(idx) = -1;
                    else
                        cw_w(idx) = min((2^retx_w(idx))*W_w0, (2^m_w)*W_w0); bo_w(idx) = -1;
                    end
                else
                    busy_dur = T_succ_w; succ_w = succ_w + 1;
                    total_delay_w = total_delay_w + (sim_time + busy_dur - contention_start_w(idx));
                    q_w(idx) = max(0, q_w(idx) - 1); retx_w(idx) = 0; cw_w(idx) = W_w0; bo_w(idx) = -1;
                end
            else
                idx = find(tx_u);
                if rand() < P_coll_h_u
                    busy_dur = T_coll_u;
                    retx_u(idx) = retx_u(idx) + 1;
                    if retx_u(idx) > max_retx_u
                        q_u(idx) = max(0, q_u(idx) - 1); retx_u(idx) = 0; cw_u(idx) = W_u0; bo_u(idx) = -1;
                    else
                        cw_u(idx) = min((2^retx_u(idx))*W_u0, (2^m_u)*W_u0); bo_u(idx) = -1;
                    end
                else
                    busy_dur = T_succ_u; succ_u = succ_u + 1;
                    total_delay_u = total_delay_u + (sim_time + busy_dur - contention_start_u(idx));
                    q_u(idx) = max(0, q_u(idx) - 1); retx_u(idx) = 0; cw_u(idx) = W_u0; bo_u(idx) = -1;
                end
            end
        else
            % Multi-transmitter (Local Collision)
            if sum(tx_w) > 0, busy_dur = max(busy_dur, T_coll_w); end
            if sum(tx_u) > 0, busy_dur = max(busy_dur, T_coll_u); end
            
            for idx = find(tx_w)
                retx_w(idx) = retx_w(idx) + 1;
                if retx_w(idx) > max_retx_w
                    q_w(idx) = max(0, q_w(idx) - 1); retx_w(idx) = 0; cw_w(idx) = W_w0; bo_w(idx) = -1;
                else
                    cw_w(idx) = min((2^retx_w(idx))*W_w0, (2^m_w)*W_w0); bo_w(idx) = -1;
                end
            end
            for idx = find(tx_u)
                retx_u(idx) = retx_u(idx) + 1;
                if retx_u(idx) > max_retx_u
                    q_u(idx) = max(0, q_u(idx) - 1); retx_u(idx) = 0; cw_u(idx) = W_u0; bo_u(idx) = -1;
                else
                    cw_u(idx) = min((2^retx_u(idx))*W_u0, (2^m_u)*W_u0); bo_u(idx) = -1;
                end
            end
        end
        
        % 5. Advance time and calculate arrivals during the busy+defer period
        sim_time = sim_time + step_time + busy_dur + T_DIFS;
        
        arr_w = poissrnd(lambda_us * (step_time + busy_dur + T_DIFS), 1, N_w);
        arr_u = poissrnd(lambda_us * (step_time + busy_dur + T_DIFS), 1, N_u);
        q_w = q_w + arr_w; q_u = q_u + arr_u;
    end
    
    % Compile Final Metrics per node average
    tp_w = (succ_w * payload_w) / (N_w * Tsim_ms * 1000);
    tp_u = (succ_u * payload_u) / (N_u * Tsim_ms * 1000);
    del_w = (total_delay_w / max(1, succ_w)) / 1000;
    del_u = (total_delay_u / max(1, succ_u)) / 1000;
end