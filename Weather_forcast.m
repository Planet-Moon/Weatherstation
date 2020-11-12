%% Read Data from Remote Target
%remotecopy -local . -from -remote ~/Wetterlog/Wetterlog.csv

%% Import Data from CSV
opts = delimitedTextImportOptions("NumVariables", 11);

% Specify range and delimiter
opts.DataLines = [1, Inf];
opts.Delimiter = ";";

% Specify column names and types
opts.VariableNames = ["Year", "Month", "Day", "Hour", "Minute", "Second", "RelativeHumidity", "Temperature", "AtmosphericPressure","UP", "bmp_temperature", "Lightintensity"];
opts.VariableTypes = ["double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Import the data
%Wetterlog = readtable(".\Wetterlog.csv", opts)
%clear opts

%% Read all *.csv files in directory
clear Wetterlog
ds = tabularTextDatastore(".",'FileExtensions','.csv');
for i = 1:length(ds.Files)
    csvData = readtable(string(ds.Files(i)),opts);
    disp(string(ds.Files(i)))
    if isnan(csvData.Year(1))
        csvData(1,:) = [];
    end
    if i == 1
        Wetterlog = csvData;
    else
        Wetterlog = [Wetterlog; csvData];
    end
end
clear opts csvData i

%% Convert Date-String to Date-Type in Matlab
if isnan(Wetterlog.Year(1))
    disp("nan detected")
    Wetterlog(1,:) = [];
end
%Wetterlog;

Datum = NaT(size(Wetterlog,1),1);
Datum(:,:) = datetime(Wetterlog.Year,...
        Wetterlog.Month,...
        Wetterlog.Day,...
        Wetterlog.Hour+1,...
        Wetterlog.Minute,...
        Wetterlog.Second);
disp("Last measurement at " + datestr(Datum(end)))

%% Plot Data from Sensors
delete_entries = find(Wetterlog.AtmosphericPressure>120000);
delete_entries = [delete_entries,find(Wetterlog.RelativeHumidity<10)];
Wetterlog(delete_entries,:) = [];
Datum(delete_entries) = [];
Wetterlog.Lightintensity = Wetterlog.Lightintensity*100/409.6;

figure
sub1 = subplot(6,1,1);
plot(Datum,Wetterlog.RelativeHumidity)
title("Humidity")
ylabel("RH %")
sub2 = subplot(6,1,2);
plot(Datum,Wetterlog.Temperature)
title("Temperature")
ylabel("°C")
sub3 = subplot(6,1,3);
plot(Datum,Wetterlog.AtmosphericPressure)
title("AtmospericPressure")
ylabel("Pa")
sub4 = subplot(6,1,4);
plot(Datum,Wetterlog.UP)
title("UP")
sub5 = subplot(6,1,5);
plot(Datum,Wetterlog.bmp_temperature)
title("bmp\_temperature")
ylabel("°C")
sub6 = subplot(6,1,6);
plot(Datum,Wetterlog.Lightintensity)
title("Lightintensity")
ylabel("%")

linkaxes([sub1,sub2,sub3,sub4,sub5,sub6],"x");
%%
figure
sub1 = subplot(4,1,1);
plot(Datum,Wetterlog.RelativeHumidity)
title("Humidity")
ylabel("RH %")
datetick('x','dd.mm.yy')
%xticks(Datum(1):caldays(1):Datum(end))
xlim([Datum(1) Datum(end)])
ylim([min(Wetterlog.RelativeHumidity) max(Wetterlog.RelativeHumidity)])
sub2 = subplot(4,1,2);
hold on
plot(Datum,Wetterlog.Temperature)
% [TemperaturMittel,std] = Mittelwertfilter((Wetterlog.Temperature.'),3600*12);
% plot(Datum,TemperaturMittel.')
hold off
title("Temperature")
ylabel("°C")
xlim([Datum(1) Datum(end)])
ylim([min(Wetterlog.Temperature) max(Wetterlog.Temperature)])
sub3 = subplot(4,1,3);
plot(Datum,Wetterlog.AtmosphericPressure)
title("AtmospericPressure")
ylabel("Pa")
xlim([Datum(1) Datum(end)])
ylim([min(Wetterlog.AtmosphericPressure) max(Wetterlog.AtmosphericPressure)])
sub4 = subplot(4,1,4);
plot(Datum,Wetterlog.Lightintensity)
title("Lightintensity")
ylabel("%")
xlim([Datum(1) Datum(end)])
ylim([min(Wetterlog.Lightintensity) max(Wetterlog.Lightintensity)])

linkaxes([sub1,sub2,sub3,sub4],"x");

% test.UT = 27898;
% test.UP = 23843;
% test.oss = 0;
% [T,P] = calc_pressure(test.UT,test.UP,test.oss);

% [T,P] = calc_pressure(Wetterlog.bmp_temperature,Wetterlog.UP,3);
% [P] = calc_pressure_T_UP(Wetterlog.bmp_temperature,Wetterlog.UP,3);
% T = Wetterlog.bmp_temperature;

%[P,~] = Mittelwertfilter(P.',floor(length(P)/16));
% % P = P.';
%%
figure
sub1 = subplot(2,1,1);
hold on
plot(Datum,Wetterlog.AtmosphericPressure)
% plot(Datum,P)
hold off
legend("\muC","Matlab")
title("Luftdruck")
sub2 = subplot(2,1,2);
hold on
plot(Datum,Wetterlog.Temperature)
% plot(Datum,T)
hold off
title("Temperatur")
legend("Si","BMP")

linkaxes([sub1,sub2],"x");

%% Calculate means
clear values values_mean

values = {};
value_pos = [7,8,9,12];

figure
hold on
for i = min(year(Datum)):max(year(Datum))
    year_pos{i} = find(year(Datum)==i);
    for j = 1:4
        values.Year{i,j} = Wetterlog(year_pos{i},value_pos(j));
        values_mean.Year(i,j) = mean(values.Year{i,j}.Variables);
    end
    plot(Datum(year_pos{i}),Wetterlog.Lightintensity(year_pos{i}))
end
hold off
title("Year")

figure
hold on
for i = 1:12
    month_pos{i} = find(month(Datum)==i);
    for j = 1:4
        values.Month{i,j} = Wetterlog(month_pos{i},value_pos(j));
        values_mean.Month(i,j) = mean(values.Month{i,j}.Variables);
    end
    plot(Datum(month_pos{i}),Wetterlog.Lightintensity(month_pos{i}))
end
hold off
title("Month")

figure
hold on
for i = 1:52
    week_pos{i} = find(week(Datum)==i);
    for j = 1:4
        values.Week{i,j} = Wetterlog(week_pos{i},value_pos(j));
        values_mean.Week(i,j) = mean(values.Week{i,j}.Variables);
    end
    plot(Datum(week_pos{i}),Wetterlog.Lightintensity(week_pos{i}))
end
hold off
title("Week")

figure
hold on
for i = 1:31
    day_pos{i} = find(day(Datum)==i);
    for j = 1:4
        values.Day{i,j} = Wetterlog(day_pos{i},value_pos(j));
        values_mean.Day(i,j) = mean(values.Day{i,j}.Variables);
    end
    plot(Datum(day_pos{i}),Wetterlog.Lightintensity(day_pos{i}))
end
hold off
title("Day")

figure
hold on
for i = 1:24
    hour_pos{i} = find(hour(Datum)==i-1);
    for j = 1:4
        values.Hour{i,j} = Wetterlog(hour_pos{i},value_pos(j));
        values_mean.Hour(i,j) = mean(values.Hour{i,j}.Variables);
    end
    plot(Datum(hour_pos{i}),Wetterlog.Lightintensity(hour_pos{i}))
end
hold off
legend_array = ["0h","1h","2h","3h","4h","5h","6h","7h","8h","9h","10h","11h","12h",...
    "13h","14h","15h","16h","17h","18h","19h","20h","21h","22hh","23h"];
%legend(legend_array)
title("Hour")


% figure
% hold on
% for i = 1:60
%     minute_pos{i} = find(minute(Datum)==i-1);
%     for j = 1:4
%         values.Minute{i,j} = Wetterlog(minute_pos{i},value_pos(j));
%         values_mean.Minute(i,j) = mean(values.Minute{i,j}.Variables);
%     end
%     plot(Datum(minute_pos{i}),Wetterlog.Lightintensity(minute_pos{i}))
% end
% hold off
% title("Minute")

%% Plot means
x_labels = ["RH (%)","T (°C)","P (hPa)","LI (%)"];

figure
for i = 1:4
    subplot(4,1,i)
    plot(values_mean.Month(:,i),"-x")
    ylabel(x_labels(i))
    if i == 1
        title("Mean Month")
    end
end

figure
for i = 1:4
    subplot(4,1,i)
    plot(values_mean.Week(:,i),"-x")
    ylabel(x_labels(i))
    if i == 1
        title("Mean Week")
    end
end

figure
for i = 1:4
    subplot(4,1,i)
    plot(values_mean.Day(:,i),"-x")
    ylabel(x_labels(i))
    if i == 1
        title("Mean Day")
    end
end

figure
for i = 1:4
    subplot(4,1,i)
    plot(values_mean.Hour(:,i),"-x")
    ylabel(x_labels(i))
    if i == 1
        title("Mean Hour")
    end
end

% figure
% for i = 1:4
%     subplot(4,1,i)
%     plot(values_mean.Minute(:,i),"-x")
%     ylabel(x_labels(i))
%     if i == 1
%         title("Minute")
%     end
% end


%% Calculate Daywise Standarddeviation
for i = 1:31
    day_pos{i} = find(day(Datum)==i);
    for j = 1:4
        values.Day{i,j} = Wetterlog(day_pos{i},value_pos(j));
        values_std.Day(i,j) = std(values.Day{i,j}.Variables);
    end    
end

%% Features of an average day
for i = 1:4
    mean_std.Day(i) = std(values_mean.Hour(:,i)); % Standardabweichung
end

%% Plot Daywise Standarddeviation
figure
for i = 1:4
    subplot(4,1,i)
    plot(values_std.Day(:,i),"-x")
    line([1 size(values_std.Day,1)],[mean_std.Day(i) mean_std.Day(i)],"color","red","LineStyle","--")
    ylabel("\sigma "+x_labels(i))
    if(i == 1)
        title("Std (\sigma) Day")
    end
end

%% Make Table for ML
% "meanRH" "meanT" "meanAP" "meanLI"
% "stdRH" "stdT" "stdAP" "stdLI"
% "maxRH" "maxT" "maxAP" "maxLI"
% "minRH" "minT" "minAP" "minLI"
clear mean_lastweek std_lastweek max_lastweek min_lastweek day_classification

mean_lastweek.day = [];
mean_lastweek.week = [];
mean_lastweek.data = zeros(7,4);

std_lastweek.day = [];
std_lastweek.week = [];
std_lastweek.data = zeros(7,4);

max_lastweek.day = [];
max_lastweek.week = [];
max_lastweek.data = zeros(7,4);

min_lastweek.day = [];
min_lastweek.week = [];
min_lastweek.data = zeros(7,4);

values_today.date = [];
values_today.mean = [];
values_today.std = [];
values_today.max = [];
values_today.min = [];

first_day = datetime(year(Datum(1)),month(Datum(1)),day(Datum(1)+1));
last_day = datetime(year(Datum(end)),month(Datum(end)),day(Datum(end)+1));
first_day + caldays(7);
loop_counter = 0;
for i = first_day+caldays(7):caldays(1):last_day
    loop_counter = loop_counter + 1;
    for j = 1:7
       k = i - caldays(j);
       pos = find((Wetterlog.Year == year(k)) & (Wetterlog.Month == month(k)) & (Wetterlog.Day == day(k)));
       mean_lastweek.day = [mean_lastweek.day; {datestr(i)}, {mean(Wetterlog(pos,value_pos).Variables)}, {datestr(i-caldays(j))}];
       mean_lastweek.data(j,:) = mean(Wetterlog(pos,value_pos).Variables);
       
       std_lastweek.day = [std_lastweek.day; {datestr(i)}, {std(Wetterlog(pos,value_pos).Variables)}];
       std_lastweek.data(j,:) = std(Wetterlog(pos,value_pos).Variables);
       
       max_lastweek.day = [max_lastweek.day; {datestr(i)}, {max(Wetterlog(pos,value_pos).Variables)}];
       max_lastweek.data(j,:) = max(Wetterlog(pos,value_pos).Variables);
       
       min_lastweek.day = [min_lastweek.day; {datestr(i)}, {min(Wetterlog(pos,value_pos).Variables)}];
       min_lastweek.data(j,:) = min(Wetterlog(pos,value_pos).Variables);
    end
    mean_lastweek.week = [mean_lastweek.week; {datestr(i,29)}, {mean(mean_lastweek.data)}];
    std_lastweek.week = [std_lastweek.week; {datestr(i,29)}, {mean(std_lastweek.data)}];
    max_lastweek.week = [max_lastweek.week; {datestr(i,29)}, {mean(max_lastweek.data)}];
    min_lastweek.week = [min_lastweek.week; {datestr(i,29)}, {mean(min_lastweek.data)}];
    pos = find((Wetterlog.Year == year(i)) & (Wetterlog.Month == month(i)) & (Wetterlog.Day == day(i)));
    values_today.date = [values_today.date; i];
    values_today.mean = [values_today.mean; {mean(Wetterlog(pos,value_pos).Variables)}];
    values_today.std = [values_today.std; {std(Wetterlog(pos,value_pos).Variables)}];
    values_today.max = [values_today.max; {max(Wetterlog(pos,value_pos).Variables)}];
    values_today.min = [values_today.min; {min(Wetterlog(pos,value_pos).Variables)}];
end
loop_counter = loop_counter - 1;
values_today.date(end) = [];
values_today.mean(end) = [];
values_today.std(end) = [];
values_today.max(end) = [];
values_today.min(end) = [];


day_classification = strings(loop_counter,1);
tmp = cell2mat(values_today.mean(:,1));
tmp_week = week(values_today.date);
tmp_month = month(values_today.date);
reference_line_week = zeros(loop_counter,1);
reference_line_month = zeros(loop_counter,1);
for i = 1:loop_counter
    reference_line_week(i) = values_mean.Week(tmp_week(i),4);
    reference_line_month(i) = values_mean.Month(tmp_month(i),4); 
    if(tmp(i,4) < values_mean.Month(tmp_month(i),4))
        day_classification(i) = "cloudy";
    else
        day_classification(i) = "sunny";
    end
end

figure
hold on
plot(tmp(:,4))
plot(reference_line_week)
plot(reference_line_month)
hold off
%%
clear table_ML_lastWeek
table_ML_lastWeek = table();
table_ML_lastWeek.Date = mean_lastweek.week(1:end-1,1);
table_ML_lastWeek.Week = week(values_today.date);
table_ML_lastWeek.Month = month(values_today.date);

tmp = cell2mat(mean_lastweek.week(:,2));
data_predict.mean = tmp(end,:);
tmp(end,:) = [];
table_ML_lastWeek.LW_meanRH = tmp(:,1);
table_ML_lastWeek.LW_meanT = tmp(:,2);
table_ML_lastWeek.LW_meanAP = tmp(:,3);
table_ML_lastWeek.LW_meanLI = tmp(:,4);

tmp = cell2mat(std_lastweek.week(:,2));
data_predict.std = tmp(end,:);
tmp(end,:) = [];
table_ML_lastWeek.LW_stdRH = tmp(:,1);
table_ML_lastWeek.LW_stdT = tmp(:,2);
table_ML_lastWeek.LW_stdAP = tmp(:,3);
table_ML_lastWeek.LW_stdLI = tmp(:,4);

tmp = cell2mat(max_lastweek.week(:,2));
data_predict.max = tmp(end,:);
tmp(end,:) = [];
table_ML_lastWeek.LW_maxRH = tmp(:,1);
table_ML_lastWeek.LW_maxT = tmp(:,2);
table_ML_lastWeek.LW_maxAP = tmp(:,3);
table_ML_lastWeek.LW_maxLI = tmp(:,4);

tmp = cell2mat(min_lastweek.week(:,2));
data_predict.min = tmp(end,:);
tmp(end,:) = [];
table_ML_lastWeek.LW_minRH = tmp(:,1);
table_ML_lastWeek.LW_minT = tmp(:,2);
table_ML_lastWeek.LW_minAP = tmp(:,3);
table_ML_lastWeek.LW_minLI = tmp(:,4);

table_ML_lastWeek.Classification = day_classification;
%%
% viewmodel
if exist("trainedModel")
    view(trainedModel.ClassificationTree,'Mode','graph');
    save trainedModel
else
    load("trainedModel.mat")
end
%%
predict_table = table();

predict_table.Data = mean_lastweek.week(end,1);
predict_table.Week = week(Datum(end));
predict_table.Month = month(Datum(end));

predict_table.LW_meanRH = data_predict.mean(1);
predict_table.LW_meanT = data_predict.mean(2);
predict_table.LW_meanAP = data_predict.mean(3);
predict_table.LW_meanLI = data_predict.mean(4);

predict_table.LW_stdRH = data_predict.std(1);
predict_table.LW_stdT = data_predict.std(2);
predict_table.LW_stdAP = data_predict.std(3);
predict_table.LW_stdLI = data_predict.std(4);

predict_table.LW_maxRH = data_predict.max(1);
predict_table.LW_maxT = data_predict.max(2);
predict_table.LW_maxAP = data_predict.max(3);
predict_table.LW_maxLI = data_predict.max(4);

predict_table.LW_minRH = data_predict.min(1);
predict_table.LW_minT = data_predict.min(2);
predict_table.LW_minAP = data_predict.min(3);
predict_table.LW_minLI = data_predict.min(4);

predict_table.Month = month(Datum(end));
predict_table.Week = week(Datum(end));

prediction = trainedModel.predictFcn(predict_table)
sound(sin(1:3000));
