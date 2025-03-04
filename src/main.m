clc; clear; close all;

points = [[0.2; 0.2], [0.4; 0.8], [0.6; 0.2], [0.8; 0.8]];
start(points);

function start(init_curve_points)
% 创建主窗口
fig = uifigure('Name', 'Bezier 样条绘制', 'Position', [100, 100, 600, 400]);
origin_fig_func = [];

g = uigridlayout(fig, [1, 2], 'RowHeight', {'1x', 'fit'}, 'ColumnWidth', {'fit', '1x'});

% 创建左侧面板
panel = uipanel(g, 'Title', '选项');
panel_grid = uigridlayout(panel, [6, 1], 'RowHeight', {'fit', 'fit', 'fit', '1x'});

knot_point_cbx = uicheckbox(panel_grid, 'Text', '显示关键节点', 'ValueChangedFcn', @switchKnotPointCheckBox);
ctr_point_cbx = uicheckbox(panel_grid, 'Text', '显示控制节点', 'ValueChangedFcn', @switchControlPointCheckBox);
curvature_cbx = uicheckbox(panel_grid, 'Text', '显示曲率梳', 'ValueChangedFcn', @switchCurvatureCheckBox);

% 创建提示区
tips = uitextarea(panel_grid);
tips.Editable = false;
tips.Value = '点击节点并拖动以更改曲线';

% 默认勾选
knot_point_cbx.Value = true;
ctr_point_cbx.Value = true;
curvature_cbx.Value = true;

% 创建坐标区
ax = uiaxes(g, 'Xlim', [0, 1], 'YLim', [0, 1]);
title(ax, '绘图窗口');
ax.XAxis.Visible = 'off';
ax.YAxis.Visible = 'off';
% grid(ax, "on");
axis(ax, 'equal');
disableDefaultInteractivity(ax);
xlimit = get(ax, 'xlim');
ylimit = get(ax, 'ylim');

% 创建重置按钮
uibutton(g, 'push', 'Text', '重置', 'ButtonPushedFcn', @(btn, event) resetAxes());

% 绘制曲线
cbss = cell(1); % Cubic Bezier Splines
kpss = cell(1); % (Knot Points)s
cpss = cell(1); % (Control Points)s
cpsls = cell(1); % Control Points Lines
curves = gobjects(1);
curvatures = cell(1);
ccidx = 1; % current curve index
cpidx = []; % current point index

cbss{1} = CubicBezierSpline(init_curve_points);
replotSpline(1);

% 切换关键节点显示的回调函数
    function switchKnotPointCheckBox(~, event)
        if event.Value
            for k = 1:length(cbss)
                for t = 1:cbss{k}.length()
                    set(kpss{k}(t), 'Marker', 'o', 'MarkerEdgeColor', 'r');
                end
            end
        else
            for k = 1:length(cbss)
                for t = 1:cbss{k}.length()
                    set(kpss{k}(t), 'Marker', 'none', 'MarkerEdgeColor', 'none');
                end
            end
        end
    end

% 切换控制节点显示的回调函数
    function switchControlPointCheckBox(~, event)
        if event.Value
            for k = 1:length(cbss)
                for t = 1:2 * cbss{k}.length() - 2
                    set(cpss{k}(t), 'Marker', 'o', 'MarkerEdgeColor', '#006400');
                    set(cpsls{k}(t), 'LineStyle', '--', 'Color', '#006400');
                end
            end
        else
            for k = 1:length(cbss)
                for t = 1:2 * cbss{k}.length() - 2
                    set(cpss{k}(t), 'Marker', 'none', 'MarkerEdgeColor', 'none');
                    set(cpsls{k}(t), 'LineStyle', 'none', 'Color', 'none');
                end
            end
        end
    end

% 切换曲率梳显示的回调函数
    function switchCurvatureCheckBox(~, event)
        if event.Value
            for k = 1:length(cbss)
                m = 10 * (cbss{k}.length() - 1) + 1;
                set(curvatures{k}{1}, 'Color', '#FFA500');
                for t = 1:m
                    set(curvatures{k}{2}(t), 'Color', '#FFA500');
                end
            end
        else
            for k = 1:length(cbss)
                m = 10 * (cbss{k}.length() - 1) + 1;
                set(curvatures{k}{1}, 'Color', 'none');
                for t = 1:m
                    set(curvatures{k}{2}(t), 'Color', 'none');
                end
            end
        end
    end

