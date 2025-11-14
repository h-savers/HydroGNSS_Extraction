
function [DataTag, noday, Track_ID, IND_sixhours, L1b_ProcessorVersion, L1a_ProcessorVersion]=read_L1Bproduct(DataTag, Day_to_process,...
    SM_Time_resolution, Path_HydroGNSS_Data, metadata_name, readDDM, ...
    DDMs_name, Track_ID, IND_sixhours, L1b_ProcessorVersion, L1a_ProcessorVersion) ; 
%
% Track_ID: ID of the track written in the output structure which
% starts from the one the previous day
noday=0 ; 
global namelogfile logfileID  ; 
global ReflectionCoefficientAtSP Sigma0 ; 
%a
% ReflectionCoefficientAtSP={}  ; removed as it is initialized outside
% Sigma0={}  ; ReflectionCoefficientAtSP
% DataTag="" ; 
%
% ***********  loop on number of days to process for a single map
formatSpec='%02u' ; 
for j=1: SM_Time_resolution ; 
    SM_Day=Day_to_process+j-1  ; 
Month=month(SM_Day)  ; Day=day(SM_Day)   ; Year=year(SM_Day)   ; 
Path_L1B_day=[char(Path_HydroGNSS_Data), '\', num2str(Year), '-', num2str(Month, formatSpec),'\', num2str(Day,formatSpec)] ;
%
if exist(Path_L1B_day)==0 ; %, disp(['Directory of day ' char(SM_Day) ' does not exist. Skipped']), 
    disp([char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')) ' WARNING: Directory of day ' char(SM_Day) ' does not exist. Skipped']) ;
    fprintf(logfileID,[char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')) ' WARNING: Directory of day ' char(SM_Day) ' does not exist. Skipped']) ; 
    fprintf(logfileID,'\n') ; 
noday=1; 
continue 
end 


%
D=dir(Path_L1B_day) ; 
Num_sixhours=0 ; 
if length(D)==0 % , disp(['No L1B data found in directory of day ' char(SM_Day)]), 
    disp([char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')) ' WARNING: No L1B data found in directory of day ' char(SM_Day) '. Skipped']) ;
    fprintf(logfileID,[char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')) ' WARNING: Directory of day ' char(SM_Day) ' does not exist. Skipped']) ; 
    fprintf(logfileID,'\n') ; 
    noday=1 ; 
    return 
end; 
for jj=3:length(D)  ; % 
if D(jj).isdir==1 & exist([Path_L1B_day,'\',char(D(jj).name),'\',metadata_name])>0, Num_sixhours=Num_sixhours+1 ;  end  ;  ; 
end    
% Num_sixhours=length(D)-2 ; 
% disp(['Reading Year=', num2str(Year), ' Month=', num2str(Month), ' Day=', num2str(Day), ' Num_sixhours=', num2str(Num_sixhours)]) ; 
disp([char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')) ' INFO: Reading Year=', num2str(Year), ' Month=', num2str(Month), ' Day=', num2str(Day), ' Num_sixhours=', num2str(Num_sixhours)]) ;
fprintf(logfileID,[char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')) ' INFO: Reading Year=', num2str(Year), ' Month=', num2str(Month), ' Day=', num2str(Day), ' Num_sixhours=', num2str(Num_sixhours)]) ; 
fprintf(logfileID,'\n') ;
%
% create string array with all 6-hours segments within one day 
Dir_Day=[] ; 
% DataTag=[] ; 
for jj=3:Num_sixhours+2 ; 
        Dir_Day= [Dir_Day ; D(jj).name];
end
Dir_Day=string(Dir_Day) ; 

% toc
% disp('Initiate reading loop of 6-hours') ; 
% ***************  loop on 6-hours segments within one day 
DataTag="" ; 
for jj=1:Num_sixhours  ; 
%
disp(['Initiate reading loop of 6-hours: ' char(Dir_Day(jj))]) ;
%
if exist([Path_L1B_day,'\',char(Dir_Day(jj)),'\',metadata_name])==0
    disp([char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')) ' ERROR: metadata file does not exist. Program exiting']) ;
    fprintf(logfileID,[char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')) ' ERROR: metadata file does not exist. Program exiting']) ; 
    fprintf(logfileID,'\n') ;    
    return
end
%

% 
% % % L1a_AlgorithmVersion = ncreadatt([Path_L1B_day,'\',char(Dir_Day(jj)),'\',metadata_name], '/', 'L1a_AlgorithmVersion');

%
infometa=ncinfo([Path_L1B_day,'\',char(Dir_Day(jj)),'\',metadata_name]) ; 
[a, Num_Groups]=size(infometa.Groups) ; 
% Num_Groups= length(netcdf.inqGrps(ncid)) ; 

IND_sixhours=IND_sixhours+1  ; 
[a b ]= size(infometa.Attributes) ; % b is the numbero of elements in main Attribute to find the "DataTag" 
for jk=1:b ,  if infometa.Attributes(jk).Name == "DataTag" , ind=jk; end, end
DataTag(IND_sixhours)=convertCharsToStrings(infometa.Attributes(ind).Value) ; 
ncid = netcdf.open(fullfile([Path_L1B_day,'\',char(Dir_Day(jj))],metadata_name), 'NC_NOWRITE');
trackNcids = netcdf.inqGrps(ncid);
 for track = 1:length(trackNcids)
    channelNcids{track} = netcdf.inqGrps(trackNcids(track));    % ??? valkuare se fare un solo vettore che deve avere dumensiobni varabilim2x2 o 2x4
    for chan = 1:length(netcdf.inqGrps(trackNcids(track)))
        coinNcids{track}(chan,:) = netcdf.inqGrps(channelNcids{track}(chan));
    end
 end

% Init reading time and RX position for all the entire data vector
L1b_ProcessorVersion = netcdf.getAtt(ncid,netcdf.getConstant("NC_GLOBAL"),'L1b_ProcessorVersion');
L1a_ProcessorVersion = netcdf.getAtt(ncid,netcdf.getConstant("NC_GLOBAL"),'L1a_ProcessorVersion');

%%%%%  from here we read gloabal (all tracks) quantities. It could be
%%%%%  removed ?????????????
varID=netcdf.inqVarID(ncid, 'IntegrationMidPointTime')  ;
read=netcdf.getVar(ncid,varID)  ;
IntegrationMidPointTimetot=read ; 

varID=netcdf.inqVarID(ncid, 'ReceiverPositionX')  ;
read=netcdf.getVar(ncid,varID)  ;
ReceiverPositionXtot=read ; 

varID=netcdf.inqVarID(ncid, 'ReceiverPositionY')  ;
read=netcdf.getVar(ncid,varID)  ;
ReceiverPositionYtot=read ; 

varID=netcdf.inqVarID(ncid, 'ReceiverPositionZ') ;
read=netcdf.getVar(ncid,varID)  ;
ReceiverPositionZtot=read ; 
% End reading RX position for all the entire data vector
%%%%% to here ?????

if exist(fullfile([Path_L1B_day,'\',char(Dir_Day(jj))],DDMs_name)) ==0 ; 
disp([char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')) ' WARNING: DDM file does not exist in group ' char(string(Year)) '-' char(string(Month)) '-' char(string(Day)) '/' char(Dir_Day(jj)) '. Set DDM to "No"']) ;
fprintf(logfileID,[char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')) ' WARNING: DDM file does not exist in group ' char(string(Year)) '-' char(string(Month)) '-' char(string(Day)) '/' char(Dir_Day(jj)) '. Set DDM to "No"']) ;
fprintf(logfileID,'\n') ;
readDDM="No" ; 
elseif exist(fullfile([Path_L1B_day,'\',char(Dir_Day(jj))],DDMs_name)) >0 & readDDM=="Yes" |  exist(fullfile([Path_L1B_day,'\',char(Dir_Day(jj))],DDMs_name)) >0 & readDDM=="Y" 
ncid2 = netcdf.open(fullfile([Path_L1B_day,'\',char(Dir_Day(jj))],DDMs_name), 'NC_NOWRITE');
trackNcids2 = netcdf.inqGrps(ncid2);
for track = 1:length(trackNcids2)
    channelNcids2(track,:) = netcdf.inqGrps(trackNcids2(track));
    for chan = 1:length(channelNcids2(track,:))
        coinNcids2{track}(chan,:) = netcdf.inqGrps(channelNcids2(chan));
    end
 end

end


% toc
% disp('Initiate reading loop over groups') ; 
disp([char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')) ' INFO: Initiate reading tracks of group ' char(string(Year)) '-' char(string(Month)) '-' char(string(Day)) '/' char(Dir_Day(jj))]) ;
fprintf(logfileID,[char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')) ' INFO: Initiate reading tracks of group ' char(string(Year)) '-' char(string(Month)) '-' char(string(Day)) '/' char(Dir_Day(jj))]) ;
fprintf(logfileID,'\n') ;



% loop on Groups (i.e., tracks) within each 6-hours segment 
% Num_Groups=2 ; % WARNTING: this is to read only one group and speed up
firstsampleInGroup=1 ; % integer identifying the first sample of a track in the entire data vector   
for kk=1:Num_Groups ; 
% toc
% disp(['Reading Six-hour ', num2str(jj), ' of ', num2str(Num_sixhours), ' - Group/Track ', num2str(kk), ' of ', num2str(Num_Groups)]) ; 
disp([char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')) ' INFO: Reading Six-hour block ', char(Dir_Day(jj)), ' (', num2str(jj), ' of ', num2str(Num_sixhours), ') on ' char(datetime(Year, Month, Day)) '. Group/Track ', num2str(kk), ' of ', num2str(Num_Groups)]) ;
fprintf(logfileID,[char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')) ' INFO: Reading Six-hour block ', char(Dir_Day(jj)), ' (', num2str(jj), ' of ', num2str(Num_sixhours), ') on ' char(datetime(Year, Month, Day)) '. Group/Track ', num2str(kk), ' of ', num2str(Num_Groups)]) ; 
fprintf(logfileID,'\n') ;
%
[a NumberOfChannels]=size(infometa.Groups(kk).Groups) ; 
%
if NumberOfChannels > 0   
% Case of HydroGNSS with several channels. Read specular point data   
Track_ID=Track_ID+1 ; 
% [c d]=size(num2str(Track_ID)) ; 
% groupname='000000'; groupname(6-d+1:end)=num2str(Track_ID) ;
% ReflectionCoefficientAtSP(Track_ID).Name= groupname ; 
ReflectionCoefficientAtSP(Track_ID).Name=['Track n. ', num2str(Track_ID)] ; 
ReflectionCoefficientAtSP(Track_ID).PRN=infometa.Groups(kk).Attributes(7).Value  ; 
ReflectionCoefficientAtSP(Track_ID).GNSSConstellation_units=infometa.Groups(kk).Attributes(5).Value  ; 
ReflectionCoefficientAtSP(Track_ID).TrackIDOrbit=infometa.Groups(kk).Attributes(2).Value  ; 
varIdTime = netcdf.inqVarID(trackNcids(kk), 'IntegrationMidPointTime');
read=netcdf.getVar(trackNcids(kk), varIdTime);
[sizeGroup b]=size(read) ; % get the size of the group (or track) 

% read=ncread([Path_L1B_day,'\',char(Dir_Day(jj)),'\', metadata_name],...
%     [infometa.Groups(kk).Name, '/IntegrationMidPointTime']) ; 
ReflectionCoefficientAtSP(Track_ID).time=read ; 

varId = netcdf.inqVarID(trackNcids(kk), 'SpecularPointLat');
read=netcdf.getVar(trackNcids(kk), varId);

% read=ncread([Path_L1B_day,'\',char(Dir_Day(jj)),'\', metadata_name],...
%     [infometa.Groups(kk).Name, '/SpecularPointLat']) ; 
ReflectionCoefficientAtSP(Track_ID).SpecularPointLat=read ; 

varId = netcdf.inqVarID(trackNcids(kk), 'SpecularPointLon');
read=netcdf.getVar(trackNcids(kk), varId);

% read=ncread([Path_L1B_day,'\',char(Dir_Day(jj)),'\', metadata_name],...
%     [infometa.Groups(kk).Name, '/SpecularPointLon']) ;
ReflectionCoefficientAtSP(Track_ID).SpecularPointLon=read ; 
%
varId = netcdf.inqVarID(trackNcids(kk), 'LandType');
read=netcdf.getVar(trackNcids(kk), varId);
ReflectionCoefficientAtSP(Track_ID).LandType=read ; 
%
% Init calculate ranges 
%
varId = netcdf.inqVarID(trackNcids(kk), 'SpecularPointPositionX');
read=netcdf.getVar(trackNcids(kk), varId);
ReflectionCoefficientAtSP(Track_ID).SpecularPointPositionX=read ; 

varId = netcdf.inqVarID(trackNcids(kk), 'SpecularPointPositionY');
read=netcdf.getVar(trackNcids(kk), varId);
ReflectionCoefficientAtSP(Track_ID).SpecularPointPositionY=read ; 

varId = netcdf.inqVarID(trackNcids(kk), 'SpecularPointPositionZ');
read=netcdf.getVar(trackNcids(kk), varId);
ReflectionCoefficientAtSP(Track_ID).SpecularPointPositionZ=read ; 

varId = netcdf.inqVarID(trackNcids(kk), 'TransmitterPositionX');
read=netcdf.getVar(trackNcids(kk), varId);
ReflectionCoefficientAtSP(Track_ID).TransmitterPositionX=read ; 

varId = netcdf.inqVarID(trackNcids(kk), 'TransmitterPositionY');
read=netcdf.getVar(trackNcids(kk), varId);
ReflectionCoefficientAtSP(Track_ID).TransmitterPositionY=read ; 

varId = netcdf.inqVarID(trackNcids(kk), 'TransmitterPositionZ');
read=netcdf.getVar(trackNcids(kk), varId);
ReflectionCoefficientAtSP(Track_ID).TransmitterPositionZ=read ; 
% Extract the RX position at the correct time
%
ReceiverPositionX=zeros(sizeGroup,1)  ; 
ReceiverPositionY=zeros(sizeGroup,1)  ; 
ReceiverPositionZ=zeros(sizeGroup,1)  ; 
%
for ii=1: sizeGroup   %%%% ???? This look could be removed by reading variable into groups
indicesTime=find(IntegrationMidPointTimetot==ReflectionCoefficientAtSP(Track_ID).time(ii) ) ; 
%
ReceiverPositionX(ii)= ReceiverPositionXtot(indicesTime(1)) ; 
ReceiverPositionY(ii)= ReceiverPositionYtot(indicesTime(1)) ; 
ReceiverPositionZ(ii)= ReceiverPositionZtot(indicesTime(1)) ;
%
end 
%
ReflectionCoefficientAtSP(Track_ID).ReceiverPositionX=...
      ReceiverPositionX; 
ReflectionCoefficientAtSP(Track_ID).ReceiverPositionY=...
      ReceiverPositionY ;  
ReflectionCoefficientAtSP(Track_ID).ReceiverPositionZ=...
      ReceiverPositionZ ;  
%
% ReflectionCoefficientAtSP(Track_ID).ReceiverPositionX=...
%     ReceiverPositionXtot(firstsampleInGroup: firstsampleInGroup+sizeGroup-1) ;  
% 
% ReflectionCoefficientAtSP(Track_ID).ReceiverPositionY=...
%     ReceiverPositionYtot(firstsampleInGroup: firstsampleInGroup+sizeGroup-1) ;  
% 
% ReflectionCoefficientAtSP(Track_ID).ReceiverPositionZ=...
%     ReceiverPositionZtot(firstsampleInGroup: firstsampleInGroup+sizeGroup-1) ;  
% %
% firstsampleInGroup=firstsampleInGroup+sizeGroup ; 
%
% End calculate ranges 
%
varId = netcdf.inqVarID(trackNcids(kk), 'SPIncidenceAngle');
read=netcdf.getVar(trackNcids(kk), varId);
% read=ncread([Path_L1B_day,'\',char(Dir_Day(jj)),'\', metadata_name],...
%     [infometa.Groups(kk).Name,'/SPIncidenceAngle']) ;
ReflectionCoefficientAtSP(Track_ID).SPIncidenceAngle= read ; 

varId = netcdf.inqVarID(trackNcids(kk), 'SPAzimuthORF');
read=netcdf.getVar(trackNcids(kk), varId);
ReflectionCoefficientAtSP(Track_ID).SPAzimuthORF= read ; 

varId = netcdf.inqVarID(trackNcids(kk), 'SPAzimuthARF');
read=netcdf.getVar(trackNcids(kk), varId);
% read=ncread([Path_L1B_day,'\',char(Dir_Day(jj)),'\', metadata_name],...
%     [infometa.Groups(kk).Name,'/SPAzimuthARF']) ;
ReflectionCoefficientAtSP(Track_ID).PAzimuthARF=read ; 

varId = netcdf.inqVarID(trackNcids(kk), 'ReflectionHeight');
read=netcdf.getVar(trackNcids(kk), varId);
% read=ncread([Path_L1B_day,'\',char(Dir_Day(jj)),'\', metadata_name],...
%     [infometa.Groups(kk).Name,'/ReflectionHeight']) ;
ReflectionCoefficientAtSP(Track_ID).ReflectionHeight= read ; 
% Identify six hor directory to write 
ReflectionCoefficientAtSP(Track_ID).SixHourDir=string([num2str(Year),'-', num2str(Month, formatSpec),'\',num2str(Day,formatSpec), '\',char(Dir_Day(jj))]) ;  
%
% ii count the channels in each track 
for ii=1:NumberOfChannels ; % Loop on reading of variables inside incoherent group of each channel 'ii' (max 4) in track 'kk' 
%
% Find polarization and channel (Galileo E1, E5 or GPS L1, L5)
Polarization=infometa.Groups(kk).Groups(ii).Attributes(4).Value ; % polarization LHCP or RHCP
% Change by Mauro to fix bug on name of signal without undescore
infometa.Groups(kk).Groups(ii).Attributes(3).Value=replace(infometa.Groups(kk).Groups(ii).Attributes(3).Value, ' ', '_') ; 
% end change
%r
Signal=split(infometa.Groups(kk).Groups(ii).Attributes(3).Value, '_') ; 
ReflectionCoefficientAtSP(Track_ID).Satellite=Signal{1} ; 
Signal_Pol=[Signal{2}, '_', Polarization] ; 
switch Signal{1} 
    case 'GPS'
        switch Signal_Pol 
            case 'L1_LHCP' 
%                 ['ReflectionCoefficientAtSP', '.', Signal{2}, '_', Polarization] 

% Read flags for each channel 
% varIdch = netcdf.inqGrps(channelNcids(kk,ii));
varIdch =netcdf.inqGrps(channelNcids{kk}(ii)) ; 
varId=netcdf.inqVarID(varIdch(1), 'DirectSignalInDDM') ;
read=netcdf.getVar(varIdch(1), varId) ; 
FlagL1b=read ; 

% April 2023 % reading 'LowAGSP', 'LowSNR', 'VeryLowSNR', and 'HighNoiseKurtosis' from "incoherent measurement variables"
% varIdch = netcdf.inqGrps(channelNcids(kk,ii));
varId=netcdf.inqVarID(varIdch(1), 'LowAGSP') ; 
read=netcdf.getVar(varIdch(1), varId) ;
FlagL1b=FlagL1b+read.*2 ; 

% varIdch = netcdf.inqGrps(channelNcids(kk,ii));
varId=netcdf.inqVarID(varIdch(1), 'LowSNR') ; 
read=netcdf.getVar(varIdch(1), varId) ;
FlagL1b=FlagL1b+read.*4 ;

% varIdch = netcdf.inqGrps(channelNcids(kk,ii));
varId=netcdf.inqVarID(varIdch(1), 'VeryLowSNR') ; 
read=netcdf.getVar(varIdch(1), varId) ;
FlagL1b=FlagL1b+read.*8 ;

varId=netcdf.inqVarID(varIdch(1), 'HighNoiseKurtosis') ; 
read=netcdf.getVar(varIdch(1), varId) ;
FlagL1b=FlagL1b+read.*16 ;
ReflectionCoefficientAtSP(Track_ID).Kurtosis_DDM_L1_LHCP=FlagL1b  ; 

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'ReflectionCoefficientAtSP');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).L1_LHCP=read ; 

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'DDMSNRAtPeakSingleDDM');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).SNR_L1_LHCP=read  ; 

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'PowerSpreadRatio');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).PowerSpreadRatio_L1_LHCP=read  ; 

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'Sigma0');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
Sigma0(Track_ID).NBRCS_L1_LHCP=read ; 

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'EIRP');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).EIRP_L1_LHCP=read ; 

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'AntennaGainTowardsSpecularPoint');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).rxAntennaGain_L1_LHCP=read ; 

%varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'QC_pass_flag');
%read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
%ReflectionCoefficientAtSP(Track_ID).QualityControlFlags_L1_LHCP=read ; 

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'DDMSNRAtPeakSingleDDM');
read = netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).PowerAnalog_W_L1_LHCP = read;

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'MeanNoise');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).noise_floor_Counts_L1_LHCP=read ; 

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'NoiseKurtosis');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).Kurtosis_DOPP_0_L1_LHCP=read ; 

if readDDM=="Yes" | readDDM=="Y"
    
varId = netcdf.inqVarID(coinNcids2{kk}(ii,1), 'DDM');  
read=netcdf.getVar(coinNcids2{kk}(ii,1), varId, 'uint16');

% read=ncread([Path_L1B_day,'\',char(Dir_Day(jj)),'\', DDMs_name],...
%     [infometa.Groups(kk).Name,'/', infometa.Groups(kk).Groups(ii).Name,...
%     '/Incoherent/DDM']) ;
Sigma0(Track_ID).DDMs=read ; 
end

            case 'L1_RHCP'

% Read flags for each channel 
% varIdch = netcdf.inqGrps(channelNcids(kk,ii));
varIdch =netcdf.inqGrps(channelNcids{kk}(ii)) ; 
varId=netcdf.inqVarID(varIdch(1), 'DirectSignalInDDM') ; 
read=netcdf.getVar(varIdch(1), varId) ; 
FlagL1b=read ; 

% April 2023 % reading 'LowAGSP', 'LowSNR', 'VeryLowSNR', and 'HighNoiseKurtosis' from incoherent measurement variables
% varIdch = netcdf.inqGrps(channelNcids(kk,ii));
varId=netcdf.inqVarID(varIdch(1), 'LowAGSP') ; 
read=netcdf.getVar(varIdch(1), varId) ;
FlagL1b=FlagL1b+read.*2 ; 

% varIdch = netcdf.inqGrps(channelNcids(kk,ii));
varId=netcdf.inqVarID(varIdch(1), 'LowSNR') ; 
read=netcdf.getVar(varIdch(1), varId) ;
FlagL1b=FlagL1b+read.*4 ;

% varIdch = netcdf.inqGrps(channelNcids(kk,ii));
varId=netcdf.inqVarID(varIdch(1), 'VeryLowSNR') ; 
read=netcdf.getVar(varIdch(1), varId) ;
FlagL1b=FlagL1b+read.*8 ;

% varIdch = netcdf.inqGrps(channelNcids(kk,ii));
varId=netcdf.inqVarID(varIdch(1), 'HighNoiseKurtosis') ; 
read=netcdf.getVar(varIdch(1), varId) ;
FlagL1b=FlagL1b+read.*16 ;
ReflectionCoefficientAtSP(Track_ID).Kurtosis_DDM_L1_RHCP=FlagL1b  ; 

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'ReflectionCoefficientAtSP');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).L1_RHCP=read ; 

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'DDMSNRAtPeakSingleDDM');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).SNR_L1_RHCP=read  ; 

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'PowerSpreadRatio');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).PowerSpreadRatio_L1_RHCP=read  ; 

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'EIRP');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).EIRP_L1_RHCP=read ;   

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'AntennaGainTowardsSpecularPoint');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).rxAntennaGain_L1_RHCP=read ;   


% varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'QC_pass_flag');
% read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
% ReflectionCoefficientAtSP(Track_ID).QualityControlFlags_L1_RHCP=read ; 


varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'DDMSNRAtPeakSingleDDM');
read = netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).PowerAnalog_W_L1_RHCP = read;

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'MeanNoise');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).noise_floor_Counts_L1_RHCP=read ;   

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'NoiseKurtosis');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).Kurtosis_DOPP_0_L1_RHCP=read ; 

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'Sigma0');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
Sigma0(Track_ID).NBRCS_L1_RHCP=read ;   


if readDDM=="Yes" | readDDM=="Y"

varId = netcdf.inqVarID(coinNcids2{kk}(ii,1), 'DDM');  
read=netcdf.getVar(coinNcids2{kk}(ii,1), varId, 'uint16');

% read=ncread([Path_L1B_day,'\',char(Dir_Day(jj)),'\', DDMs_name],...
%     [infometa.Groups(kk).Name,'/', infometa.Groups(kk).Groups(ii).Name,...
%     '/Incoherent/DDM']) ;

Sigma0(Track_ID).DDMs=read ; 
end
            case 'L5_LHCP' 

                % Read flags for each channel 
% varIdch = netcdf.inqGrps(channelNcids(kk,ii));
varIdch =netcdf.inqGrps(channelNcids{kk}(ii)) ; 
varId=netcdf.inqVarID(varIdch(1), 'DirectSignalInDDM') ; 
read=netcdf.getVar(varIdch(1), varId) ; 
FlagL1b=read ; 

% April 2023 % reading 'LowAGSP', 'LowSNR', 'VeryLowSNR', and 'HighNoiseKurtosis' from incoherent measurement variables
% varIdch = netcdf.inqGrps(channelNcids(kk,ii));
varId=netcdf.inqVarID(varIdch(1), 'LowAGSP') ; 
read=netcdf.getVar(varIdch(1), varId) ;
FlagL1b=FlagL1b+read.*2 ; 

% varIdch = netcdf.inqGrps(channelNcids(kk,ii));
varId=netcdf.inqVarID(varIdch(1), 'LowSNR') ; 
read=netcdf.getVar(varIdch(1), varId) ;
FlagL1b=FlagL1b+read.*4 ;

% varIdch = netcdf.inqGrps(channelNcids(kk,ii));
varId=netcdf.inqVarID(varIdch(1), 'VeryLowSNR') ; 
read=netcdf.getVar(varIdch(1), varId) ;
FlagL1b=FlagL1b+read.*8 ;

% varIdch = netcdf.inqGrps(channelNcids(kk,ii));
varId=netcdf.inqVarID(varIdch(1), 'HighNoiseKurtosis') ; 
read=netcdf.getVar(varIdch(1), varId) ;
FlagL1b=FlagL1b+read.*16 ;
ReflectionCoefficientAtSP(Track_ID).Kurtosis_DDM_L5_LHCP=FlagL1b  ; 

% April 2023 %end 
% Read flags for each channel 
%
varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'ReflectionCoefficientAtSP');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).L5_LHCP=read ; 

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'PowerSpreadRatio');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).PowerSpreadRatio_L5_LHCP=read  ;

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'DDMSNRAtPeakSingleDDM');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).SNR_L5_LHCP=read  ; 

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'EIRP');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).EIRP_L5_LHCP=read ;

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'AntennaGainTowardsSpecularPoint');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).rxAntennaGain_L5_LHCP=read ;

% varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'QC_pass_flag');
% read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
% ReflectionCoefficientAtSP(Track_ID).QualityControlFlags_L5_LHCP=read ; 

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'DDMSNRAtPeakSingleDDM');
read = netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).PowerAnalog_W_L5_LHCP = read;

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'MeanNoise');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).noise_floor_Counts_L5_LHCP=read ;

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'NoiseKurtosis');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).Kurtosis_DOPP_0_L5_LHCP=read ;


varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'Sigma0');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
Sigma0(Track_ID).NBRCS_L5_LHCP= read ; 

if readDDM=="Yes" | readDDM=="Y"

varId = netcdf.inqVarID(coinNcids2{kk}(ii,1), 'DDM');  
read=netcdf.getVar(coinNcids2{kk}(ii,1), varId, 'uint16');

% read=ncread([Path_L1B_day,'\',char(Dir_Day(jj)),'\', DDMs_name],...
%     [infometa.Groups(kk).Name,'/', infometa.Groups(kk).Groups(ii).Name,...
%     '/Incoherent/DDM']) ;
Sigma0(Track_ID).DDMs=read ; 
end

            case 'L5_RHCP' 

% Read flags for each channel 
% varIdch = netcdf.inqGrps(channelNcids(kk,ii));
varIdch =netcdf.inqGrps(channelNcids{kk}(ii)) ; 
varId=netcdf.inqVarID(varIdch(1), 'DirectSignalInDDM') ; 
read=netcdf.getVar(varIdch(1), varId) ; 
FlagL1b=read ; 

% April 2023 % reading 'LowAGSP', 'LowSNR', 'VeryLowSNR', and 'HighNoiseKurtosis' from incoherent measurement variables

% varIdch = netcdf.inqGrps(channelNcids(kk,ii));
varId=netcdf.inqVarID(varIdch(1), 'LowAGSP') ; 
read=netcdf.getVar(varIdch(1), varId) ;
FlagL1b=FlagL1b+read.*2 ; 


% varIdch = netcdf.inqGrps(channelNcids(kk,ii));
varId=netcdf.inqVarID(varIdch(1), 'LowSNR') ; 
read=netcdf.getVar(varIdch(1), varId) ;
FlagL1b=FlagL1b+read.*4 ;

% varIdch = netcdf.inqGrps(channelNcids(kk,ii));
varId=netcdf.inqVarID(varIdch(1), 'VeryLowSNR') ; 
read=netcdf.getVar(varIdch(1), varId) ;
FlagL1b=FlagL1b+read.*8 ;

% varIdch = netcdf.inqGrps(channelNcids(kk,ii));
varId=netcdf.inqVarID(varIdch(1), 'HighNoiseKurtosis') ; 
read=netcdf.getVar(varIdch(1), varId) ;
FlagL1b=FlagL1b+read.*16 ;
ReflectionCoefficientAtSP(Track_ID).Kurtosis_DDM_L5_RHCP=FlagL1b  ;


varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'ReflectionCoefficientAtSP');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).L5_RHCP=read ; 

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'PowerSpreadRatio');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).PowerSpreadRatio_L5_RHCP=read  ; 

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'DDMSNRAtPeakSingleDDM');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).SNR_L5_RHCP=read  ; 

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'EIRP');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).EIRP_L5_RHCP=read ;

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'AntennaGainTowardsSpecularPoint');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).rxAntennaGain_L5_RHCP=read ;


% varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'QC_pass_flag');
% read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
% ReflectionCoefficientAtSP(Track_ID).QualityControlFlags_L5_RHCP=read ;

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'DDMSNRAtPeakSingleDDM');
read = netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).PowerAnalog_W_L5_RHCP = read;

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'MeanNoise');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).noise_floor_Counts_L5_RHCP=read ;

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'NoiseKurtosis');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).Kurtosis_DOPP_0_L5_RHCP=read ;

%
varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'Sigma0');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
% read=ncread([Path_L1B_day,'\',char(Dir_Day(jj)),'\', metadata_name],...
%     [infometa.Groups(kk).Name,'/', infometa.Groups(kk).Groups(ii).Name,...
%     '/Incoherent/Sigma0']) ;
Sigma0(Track_ID).NBRCS_L5_RHCP=read ; 

if readDDM=="Yes" | readDDM=="Y"

varId = netcdf.inqVarID(coinNcids2{kk}(ii,1), 'DDM');  
read=netcdf.getVar(coinNcids2{kk}(ii,1), varId, 'uint16');

% read=ncread([Path_L1B_day,'\',char(Dir_Day(jj)),'\', DDMs_name],...
%     [infometa.Groups(kk).Name,'/', infometa.Groups(kk).Groups(ii).Name,...
%     '/Incoherent/DDM']) ;
Sigma0(Track_ID).DDMs=read ; 
end

      otherwise
%         disp('NO GPS signal') 
    disp([char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')) ' WARNING: NO GPS signal']) ;
    fprintf(logfileID,[char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')) ' WARNING: NO GPS signal']) ; 
    fprintf(logfileID,'\n') ;

      end  % end switch case GPS 
    
case 'Galileo'
    
    switch Signal_Pol 
      case 'E1_LHCP' 
%                 ['ReflectionCoefficientAtSP', '.', Signal{2}, '_', Polarization] 
% Read flags for each channel 
% varIdch = netcdf.inqGrps(channelNcids(kk,ii));
varIdch =netcdf.inqGrps(channelNcids{kk}(ii)) ; 
varId=netcdf.inqVarID(varIdch(1), 'DirectSignalInDDM') ; 
read=netcdf.getVar(varIdch(1), varId) ; 
FlagL1b=read ; 

% April 2023 % reading 'LowAGSP', 'LowSNR', 'VeryLowSNR', and 'HighNoiseKurtosis' from incoherent measurement variables
% varIdch = netcdf.inqGrps(channelNcids(kk,ii));
varId=netcdf.inqVarID(varIdch(1), 'LowAGSP') ; 
read=netcdf.getVar(varIdch(1), varId) ;
FlagL1b=FlagL1b+read.*2 ; 

% varIdch = netcdf.inqGrps(channelNcids(kk,ii));
varId=netcdf.inqVarID(varIdch(1), 'LowSNR') ; 
read=netcdf.getVar(varIdch(1), varId) ;
FlagL1b=FlagL1b+read.*4 ;

% varIdch = netcdf.inqGrps(channelNcids(kk,ii));
varId=netcdf.inqVarID(varIdch(1), 'VeryLowSNR') ; 
read=netcdf.getVar(varIdch(1), varId) ;
FlagL1b=FlagL1b+read.*8 ;

% varIdch = netcdf.inqGrps(channelNcids(kk,ii));
varId=netcdf.inqVarID(varIdch(1), 'HighNoiseKurtosis') ; 
read=netcdf.getVar(varIdch(1), varId) ;
FlagL1b=FlagL1b+read.*16 ;
ReflectionCoefficientAtSP(Track_ID).Kurtosis_DDM_E1_LHCP=FlagL1b  ; 

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'ReflectionCoefficientAtSP');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).E1_LHCP=read ; 

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'PowerSpreadRatio');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).PowerSpreadRatio_E1_LHCP=read  ; 

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'DDMSNRAtPeakSingleDDM');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).SNR_E1_LHCP=read  ; 

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'EIRP');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).EIRP_E1_LHCP=read ;


varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'AntennaGainTowardsSpecularPoint');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).rxAntennaGain_E1_LHCP=read ;

% varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'QC_pass_flag');
% read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
% ReflectionCoefficientAtSP(Track_ID).QualityControlFlags_E1_LHCP=read ;

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'DDMSNRAtPeakSingleDDM');
read = netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).PowerAnalog_W_E1_LHCP = read;

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'MeanNoise');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).noise_floor_Counts_E1_LHCP=read ;

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'NoiseKurtosis');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).Kurtosis_DOPP_0_E1_LHCP=read ;



varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'Sigma0');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
Sigma0(Track_ID).NBRCS_E1_LHCP=read ; 

if readDDM=="Yes" | readDDM=="Y"

varId = netcdf.inqVarID(coinNcids2{kk}(ii,1), 'DDM');  
read=netcdf.getVar(coinNcids2{kk}(ii,1), varId, 'uint16');

% read=ncread([Path_L1B_day,'\',char(Dir_Day(jj)),'\', DDMs_name],...
%     [infometa.Groups(kk).Name,'/', infometa.Groups(kk).Groups(ii).Name,...
%     '/Incoherent/DDM']) ;
Sigma0(Track_ID).DDMs=read ; 
end

      case 'E1_RHCP'

% Read flags for each channel 
% varIdch = netcdf.inqGrps(channelNcids(kk,ii));
varIdch =netcdf.inqGrps(channelNcids{kk}(ii)) ; 
varId=netcdf.inqVarID(varIdch(1), 'DirectSignalInDDM') ; 
read=netcdf.getVar(varIdch(1), varId) ; 
FlagL1b=read ; 

% April 2023 % reading 'LowAGSP', 'LowSNR', 'VeryLowSNR', and 'HighNoiseKurtosis' from incoherent measurement variables
% varIdch = netcdf.inqGrps(channelNcids(kk,ii));
varId=netcdf.inqVarID(varIdch(1), 'LowAGSP') ; 
read=netcdf.getVar(varIdch(1), varId) ;
FlagL1b=FlagL1b+read.*2 ; 

% varIdch = netcdf.inqGrps(channelNcids(kk,ii));
varId=netcdf.inqVarID(varIdch(1), 'LowSNR') ; 
read=netcdf.getVar(varIdch(1), varId) ;
FlagL1b=FlagL1b+read.*4 ;

% varIdch = netcdf.inqGrps(channelNcids(kk,ii));
varId=netcdf.inqVarID(varIdch(1), 'VeryLowSNR') ; 
read=netcdf.getVar(varIdch(1), varId) ;
FlagL1b=FlagL1b+read.*8 ;

% varIdch = netcdf.inqGrps(channelNcids(kk,ii));
varId=netcdf.inqVarID(varIdch(1), 'HighNoiseKurtosis') ; 
read=netcdf.getVar(varIdch(1), varId) ;
FlagL1b=FlagL1b+read.*16 ;
ReflectionCoefficientAtSP(Track_ID).Kurtosis_DDM_E1_RHCP=FlagL1b  ; 

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'ReflectionCoefficientAtSP');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');          
ReflectionCoefficientAtSP(Track_ID).E1_RHCP=read ; 

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'PowerSpreadRatio');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).PowerSpreadRatio_E1_RHCP=read  ; 

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'DDMSNRAtPeakSingleDDM');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).SNR_E1_RHCP=read  ; 

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'EIRP');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).EIRP_E1_RHCP=read ;

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'AntennaGainTowardsSpecularPoint');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).rxAntennaGain_E1_RHCP=read ;

% varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'QC_pass_flag');
% read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
% ReflectionCoefficientAtSP(Track_ID).QualityControlFlags_E1_RHCP=read ;

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'DDMSNRAtPeakSingleDDM');
read = netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).PowerAnalog_W_E1_RHCP = read;

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'MeanNoise');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).noise_floor_Counts_E1_RHCP=read ;

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'NoiseKurtosis');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).Kurtosis_DOPP_0_E1_RHCP=read ;

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'Sigma0');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
Sigma0(Track_ID).NBRCS_E1_RHCP=read ;       

if readDDM=="Yes" | readDDM=="Y"

varId = netcdf.inqVarID(coinNcids2{kk}(ii,1), 'DDM');  
read=netcdf.getVar(coinNcids2{kk}(ii,1), varId, 'uint16');

% read=ncread([Path_L1B_day,'\',char(Dir_Day(jj)),'\', DDMs_name],...
%     [infometa.Groups(kk).Name,'/', infometa.Groups(kk).Groups(ii).Name,...
%     '/Incoherent/DDM']) ;
Sigma0(Track_ID).DDMs=read ; 
end

        case 'E5_LHCP' 
            
% Read flags for each channel 
% varIdch = netcdf.inqGrps(channelNcids(kk,ii));
varIdch =netcdf.inqGrps(channelNcids{kk}(ii)) ; 
varId=netcdf.inqVarID(varIdch(1), 'DirectSignalInDDM') ; 
read=netcdf.getVar(varIdch(1), varId) ; 
FlagL1b=read ; 

% April 2023 % reading 'LowAGSP', 'LowSNR', 'VeryLowSNR', and 'HighNoiseKurtosis' from incoherent measurement variables
% varIdch = netcdf.inqGrps(channelNcids(kk,ii));
varId=netcdf.inqVarID(varIdch(1), 'LowAGSP') ; 
read=netcdf.getVar(varIdch(1), varId) ;
FlagL1b=FlagL1b+read.*2 ; 

% varIdch = netcdf.inqGrps(channelNcids(kk,ii));
varId=netcdf.inqVarID(varIdch(1), 'LowSNR') ; 
read=netcdf.getVar(varIdch(1), varId) ;
FlagL1b=FlagL1b+read.*4 ;

% varIdch = netcdf.inqGrps(channelNcids(kk,ii));
varId=netcdf.inqVarID(varIdch(1), 'VeryLowSNR') ; 
read=netcdf.getVar(varIdch(1), varId) ;
FlagL1b=FlagL1b+read.*8 ;

% varIdch = netcdf.inqGrps(channelNcids(kk,ii));
varId=netcdf.inqVarID(varIdch(1), 'HighNoiseKurtosis') ; 
read=netcdf.getVar(varIdch(1), varId) ;
FlagL1b=FlagL1b+read.*16 ;
ReflectionCoefficientAtSP(Track_ID).Kurtosis_DDM_E5_LHCP=FlagL1b  ; 

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'ReflectionCoefficientAtSP');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');               
ReflectionCoefficientAtSP(Track_ID).E5_LHCP= read ; 

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'PowerSpreadRatio');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).PowerSpreadRatio_E5_LHCP=read  ; 

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'DDMSNRAtPeakSingleDDM');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).SNR_E5_LHCP=read  ; 

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'EIRP');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).EIRP_E5_LHCP=read ;

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'AntennaGainTowardsSpecularPoint');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).rxAntennaGain_E5_LHCP=read ;

% varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'QC_pass_flag');
% read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
% ReflectionCoefficientAtSP(Track_ID).QualityControlFlags_E5_LHCP=read ;

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'DDMSNRAtPeakSingleDDM');
read = netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).PowerAnalog_W_E5_LHCP = read;

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'MeanNoise');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).noise_floor_Counts_E5_LHCP=read ;

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'NoiseKurtosis');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).Kurtosis_DOPP_0_E5_LHCP=read ;


varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'Sigma0');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
Sigma0(Track_ID).NBRCS_E5_LHCP=read ; 

if readDDM=="Yes" | readDDM=="Y"

varId = netcdf.inqVarID(coinNcids2{kk}(ii,1), 'DDM');  
read=netcdf.getVar(coinNcids2{kk}(ii,1), varId, 'uint16');

% read=ncread([Path_L1B_day,'\',char(Dir_Day(jj)),'\', DDMs_name],...
%     [infometa.Groups(kk).Name,'/', infometa.Groups(kk).Groups(ii).Name,...
%     '/Incoherent/DDM']) ;
Sigma0(Track_ID).DDMs=read ; 
end
        case 'E5_RHCP' 
    
% Read flags for each channel 
% varIdch = netcdf.inqGrps(channelNcids(kk,ii));
varIdch =netcdf.inqGrps(channelNcids{kk}(ii)) ; 
varId=netcdf.inqVarID(varIdch(1), 'DirectSignalInDDM') ; 
read=netcdf.getVar(varIdch(1), varId) ; 
FlagL1b=read ; 

% April 2023 % reading 'LowAGSP', 'LowSNR', 'VeryLowSNR', and 'HighNoiseKurtosis' from incoherent measurement variables
% varIdch = netcdf.inqGrps(channelNcids(kk,ii));
varId=netcdf.inqVarID(varIdch(1), 'LowAGSP') ; 
read=netcdf.getVar(varIdch(1), varId) ;
FlagL1b=FlagL1b+read.*2 ; 

% varIdch = netcdf.inqGrps(channelNcids(kk,ii));
varId=netcdf.inqVarID(varIdch(1), 'LowSNR') ; 
read=netcdf.getVar(varIdch(1), varId) ;
FlagL1b=FlagL1b+read.*4 ;

% varIdch = netcdf.inqGrps(channelNcids(kk,ii));
varId=netcdf.inqVarID(varIdch(1), 'VeryLowSNR') ; 
read=netcdf.getVar(varIdch(1), varId) ;
FlagL1b=FlagL1b+read.*8 ;

% varIdch = netcdf.inqGrps(channelNcids(kk,ii));
varId=netcdf.inqVarID(varIdch(1), 'HighNoiseKurtosis') ; 
read=netcdf.getVar(varIdch(1), varId) ;
FlagL1b=FlagL1b+read.*16 ;
ReflectionCoefficientAtSP(Track_ID).Kurtosis_DDM_E5_RHCP=FlagL1b  ;
              
varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'ReflectionCoefficientAtSP');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).E5_RHCP=read ; 

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'PowerSpreadRatio');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).PowerSpreadRatio_E5_RHCP=read  ; 

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'DDMSNRAtPeakSingleDDM');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).SNR_E5_RHCP=read  ; 

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'EIRP');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).EIRP_E5_RHCP=read ;

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'AntennaGainTowardsSpecularPoint');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).rxAntennaGain_E5_RHCP=read ;

% varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'QC_pass_flag');
% read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
% ReflectionCoefficientAtSP(Track_ID).QualityControlFlags_E5_RHCP=read ;

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'DDMSNRAtPeakSingleDDM');
read = netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).PowerAnalog_W_E5_RHCP = read;

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'MeanNoise');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).noise_floor_Counts_E5_RHCP=read ;

varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'NoiseKurtosis');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
ReflectionCoefficientAtSP(Track_ID).Kurtosis_DOPP_0_E5_RHCP=read ;


varId = netcdf.inqVarID(coinNcids{kk}(ii,1), 'Sigma0');
read=netcdf.getVar(coinNcids{kk}(ii,1), varId, 'double');
Sigma0(Track_ID).NBRCS_E5_RHCP=read ; 

if readDDM=="Yes" | readDDM=="Y"
    
varId = netcdf.inqVarID(coinNcids2{kk}(ii,1), 'DDM');  
read=netcdf.getVar(coinNcids2{kk}(ii,1), varId, 'uint16');

% read=ncread([Path_L1B_day,'\',char(Dir_Day(jj)),'\', DDMs_name],...
%     [infometa.Groups(kk).Name,'/', infometa.Groups(kk).Groups(ii).Name,...
%     '/Incoherent/DDM']) ;
Sigma0(Track_ID).DDMs=read ; 
end

      otherwise
%         disp('NO Galileo signal') 
    disp([char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')) ' WARNING: NO Galileo signal']) ;
    fprintf(logfileID,[char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')) ' WARNING: NO Galileo signal']) ; 
    fprintf(logfileID,'\n') ;

    end  % end switch case Galileo
    otherwise
%         disp('NO TX constellation') 
    disp([char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')) ' WARNING: NO TX constellation']) ;
    fprintf(logfileID,[char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')) ' WARNING: NO TX constellation']) ; 
    fprintf(logfileID,'\n') ;

 end  % end switch between signals / pol 
% ReflectionCoefficientAtSP(Track_ID).Satellite=Signal{1} ; 
end       % end loop on channels 
        

elseif NumberOfChannels== 0  ; 
read=ncread([Path_L1B_day,'\',char(Dir_Day(jj)),'\', metadata_name], ['/',...
    infometa.Groups(kk).Name,'/IntegrationMidPointTime']) ; 
IntegrationMidPointTime=[IntegrationMidPointTime, read'] ;  
read=ncread([Path_L1B_day,'\',char(Dir_Day(jj)),'\', metadata_name], ['/',...
    infometa.Groups(kk).Name,'/SpecularPointLat']) ; 
SpecularPointLat=[SpecularPointLat, read'] ; 

read=ncread([Path_L1B_day,'\',char(Dir_Day(jj)),'\', metadata_name], ['/',...
    infometa.Groups(kk).Name,'/SpecularPointLon']) ;
SpecularPointLon=[SpecularPointLon, read'] ; 

read=ncread([Path_L1B_day,'\',char(Dir_Day(jj)),'\', metadata_name], ['/',...
    infometa.Groups(kk).Name,'/SPIncidenceAngle']) ;
SPIncidenceAngle=[SPIncidenceAngle read'] ; 

read=ncread([Path_L1B_day,'\',char(Dir_Day(jj)),'\', metadata_name], ['/',...
    infometa.Groups(kk).Name,'/PAzimuthARF']) ;
PAzimuthARF=[PAzimuthARF read'] ; 

read=ncread([Path_L1B_day,'\',char(Dir_Day(jj)),'\', metadata_name], ['/',...
    infometa.Groups(kk).Name,'/ReflectionHeight']) ;
ReflectionHeight=[ReflectionHeight read'] ; 

read=ncread([Path_L1B_day,'\',char(Dir_Day(jj)),'\', metadata_name], ['/',...
    infometa.Groups(kk).Name,'/DDMSNRAtPeakSingleDDM']) ; 
DDMSNRAtPeakSingleDDM=[DDMSNRAtPeakSingleDDM, read'] ; 

read=ncread([Path_L1B_day,'\',char(Dir_Day(jj)),'\DDMs.nc'], ['/',...
    infometa.Groups(kk).Name,'/DDM']) ; 
DDM=cat(3, DDM, read) ; 
% Reading DDMs

% [column,row] = geo2easeGrid(SpecularPointLat,SpecularPointLon);
% AccuDDMSNR =accumarray([row column],10.^(DDMSNRAtPeakSingleDDM/10), [], @mean) ;
    end
end % end loop on number of groups/tracks
netcdf.close(ncid) ; 
if readDDM=="Yes" | readDDM=="Y" , netcdf.close(ncid2) , end ; 
end % end loop on number of six-hour blocks 
end % end loop on number of days

end
