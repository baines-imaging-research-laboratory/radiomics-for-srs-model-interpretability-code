Experiment.StartNewSection('Analysis');

[vdTimeToProgressionPerSample_days, vdTimeToCensorPerSample_days] = FileIOUtils.LoadMatFile(...
    fullfile(ExperimentManager.GetPathToExperimentAssetResultsDirectory('AYS-105-002-100'), '01 Analysis', 'Time to Progression and Censor.mat'),...
    'vdTimeToProgressionPerSample_days', 'vdTimeToCensorPerSample_days');

dRankSumPValue = 0.0003;

vdRPAGroupPerSample = FileIOUtils.LoadMatFile(...
    fullfile(ExperimentManager.GetPathToExperimentAssetResultsDirectory('AYS-105-003-102'), '01 Analysis', 'RPA Groups.mat'),...
    'm2dRPAGroupPerSample');

hFig = PerformKMAnalysis(vdRPAGroupPerSample, vdTimeToProgressionPerSample_days, vdTimeToCensorPerSample_days, dRankSumPValue);

savefig(hFig, fullfile(Experiment.GetResultsDirectory(), "KM Plot.fig"));
saveas(hFig, fullfile(Experiment.GetResultsDirectory(), "KM Plot.svg"));
delete(hFig);






function hFig = PerformKMAnalysis(vdRPAGroupPerSample, vdTimeToProgressionPerSample_days, vdTimeToCensorPerSample_days, dRankSumPValue)

vdSize_cm = [17.5/2 6]; % width height
dFontSize = 8;
chFont = 'Arial';

hFig = figure();

hFig.Units = 'centimeters';

vdPosition = hFig.Position;
vdPosition(3:4) = vdSize_cm;
hFig.Position = vdPosition;

hFig.Units = 'pixels';


hold('on');

vdXTicks = 0:3:18;

m2dNumberAtRiskPerRPAGroupPerTick = zeros(4, length(vdXTicks));

vsLineStylePerGroup = ["-." "-" "-." "-"];
vdLineThickness = [1.1 1 2 2];

c1hKMPlots = cell(4,1);

for dGroup = 1:4
    vdTimeToProgression = vdTimeToProgressionPerSample_days(vdRPAGroupPerSample == dGroup);
    vdTimeToCensor = vdTimeToCensorPerSample_days(vdRPAGroupPerSample == dGroup);
    
    vdTimeToCensor(vdTimeToProgression ~= 0) = [];
    vdTimeToProgression(vdTimeToProgression == 0) = [];
    
    [v_f,v_x] = ecdf([vdTimeToCensor; vdTimeToProgression], 'censoring', [true(size(vdTimeToCensor)); false(size(vdTimeToProgression))]);
    
    c1hKMPlots{dGroup} = stairs([(v_x*12/365);18],100*[v_f;v_f(end)], 'LineWidth', vdLineThickness(dGroup), 'LineStyle', vsLineStylePerGroup(dGroup), 'Color', 'k');
    
    vdTimeToEvent_months = [vdTimeToCensor; vdTimeToProgression]*12/365;
    
    for dTickIndex=1:length(vdXTicks)
        m2dNumberAtRiskPerRPAGroupPerTick(dGroup,dTickIndex) = sum(vdTimeToEvent_months >= vdXTicks(dTickIndex));
    end
end

hAxes = gca;

hAxes.FontName = 'Arial';
hAxes.FontSize = 8;

xlabel('Time to Progression (months)');
ylabel('Progressive Disease (%)');

xlim([0, 18]);
ylim([0, 60]);

hAxes.YAxis.MinorTickValues = 5:10:55;

xticks(vdXTicks);
yticks(0:10:60);

grid('on');
hAxes.YMinorGrid = 'on';
hAxes.YMinorTick = 'on';

hAxes.Units = 'points';
hAxes.Position = [35 70 200 95];

vdTextYPositionsPerGroup = [-18 -23 -28 -33];

hAxes.Clipping = 'off';

for dGroupIndex=1:4
    line(hAxes, [-1 -2.6], [vdTextYPositionsPerGroup(dGroupIndex) vdTextYPositionsPerGroup(dGroupIndex)],...
        'LineWidth', vdLineThickness(dGroupIndex), 'LineStyle', vsLineStylePerGroup(dGroupIndex), 'Color', 'k');
    
    for dXTickIndex=1:length(vdXTicks)
        text(vdXTicks(dXTickIndex), vdTextYPositionsPerGroup(dGroupIndex), string(m2dNumberAtRiskPerRPAGroupPerTick(dGroupIndex, dXTickIndex)),...
            'FontName', 'Arial', 'FontSize', 8, 'HorizontalAlignment', 'center');
    end
end

text(hAxes, 9, -40, "Brain Metastases at Risk", 'FontName', 'Arial', 'FontSize', 8.8, 'HorizontalAlignment', 'center');

hAxes.YLabel.Position = [-1.4, 27.5, -1];

if dRankSumPValue < 0.0001
    sPValueString = "p < 0.0001";
else
    sPValueString = "p = " + string(round(dRankSumPValue, 4));
end


text(hAxes, 0.75, 52.5, sPValueString, 'FontName', 'Arial', 'FontSize', 8.8, 'HorizontalAlignment', 'left', 'FontWeight', 'bold');

end