% 重置按钮的回调函数
    function resetAxes()
        cla(ax);
        cbss = cell(1);
        kpss = cell(1);
        cpss = cell(1);
        cpsls = cell(1);
        curves = gobjects(1);
        curvatures = cell(1);
        ccidx = 1;
        cpidx = [];
        cbss{1} = CubicBezierSpline([[0.2; 0.2], [0.4; 0.8], [0.6; 0.2], [0.8; 0.8]]);
        replotSpline(1);
    end

    function replotSpline(k)
        m = cbss{k}.length();
        kpss{k} = gobjects(1, m);
        cpss{k} = gobjects(1, 2 * m - 2);
        cpsls{k} = gobjects(1, 2 * m - 2);
        
        % 绘制节点
        for t = 1:m
            kpss{k}(t) = patch(ax, 'xdata', cbss{k}.KnotPoints(1, t), 'ydata', cbss{k}.KnotPoints(2, t), ...
                'LineStyle', 'none', 'FaceColor', 'none', 'Marker', 'o', ...
                'MarkerEdgeColor', 'r', 'UserData', [k, t], 'ButtonDownFcn', @selectKnot);
        end
        
        % 绘制控制节点
        if m > 1
            % 绘制节点
            for t = 1:2 * m - 2
                cpss{k}(t) = patch(ax, 'xdata', cbss{k}.ControlPoints(1, t), 'ydata', cbss{k}.ControlPoints(2, t), ...
                    'LineStyle', 'none', 'FaceColor', 'none', 'UserData', [k, t], 'ButtonDownFcn', @selectControl);
                if ctr_point_cbx.Value
                    set(cpss{k}(t), 'Marker', 'o', 'MarkerEdgeColor', '#006400');
                else
                    set(cpss{k}(t), 'Marker', 'none', 'MarkerEdgeColor', 'none');
                end
            end
            % 绘制连线
            for t = 1:m - 1
                cpsls{k}(2 * t) = line(ax, [cbss{k}.ControlPoints(1, 2 * t), cbss{k}.KnotPoints(1, t + 1)], ...
                    [cbss{k}.ControlPoints(2, 2 * t), cbss{k}.KnotPoints(2, t + 1)]);
                cpsls{k}(2 * t - 1) = line(ax, [cbss{k}.ControlPoints(1, 2 * t - 1), cbss{k}.KnotPoints(1, t)], ...
                    [cbss{k}.ControlPoints(2, 2 * t - 1), cbss{k}.KnotPoints(2, t)]);
                if ctr_point_cbx.Value
                    set(cpsls{k}(2 * t), 'LineStyle', '--', 'Color', '#006400');
                    set(cpsls{k}(2 * t - 1), 'LineStyle', '--', 'Color', '#006400');
                else
                    set(cpsls{k}(2 * t), 'LineStyle', 'none', 'Color', 'none');
                    set(cpsls{k}(2 * t - 1), 'LineStyle', 'none', 'Color', 'none');
                end
            end
        end
        
        if m > 1
            % 绘制曲线
            t = linspace(0, 1, 100 * (m - 1) + 1);
            curr_spline_func = cbss{k}.splineFunc();
            pos = curr_spline_func(t);
            curves(k) = line(ax, pos(1, :), pos(2, :), 'UserData', k, 'ButtonDownFcn', @selectCurve);
            if ccidx == k
                set(curves(k), 'Color', 'blue');
            else
                set(curves(k), 'Color', 'black');
            end
            
            % 绘制曲率弧
            curr_spline_normal_func = cbss{k}.normalFunc();
            normal_pos = curr_spline_normal_func(t) / 50;
            corr_curve_pos = pos(:, 1:10:100 * (m - 1) + 1);
            corr_normal_pos = normal_pos(:, 1:10:100 * (m - 1) + 1);
            normal_pos = pos - normal_pos;
            corr_normal_pos = corr_curve_pos - corr_normal_pos;
            curvatures{k} = cell(1, 2);
            curvatures{k}{1} = line(ax, normal_pos(1, :), normal_pos(2, :));
            if curvature_cbx.Value
                set(curvatures{k}{1}, 'Color', '#FFA500');
            else
                set(curvatures{k}{1}, 'Color', 'none');
            end
            curvatures{k}{2} = gobjects(1, 10 * (m - 1) + 1);
            for t = 1:10 * (m - 1) + 1
                curvatures{k}{2}(t) = line(ax, [corr_curve_pos(1, t), corr_normal_pos(1, t)], [corr_curve_pos(2, t), corr_normal_pos(2, t)]);
                if curvature_cbx.Value
                    set(curvatures{k}{2}(t), 'Color', '#FFA500');
                else
                    set(curvatures{k}{2}(t), 'Color', 'none');
                end
            end
        end
    end

    function selectCurve(src, ~)
        index = get(src, 'UserData');
        index = index(1);
        set(curves(ccidx), 'Color', 'black');
        set(curves(index), 'Color', 'blue');
        ccidx = index;
    end

    function selectKnot(src, ~)
        index = get(src, 'UserData');
        cpidx = index(2);
        index = index(1);
        % 选中曲线
        set(curves(ccidx), 'Color', 'black');
        set(curves(index), 'Color', 'blue');
        ccidx = index;
        % 保存原有回调函数
        origin_fig_func = get(gcbf, {'WindowButtonMotionFcn', 'WindowButtonUpFcn'});
        set(gcbf, 'WindowButtonMotionFcn', @moveKnot, 'WindowButtonUpFcn', @drop);
    end

    function moveKnot(~, ~)
        fig.Pointer = 'hand';
        curr_point = get(ax, 'currentPoint');
        xnew = min(max(curr_point(1), xlimit(1)), xlimit(2));
        ynew = min(max(curr_point(3), ylimit(1)), ylimit(2));
        differ = [xnew; ynew] - cbss{ccidx}.KnotPoints(:, cpidx);
        cbss{ccidx}.KnotPoints(:, cpidx) = [xnew; ynew];
        if cpidx > 1
            cbss{ccidx}.ControlPoints(:, 2 * cpidx - 2) = ...
                cbss{ccidx}.ControlPoints(:, 2 * cpidx - 2) + differ;
        end
        if cpidx < cbss{ccidx}.length()
            cbss{ccidx}.ControlPoints(:, 2 * cpidx - 1) = ...
                cbss{ccidx}.ControlPoints(:, 2 * cpidx - 1) + differ;
        end
        updateCurve('Knot');
    end

    function selectControl(src, ~)
        index = get(src, 'UserData');
        cpidx = index(2);
        index = index(1);
        % 选中曲线
        set(curves(ccidx), 'Color', 'black');
        set(curves(index), 'Color', 'blue');
        ccidx = index;
        % 保存原有回调函数
        origin_fig_func = get(gcbf, {'WindowButtonMotionFcn', 'WindowButtonUpFcn'});
        set(gcbf, 'WindowButtonMotionFcn', @moveControl, 'WindowButtonUpFcn', @drop);
    end

    function moveControl(~, ~)
        fig.Pointer = 'hand';
        curr_point = get(ax, 'currentPoint');
        xnew = min(max(curr_point(1), xlimit(1)), xlimit(2));
        ynew = min(max(curr_point(3), ylimit(1)), ylimit(2));
        t = fix(cpidx / 2) + 1;
        cbss{ccidx}.ControlPoints(:, cpidx) = [xnew; ynew];
        if cpidx > 1 && cpidx < 2 * cbss{ccidx}.length() - 2 && cbss{ccidx}.KnotsContinuity(t - 1)
            corr_cp_idx = 4 * t - 3 - cpidx;
            cbss{ccidx}.ControlPoints(:, corr_cp_idx) = 2 * cbss{ccidx}.KnotPoints(:, t) - [xnew; ynew];
        end
        updateCurve('Control');
    end

    function drop(src, ~)
        fig.Pointer = 'arrow';
        set(src, 'WindowButtonMotionFcn', origin_fig_func{1}, 'WindowButtonUpFcn', origin_fig_func{2});
    end

    function updateCurve(type)
        m = cbss{ccidx}.length();
        switch type
            case 'Knot'
                set(kpss{ccidx}(cpidx), 'XData', cbss{ccidx}.KnotPoints(1, cpidx), 'YData', cbss{ccidx}.KnotPoints(2, cpidx));
                if cpidx > 1
                    set(cpss{ccidx}(2 * cpidx - 2), 'XData', cbss{ccidx}.ControlPoints(1, 2 * cpidx - 2), ...
                        'YData', cbss{ccidx}.ControlPoints(2, 2 * cpidx - 2));
                    cpsls{ccidx}(2 * cpidx - 2).XData = [cbss{ccidx}.ControlPoints(1, 2 * cpidx - 2), cbss{ccidx}.KnotPoints(1, cpidx)];
                    cpsls{ccidx}(2 * cpidx - 2).YData = [cbss{ccidx}.ControlPoints(2, 2 * cpidx - 2), cbss{ccidx}.KnotPoints(2, cpidx)];
                end
                if cpidx < m
                    set(cpss{ccidx}(2 * cpidx - 1), 'XData', cbss{ccidx}.ControlPoints(1, 2 * cpidx - 1), ...
                        'YData', cbss{ccidx}.ControlPoints(2, 2 * cpidx - 1));
                    cpsls{ccidx}(2 * cpidx - 1).XData = [cbss{ccidx}.ControlPoints(1, 2 * cpidx - 1), cbss{ccidx}.KnotPoints(1, cpidx)];
                    cpsls{ccidx}(2 * cpidx - 1).YData = [cbss{ccidx}.ControlPoints(2, 2 * cpidx - 1), cbss{ccidx}.KnotPoints(2, cpidx)];
                end
            case 'Control'
                t = fix(cpidx / 2) + 1;
                set(cpss{ccidx}(cpidx), 'XData', cbss{ccidx}.ControlPoints(1, cpidx), 'YData', cbss{ccidx}.ControlPoints(2, cpidx));
                cpsls{ccidx}(cpidx).XData = [cbss{ccidx}.ControlPoints(1, cpidx), cbss{ccidx}.KnotPoints(1, t)];
                cpsls{ccidx}(cpidx).YData = [cbss{ccidx}.ControlPoints(2, cpidx), cbss{ccidx}.KnotPoints(2, t)];
                if cpidx > 1 && cpidx < 2 * cbss{ccidx}.length() - 2 && cbss{ccidx}.KnotsContinuity(t - 1)
                    corr_cp_idx = 4 * t - 3 - cpidx;
                    set(cpss{ccidx}(corr_cp_idx), 'XData', cbss{ccidx}.ControlPoints(1, corr_cp_idx), ...
                        'YData', cbss{ccidx}.ControlPoints(2, corr_cp_idx));
                    cpsls{ccidx}(corr_cp_idx).XData = [cbss{ccidx}.ControlPoints(1, corr_cp_idx), cbss{ccidx}.KnotPoints(1, t)];
                    cpsls{ccidx}(corr_cp_idx).YData = [cbss{ccidx}.ControlPoints(2, corr_cp_idx), cbss{ccidx}.KnotPoints(2, t)];
                end
        end
        t = linspace(0, 1, 100 * (m - 1) + 1);
        curr_spline_func = cbss{ccidx}.splineFunc();
        pos = curr_spline_func(t);
        curves(ccidx).XData = pos(1, :);
        curves(ccidx).YData = pos(2, :);
        
        curr_spline_normal_func = cbss{ccidx}.normalFunc();
        normal_pos = curr_spline_normal_func(t) / 50;
        corr_curve_pos = pos(:, 1:10:100 * (m - 1) + 1);
        corr_normal_pos = normal_pos(:, 1:10:100 * (m - 1) + 1);
        normal_pos = pos - normal_pos;
        corr_normal_pos = corr_curve_pos - corr_normal_pos;
        set(curvatures{ccidx}{1}, 'XData', normal_pos(1, :), 'YData', normal_pos(2, :));
        for t = 1:10 * (m - 1) + 1
            curvatures{ccidx}{2}(t).XData = [corr_curve_pos(1, t), corr_normal_pos(1, t)];
            curvatures{ccidx}{2}(t).YData = [corr_curve_pos(2, t), corr_normal_pos(2, t)];
        end
    end
end
