clc;
clear;
% System parameters
max_runs = 3000;
% info_length = 256;   % 信息序列长度
% codeRate = 1/2;         % 编码速率
EbNo_dB_vec = 0:2:16;   % 比特能量与噪声功率谱密度比（dB）


%% Comparision Parameter
monitor_onoff = 1;      % 1: on; 0: off
num_monitor_comp = 1;   % 实时监测的对比项
num_monitor_ebno = 2;   % 实时监测的信噪比项(index of EbNo_dB_vec)
legends = {};

% Variables

c = 8;
legends = {'1','3','5','7','9','11','13','15'};
L_lengths(1:c) = 256;
ask_depths(1:c) = 1;
constraintLengths(1:c) = 3;
trelliss(1:c) = poly2trellis(constraintLengths(c), [5 7]);
traceback_depths(1:c) = [1:2:15];


% c = 1;
% legends{c} = ' L=256, trace=1 ';        % 为保证表格打印效果，字符最好左右留空格
% L_lengths(c) = 256;             % 基带信号码长
% ask_depths(c) = 1;            % ASK调制深度
% constraintLengths(c) = 3;       % 卷积码约束长度
% trelliss(c) = poly2trellis(constraintLengths(c), [5 7]);    % 生成多项式为 [111, 101]，约束长度为 3
% traceback_depths(c) = 1;
% 
% c = 2;
% legends{c} = ' L=256, g=[5 7 7] ';
% L_lengths(c) = 256;
% ask_depths(c) = 1;
% constraintLengths(c) = 3;
% trelliss(c) = poly2trellis(constraintLengths(c), [5 7 7]);
% traceback_depths(c) = 5*constraintLengths(c);
% 
% c = 3;
% legends{c} = ' L=256 g=[133 171]';
% L_lengths(c) = 256;
% ask_depths(c) = 1;
% constraintLengths(c) = 7;
% trelliss(c) = poly2trellis(constraintLengths(c), [133 171]);
% traceback_depths(c) = 5*constraintLengths(c);
% 
% c = 4;
% legends{c} = ' L=256 g=[133 171 165]';
% L_lengths(c) = 256;
% ask_depths(c) = 1;
% constraintLengths(c) = 7;
% trelliss(c) = poly2trellis(constraintLengths(c), [133 171 165]);
% traceback_depths(c) = 5*constraintLengths(c);
% 
% c = 5;
% legends{c} = ' L=256 g=[5 7 7 7] ';
% L_lengths(c) = 256;
% ask_depths(c) = 1;
% constraintLengths(c) = 3;
% trelliss(c) = poly2trellis(constraintLengths(c), [5 7 7 7]);
% traceback_depths(c) = 5*constraintLengths(c);
% 
% c = 6;
% legends{c} = ' L=256 g=[133 171 165 147] ';
% L_lengths(c) = 4096;
% ask_depths(c) = 1;
% constraintLengths(c) = 7;
% trelliss(c) = poly2trellis(constraintLengths(c), [133 171 165 147]);
% traceback_depths(c) = 5*constraintLengths(c);

num_comp = c;

% ber storage
ber_sum = zeros(num_comp, length(EbNo_dB_vec));     %每行对应一个对比条件，列对应多个信噪比，命令行窗口打印时矩阵会转置

% Print
print_resolution = 5;
print_matrix = zeros(length(EbNo_dB_vec),c+1);
print_matrix(:,1) = EbNo_dB_vec';

% 实时更新图形
if (monitor_onoff == 1)
    monitor_matrix = nan(max_runs / print_resolution);
    hFig = figure;
    hold on;
    hPlot30 = semilogy(print_resolution:print_resolution:max_runs, nan(max_runs / print_resolution), 'o-');
    % hPlot80 = semilogy(EbNo_dB_vec, nan(size(EbNo_dB_vec)), 's-');
    % hPlot100 = semilogy(EbNo_dB_vec, nan(size(EbNo_dB_vec)), '^-');
    hold off;
    legend(legends{num_monitor_comp});
    title(['实时平均 BER 曲线, EbNo = ' num2str(EbNo_dB_vec(num_monitor_ebno))]);
    xlabel('Run times');
    ylabel('BER');
    grid on;
end

%% Begin
ber = zeros(num_comp, length(EbNo_dB_vec));
for i_runs = 1 : max_runs
%     info_bits = randi([0, 1], info_length, 1); % 生成随机二进制信息序列
%     [ber(1, :)] = conv_ask_ber(info_bits, ask_depth_30, EbNo_dB_vec, constraintLength, trellis);
%     [ber(2, :)] = conv_ask_ber(info_bits, ask_depth_80, EbNo_dB_vec, constraintLength, trellis);
%     [ber(3, :)] = conv_ask_ber(info_bits, ask_depth_100, EbNo_dB_vec, constraintLength, trellis);

    for i_comp = 1 : num_comp   % i_comp指第i个对比条件，对应上面的第i行函数调用
        [ber(i_comp, :)] = conv_ask_ber(L_lengths(i_comp), ask_depths(i_comp), EbNo_dB_vec, constraintLengths(i_comp), trelliss(i_comp), traceback_depths(i_comp));
        ber_sum(i_comp, :) = ber_sum(i_comp, :) + ber(i_comp, :);
    end

    % Print
    if(mod(i_runs,print_resolution) == 0)
        for i_comp = 1 : num_comp
            print_matrix(:, i_comp + 1) = ber_sum(i_comp, :)'./i_runs;
        end
        disp(' ');
        disp(['Current run_time = ' num2str(i_runs)]);
        %         disp('ebno       ber_ask30 ber_ask80 ber_ask100');
        disp(['ebno      ' legends{:}]);
        disp(num2str(print_matrix, '%.6f '));
        % Moniter
        if(monitor_onoff == 1)
            monitor_matrix(1,i_runs / print_resolution) = print_matrix(num_monitor_ebno,num_monitor_comp+1)';
            set(hPlot30, 'YData', monitor_matrix(1,:));
            drawnow;
        end
    end
end


%% Final Result
ber_avg = zeros(num_comp, length(EbNo_dB_vec));
for i_comp = 1 : num_comp      %这里用i_comp1是为了避免重复使用前面用过的i_comp，但我也不确定这里重复使用会不会出问题
    ber_avg(i_comp, :) = ber_sum(i_comp, :) / max_runs;
end

markers = {'o-', 's-', '^-', 'd-', 'p-', 'h-', '+-', '*-', '.', 'x', 'v', '>', '<',};
figure;
hold on;    %hold on启动图形保持，当前的普通坐标轴也会被保持，semilogy将无法改变坐标轴为对数坐标.
for i_comp = 1 : num_comp 
    semilogy(EbNo_dB_vec, ber_avg(i_comp, :), markers{i_comp});     % 笔记： {}提取的是单元格内容，()提取的是一个单元格数组的子集。若使用了markers(i)，则marker的类型将是cell而非char
end
hold off;
% legend('ASK 调制深度 30%', 'ASK 调制深度 80%', 'ASK 调制深度 100%', 'legend4');
legend(legends{1:num_comp});
title('误码率性能对比');
xlabel('Eb/No (dB)');
ylabel('误码率 (BER)');
grid on;
set(gca, 'YScale', 'log');  %强制设置y轴为对数坐标
