
function ReflectionCoefficientAtSP=HydroGNSS_extract(init_SM_Day,final_SM_Day, configurationPath) ; 
%%utctimefixed
close all
clearvars -except  init_SM_Day final_SM_Day configurationPath

global namelogfile logfileID  ; 
global ReflectionCoefficientAtSP Sigma0 ; 

ex=exist('configurationPath') ;
if ex ==0
    mode="GUI" ;
    
    [configurationfile configurationPath] = uigetfile('../*.cfg', 'Select input configuration file') ; 
    configurationPath= [ configurationPath configurationfile]  ; 
else
    if ~isfile(configurationPath)
        throw(MException('INPUT:ERROR', "Cannot find configuration file. Please check the command line and try again."))
    end
    mode="input" ;
end

%    

[ProcessingSatellite, DataInputRootPath, DataOutputRootPath, Outfileprefix, LogsOutputRootPath, LatSouth, LatNorth, LonWest, LonEast, Dayinit, Dayfinal, DDM] = ReadConfFile(configurationPath);

switch mode
    case "GUI" 
%
% ****** get inputs from GUI
%
    disp('GUI mode')
% *************  Start GUI 
Answer{1}= char(ProcessingSatellite) ;    Answer{7}=char(string(LatNorth)) ;
Answer{2}=char(DataInputRootPath)  ;      Answer{8}= char(string(LonWest)) ;
Answer{3}=char(DataOutputRootPath)  ;     Answer{9}= char(string(LonEast)) ;
Answer{5}=char(Outfileprefix)  ;          Answer{10}= char(Dayinit) ;
Answer{4}=char(LogsOutputRootPath)  ;     Answer{11}=char(Dayfinal) ;
Answer{6}=char(string(LatSouth))  ;       Answer{12}= char(DDM) ;
% ****** get inputs from GUI
prompt={ 'ProcessingSatellite [HydroGNSS-1 | HydeoGNSS-2 | both]: ',...
         'DataInputRootPath: ',...
         'DataOutputRootPath: ',...
         'LogsOutputRootPath: ', ...
         'Outfileprefix: ',...
         'Southernmost latitude: ', ...
         'Northernmost latitude: ', ...
         'Westernmost longitude: ', ...
         'Easternmost longitude:', ...
         'First day to extract: ', ...
         'Last day to extract: ', ...
         'DDM [Yes/No]:' }  ; 
opts.Resize='on';
opts.WindowStyle='normal';
opts.Interpreter='tex';
name='HydroGNSS L1B data extraction';
numlines=[1 90; 1 90; 1 90; 1 90; 1 30; 1 30 ; 1 30; 1 30; 1 30; 1 30; 1 30; 1 30] ; 
defaultanswer={Answer{1},Answer{2},...
                 Answer{3},Answer{4},Answer{5},Answer{6},Answer{7},...
                 Answer{8},Answer{9},Answer{10},...
                 Answer{11},Answer{12}};
Answer=inputdlg(prompt,name,numlines,defaultanswer,opts);

ProcessingSatellite= Answer{1};
DataInputRootPath= Answer{2};
DataOutputRootPath= Answer{3};
Outfileprefix= Answer{5};
LogsOutputRootPath=Answer{4} ; 
LatSouth= str2num(Answer{6}) ; 
LatNorth= str2num(Answer{7}) ;
LonWest=   str2num(Answer{8}) ; ...
LonEast=   str2num(Answer{9}) ;
Dayinit=Answer{10} ;
Dayfinal=Answer{11} ;
DDM=Answer{12} ;
%
% ****** Save GUI input into Input Configuration File 
% save('../conf/Configuration.mat', 'Answer', '-append') ;

WriteConfig(configurationPath, ProcessingSatellite, DataInputRootPath, DataOutputRootPath, LogsOutputRootPath, Outfileprefix, LatSouth, LatNorth, LonWest, LonEast, Dayinit, Dayfinal, DDM);


% switch mode
    case "input" 
    disp('input mode')

[ProcessingSatellite, DataInputRootPath, DataOutputRootPath, Outfileprefix, LogsOutputRootPath, LatSouth, LatNorth, LonWest, LonEast, dummy1, dummy2, DDM] = ReadConfFile(configurationPath);

%scrivere il configuration
% WriteConfig(configurationPath, ProcessingSatellite, DataInputRootPath, DataOutputRootPath, LogsOutputRootPath, Outfileprefix, LatSouth, LatNorth, LonWest, LonEast, Dayinit, Dayfinal, DDM);


end

Dayinit = datetime(Dayinit, 'InputFormat', 'yyyy-MM-dd''T''HH:mm') ;
Dayfinal = datetime(Dayfinal, 'InputFormat', 'yyyy-MM-dd''T''HH:mm') ;
%%
% Set and open the log file
%
if ~exist(LogsOutputRootPath)
        throw(MException('INPUT:ERROR', "Cannot find configuration file. Please check the command line and try again."))
