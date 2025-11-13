function WriteConfig(configurationPath, ProcessingSatellite, DataInputRootPath, DataOutputRootPath, LogsOutputRootPath, Outfileprefix, LatSouth, LatNorth, LonWest, LonEast, Dayinit, Dayfinal, DDM)
conffileID = fopen(configurationPath, 'W') ; 
% conffileID = fopen(configurationPath) ; 
fprintf(conffileID,'%s',['ProcessingSatellite=' ProcessingSatellite] ); fprintf(conffileID,'\n') ; 
fprintf(conffileID,'%s', ['DataInputRootPath=' DataInputRootPath] ); fprintf(conffileID,'\n') ; 
fprintf(conffileID,'%s',['DataOutputRootPath=' DataOutputRootPath] ); fprintf(conffileID,'\n') ; 
fprintf(conffileID,'%s',['LogsOutputRootPath=' LogsOutputRootPath] ); fprintf(conffileID,'\n') ; 
fprintf(conffileID,'%s',['Outfileprefix=' Outfileprefix] ); fprintf(conffileID,'\n') ; 
fprintf(conffileID,['LatSouth=' char(string(LatSouth))] ); fprintf(conffileID,'\n') ; 
fprintf(conffileID,['LatNorth=' char(string(LatNorth))] ); fprintf(conffileID,'\n') ; 
fprintf(conffileID,['LonWest=' char(string(LonWest))] ); fprintf(conffileID,'\n') ; 
fprintf(conffileID,['LonEast=' char(string(LonEast))] ); fprintf(conffileID,'\n') ; 
fprintf(conffileID,'%s',['Dayinit=' Dayinit] ); fprintf(conffileID,'\n') ; 
fprintf(conffileID,'%s',['Dayfinal=' Dayfinal] ); fprintf(conffileID,'\n') ; 
fprintf(conffileID,'%s',['DDM=' DDM] ); fprintf(conffileID,'\n') ; 
fclose(conffileID) ;
end