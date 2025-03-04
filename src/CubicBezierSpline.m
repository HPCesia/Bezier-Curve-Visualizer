classdef CubicBezierSpline
    properties
        KnotPoints
        ControlPoints
        KnotsContinuity
    end
    methods
        function obj = CubicBezierSpline(varargin)
            % CubicBezierSpline - 类型构造函数
            %   语法
            %     obj = CubicBezierSpline()
            %     obj = CubicBezierSpline(knot_points)
            %
            %   输入参数
            %     knot_points - 节点位置，矩阵每列为一个节点位置
            %       标量 | 向量 | 矩阵
            switch nargin
                case 0
                    obj.KnotPoints = [];
                    obj.ControlPoints = [];
                    obj.KnotsContinuity = [];
                case 1
                    knot_points = varargin{1};
                    obj = obj.setKnot(knot_points);
                otherwise
                    error('输入参数过多。')
            end
        end
        function TF = isempty(obj)
            % ISEMPTY - 检查是否为空
            %
            %   语法
            %     TF = ISEMPTY(obj)
            %     TF = obj.ISEMPTY
            %
            %   输入参数
            %     obj - CubicBezierSpline 对象
            %       CubicBezierSpline
            TF = isempty(obj.KnotPoints);
        end
        function L = length(obj)
            % LENGTH - 获取曲线节点数量
            %
            %   语法
            %     L = LENGTH(obj)
            %     L = obj.LENGTH
            %
            %   输入参数
            %     obj -  CubicBezierSpline 对象
            %       CubicBezierSpline
            L = size(obj.KnotPoints, 2);
        end
        function D = dim(obj)
            % DIM - 获取曲线维度
            D = size(obj.KnotPoints, 1);
        end
        function obj = addKnot(obj, position, sequence)
            % ADDKNOT - 在曲线某端增加一个节点
            %
            %   语法
            %     obj = ADDKNOT(obj, position, sequence)
            %     obj = obj.ADDKNOT(position, sequence)
            %
            %   输入参数
            %     obj -  CubicBezierSpline 对象
            %       CubicBezierSpline
            %     position - 新增节点位置
            %       实数标量 | 实数向量
            %     sequence - 节点排序
            %       'begin' | 'end'
            %
            %   输出参数
            %     obj -  CubicBezierSpline 对象
            %       CubicBezierSpline
            if size(position, 1) == 1 % 确保 position 为纵向量
                position = position';
            end
            switch obj.length()
                case 0
                    obj.KnotPoints = position;
                case 1
                    switch sequence
                        case 'begin'
                            obj.KnotPoints = [position, obj.KnotPoints];
                        case 'end'
                            obj.KnotPoints = [obj.KnotPoints, position];
                        otherwise
                            error('sequence 参数应为 ''begin'' 或 ''end''。')
                    end
                    obj.ControlPoints = obj.KnotPoints * [1/3, 2/3; 2/3, 1/3];
                otherwise
                    switch sequence
                        case 'begin'
                            obj.KnotPoints = [position, obj.KnotPoints];
                            obj.ControlPoints = ...
                                [obj.KnotPoints(:, 2) - obj.ControlPoints(:, 1) / 2 + obj.KnotPoints(:, 1), ...
                                2 * obj.KnotPoints(:, 2) - obj.ControlPoints(:, 1), obj.ControlPoints];
                            obj.KnotsContinuity = [true, obj.KnotsContinuity];
                        case 'end'
                            obj.KnotPoints = [obj.KnotPoints, position];
                            obj.ControlPoints = ...
                                [obj.ControlPoints, 2 * obj.KnotPoints(:, end - 1) - obj.ControlPoints(:, end), ...
                                obj.KnotPoints(:, end) / 2 - obj.ControlPoints(:, end) / 2 + obj.KnotPoints(:, end - 1)];
                            obj.KnotsContinuity = [obj.KnotsContinuity, true];
                        otherwise
                            error('sequence 参数应为 ''begin'' 或 ''end''。')
                    end
            end
        end
        function obj = combine(obj, seq1, othercbs, seq2)
            % COMBINE - 选定端点并连接两个三次 Bezier 样条曲线
        end
        function obj = setKnot(obj, knot_points)
            % SETKNOT - 重新设置曲线节点，并自动生成较平滑的控制节点
            if ~isreal(knot_points)
                error('knot_points 应为实数标量|向量|矩阵。')
            end
            n = size(knot_points, 2);
            obj.KnotPoints = knot_points;
            switch n
                case 0
                    obj.ControlPoints = [];
                    obj.KnotsContinuity = [];
                case 1
                    obj.ControlPoints = [];
                    obj.KnotsContinuity = [];
                case 2
                    obj.ControlPoints = obj.KnotPoints * [1/3, 2/3; 2/3, 1/3];
                    obj.KnotsContinuity = [];
                otherwise
                    obj.KnotsContinuity = true(1, n - 2);
                    obj.ControlPoints = zeros(obj.dim, (obj.length - 1) * 2);
                    for i = 2:n - 1
                        % 考虑节点连线夹角角平分线在交点处的垂线方向上，
                        % 两端节点连线长度最小值的 1/3 作为控制节点位置
                        AB = obj.KnotPoints(:, i - 1) - obj.KnotPoints(:, i);
                        AC = obj.KnotPoints(:, i + 1) - obj.KnotPoints(:, i);
                        V = normalize(AB, "norm") - normalize(AC, "norm");
                        len = min(norm(AB), norm(AC)) / 3;
                        obj.ControlPoints(:, 2 * i - 2) = obj.KnotPoints(:, i) + V * len;
                        obj.ControlPoints(:, 2 * i - 1) = obj.KnotPoints(:, i) - V * len;
                    end
                    AB = obj.ControlPoints(:, 2) - obj.KnotPoints(:, 2);
                    AC = obj.KnotPoints(:, 1) - obj.KnotPoints(:, 2);
                    obj.ControlPoints(:, 1) = obj.KnotPoints(:, 1) + AB - AC * dot(AB, AC) * 2 / (norm(AC)^2);
                    AB = obj.ControlPoints(:, end - 1) - obj.KnotPoints(:, end - 1);
                    AC = obj.KnotPoints(:, end) - obj.KnotPoints(:, end - 1);
                    obj.ControlPoints(:, end) = obj.KnotPoints(:, end) + AB - AC * dot(AB, AC) * 2 / (norm(AC)^2);
            end
        end
        function func = splineFunc(obj)
            % SPLINEFUNC - 获取三次 Bezier 样条曲线在 [0,1] 上的参数函数
            piece = obj.length - 1;
            if piece < 1
                error('样条包含节点过少。')
            end
            funs = cell(piece, 1);
            for i = 1:piece
                curve_points = [obj.KnotPoints(:, i), obj.ControlPoints(:, 2 * i - 1:2 * i), obj.KnotPoints(:, i + 1)];
                funs{i} = bezier_curve(curve_points);
            end
            function pos = curve(t)
                if min(t) < 0 || max(t) > 1
                    error('t 应在 [0,1] 之间。');
                end
                n = floor(t * piece) + 1;
                n(n > piece) = n(n > piece) - 1;
                t = t * piece - n + 1;
                pos = arrayfun(@(x, y) funs{x}(y), n, t, "UniformOutput", false);
                pos = cell2mat(pos);
            end
            func = @(t) curve(t);
        end
        function func = normalFunc(obj)
            piece = obj.length - 1;
            if piece < 1
                error('样条包含节点过少。')
            end
            funs = cell(piece, 1);
            for i = 1:piece
                curve_points = [obj.KnotPoints(:, i), obj.ControlPoints(:, 2 * i - 1:2 * i), obj.KnotPoints(:, i + 1)];
                funs{i} = cubicBezierNormal(curve_points);
            end
            function pos = curve(t)
                if min(t) < 0 || max(t) > 1
                    error('t 应在 [0,1] 之间。');
                end
                n = floor(t * piece) + 1;
                n(n > piece) = n(n > piece) - 1;
                t = t * piece - n + 1;
                pos = arrayfun(@(x, y) funs{x}(y), n, t, "UniformOutput", false);
                pos = cell2mat(pos);
            end
            func = @(t) curve(t);
        end
    end
end