end
%
logfile= datetime('now','Format','yyyyMMddHHmmss') ; 
logfile=char(logfile) ;
namelogfile=[char(Outfileprefix) '_' logfile '.log'] ;
logfileID = fopen([char(LogsOutputRootPath) '\' namelogfile], 'a+') ; 
fopen(logfileID) ; 
global namelogfile logfileID  ; 
%
%%
%%%% find out HydroGNSS file folder and names for the specified time frame
% endDate=Dayfinal+hours(3) ; % Needed since the six hour block H00 starts on the previous day at 23:00:00
% startDate=Dayinit+hours(3) ;
endDate=Dayfinal ; 
startDate=Dayinit ;

% numdays=ceil(juliandate(endDate)-juliandate(startDate)+1) ; %devo mettere +1 ???????
numdays=ceil(juliandate(endDate)-juliandate(startDate)) ; %devo mettere +1 ???????

% L2OPfolder_sixtot="" ; 
% for ii=1:numdays
% timeproduct=startDate+day(ii-1) ; 
%     for kk=1:4
%     timeproductsix=timeproduct+hours((kk-1)*6) ; 
%     timeproduct_sixtot(ii, kk)=timeproductsix ; 
%     [tyear, tmonth, tday]=ymd(timeproductsix) ; 
%     [thour, tmin, tsec]=hms(timeproductsix) ;
% 
%     six=6*fix(thour/6) ;
%     sixhour=char(string(six)) ; 
%         if tday< 10, charday=['0' char(string(tday))] ; else charday= char(string(tday)); end
%         if tmonth< 10, charmonth=['0' char(string(tmonth))] ; else charmonth= char(string(tmonth)); end
% 
%         if six >= 12 
%         L2OPfoldername=[char(DataInputRootPath) '\' char(ProcessingSatellite) '\DataRelease\L1A_L1B\' char(string(tyear)) '-' charmonth '\' charday '\H' sixhour '\'] ;
%         else
%         L2OPfoldername=[char(DataInputRootPath) '\' char(ProcessingSatellite) '\DataRelease\L1A_L1B\' char(string(tyear)) '-' charmonth '\' charday '\H0' sixhour '\'] ;
%         end
%    % L2OPfolder_sixtot(ii+ii*(kk-1))=string(L2OPfoldername) ; % vector with full folder path of L2OP product files
%    if exist(L2OPfoldername)>0 & exist([L2OPfoldername 'metadata_L1_merged.nc']) >0
%     L2OPfolder_sixtot(ii, kk)=string(L2OPfoldername) ; % matrix [num of days x 4 six hour block per day] vector with full folder path of L2OP product files
%    else
%     L2OPfolder_sixtot(ii, kk)=missing ;  
%         disp([char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')) ' WARNING: six hour block ' L2OPfoldername ' does not exist or does not contain metadata. Program continuing']) ; 
%         fprintf(logfileID,[char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')) ' WARNING: six hour block does not exist or does not contain metadata. Program continuing']) ; 
%         fprintf(logfileID,'\n') ; 
%    end
% 
%     % end 
%     end
% end
% 
% %%
% 
% GoodSixhour=find(ismissing(L2OPfolder_sixtot)==0)  ;  
% L2OPfolder_sixtot=L2OPfolder_sixtot(GoodSixhour) ;
% timeproduct_sixtot=timeproduct_sixtot(GoodSixhour) ; 
% numGoodSixhour=length(GoodSixhour) ; 


DataTag=0; Track_ID=0; IND_sixhours=0 ; 
SM_Time_resolution=ceil(juliandate(endDate)-juliandate(startDate)) ;
readDDM=DDM; DDMs_name='DDMs.nc'; L1b_ProcessorVersion=' ' ; L1a_ProcessorVersion=' ';
metadata_name='metadata_L1_merged.nc' ; Day_to_process=Dayinit; 
Path_HydroGNSS_Data=[char(DataInputRootPath), '\', char(ProcessingSatellite), '\DataRelease\L1A_L1B'] ; 

% for ii=1:numGoodSixhour
 
[DataTag, noday, Track_ID, IND_sixhours, L1b_ProcessorVersion, L1a_ProcessorVersion]=read_L1Bproduct(DataTag, Dayinit,...
    SM_Time_resolution,Path_HydroGNSS_Data, metadata_name, readDDM, ...
    DDMs_name, Track_ID, IND_sixhours, L1b_ProcessorVersion, L1a_ProcessorVersion) ;

% end

%% Crete output variables and save

[a NumOfTracks]=size(ReflectionCoefficientAtSP) ; 

numOfSP=0 ;  timeUTC=[] ; SAT=[] ; 
for ii=1:NumOfTracks
    SAT=[SAT , string(ReflectionCoefficientAtSP(ii).Satellite)] ;
    numOfSP=numOfSP+length(ReflectionCoefficientAtSP(ii).SpecularPointLat) ; 
end

timeUTC=[]; time = single([]); specularPointLat=[]; specularPointLon=[];  THETA=[] ;  constellation = strings(numOfSP,1); teWidth=single([]); spAzimuthAngleDegOrbit=[] ;dayOfYear=single([]); secondOfDay=single([]);  
reflectivityLinear_L1_L=single(NaN(numOfSP,1)) ; reflectivityLinear_L1_R=single(NaN(numOfSP,1)) ;
reflectivityLinear_E1_L=single(NaN(numOfSP,1)) ; reflectivityLinear_E1_R=single(NaN(numOfSP,1)) ;
reflectivityLinear_5_L=single(NaN(numOfSP,1)) ; reflectivityLinear_5_R=single(NaN(numOfSP,1)) ; 
SNR_L1_L=single(NaN(numOfSP,1)) ; SNR_L1_R=single(NaN(numOfSP,1)) ; SNR_5_L=single(NaN(numOfSP,1)) ; 
SNR_5_R=single(NaN(numOfSP,1)) ; SNR_E1_L=single(NaN(numOfSP,1)) ; SNR_E1_R=single(NaN(numOfSP,1));...
EIRP_L1 = single(NaN(numOfSP,1)) ; EIRP_L5 = single(NaN(numOfSP,1)) ; EIRP_E1 = single(NaN(numOfSP,1)) ; EIRP_5 = single(NaN(numOfSP,1)) ; ...
rxAntennaGain_L1_R = single(NaN(numOfSP,1)) ; rxAntennaGain_L1_L = single(NaN(numOfSP,1)); rxAntennaGain_L5_R = single(NaN(numOfSP,1)) ; rxAntennaGain_L5_L = single(NaN(numOfSP,1)); rxAntennaGain_E1_R = single(NaN(numOfSP,1)) ; rxAntennaGain_E1_L = single(NaN(numOfSP,1)); rxAntennaGain_5_R = single(NaN(numOfSP,1)) ; rxAntennaGain_5_L = single(NaN(numOfSP,1));...
qualityControlFlags_L1_R = single(NaN(numOfSP,1)) ; qualityControlFlags_L1_L = single(NaN(numOfSP,1)); qualityControlFlags_5_R = single(NaN(numOfSP,1)) ; qualityControlFlags_5_L = single(NaN(numOfSP,1)); qualityControlFlags_E1_R = single(NaN(numOfSP,1)) ; qualityControlFlags_E1_L = single(NaN(numOfSP,1)); qualityControlFlags_E5_R = single(NaN(numOfSP,1)) ; qualityControlFlags_E5_L = single(NaN(numOfSP,1));
NBRCS_L1_R = single(NaN(numOfSP,1)) ; NBRCS_L1_L = single(NaN(numOfSP,1)); NBRCS_5_R = single(NaN(numOfSP,1)) ; NBRCS_5_L = single(NaN(numOfSP,1)); NBRCS_E1_R = single(NaN(numOfSP,1)) ; NBRCS_E1_L = single(NaN(numOfSP,1)); NBRCS_E5_R = single(NaN(numOfSP,1)) ; NBRCS_E5_L = single(NaN(numOfSP,1)); powerRatio_L1_R = single(NaN(numOfSP,1)) ; powerRatio_L1_L = single(NaN(numOfSP,1)); powerRatio_5_R = single(NaN(numOfSP,1)) ; powerRatio_5_L = single(NaN(numOfSP,1)); powerRatio_E1_R = single(NaN(numOfSP,1)) ; powerRatio_E1_L = single(NaN(numOfSP,1)); powerRatio_E5_R = single(NaN(numOfSP,1)) ; powerRatio_E5_L = single(NaN(numOfSP,1)); NoiseKurtosis=single(NaN(numOfSP,1));PRN=single(NaN(numOfSP,1));GNSSConstellation = single(NaN(numOfSP,1));QC_pass_flag=single(NaN(numOfSP,1)); 
kurtosisDDM_L1_R = single(NaN(numOfSP,1)) ; kurtosisDDM_L1_L = single(NaN(numOfSP,1)); kurtosisDDM_5_R = single(NaN(numOfSP,1)) ; kurtosisDDM_5_L = single(NaN(numOfSP,1)); kurtosisDDM_E1_R = single(NaN(numOfSP,1)) ; kurtosisDDM_E1_L = single(NaN(numOfSP,1)); kurtosisDDM_E5_R = single(NaN(numOfSP,1)) ; kurtosisDDM_E5_L = single(NaN(numOfSP,1));
kurtosisDopp0_L1_R = single(NaN(numOfSP,1)) ; kurtosisDopp0_L1_L = single(NaN(numOfSP,1)); kurtosisDopp0_5_R = single(NaN(numOfSP,1)) ; kurtosisDopp0_5_L = single(NaN(numOfSP,1)); kurtosisDopp0_E1_R = single(NaN(numOfSP,1)) ; kurtosisDopp0_E1_L = single(NaN(numOfSP,1)); kurtosisDopp0_E5_R = single(NaN(numOfSP,1)) ; kurtosisDopp0_E5_L = single(NaN(numOfSP,1));
noiseFloorCounts_L1_R = single(NaN(numOfSP,1)) ; noiseFloorCounts_L1_L = single(NaN(numOfSP,1)); noiseFloorCounts_5_R = single(NaN(numOfSP,1)) ; noiseFloorCounts_5_L = single(NaN(numOfSP,1)); noiseFloorCounts_E1_R = single(NaN(numOfSP,1)) ; noiseFloorCounts_E1_L = single(NaN(numOfSP,1)); noiseFloorCounts_E5_R = single(NaN(numOfSP,1)) ; noiseFloorCounts_E5_L = single(NaN(numOfSP,1));
powerAnalogW_L1_R = single(NaN(numOfSP,1)); powerAnalogW_L1_L = single(NaN(numOfSP,1)); powerAnalogW_5_R = single(NaN(numOfSP,1)); powerAnalogW_5_L = single(NaN(numOfSP,1)); powerAnalogW_E1_R = single(NaN(numOfSP,1)); powerAnalogW_E1_L = single(NaN(numOfSP,1)); powerAnalogW_E5_R = single(NaN(numOfSP,1)); powerAnalogW_E5_L = single(NaN(numOfSP,1));


GPSindex=find(SAT=="GPS") ;
Galileoindex=find(SAT=="Galileo") ; 

fintrack=0 ; 
%dayOfYear = [];
%secondOfDay = [];
Year = single([]);


format long g   % <-- ADD this at the top of your script

for kk = 1:NumOfTracks
       t_track = ReflectionCoefficientAtSP(kk).time;  % original per-point time vector

    % --- Keep numeric time as in file (full precision)
    time = [time; t_track(:)];

    % --- Convert to full UTC datetime
% Inside your loop
t_track = ReflectionCoefficientAtSP(kk).time;  % numeric seconds

% --- Keep numeric time
time = [time; t_track(:)];


dt_full = datetime(t_track, 'ConvertFrom', 'datenum');  % full precision
timeUTC = [timeUTC; dt_full];

% Set display format for the entire timeUTC array
timeUTC.Format = 'yyyy-MM-dd HH:mm:ss';

% Additional variables
dayOfYear = [dayOfYear; day(dt_full,'dayofyear')];
secondOfDay = [secondOfDay; hour(dt_full)*3600 + minute(dt_full)*60 + second(dt_full)];
Year = [Year; year(dt_full)];


    specularPointLat=[specularPointLat ; ReflectionCoefficientAtSP(kk).SpecularPointLat] ; 
    specularPointLon=[specularPointLon ; ReflectionCoefficientAtSP(kk).SpecularPointLon] ; 
    THETA=[THETA ; ReflectionCoefficientAtSP(kk).SPIncidenceAngle] ;
    spAzimuthAngleDegOrbit=[spAzimuthAngleDegOrbit ; ReflectionCoefficientAtSP(kk).SPAzimuthORF] ;
    sizetrack=length(ReflectionCoefficientAtSP(kk).time) ; 
    intrack=fintrack+1 ; 
    fintrack=intrack+sizetrack-1 ; 



%        if isfield(ReflectionCoefficientAtSP(kk), 'EIRP') && ...
%       ~ismissing(ReflectionCoefficientAtSP(kk).EIRP)
%         EIRP(intrack:fintrack) = ReflectionCoefficientAtSP(kk).EIRP;
%         end
%         if isfield(ReflectionCoefficientAtSP(kk), 'EIRP_CM1') && ...
%        ~ismissing(ReflectionCoefficientAtSP(kk).EIRP_CM1)
%         EIRP_CM1(intrack:fintrack) = ReflectionCoefficientAtSP(kk).EIRP_CM1;
%         end
%         if isfield(ReflectionCoefficientAtSP(kk),'EIRP_CM2')&&~ismissing(ReflectionCoefficientAtSP(kk).EIRP_CM2),EIRP_CM2(intrack:fintrack)=ReflectionCoefficientAtSP(kk).EIRP_CM2;end;if isfield(ReflectionCoefficientAtSP(kk),'EIRP_CM3')&&~ismissing(ReflectionCoefficientAtSP(kk).EIRP_CM3),EIRP_CM3(intrack:fintrack)=ReflectionCoefficientAtSP(kk).EIRP_CM3;end;if isfield(ReflectionCoefficientAtSP(kk),'NoiseKurtosis')&&~ismissing(ReflectionCoefficientAtSP(kk).NoiseKurtosis),NoiseKurtosis(intrack:fintrack)=ReflectionCoefficientAtSP(kk).NoiseKurtosis;end;if isfield(ReflectionCoefficientAtSP(kk),'HighNoiseKurtosis')&&~ismissing(ReflectionCoefficientAtSP(kk).HighNoiseKurtosis),HighNoiseKurtosis(intrack:fintrack)=ReflectionCoefficientAtSP(kk).HighNoiseKurtosis;end;
if isfield(ReflectionCoefficientAtSP(kk),'PRN')&&~ismissing(ReflectionCoefficientAtSP(kk).PRN),PRN(intrack:fintrack)=ReflectionCoefficientAtSP(kk).PRN;end;
if isfield(ReflectionCoefficientAtSP(kk),'QC_pass_flag')&&~ismissing(ReflectionCoefficientAtSP(kk).QC_pass_flag),QC_pass_flag(intrack:fintrack)=ReflectionCoefficientAtSP(kk).QC_pass_flag;end;
if isfield(ReflectionCoefficientAtSP(kk),'GNSSConstellation_units')&&~ismissing(ReflectionCoefficientAtSP(kk).GNSSConstellation_units),GNSSConstellation(intrack:fintrack)=ReflectionCoefficientAtSP(kk).GNSSConstellation_units;end;


  switch SAT(kk) ; 
    case "GPS"
   % Add constellation label for GPS
    %constellation = [constellation; repmat({'GPS'}, length(refl_coeff.Latitude), 1)];

  % 
    if ismissing(ReflectionCoefficientAtSP(kk).L1_LHCP)==0 , reflectivityLinear_L1_L(intrack:fintrack)=10.^(ReflectionCoefficientAtSP(kk).L1_LHCP/10) ;...
            SNR_L1_L(intrack:fintrack)=ReflectionCoefficientAtSP(kk).SNR_L1_LHCP ; end
    if ismissing(ReflectionCoefficientAtSP(kk).L1_RHCP)==0, reflectivityLinear_L1_R(intrack:fintrack)=10.^(ReflectionCoefficientAtSP(kk).L1_RHCP/10) ;...
            SNR_L1_R(intrack:fintrack)=ReflectionCoefficientAtSP(kk).SNR_L1_RHCP ; end
    if ismissing(ReflectionCoefficientAtSP(kk).L5_LHCP)==0, reflectivityLinear_5_L(intrack:fintrack)= 10.^(ReflectionCoefficientAtSP(kk).L5_LHCP/10) ;...
        SNR_5_L(intrack:fintrack)= ReflectionCoefficientAtSP(kk).SNR_L5_LHCP ; end
    if ismissing(ReflectionCoefficientAtSP(kk).L5_RHCP)==0, reflectivityLinear_5_R(intrack:fintrack)= 10.^(ReflectionCoefficientAtSP(kk).L5_RHCP/10) ;...
        SNR_5_R(intrack:fintrack)= ReflectionCoefficientAtSP(kk).SNR_L5_RHCP ; end
    
    %EIRP lines
     if ismissing(ReflectionCoefficientAtSP(kk).EIRP_L1_LHCP)==0 , EIRP_L1(intrack:fintrack)=ReflectionCoefficientAtSP(kk).EIRP_L1_LHCP ; end

 %    if ismissing(ReflectionCoefficientAtSP(kk).EIRP_L5_LHCP)==0 , EIRP_L5(intrack:fintrack)=ReflectionCoefficientAtSP(kk).EIRP_L5_LHCP ; end
         if ismissing(ReflectionCoefficientAtSP(kk).EIRP_L5_LHCP)==0 , EIRP_5(intrack:fintrack)=ReflectionCoefficientAtSP(kk).EIRP_L5_LHCP ; end

     %rxAntenna Gain lines
     if ismissing(ReflectionCoefficientAtSP(kk).rxAntennaGain_L1_LHCP)==0 , rxAntennaGain_L1_L(intrack:fintrack)=ReflectionCoefficientAtSP(kk).rxAntennaGain_L1_LHCP ; end
     if ismissing(ReflectionCoefficientAtSP(kk).rxAntennaGain_L1_RHCP)==0 , rxAntennaGain_L1_R(intrack:fintrack)=ReflectionCoefficientAtSP(kk).rxAntennaGain_L1_RHCP ; end

     if ismissing(ReflectionCoefficientAtSP(kk).rxAntennaGain_L5_LHCP)==0 , rxAntennaGain_5_L(intrack:fintrack)=ReflectionCoefficientAtSP(kk).rxAntennaGain_L5_LHCP ; end
     if ismissing(ReflectionCoefficientAtSP(kk).rxAntennaGain_L5_RHCP)==0 , rxAntennaGain_5_R(intrack:fintrack)=ReflectionCoefficientAtSP(kk).rxAntennaGain_L5_RHCP ; end
  

    %QualityControlFlag lines
%     if ismissing(ReflectionCoefficientAtSP(kk).QualityControlFlags_L1_LHCP)==0 , qualityControlFlags_L1_L(intrack:fintrack)=ReflectionCoefficientAtSP(kk).QualityControlFlags_L1_LHCP ; end
%     if ismissing(ReflectionCoefficientAtSP(kk).QualityControlFlags_L1_RHCP)==0 , qualityControlFlags_L1_R(intrack:fintrack)=ReflectionCoefficientAtSP(kk).QualityControlFlags_L1_RHCP ; end

%     if ismissing(ReflectionCoefficientAtSP(kk).QualityControlFlags_L5_LHCP)==0 , qualityControlFlags_5_L(intrack:fintrack)=ReflectionCoefficientAtSP(kk).QualityControlFlags_L5_LHCP ; end
%     if ismissing(ReflectionCoefficientAtSP(kk).QualityControlFlags_L5_RHCP)==0 , qualityControlFlags_5_R(intrack:fintrack)=ReflectionCoefficientAtSP(kk).QualityControlFlags_L5_RHCP ; end
  

     %PowerAnalog_W lines
if ismissing(ReflectionCoefficientAtSP(kk).PowerAnalog_W_L1_LHCP)==0 , powerAnalogW_L1_L(intrack:fintrack)=ReflectionCoefficientAtSP(kk).PowerAnalog_W_L1_LHCP ; end
if ismissing(ReflectionCoefficientAtSP(kk).PowerAnalog_W_L1_RHCP)==0 , powerAnalogW_L1_R(intrack:fintrack)=ReflectionCoefficientAtSP(kk).PowerAnalog_W_L1_RHCP ; end

if ismissing(ReflectionCoefficientAtSP(kk).PowerAnalog_W_L5_LHCP)==0 , powerAnalogW_5_L(intrack:fintrack)=ReflectionCoefficientAtSP(kk).PowerAnalog_W_L5_LHCP ; end
if ismissing(ReflectionCoefficientAtSP(kk).PowerAnalog_W_L5_RHCP)==0 , powerAnalogW_5_R(intrack:fintrack)=ReflectionCoefficientAtSP(kk).PowerAnalog_W_L5_RHCP ; end


     %MeanNoise lines
     if ismissing(ReflectionCoefficientAtSP(kk).noise_floor_Counts_L1_LHCP)==0 , noiseFloorCounts_L1_L(intrack:fintrack)=ReflectionCoefficientAtSP(kk).noise_floor_Counts_L1_LHCP ; end
     if ismissing(ReflectionCoefficientAtSP(kk).noise_floor_Counts_L1_RHCP)==0 , noiseFloorCounts_L1_R(intrack:fintrack)=ReflectionCoefficientAtSP(kk).noise_floor_Counts_L1_RHCP ; end

     if ismissing(ReflectionCoefficientAtSP(kk).noise_floor_Counts_L5_LHCP)==0 , noiseFloorCounts_5_L(intrack:fintrack)=ReflectionCoefficientAtSP(kk).noise_floor_Counts_L5_LHCP ; end
     if ismissing(ReflectionCoefficientAtSP(kk).noise_floor_Counts_L5_RHCP)==0 , noiseFloorCounts_5_R(intrack:fintrack)=ReflectionCoefficientAtSP(kk).noise_floor_Counts_L5_RHCP ; end
   
     %powerRatio lines
     if ismissing(ReflectionCoefficientAtSP(kk).PowerSpreadRatio_L1_LHCP)==0 , powerRatio_L1_L(intrack:fintrack)=ReflectionCoefficientAtSP(kk).PowerSpreadRatio_L1_LHCP ; end
     if ismissing(ReflectionCoefficientAtSP(kk).PowerSpreadRatio_L1_RHCP)==0 , powerRatio_L1_R(intrack:fintrack)=ReflectionCoefficientAtSP(kk).PowerSpreadRatio_L1_RHCP ; end

     if ismissing(ReflectionCoefficientAtSP(kk).PowerSpreadRatio_L5_LHCP)==0 , powerRatio_5_L(intrack:fintrack)=ReflectionCoefficientAtSP(kk).PowerSpreadRatio_L5_LHCP ; end
     if ismissing(ReflectionCoefficientAtSP(kk).PowerSpreadRatio_L5_RHCP)==0 , powerRatio_5_R(intrack:fintrack)=ReflectionCoefficientAtSP(kk).PowerSpreadRatio_L5_RHCP ; end

     %Sigma0 lines
    if ismissing(Sigma0(kk).NBRCS_L1_LHCP)==0 , NBRCS_L1_L(intrack:fintrack)=Sigma0(kk).NBRCS_L1_LHCP ; end
    if ismissing(Sigma0(kk).NBRCS_L1_RHCP)==0 , NBRCS_L1_R(intrack:fintrack)=Sigma0(kk).NBRCS_L1_RHCP ; end

    if ismissing(Sigma0(kk).NBRCS_L5_LHCP)==0 , NBRCS_5_L(intrack:fintrack)=Sigma0(kk).NBRCS_L5_LHCP ; end
     if ismissing(Sigma0(kk).NBRCS_L5_RHCP)==0 , NBRCS_5_R(intrack:fintrack)=Sigma0(kk).NBRCS_L5_RHCP ; end

      %HighNoiseKurtosis lines
     if ismissing(ReflectionCoefficientAtSP(kk).Kurtosis_DDM_L1_LHCP)==0 , kurtosisDDM_L1_L(intrack:fintrack)=ReflectionCoefficientAtSP(kk).Kurtosis_DDM_L1_LHCP ; end
     if ismissing(ReflectionCoefficientAtSP(kk).Kurtosis_DDM_L1_RHCP)==0 , kurtosisDDM_L1_R(intrack:fintrack)=ReflectionCoefficientAtSP(kk).Kurtosis_DDM_L1_RHCP ; end

     if ismissing(ReflectionCoefficientAtSP(kk).Kurtosis_DDM_L5_LHCP)==0 , kurtosisDDM_5_L(intrack:fintrack)=ReflectionCoefficientAtSP(kk).Kurtosis_DDM_L5_LHCP ; end
     if ismissing(ReflectionCoefficientAtSP(kk).Kurtosis_DDM_L5_RHCP)==0 , kurtosisDDM_5_R(intrack:fintrack)=ReflectionCoefficientAtSP(kk).Kurtosis_DDM_L5_RHCP ; end

           %NoiseKurtosis lines
     if ismissing(ReflectionCoefficientAtSP(kk).Kurtosis_DOPP_0_L1_LHCP)==0 , kurtosisDopp0_L1_L(intrack:fintrack)=ReflectionCoefficientAtSP(kk).Kurtosis_DOPP_0_L1_LHCP ; end
     if ismissing(ReflectionCoefficientAtSP(kk).Kurtosis_DOPP_0_L1_RHCP)==0 , kurtosisDopp0_L1_R(intrack:fintrack)=ReflectionCoefficientAtSP(kk).Kurtosis_DOPP_0_L1_RHCP ; end

     if ismissing(ReflectionCoefficientAtSP(kk).Kurtosis_DOPP_0_L5_LHCP)==0 , kurtosisDopp0_5_L(intrack:fintrack)=ReflectionCoefficientAtSP(kk).Kurtosis_DOPP_0_L5_LHCP ; end
     if ismissing(ReflectionCoefficientAtSP(kk).Kurtosis_DOPP_0_L5_RHCP)==0 , kurtosisDopp0_5_R(intrack:fintrack)=ReflectionCoefficientAtSP(kk).Kurtosis_DOPP_0_L5_RHCP ; end


     case "Galileo"
    
    % Add constellation label for Galileo
    %constellation = [constellation; repmat({'Galileo'}, length(refl_coeff.Latitude), 1)];

    if ismissing(ReflectionCoefficientAtSP(kk).E1_LHCP)==0, reflectivityLinear_E1_L(intrack:fintrack)=10.^(ReflectionCoefficientAtSP(kk).E1_LHCP/10) ;...
        SNR_E1_L(intrack:fintrack)=ReflectionCoefficientAtSP(kk).SNR_E1_LHCP ; end
    if ismissing(ReflectionCoefficientAtSP(kk).E1_RHCP)==0, reflectivityLinear_E1_R(intrack:fintrack)=10.^(ReflectionCoefficientAtSP(kk).E1_RHCP/10) ;...
            SNR_E1_R(intrack:fintrack)=ReflectionCoefficientAtSP(kk).SNR_E1_RHCP ; end
    if ismissing(ReflectionCoefficientAtSP(kk).E5_LHCP)==0, reflectivityLinear_5_L(intrack:fintrack)= 10.^(ReflectionCoefficientAtSP(kk).E5_LHCP/10) ;...
            SNR_5_L(intrack:fintrack)= ReflectionCoefficientAtSP(kk).SNR_E5_LHCP ; end
    if ismissing(ReflectionCoefficientAtSP(kk).E5_RHCP)==0, reflectivityLinear_5_R(intrack:fintrack)= 10.^(ReflectionCoefficientAtSP(kk).E5_RHCP/10) ;...
            SNR_5_R(intrack:fintrack)= ReflectionCoefficientAtSP(kk).SNR_E5_RHCP ; end

   %EIRP lines
    if ismissing(ReflectionCoefficientAtSP(kk).EIRP_E1_LHCP)==0 , EIRP_E1(intrack:fintrack)=ReflectionCoefficientAtSP(kk).EIRP_E1_LHCP ; end
 %   if ismissing(ReflectionCoefficientAtSP(kk).EIRP_E5_LHCP)==0 , EIRP_E5(intrack:fintrack)=ReflectionCoefficientAtSP(kk).EIRP_E5_LHCP ; end
    if ismissing(ReflectionCoefficientAtSP(kk).EIRP_E5_LHCP)==0 , EIRP_5(intrack:fintrack)=ReflectionCoefficientAtSP(kk).EIRP_E5_LHCP ; end

     %Rx Antenna gain lines
    if ismissing(ReflectionCoefficientAtSP(kk).rxAntennaGain_E1_LHCP)==0 , rxAntennaGain_E1_L(intrack:fintrack)=ReflectionCoefficientAtSP(kk).rxAntennaGain_E1_LHCP ; end
    if ismissing(ReflectionCoefficientAtSP(kk).rxAntennaGain_E1_RHCP)==0 , rxAntennaGain_E1_R(intrack:fintrack)=ReflectionCoefficientAtSP(kk).rxAntennaGain_E1_RHCP ; end

     if ismissing(ReflectionCoefficientAtSP(kk).rxAntennaGain_E5_LHCP)==0 , rxAntennaGain_5_L(intrack:fintrack)=ReflectionCoefficientAtSP(kk).rxAntennaGain_E5_LHCP ; end
     if ismissing(ReflectionCoefficientAtSP(kk).rxAntennaGain_E5_RHCP)==0 , rxAntennaGain_5_R(intrack:fintrack)=ReflectionCoefficientAtSP(kk).rxAntennaGain_E5_RHCP ; end


     %Quality control flag lines
  %  if ismissing(ReflectionCoefficientAtSP(kk).QualityControlFlags_E1_LHCP)==0 , qualityControlFlags_E1_L(intrack:fintrack)=ReflectionCoefficientAtSP(kk).QualityControlFlags_E1_LHCP ; end
  %  if ismissing(ReflectionCoefficientAtSP(kk).QualityControlFlags_E1_RHCP)==0 , qualityControlFlags_E1_R(intrack:fintrack)=ReflectionCoefficientAtSP(kk).QualityControlFlags_E1_RHCP ; end

  %  if ismissing(ReflectionCoefficientAtSP(kk).QualityControlFlags_E5_LHCP)==0 , qualityControlFlags_5_L(intrack:fintrack)=ReflectionCoefficientAtSP(kk).QualityControlFlags_E5_LHCP ; end
  %  if ismissing(ReflectionCoefficientAtSP(kk).QualityControlFlags_E5_RHCP)==0 , qualityControlFlags_5_R(intrack:fintrack)=ReflectionCoefficientAtSP(kk).QualityControlFlags_E5_RHCP ; end


%PowerAnalog_W lines
if ismissing(ReflectionCoefficientAtSP(kk).PowerAnalog_W_E1_LHCP)==0 , powerAnalogW_E1_L(intrack:fintrack)=ReflectionCoefficientAtSP(kk).PowerAnalog_W_E1_LHCP ; end
if ismissing(ReflectionCoefficientAtSP(kk).PowerAnalog_W_E1_RHCP)==0 , powerAnalogW_E1_R(intrack:fintrack)=ReflectionCoefficientAtSP(kk).PowerAnalog_W_E1_RHCP ; end

if ismissing(ReflectionCoefficientAtSP(kk).PowerAnalog_W_E5_LHCP)==0 , powerAnalogW_5_L(intrack:fintrack)=ReflectionCoefficientAtSP(kk).PowerAnalog_W_E5_LHCP ; end
if ismissing(ReflectionCoefficientAtSP(kk).PowerAnalog_W_E5_RHCP)==0 , powerAnalogW_5_R(intrack:fintrack)=ReflectionCoefficientAtSP(kk).PowerAnalog_W_E5_RHCP ; end


   
     %MeanNoise lines
    if ismissing(ReflectionCoefficientAtSP(kk).noise_floor_Counts_E1_LHCP)==0 , noiseFloorCounts_E1_L(intrack:fintrack)=ReflectionCoefficientAtSP(kk).noise_floor_Counts_E1_LHCP ; end
    if ismissing(ReflectionCoefficientAtSP(kk).noise_floor_Counts_E1_RHCP)==0 , noiseFloorCounts_E1_R(intrack:fintrack)=ReflectionCoefficientAtSP(kk).noise_floor_Counts_E1_RHCP ; end

     if ismissing(ReflectionCoefficientAtSP(kk).noise_floor_Counts_E5_LHCP)==0 , noiseFloorCounts_5_L(intrack:fintrack)=ReflectionCoefficientAtSP(kk).noise_floor_Counts_E5_LHCP ; end
     if ismissing(ReflectionCoefficientAtSP(kk).noise_floor_Counts_E5_RHCP)==0 , noiseFloorCounts_5_R(intrack:fintrack)=ReflectionCoefficientAtSP(kk).noise_floor_Counts_E5_RHCP ; end


          %PowerSpreadRatio lines
     if ismissing(ReflectionCoefficientAtSP(kk).PowerSpreadRatio_E1_LHCP)==0 , powerRatio_E1_L(intrack:fintrack)=ReflectionCoefficientAtSP(kk).PowerSpreadRatio_E1_LHCP ; end
     if ismissing(ReflectionCoefficientAtSP(kk).PowerSpreadRatio_E1_RHCP)==0 , powerRatio_E1_R(intrack:fintrack)=ReflectionCoefficientAtSP(kk).PowerSpreadRatio_E1_RHCP ; end

     if ismissing(ReflectionCoefficientAtSP(kk).PowerSpreadRatio_E5_LHCP)==0 , powerRatio_5_L(intrack:fintrack)=ReflectionCoefficientAtSP(kk).PowerSpreadRatio_E5_LHCP ; end
     if ismissing(ReflectionCoefficientAtSP(kk).PowerSpreadRatio_E5_RHCP)==0 , powerRatio_5_R(intrack:fintrack)=ReflectionCoefficientAtSP(kk).PowerSpreadRatio_E5_RHCP ; end

     %HighNoiseKurtosis lines
     if ismissing(ReflectionCoefficientAtSP(kk).Kurtosis_DDM_E1_LHCP)==0 , kurtosisDDM_E1_L(intrack:fintrack)=ReflectionCoefficientAtSP(kk).Kurtosis_DDM_E1_LHCP ; end
     if ismissing(ReflectionCoefficientAtSP(kk).Kurtosis_DDM_E1_RHCP)==0 , kurtosisDDM_E1_R(intrack:fintrack)=ReflectionCoefficientAtSP(kk).Kurtosis_DDM_E1_RHCP ; end

     if ismissing(ReflectionCoefficientAtSP(kk).Kurtosis_DDM_E5_LHCP)==0 , kurtosisDDM_5_L(intrack:fintrack)=ReflectionCoefficientAtSP(kk).Kurtosis_DDM_E5_LHCP ; end
     if ismissing(ReflectionCoefficientAtSP(kk).Kurtosis_DDM_E5_RHCP)==0 , kurtosisDDM_5_R(intrack:fintrack)=ReflectionCoefficientAtSP(kk).Kurtosis_DDM_E5_RHCP ; end

     %NoiseKurtosis lines
     if ismissing(ReflectionCoefficientAtSP(kk).Kurtosis_DOPP_0_E1_LHCP)==0 , kurtosisDopp0_E1_L(intrack:fintrack)=ReflectionCoefficientAtSP(kk).Kurtosis_DOPP_0_E1_LHCP ; end
     if ismissing(ReflectionCoefficientAtSP(kk).Kurtosis_DOPP_0_E1_RHCP)==0 , kurtosisDopp0_E1_R(intrack:fintrack)=ReflectionCoefficientAtSP(kk).Kurtosis_DOPP_0_E1_RHCP ; end

     if ismissing(ReflectionCoefficientAtSP(kk).Kurtosis_DOPP_0_E5_LHCP)==0 , kurtosisDopp0_5_L(intrack:fintrack)=ReflectionCoefficientAtSP(kk).Kurtosis_DOPP_0_E5_LHCP ; end
     if ismissing(ReflectionCoefficientAtSP(kk).Kurtosis_DOPP_0_E5_RHCP)==0 , kurtosisDopp0_5_R(intrack:fintrack)=ReflectionCoefficientAtSP(kk).Kurtosis_DOPP_0_E5_RHCP ; end

     %Sigma0 lines
     if ismissing(Sigma0(kk).NBRCS_E1_LHCP)==0 , NBRCS_E1_L(intrack:fintrack)=Sigma0(kk).NBRCS_E1_LHCP ; end
     if ismissing(Sigma0(kk).NBRCS_E1_RHCP)==0 , NBRCS_E1_R(intrack:fintrack)=Sigma0(kk).NBRCS_E1_RHCP ; end

     if ismissing(Sigma0(kk).NBRCS_E5_LHCP)==0 , NBRCS_5_L(intrack:fintrack)=Sigma0(kk).NBRCS_E5_LHCP ; end
     if ismissing(Sigma0(kk).NBRCS_E5_RHCP)==0 , NBRCS_5_R(intrack:fintrack)=Sigma0(kk).NBRCS_E5_RHCP ; end


  end % end case over the satgellite
end % end fir over the tracks

%  
Nameout=[char(Outfileprefix) '_' char(datetime('now','Format','yy-MM-dd_HH-mm'),'yy-MM-dd_HH-mm') '.mat'] ; 
%
%QualityControlFlags = QC_pass_flag;  % create the new variable
pseudoRandomNoise = PRN;
transmittingSpacecraft = SAT;
%Kurtosis_DDM = HighNoiseKurtosis; 
%Kurtosis_DOPP_0 = NoiseKurtosis;
incidenceAngleDeg = THETA;
%spAzimuthAngleDegOrbit = SPAzimuthARF



% Initialize string array of same size as GNSSConstellation
constellation = strings(size(GNSSConstellation));  

% Assign values based on GNSSConstellation
constellation(GNSSConstellation == 0) = "GPS";
constellation(GNSSConstellation == 2) = "Galileo";

% Optional: mark unknowns
constellation(~(GNSSConstellation==0 | GNSSConstellation==2)) = "Unknown";


save([char(DataOutputRootPath) '\' Nameout], 'specularPointLat', 'specularPointLon', 'incidenceAngleDeg','spAzimuthAngleDegOrbit', 'dayOfYear',  'secondOfDay','time', 'timeUTC',...
    'reflectivityLinear_L1_L', 'reflectivityLinear_L1_R', 'reflectivityLinear_E1_L',...
    'reflectivityLinear_E1_R', 'reflectivityLinear_5_L', 'reflectivityLinear_5_R',...
    'SNR_L1_L', 'SNR_L1_R', 'SNR_5_L', 'SNR_5_R', 'SNR_E1_L', 'SNR_E1_R', ...
    'EIRP_L1','EIRP_5','EIRP_E1', ...
    'rxAntennaGain_L1_R','rxAntennaGain_L1_L','rxAntennaGain_E1_R','rxAntennaGain_E1_L','rxAntennaGain_5_R','rxAntennaGain_5_L', ...
    'qualityControlFlags_L1_R','qualityControlFlags_L1_L','qualityControlFlags_5_R','qualityControlFlags_5_L','qualityControlFlags_E1_R','qualityControlFlags_E1_L', ...
    'powerAnalogW_L1_R','powerAnalogW_L1_L','powerAnalogW_E1_R','powerAnalogW_E1_L','powerAnalogW_5_R','powerAnalogW_5_L',...
    'NBRCS_L1_R','NBRCS_L1_L','NBRCS_5_R','NBRCS_5_L','NBRCS_E1_R','NBRCS_E1_L','powerRatio_L1_R','powerRatio_L1_L','powerRatio_E1_R','powerRatio_E1_L','powerRatio_5_R','powerRatio_5_L', ...
    'kurtosisDDM_L1_R','kurtosisDDM_L1_L','kurtosisDDM_5_R','kurtosisDDM_5_L','kurtosisDDM_E1_R','kurtosisDDM_E1_L',...
    'kurtosisDopp0_L1_R','kurtosisDopp0_L1_L','kurtosisDopp0_E1_R','kurtosisDopp0_E1_L','kurtosisDopp0_5_R','kurtosisDopp0_5_L',...
    'pseudoRandomNoise','Year', 'teWidth', 'constellation', ...
    'noiseFloorCounts_L1_R','noiseFloorCounts_L1_L','noiseFloorCounts_E1_R','noiseFloorCounts_E1_L','noiseFloorCounts_5_R','noiseFloorCounts_5_L') ; 


 disp([char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')) ' INFO: End of program']) ; 
 %fprintf(logfileID,[char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')) ' INFO: End of program']) ; 
 %fprintf(logfileID,'\n') ; 