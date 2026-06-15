classdef ContactlessHRRRMonitoringApp < matlab.apps.AppBase
    % Healthcare-style GUI for radar-based respiration and heart-rate monitoring.
    % Run from MATLAB with:
    %   app = ContactlessHRRRMonitoringApp;

    properties (Access = public)
        UIFigure matlab.ui.Figure
        RootGrid matlab.ui.container.GridLayout
        HeaderPanel matlab.ui.container.Panel
        HeaderGrid matlab.ui.container.GridLayout
        TitleLabel matlab.ui.control.Label
        SubtitleLabel matlab.ui.control.Label
        CenterGrid matlab.ui.container.GridLayout
        RespirationPanel matlab.ui.container.Panel
        RespirationAxes matlab.ui.control.UIAxes
        HeartbeatPanel matlab.ui.container.Panel
        HeartbeatAxes matlab.ui.control.UIAxes
        BottomPanel matlab.ui.container.Panel
        BottomGrid matlab.ui.container.GridLayout
        RespRatePanel matlab.ui.container.Panel
        HeartRatePanel matlab.ui.container.Panel
        RespRateTitleLabel matlab.ui.control.Label
        HeartRateTitleLabel matlab.ui.control.Label
        RespRateValueLabel matlab.ui.control.Label
        HeartRateValueLabel matlab.ui.control.Label
        StatusLabel matlab.ui.control.Label
        LoadButton matlab.ui.control.Button
        ExportButton matlab.ui.control.Button
    end

    properties (Access = private)
        RadarData struct = struct()
        ProcessedData struct = struct()
        LoadedFile string = ""
        ExportedScriptPath string = ""
    end

    properties (Access = private, Constant)
        BG_COLOR = '#0B1F2A'
        PANEL_COLOR = '#102D3A'
        ACCENT_COLOR = '#00C2A8'
        SECONDARY_COLOR = '#4DA8FF'
        TEXT_COLOR = '#E6F1F5'
        MUTED_TEXT_COLOR = '#94B7C4'
        WARNING_COLOR = '#FF6B6B'
        RESP_COLOR = '#55D6FF'
        HEART_COLOR = '#FF6B6B'
    end

    methods (Access = public)
        function app = ContactlessHRRRMonitoringApp
            createComponents(app);
            styleAxes(app);
            setStatus(app, 'Ready to load radar data.', app.SECONDARY_COLOR);
            startupPlaceholderPlots(app);

            if nargout == 0
                clear app
            end
        end
    end

    methods (Access = private)
        function createComponents(app)
            app.UIFigure = uifigure( ...
                'Name', 'Contactless HR & RR Monitoring System', ...
                'Color', app.BG_COLOR, ...
                'Position', [120 120 1280 760], ...
                'AutoResizeChildren', 'off');

            app.RootGrid = uigridlayout(app.UIFigure, [3 1]);
            app.RootGrid.RowHeight = {90, '1x', 150};
            app.RootGrid.ColumnWidth = {'1x'};
            app.RootGrid.Padding = [20 20 20 20];
            app.RootGrid.RowSpacing = 18;
            app.RootGrid.BackgroundColor = app.BG_COLOR;

            app.HeaderPanel = uipanel(app.RootGrid, ...
                'BorderType', 'none', ...
                'BackgroundColor', app.PANEL_COLOR);
            app.HeaderPanel.Layout.Row = 1;
            app.HeaderPanel.Layout.Column = 1;

            app.HeaderGrid = uigridlayout(app.HeaderPanel, [2 1]);
            app.HeaderGrid.RowHeight = {42, 26};
            app.HeaderGrid.ColumnWidth = {'1x'};
            app.HeaderGrid.Padding = [22 12 22 10];
            app.HeaderGrid.BackgroundColor = app.PANEL_COLOR;

            app.TitleLabel = uilabel(app.HeaderGrid, ...
                'Text', 'Contactless HR & RR Monitoring System', ...
                'FontSize', 26, ...
                'FontWeight', 'bold', ...
                'FontColor', app.TEXT_COLOR, ...
                'HorizontalAlignment', 'center');
            app.TitleLabel.Layout.Row = 1;

            app.SubtitleLabel = uilabel(app.HeaderGrid, ...
                'Text', 'Radar-driven respiratory and cardiac waveform analytics for non-contact monitoring', ...
                'FontSize', 13, ...
                'FontColor', app.MUTED_TEXT_COLOR, ...
                'HorizontalAlignment', 'center');
            app.SubtitleLabel.Layout.Row = 2;

            app.CenterGrid = uigridlayout(app.RootGrid, [1 2]);
            app.CenterGrid.Layout.Row = 2;
            app.CenterGrid.ColumnWidth = {'1x', '1x'};
            app.CenterGrid.RowHeight = {'1x'};
            app.CenterGrid.ColumnSpacing = 18;
            app.CenterGrid.Padding = [0 0 0 0];
            app.CenterGrid.BackgroundColor = app.BG_COLOR;

            app.RespirationPanel = uipanel(app.CenterGrid, ...
                'Title', 'Respiration Waveform', ...
                'ForegroundColor', app.TEXT_COLOR, ...
                'FontWeight', 'bold', ...
                'BackgroundColor', app.PANEL_COLOR, ...
                'HighlightColor', app.SECONDARY_COLOR, ...
                'BorderType', 'line');
            app.RespirationPanel.Layout.Column = 1;

            app.RespirationAxes = uiaxes(app.RespirationPanel, ...
                'Position', [20 20 560 400], ...
                'Color', app.PANEL_COLOR, ...
                'XColor', app.TEXT_COLOR, ...
                'YColor', app.TEXT_COLOR, ...
                'GridColor', [0.45 0.65 0.72], ...
                'MinorGridColor', [0.20 0.35 0.42]);

            app.HeartbeatPanel = uipanel(app.CenterGrid, ...
                'Title', 'Heartbeat Waveform', ...
                'ForegroundColor', app.TEXT_COLOR, ...
                'FontWeight', 'bold', ...
                'BackgroundColor', app.PANEL_COLOR, ...
                'HighlightColor', app.SECONDARY_COLOR, ...
                'BorderType', 'line');
            app.HeartbeatPanel.Layout.Column = 2;

            app.HeartbeatAxes = uiaxes(app.HeartbeatPanel, ...
                'Position', [20 20 560 400], ...
                'Color', app.PANEL_COLOR, ...
                'XColor', app.TEXT_COLOR, ...
                'YColor', app.TEXT_COLOR, ...
                'GridColor', [0.45 0.65 0.72], ...
                'MinorGridColor', [0.20 0.35 0.42]);

            app.BottomPanel = uipanel(app.RootGrid, ...
                'BorderType', 'none', ...
                'BackgroundColor', app.BG_COLOR);
            app.BottomPanel.Layout.Row = 3;

            app.BottomGrid = uigridlayout(app.BottomPanel, [2 4]);
            app.BottomGrid.RowHeight = {'1x', 58};
            app.BottomGrid.ColumnWidth = {'1.35x', '1.35x', 190, 220};
            app.BottomGrid.ColumnSpacing = 18;
            app.BottomGrid.RowSpacing = 14;
            app.BottomGrid.Padding = [0 0 0 0];
            app.BottomGrid.BackgroundColor = app.BG_COLOR;

            app.RespRatePanel = uipanel(app.BottomGrid, ...
                'BackgroundColor', app.PANEL_COLOR, ...
                'BorderType', 'line', ...
                'HighlightColor', app.ACCENT_COLOR);
            app.RespRatePanel.Layout.Row = 1;
            app.RespRatePanel.Layout.Column = 1;

            respGrid = uigridlayout(app.RespRatePanel, [3 1]);
            respGrid.RowHeight = {22, 36, 18};
            respGrid.Padding = [20 10 20 10];
            respGrid.BackgroundColor = app.PANEL_COLOR;

            app.RespRateTitleLabel = uilabel(respGrid, ...
                'Text', 'Respiration Rate', ...
                'FontColor', app.MUTED_TEXT_COLOR, ...
                'FontSize', 13, ...
                'FontWeight', 'bold');
            app.RespRateTitleLabel.Layout.Row = 1;

            app.RespRateValueLabel = uilabel(respGrid, ...
                'Text', '-- bpm', ...
                'FontColor', app.TEXT_COLOR, ...
                'FontSize', 28, ...
                'FontWeight', 'bold', ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'center');
            app.RespRateValueLabel.Layout.Row = 2;

            respInfoLabel = uilabel(respGrid, ...
                'Text', 'Breaths per minute', ...
                'FontColor', app.MUTED_TEXT_COLOR, ...
                'FontSize', 11, ...
                'HorizontalAlignment', 'center');
            respInfoLabel.Layout.Row = 3;

            app.HeartRatePanel = uipanel(app.BottomGrid, ...
                'BackgroundColor', app.PANEL_COLOR, ...
                'BorderType', 'line', ...
                'HighlightColor', app.SECONDARY_COLOR);
            app.HeartRatePanel.Layout.Row = 1;
            app.HeartRatePanel.Layout.Column = 2;

            heartGrid = uigridlayout(app.HeartRatePanel, [3 1]);
            heartGrid.RowHeight = {22, 36, 18};
            heartGrid.Padding = [20 10 20 10];
            heartGrid.BackgroundColor = app.PANEL_COLOR;

            app.HeartRateTitleLabel = uilabel(heartGrid, ...
                'Text', 'Heart Rate', ...
                'FontColor', app.MUTED_TEXT_COLOR, ...
                'FontSize', 13, ...
                'FontWeight', 'bold');
            app.HeartRateTitleLabel.Layout.Row = 1;

            app.HeartRateValueLabel = uilabel(heartGrid, ...
                'Text', '-- bpm', ...
                'FontColor', app.TEXT_COLOR, ...
                'FontSize', 28, ...
                'FontWeight', 'bold', ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'center');
            app.HeartRateValueLabel.Layout.Row = 2;

            heartInfoLabel = uilabel(heartGrid, ...
                'Text', 'Beats per minute', ...
                'FontColor', app.MUTED_TEXT_COLOR, ...
                'FontSize', 11, ...
                'HorizontalAlignment', 'center');
            heartInfoLabel.Layout.Row = 3;

            app.StatusLabel = uilabel(app.BottomGrid, ...
                'Text', 'System status', ...
                'FontColor', app.MUTED_TEXT_COLOR, ...
                'FontSize', 12, ...
                'HorizontalAlignment', 'left');
            app.StatusLabel.Layout.Row = 1;
            app.StatusLabel.Layout.Column = 3;

            app.LoadButton = uibutton(app.BottomGrid, 'push', ...
                'Text', 'Load Data', ...
                'ButtonPushedFcn', @(src, event)onLoadData(app), ...
                'BackgroundColor', app.ACCENT_COLOR, ...
                'FontColor', app.BG_COLOR, ...
                'FontWeight', 'bold');
            app.LoadButton.Layout.Row = 2;
            app.LoadButton.Layout.Column = 3;

            app.ExportButton = uibutton(app.BottomGrid, 'push', ...
                'Text', 'Export MATLAB Script', ...
                'ButtonPushedFcn', @(src, event)exportScript(app), ...
                'BackgroundColor', app.SECONDARY_COLOR, ...
                'FontColor', app.BG_COLOR, ...
                'FontWeight', 'bold', ...
                'Enable', 'off');
            app.ExportButton.Layout.Row = 2;
            app.ExportButton.Layout.Column = 4;

            app.UIFigure.SizeChangedFcn = @(src, event)resizePlots(app);
        end

        function styleAxes(app)
            axesList = [app.RespirationAxes, app.HeartbeatAxes];

            for ax = axesList
                ax.FontSize = 12;
                ax.FontName = 'Segoe UI';
                ax.Box = 'on';
                ax.XGrid = 'on';
                ax.YGrid = 'on';
                ax.GridAlpha = 0.25;
                ax.LineWidth = 1;
                ax.Toolbar.Visible = 'off';
                xlabel(ax, 'Time (s)', 'Color', app.TEXT_COLOR);
                ylabel(ax, 'Amplitude', 'Color', app.TEXT_COLOR);
            end
        end

        function startupPlaceholderPlots(app)
            t = linspace(0, 20, 1200);
            respPlaceholder = 0.6 * sin(2*pi*0.25*t) .* exp(-0.02*t);
            heartPlaceholder = 0.15 * sin(2*pi*1.2*t) + 0.03 * randn(size(t));

            plot(app.RespirationAxes, t, respPlaceholder, 'LineWidth', 1.8, 'Color', app.RESP_COLOR);
            title(app.RespirationAxes, 'Awaiting radar input', 'Color', app.TEXT_COLOR);

            plot(app.HeartbeatAxes, t, heartPlaceholder, 'LineWidth', 1.2, 'Color', app.HEART_COLOR);
            title(app.HeartbeatAxes, 'Awaiting radar input', 'Color', app.TEXT_COLOR);
        end

        function resizePlots(app)
            panelPadding = 24;
            plotHeight = max(260, app.RespirationPanel.Position(4) - 48);
            plotWidthResp = max(260, app.RespirationPanel.Position(3) - 2 * panelPadding);
            plotWidthHeart = max(260, app.HeartbeatPanel.Position(3) - 2 * panelPadding);

            app.RespirationAxes.Position = [panelPadding 18 plotWidthResp plotHeight];
            app.HeartbeatAxes.Position = [panelPadding 18 plotWidthHeart plotHeight];
        end

        function onLoadData(app)
            [fileName, filePath] = uigetfile('*.mat', 'Select radar data file');
            if isequal(fileName, 0)
                setStatus(app, 'Load canceled. No file selected.', app.MUTED_TEXT_COLOR);
                return;
            end

            fullPath = fullfile(filePath, fileName);
            processLoadedFile(app, fullPath);
        end

        function processLoadedFile(app, fullPath)
            app.toggleBusyState(true, 'Loading and processing radar data...');
            dlg = uiprogressdlg(app.UIFigure, ...
                'Title', 'Processing Radar Data', ...
                'Message', 'Loading file and extracting physiological waveforms...', ...
                'Indeterminate', 'on', ...
                'Cancelable', 'off');

            cleanupObj = onCleanup(@()deleteValidDialog(dlg));
            finalStatusMessage = 'Ready';
            finalStatusColor = app.MUTED_TEXT_COLOR;

            try
                drawnow;
                app.RadarData = loadData(app, fullPath);
                app.ProcessedData = runProcessingPipeline(app, app.RadarData);
                app.LoadedFile = string(fullPath);
                app.updatePlotsAndMetrics();
                app.ExportButton.Enable = 'on';
                [~, baseName, ext] = fileparts(fullPath);
                finalStatusMessage = sprintf('Processed %s%s successfully.', baseName, ext);
                finalStatusColor = app.ACCENT_COLOR;
            catch ME
                app.ProcessedData = struct();
                app.ExportButton.Enable = 'off';
                startupPlaceholderPlots(app);
                app.RespRateValueLabel.Text = '-- bpm';
                app.HeartRateValueLabel.Text = '-- bpm';
                finalStatusMessage = ME.message;
                finalStatusColor = app.WARNING_COLOR;
                uialert(app.UIFigure, ME.message, 'Processing Error', 'Icon', 'error');
            end

            clear cleanupObj
            app.toggleBusyState(false, finalStatusMessage, finalStatusColor);
        end

        function radarData = loadData(app, fullPath)
            %#ok<INUSD>
            rawData = load(fullPath);
            [radarI, radarQ] = app.extractRadarSignals(rawData);
            sampleRate = app.extractSampleRate(rawData);
            t = (0:numel(radarI)-1) ./ sampleRate;

            radarData = struct( ...
                'filePath', string(fullPath), ...
                'raw', rawData, ...
                'radar_i', radarI(:), ...
                'radar_q', radarQ(:), ...
                'Fs', sampleRate, ...
                't', t(:));
        end

        function processed = runProcessingPipeline(app, radarData)
            phase = unwrap(atan2(radarData.radar_q, radarData.radar_i));
            phaseDetrended = detrend(filloutliers(phase, 'linear', 'movmedian', 25));

            fc = 24e9;
            c = 3e8;
            lambda = c / fc;
            displacement = (lambda / (4*pi)) * phaseDetrended;

            respSignal = processRespiration(app, displacement, radarData.Fs);
            heartSignal = processHeartbeat(app, displacement, radarData.Fs);
            [rr, hr, respMeta, heartMeta] = computeRates(app, respSignal, heartSignal, radarData.Fs);

            processed = struct( ...
                'phase', phase, ...
                'phaseDetrended', phaseDetrended, ...
                'displacement', displacement, ...
                'respiration', respSignal, ...
                'heartbeat', heartSignal, ...
                'respirationRate', rr, ...
                'heartRate', hr, ...
                'respirationMeta', respMeta, ...
                'heartbeatMeta', heartMeta);
        end

        function respSignal = processRespiration(app, displacement, Fs)
            %#ok<INUSD>
            respFilter = designfilt('bandpassiir', ...
                'FilterOrder', 4, ...
                'HalfPowerFrequency1', 0.1, ...
                'HalfPowerFrequency2', 0.5, ...
                'SampleRate', Fs);

            filtered = filtfilt(respFilter, displacement);
            respSignal = smoothdata(filtered, 'movmean', max(5, round(Fs * 0.2)));
        end

        function heartSignal = processHeartbeat(app, displacement, Fs)
            %#ok<INUSD>
            heartFilter = designfilt('bandpassiir', ...
                'FilterOrder', 4, ...
                'HalfPowerFrequency1', 0.8, ...
                'HalfPowerFrequency2', 2.5, ...
                'SampleRate', Fs);

            filtered = filtfilt(heartFilter, displacement);
            sgolayWindow = max(7, 2 * floor(Fs * 0.08 / 2) + 1);
            heartSignal = smoothdata(filtered, 'sgolay', sgolayWindow);
        end

        function [respRate, heartRate, respMeta, heartMeta] = computeRates(app, respSignal, heartSignal, Fs)
            %#ok<INUSD>
            [respRate, respMeta] = estimateRate(respSignal, Fs, [0.1 0.5], round(Fs * 1.8));
            [heartRate, heartMeta] = estimateRate(heartSignal, Fs, [0.8 2.5], round(Fs * 0.35));
        end

        function updatePlotsAndMetrics(app)
            t = app.RadarData.t;
            respSignal = app.ProcessedData.respiration;
            heartSignal = app.ProcessedData.heartbeat;

            cla(app.RespirationAxes);
            cla(app.HeartbeatAxes);

            plot(app.RespirationAxes, t, respSignal, 'LineWidth', 1.8, 'Color', app.RESP_COLOR);
            title(app.RespirationAxes, 'Respiration Waveform', 'Color', app.TEXT_COLOR);
            hold(app.RespirationAxes, 'on');
            if ~isempty(app.ProcessedData.respirationMeta.peakLocs)
                plot(app.RespirationAxes, ...
                    t(app.ProcessedData.respirationMeta.peakLocs), ...
                    respSignal(app.ProcessedData.respirationMeta.peakLocs), ...
                    'o', 'MarkerSize', 5, 'MarkerEdgeColor', app.ACCENT_COLOR, ...
                    'MarkerFaceColor', app.ACCENT_COLOR);
            end
            hold(app.RespirationAxes, 'off');

            plot(app.HeartbeatAxes, t, heartSignal, 'LineWidth', 1.3, 'Color', app.HEART_COLOR);
            title(app.HeartbeatAxes, 'Heartbeat Waveform', 'Color', app.TEXT_COLOR);
            hold(app.HeartbeatAxes, 'on');
            if ~isempty(app.ProcessedData.heartbeatMeta.peakLocs)
                plot(app.HeartbeatAxes, ...
                    t(app.ProcessedData.heartbeatMeta.peakLocs), ...
                    heartSignal(app.ProcessedData.heartbeatMeta.peakLocs), ...
                    'o', 'MarkerSize', 4, 'MarkerEdgeColor', app.SECONDARY_COLOR, ...
                    'MarkerFaceColor', app.SECONDARY_COLOR);
            end
            hold(app.HeartbeatAxes, 'off');

            app.RespRateValueLabel.Text = sprintf('%.1f bpm', app.ProcessedData.respirationRate);
            app.HeartRateValueLabel.Text = sprintf('%.1f bpm', app.ProcessedData.heartRate);
            drawnow;
        end

        function exportScript(app)
            if isempty(fieldnames(app.ProcessedData))
                uialert(app.UIFigure, 'Load and process radar data before exporting a script.', ...
                    'Export Unavailable', 'Icon', 'warning');
                return;
            end

            defaultName = 'exported_radar_vitals_pipeline.m';
            [fileName, filePath] = uiputfile('*.m', 'Save MATLAB Script', defaultName);
            if isequal(fileName, 0)
                setStatus(app, 'Export canceled. Script not saved.', app.MUTED_TEXT_COLOR);
                return;
            end

            app.toggleBusyState(true, 'Exporting MATLAB script...');
            finalStatusMessage = 'Ready';
            finalStatusColor = app.MUTED_TEXT_COLOR;

            try
                scriptText = app.buildExportScriptText();
                fullExportPath = fullfile(filePath, fileName);
                fid = fopen(fullExportPath, 'w');
                if fid == -1
                    error('Unable to create the selected MATLAB script file.');
                end

                cleanupFile = onCleanup(@()fclose(fid));
                fprintf(fid, '%s', scriptText);
                clear cleanupFile

                app.ExportedScriptPath = string(fullExportPath);
                finalStatusMessage = sprintf('Script exported to %s', fullExportPath);
                finalStatusColor = app.ACCENT_COLOR;
            catch ME
                finalStatusMessage = ME.message;
                finalStatusColor = app.WARNING_COLOR;
                uialert(app.UIFigure, ME.message, 'Export Error', 'Icon', 'error');
            end

            app.toggleBusyState(false, finalStatusMessage, finalStatusColor);
        end

        function scriptText = buildExportScriptText(app)
            escapedPath = strrep(char(app.LoadedFile), '''', '''''');
            scriptLines = {
                '%% Exported radar vital-sign monitoring pipeline'
                '% Generated by ContactlessHRRRMonitoringApp'
                ''
                'clc; close all;'
                sprintf('dataFile = ''%s'';', escapedPath)
                'rawData = load(dataFile);'
                ''
                '% Resolve radar channels from common variable names.'
                '[radar_i, radar_q] = localExtractRadarSignals(rawData);'
                'Fs = localExtractSampleRate(rawData);'
                't = (0:numel(radar_i)-1) ./ Fs;'
                ''
                '% Phase extraction and detrending.'
                'phase = unwrap(atan2(radar_q, radar_i));'
                'phaseDetrended = detrend(filloutliers(phase, ''linear'', ''movmedian'', 25));'
                ''
                '% Convert phase to chest displacement.'
                'fc = 24e9;'
                'c = 3e8;'
                'lambda = c / fc;'
                'displacement = (lambda / (4*pi)) * phaseDetrended;'
                ''
                '% Respiration processing.'
                'respFilter = designfilt(''bandpassiir'', ''FilterOrder'', 4, ...'
                '    ''HalfPowerFrequency1'', 0.1, ''HalfPowerFrequency2'', 0.5, ''SampleRate'', Fs);'
                'respSignal = filtfilt(respFilter, displacement);'
                'respSignal = smoothdata(respSignal, ''movmean'', max(5, round(Fs * 0.2)));'
                ''
                '% Heartbeat processing.'
                'heartFilter = designfilt(''bandpassiir'', ''FilterOrder'', 4, ...'
                '    ''HalfPowerFrequency1'', 0.8, ''HalfPowerFrequency2'', 2.5, ''SampleRate'', Fs);'
                'heartSignal = filtfilt(heartFilter, displacement);'
                'heartSignal = smoothdata(heartSignal, ''sgolay'', max(7, 2 * floor(Fs * 0.08 / 2) + 1));'
                ''
                '% Rate estimation using peak detection with FFT fallback.'
                '[respRate, respMeta] = localEstimateRate(respSignal, Fs, [0.1 0.5], round(Fs * 1.8));'
                '[heartRate, heartMeta] = localEstimateRate(heartSignal, Fs, [0.8 2.5], round(Fs * 0.35));'
                ''
                '% Visualization.'
                'figure(''Name'', ''Exported Contactless HR & RR Analysis'', ''Color'', [0.043 0.122 0.165]);'
                'tiledlayout(1, 2, ''Padding'', ''compact'', ''TileSpacing'', ''compact'');'
                ''
                'nexttile;'
                'plot(t, respSignal, ''Color'', [0.333 0.839 1.0], ''LineWidth'', 1.6); hold on;'
                'if ~isempty(respMeta.peakLocs)'
                '    plot(t(respMeta.peakLocs), respSignal(respMeta.peakLocs), ''o'', ''Color'', [0 0.761 0.659], ''MarkerFaceColor'', [0 0.761 0.659]);'
                'end'
                'title(sprintf(''Respiration Waveform | RR = %.1f bpm'', respRate), ''Color'', [0.902 0.945 0.961]);'
                'xlabel(''Time (s)''); ylabel(''Amplitude''); grid on;'
                'set(gca, ''Color'', [0.063 0.176 0.227], ''XColor'', [0.902 0.945 0.961], ''YColor'', [0.902 0.945 0.961]);'
                ''
                'nexttile;'
                'plot(t, heartSignal, ''Color'', [1.0 0.42 0.42], ''LineWidth'', 1.1); hold on;'
                'if ~isempty(heartMeta.peakLocs)'
                '    plot(t(heartMeta.peakLocs), heartSignal(heartMeta.peakLocs), ''o'', ''Color'', [0.302 0.659 1.0], ''MarkerFaceColor'', [0.302 0.659 1.0]);'
                'end'
                'title(sprintf(''Heartbeat Waveform | HR = %.1f bpm'', heartRate), ''Color'', [0.902 0.945 0.961]);'
                'xlabel(''Time (s)''); ylabel(''Amplitude''); grid on;'
                'set(gca, ''Color'', [0.063 0.176 0.227], ''XColor'', [0.902 0.945 0.961], ''YColor'', [0.902 0.945 0.961]);'
                ''
                'fprintf(''Respiration Rate: %.1f bpm\n'', respRate);'
                'fprintf(''Heart Rate: %.1f bpm\n'', heartRate);'
                ''
                'function [radar_i, radar_q] = localExtractRadarSignals(rawData)'
                'fields = fieldnames(rawData);'
                'radar_i = []; radar_q = [];'
                'preferredI = {''radar_i'', ''I'', ''i'', ''inphase'', ''in_phase''};'
                'preferredQ = {''radar_q'', ''Q'', ''q'', ''quadrature'', ''quad''};'
                'for idx = 1:numel(preferredI)'
                '    if isfield(rawData, preferredI{idx}), radar_i = rawData.(preferredI{idx}); break; end'
                'end'
                'for idx = 1:numel(preferredQ)'
                '    if isfield(rawData, preferredQ{idx}), radar_q = rawData.(preferredQ{idx}); break; end'
                'end'
                'if isempty(radar_i) || isempty(radar_q)'
                '    numericVectors = {};'
                '    for k = 1:numel(fields)'
                '        value = rawData.(fields{k});'
                '        if isnumeric(value) && isvector(value) && numel(value) > 128'
                '            numericVectors{end+1} = value; %#ok<AGROW>'
                '        end'
                '    end'
                '    if numel(numericVectors) < 2'
                '        error(''Unable to identify radar I/Q channels in the selected MAT file.'');'
                '    end'
                '    radar_i = numericVectors{1};'
                '    radar_q = numericVectors{2};'
                'end'
                'radar_i = radar_i(:); radar_q = radar_q(:);'
                'if numel(radar_i) ~= numel(radar_q)'
                '    error(''Radar I and Q channels must have the same length.'');'
                'end'
                'end'
                ''
                'function Fs = localExtractSampleRate(rawData)'
                'preferredFs = {''Fs'', ''fs'', ''fs_radar'', ''sampleRate'', ''sampling_frequency''};'
                'Fs = [];'
                'for idx = 1:numel(preferredFs)'
                '    if isfield(rawData, preferredFs{idx})'
                '        Fs = rawData.(preferredFs{idx});'
                '        break;'
                '    end'
                'end'
                'if isempty(Fs), Fs = 100; end'
                'Fs = double(Fs(1));'
                'end'
                ''
                'function [rateBpm, meta] = localEstimateRate(signal, Fs, freqBand, minPeakDistance)'
                'signal = signal(:);'
                'minPeakDistance = max(1, minPeakDistance);'
                'peakThreshold = mean(signal) + 0.2 * std(signal);'
                '[peakValues, peakLocs] = findpeaks(signal, ''MinPeakDistance'', minPeakDistance, ''MinPeakHeight'', peakThreshold);'
                'durationSeconds = numel(signal) / Fs;'
                'rateFromPeaks = numel(peakLocs) * 60 / max(durationSeconds, eps);'
                '[pxx, f] = periodogram(signal, [], max(256, 2^nextpow2(numel(signal))), Fs);'
                'bandMask = f >= freqBand(1) & f <= freqBand(2);'
                'if any(bandMask)'
                '    [~, maxIdx] = max(pxx(bandMask));'
                '    bandFreqs = f(bandMask);'
                '    rateFromFFT = bandFreqs(maxIdx) * 60;'
                'else'
                '    rateFromFFT = rateFromPeaks;'
                'end'
                'if numel(peakLocs) >= 2 && isfinite(rateFromPeaks) && rateFromPeaks > 0'
                '    rateBpm = rateFromPeaks;'
                'else'
                '    rateBpm = rateFromFFT;'
                'end'
                'meta = struct(''peakLocs'', peakLocs, ''peakValues'', peakValues, ''fftRate'', rateFromFFT);'
                'end'
            };

            scriptText = strjoin(scriptLines, newline);
        end

        function [radarI, radarQ] = extractRadarSignals(app, rawData)
            %#ok<INUSD>
            radarI = [];
            radarQ = [];

            preferredI = {'radar_i', 'I', 'i', 'inphase', 'in_phase'};
            preferredQ = {'radar_q', 'Q', 'q', 'quadrature', 'quad'};

            for idx = 1:numel(preferredI)
                if isfield(rawData, preferredI{idx})
                    radarI = rawData.(preferredI{idx});
                    break;
                end
            end

            for idx = 1:numel(preferredQ)
                if isfield(rawData, preferredQ{idx})
                    radarQ = rawData.(preferredQ{idx});
                    break;
                end
            end

            if isempty(radarI) || isempty(radarQ)
                numericVectors = {};
                fields = fieldnames(rawData);
                for k = 1:numel(fields)
                    value = rawData.(fields{k});
                    if isnumeric(value) && isvector(value) && numel(value) > 128
                        numericVectors{end+1} = value; %#ok<AGROW>
                    end
                end

                if numel(numericVectors) < 2
                    error(['Unable to identify radar I/Q channels. The MAT file should contain ', ...
                           '`radar_i` and `radar_q` (or equivalent vector variables).']);
                end

                radarI = numericVectors{1};
                radarQ = numericVectors{2};
            end

            radarI = radarI(:);
            radarQ = radarQ(:);

            if numel(radarI) ~= numel(radarQ)
                error('Radar I and Q channels must have the same number of samples.');
            end
        end

        function Fs = extractSampleRate(app, rawData)
            %#ok<INUSD>
            preferredFs = {'Fs', 'fs', 'fs_radar', 'sampleRate', 'sampling_frequency'};
            Fs = [];

            for idx = 1:numel(preferredFs)
                if isfield(rawData, preferredFs{idx})
                    Fs = rawData.(preferredFs{idx});
                    break;
                end
            end

            if isempty(Fs)
                Fs = 100;
            end

            Fs = double(Fs(1));
            if ~isfinite(Fs) || Fs <= 0
                error('A valid sampling rate could not be determined from the MAT file.');
            end
        end

        function toggleBusyState(app, isBusy, statusMessage, statusColor)
            if nargin < 4
                statusColor = app.MUTED_TEXT_COLOR;
            end

            if isBusy
                app.LoadButton.Enable = 'off';
                app.ExportButton.Enable = 'off';
                app.UIFigure.Pointer = 'watch';
                setStatus(app, statusMessage, app.SECONDARY_COLOR);
            else
            
                app.LoadButton.Enable = 'on';
                if ~isempty(fieldnames(app.ProcessedData))
                    app.ExportButton.Enable = 'on';
                end
                app.UIFigure.Pointer = 'arrow';
                setStatus(app, statusMessage, statusColor);
            end
            drawnow;
        end

        function setStatus(app, message, colorValue)
            app.StatusLabel.Text = message;
            app.StatusLabel.FontColor = colorValue;
        end
    end
end

function [rateBpm, meta] = estimateRate(signal, Fs, freqBand, minPeakDistance)
signal = signal(:);
minPeakDistance = max(1, round(minPeakDistance));

peakThreshold = mean(signal, 'omitnan') + 0.20 * std(signal, 'omitnan');
[peakValues, peakLocs] = findpeaks(signal, ...
    'MinPeakDistance', minPeakDistance, ...
    'MinPeakHeight', peakThreshold);

durationSeconds = numel(signal) / Fs;
rateFromPeaks = numel(peakLocs) * 60 / max(durationSeconds, eps);

nfft = max(256, 2^nextpow2(numel(signal)));
[pxx, f] = periodogram(signal, [], nfft, Fs);
bandMask = f >= freqBand(1) & f <= freqBand(2);

if any(bandMask)
    [~, idx] = max(pxx(bandMask));
    bandFreqs = f(bandMask);
    rateFromFFT = bandFreqs(idx) * 60;
else
    rateFromFFT = rateFromPeaks;
end

if numel(peakLocs) >= 2 && isfinite(rateFromPeaks) && rateFromPeaks > 0
    rateBpm = rateFromPeaks;
else
    rateBpm = rateFromFFT;
end

meta = struct( ...
    'peakLocs', peakLocs, ...
    'peakValues', peakValues, ...
    'fftRate', rateFromFFT);
end

function deleteValidDialog(dlg)
if ~isempty(dlg) && isvalid(dlg)
    close(dlg);
end
end
