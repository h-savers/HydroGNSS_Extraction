
function ReflectionCoefficientAtSP=HydroGNSS_extract(init_SM_Day,final_SM_Day, configurationPath) ; 

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

numOfSP=0 ;  time=[] ; SAT=[] ; 
for ii=1:NumOfTracks
    SAT=[SAT , string(ReflectionCoefficientAtSP(ii).Satellite)] ;
    numOfSP=numOfSP+length(ReflectionCoefficientAtSP(ii).SpecularPointLat) ; 
end

time=[]; SPLAT=[]; SPLON=[];  THETA=[] ; DoY=[] ; SoD=[] ;  
REFLECTIVITY_LINEAR_L1_L=NaN(numOfSP,1) ; REFLECTIVITY_LINEAR_L1_R=NaN(numOfSP,1) ;
REFLECTIVITY_LINEAR_E1_L=NaN(numOfSP,1) ; REFLECTIVITY_LINEAR_E1_R=NaN(numOfSP,1) ;
REFLECTIVITY_LINEAR_5_L=NaN(numOfSP,1) ; REFLECTIVITY_LINEAR_5_R=NaN(numOfSP,1) ; 
SNR_L1_L=NaN(numOfSP,1) ; SNR_L1_R=NaN(numOfSP,1) ; SNR_5_L=NaN(numOfSP,1) ; 
SNR_5_R=NaN(numOfSP,1) ; SNR_E1_L=NaN(numOfSP,1) ; SNR_E1_R=NaN(numOfSP,1) ;

GPSindex=find(SAT=="GPS") ;
Galileoindex=find(SAT=="Galileo") ; 

fintrack=0 ; 
for kk=1:NumOfTracks 
    DoY=[] ; 
    SoD=[] ;
    time=[time ; ReflectionCoefficientAtSP(kk).time] ; 
    SPLAT=[SPLAT ; ReflectionCoefficientAtSP(kk).SpecularPointLat] ; 
    SPLON=[SPLON ; ReflectionCoefficientAtSP(kk).SpecularPointLon] ; 
    THETA=[THETA ; ReflectionCoefficientAtSP(kk).SPIncidenceAngle] ;
    sizetrack=length(ReflectionCoefficientAtSP(kk).time) ; 
    intrack=fintrack+1 ; 
    fintrack=intrack+sizetrack-1 ; 
  switch SAT(kk) ; 
    case "GPS"
  % 
    if ismissing(ReflectionCoefficientAtSP(kk).L1_LHCP)==0 , REFLECTIVITY_LINEAR_L1_L(intrack:fintrack)=10.^(ReflectionCoefficientAtSP(kk).L1_LHCP/10) ;...
            SNR_L1_L(intrack:fintrack)=ReflectionCoefficientAtSP(kk).SNR_L1_LHCP ; end
    if ismissing(ReflectionCoefficientAtSP(kk).L1_RHCP)==0, REFLECTIVITY_LINEAR_L1_R(intrack:fintrack)=10.^(ReflectionCoefficientAtSP(kk).L1_RHCP/10) ;...
            SNR_L1_R(intrack:fintrack)=ReflectionCoefficientAtSP(kk).SNR_L1_RHCP ; end
    if ismissing(ReflectionCoefficientAtSP(kk).L5_LHCP)==0, REFLECTIVITY_LINEAR_5_L(intrack:fintrack)= 10.^(ReflectionCoefficientAtSP(kk).L5_LHCP/10) ;...
        SNR_5_L(intrack:fintrack)= ReflectionCoefficientAtSP(kk).SNR_L5_LHCP ; end
    if ismissing(ReflectionCoefficientAtSP(kk).L5_RHCP)==0, REFLECTIVITY_LINEAR_5_R(intrack:fintrack)= 10.^(ReflectionCoefficientAtSP(kk).L5_RHCP/10) ;...
        SNR_5_R(intrack:fintrack)= ReflectionCoefficientAtSP(kk).SNR_L5_RHCP ; end
    
     case "Galileo"
    if ismissing(ReflectionCoefficientAtSP(kk).E1_LHCP)==0, REFLECTIVITY_LINEAR_E1_L(intrack:fintrack)=10.^(ReflectionCoefficientAtSP(kk).E1_LHCP/10) ;...
        SNR_E1_L(intrack:fintrack)=ReflectionCoefficientAtSP(kk).SNR_E1_LHCP ; end
    if ismissing(ReflectionCoefficientAtSP(kk).E1_RHCP)==0, REFLECTIVITY_LINEAR_E1_R(intrack:fintrack)=10.^(ReflectionCoefficientAtSP(kk).E1_RHCP/10) ;...
            SNR_E1_R(intrack:fintrack)=ReflectionCoefficientAtSP(kk).SNR_E1_RHCP ; end
    if ismissing(ReflectionCoefficientAtSP(kk).E5_LHCP)==0, REFLECTIVITY_LINEAR_5_L(intrack:fintrack)= 10.^(ReflectionCoefficientAtSP(kk).E5_LHCP/10) ;...
            SNR_5_L(intrack:fintrack)= ReflectionCoefficientAtSP(kk).SNR_E5_LHCP ; end
    if ismissing(ReflectionCoefficientAtSP(kk).E5_RHCP)==0, REFLECTIVITY_LINEAR_5_R(intrack:fintrack)= 10.^(ReflectionCoefficientAtSP(kk).E5_RHCP/10) ;...
            SNR_5_R(intrack:fintrack)= ReflectionCoefficientAtSP(kk).SNR_E5_RHCP ; end

  end % end case over the satgellite
end % end fir over the tracks

%  
Nameout=[char(Outfileprefix) '_' char(datetime('now','Format','yy-MM-dd_HH-mm'),'yy-MM-dd_HH-mm') '.mat'] ; 
%
save([char(DataOutputRootPath) '\' Nameout], 'SPLAT', 'SPLON', 'THETA', 'DoY',  'SoD', 'time',...
    'SAT', 'REFLECTIVITY_LINEAR_L1_L', 'REFLECTIVITY_LINEAR_L1_R', 'REFLECTIVITY_LINEAR_E1_L',...
    'REFLECTIVITY_LINEAR_E1_R', 'REFLECTIVITY_LINEAR_5_L', 'REFLECTIVITY_LINEAR_5_R',...
    'SNR_L1_L', 'SNR_L1_R', 'SNR_5_L', 'SNR_5_R', 'SNR_E1_L', 'SNR_E1_R') ; 

 disp([char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')) ' INFO: End of program']) ; 
 % fprintf(logfileID,[char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')) ' INFO: End of program']) ; 
 % fprintf(logfileID,'\n') ; 
 
end

