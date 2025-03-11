function [ber] = ber_conv_dsss(L_length, EbNo_dB_vec, ask_depth, trellis, traceback_depth, n_m, taps_m, reg_m)
% 卷积码BER性能仿真：编码-扩频-调制-加噪-解调-解扩-译码

% Result storage
ber = zeros(size(EbNo_dB_vec));

% m_seq = 2 * mseq(5, [5 3 2], reg_m) - 1;  % 生成31位m序列
m_seq = 2 * mseq(n_m, taps_m, reg_m) - 1;

%% Encode
info_bits = randi([0, 1], L_length, 1); % 生成随机二进制信息序列
x = convenc(info_bits, trellis);
x_1 = 2 * x - 1;
spread_x = dsss_spread(x_1, m_seq);
x_modulated = modulate(ask_depth, spread_x);

% Noise
for i_ebno = 1 : length(EbNo_dB_vec)
    % add noise
    y_noisy = awgn(x_modulated,EbNo_dB_vec(i_ebno),'measured');
    % Demodulate - Hard
    y_demodulated = demodulate(ask_depth,y_noisy);
    % 解扩
    y_bip = 2 * y_demodulated - 1;
    y_despread = dsss_despread(y_bip, m_seq);
    % Decode
    x_decoded = vitdec(y_despread, trellis, traceback_depth, 'trunc', 'hard');
%     [numErrors_ask_100, ber_ask_100(i_ebno)] = biterr(info_bits, decoded_ask_100);
    [~ , ber(i_ebno)] = biterr(info_bits, x_decoded);
end

end



%% functions

function spread = dsss_spread(data, m_seq)
    spread = repelem(data, length(m_seq)) .* repmat(m_seq, length(data), 1);
end

function despread = dsss_despread(signal, m_seq)
    L = length(m_seq);
%     m_seq_bin = m_seq > 0;
    signal_re = reshape(signal, L, [])';
    y1 = signal_re * m_seq;
    despread = y1 > 0;
%     despread = (reshape(signal, L, [])' * (m_seq > 0)) > L/2; % 相关解扩
end

% function despread = dsss_despread(signal, m_seq)
%     L = length(m_seq);
%     despread = (reshape(signal, L, [])' * (m_seq > 0)) > L/2; % 相关解扩
% end