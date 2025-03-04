%   bezier_curve - 计算贝塞尔曲线。
%   此 MATLAB 函数返回由 p 决定的贝塞尔曲线。
%
%   语法
%       bfun = bezier_curve(p)
%       [bfun_1, ..., bfun_n] = bezier_curve(p)
%
%       ___ = bezier_curve(p, method)
%
%   输入参数
%       p - 贝塞尔曲线节点，每列均为一个控制节点
%           标量 | 向量 | 矩阵
%       method - 计算贝塞尔曲线的方法
%           'base' | 'poly' | 'plot'
%
%   输出参数
%       bfun - 贝塞尔曲线对应的 [0,1] 上的参数化函数
%           函数句柄
%       bfun_n - 贝塞尔曲线每一坐标分量对应的 [0,1] 上的参数化函数
%           函数句柄
function varargout = bezier_curve(p, varargin)
switch nargin
    case 1
        method = 'base';
    case 2
        method = varargin{1};
    otherwise
        error('参数数量过多。');
end

switch method
    case 'base'
        bfuns = bezier_curve_base(p);
    case 'poly'
        bfuns = bezier_curve_poly(p);
    case 'plot'
        bfuns = bezier_curve_plot(p);
    otherwise
        error('错误的 method 参数，method 应为 ''base'' | ''poly'' | ''plot''。')
end

switch nargout
    case 1
        varargout{1} = @(t) apply_functions(bfuns, t);
    case size(p, 1)
        varargout = bfuns;
    otherwise
        error('输出参数数量错误，应与 p 中每一点的维数相同或只有一个。')
end
end

function outvec = apply_functions(funs, t)
outvec = zeros(numel(funs), numel(t));
for i = 1:numel(funs)
    current_function = funs{i};
    outvec(i, :) = current_function(t);
end
end

function bfuns = bezier_curve_base(p)
[n, m] = size(p);
bfuns = cell(n, 1);
comb_vec = arrayfun(@(k) nchoosek(m - 1, k - 1), 1:m);
for i = 1:n
    bern_base = @(t, k) comb_vec(k) .* t.^(k - 1) .* (1 - t).^(m - k) * p(i, k);
    bern_bases = @(t) arrayfun(@(k) bern_base(t, k), 1:m, "UniformOutput", false)';
    bfuns{i} = @(t) sum(cell2mat(bern_bases(t)), 1);
end
end

function bfuns = bezier_curve_poly(p)
[n, m] = size(p);
bfuns = cell(n, 1);
comb_vec = arrayfun(@(k) nchoosek(m - 1, k - 1), 1:m);
% 计算 (1-t)^k 系数向量
poly_coeff_1_sub_t = arrayfun(@(s) arrayfun(@(k) nchoosek(s, k) * (-1)^(s - k), 0:s), ...
    0:m - 1, "UniformOutput", false);
% 计算所有 Bernstein 基多项式系数向量
temp_coeff_cell = arrayfun( ...
    @(k) comb_vec(k) * conv([1, zeros(1, k - 1)], poly_coeff_1_sub_t{m - k + 1}), ...
    1:m, "UniformOutput", false);
temp_coeff_mat = cell2mat(temp_coeff_cell');
for i = 1:n
    coeff = sum(temp_coeff_mat .* p(i, :)', 1);
    bfuns{i} = @(t) polyval(coeff, t);
end
end

function bfuns = bezier_curve_plot(p)
[n, m] = size(p);
bfuns = cell(n, 1);
P = cell(1, m);
for fk = 1:n
    for k = 1:m
        P{k} = @(t) p(fk, k);
    end
    for k = 1:m
        for i = 1:m - k
            P{i} = @(t) (1 - t) .* P{i}(t) + t .* P{i + 1}(t);
        end
    end
    bfuns{fk} = P{1};
end
end
