%##############################################################################
%# Author:
%#   Mauricio Marulanda
%##############################################################################
function spOut = deembedmm(varargin)
% This function de-embeds opens, shorts, and throughs from the sparameter file crude
% method, substracting Capacitance and Resistances literally from raw
% sparameter data
% Input should be sparameterFile, followed by optional properties: 'shorts',shortsFile,'opens',opensFile,'thrus',thrusFile
% The output is the filename_DEmm.s2p

%% check input functions
isFile = @(fileName) any(exist(fileName,'file'));
%% Read the inputs
inputs = inputParser;
inputs.addRequired('spFileName',isFile);
inputs.addOptional('shorts',false,isFile);
inputs.addOptional('opens',false,isFile);
inputs.addOptional('throughs',false,isFile);
inputs.addOptional('through',false,isFile);
inputs.addOptional('thrus',false,isFile);
inputs.addOptional('pads',false,isFile);
inputs.addOptional('outFileName',false);
inputs.parse(varargin{:}); args = inputs.Results;
if ischar(args.throughs) % if throughs are given only used the thrus variable
    args.thrus = args.throughs;
end
if ischar(args.through) % if throughs are given only used the thrus variable
    args.thrus = args.through;
end
%% Read the measured sparam data
spInData = read(rfdata.data, inputs.Results.spFileName); % read the file
[pathFile, fileName, extName] = fileparts(inputs.Results.spFileName); %get the file information for 2 or 3 ports
spIn = spInData.S_Parameters; z0 = spInData.Z0; freq = spInData.Freq;
outFileName = [fileName '_De'];   %set the name

%% CASE 1: if pads are given 
if ischar(args.pads)
    spPadData = read(rfdata.data,args.pads); spPads = spPadData.S_Parameters; %read the pads
    yOut = s2y(spIn,z0) - s2y(spPads,z0);
    zOut = y2z(yOut);
    outFileName = [outFileName 'Pd'];
    if ischar(args.shorts)
        spShortData = read(rfdata.data,args.shorts); spShorts = spShortData.S_Parameters; %read the shorts
        yCalSh = s2y(spShorts,z0) - s2y(spPads,z0);  
        zCalSh = y2z(yCalSh);
        outFileName = [outFileName 'Sh'];
    else
        zCalSh = 0;
    end
    if ischar(args.opens)
        spOpenData = read(rfdata.data,args.opens); spOpens = spOpenData.S_Parameters; %read the opens
        yCalOp = s2y(spOpens,z0) - s2y(spPads,z0);
        zCalOp = y2z(yCalOp) - zCalSh;
        yCalOp = z2y(zCalOp);
        outFileName = [outFileName 'Op'];
    else
        yCalOp = 0;
    end
    %spOut = z2s(y2z(yOut-yCalOp) - zCalSh,z0);  %doing opens then shorts    
    zOut = zOut - zCalSh;
    yOut = z2y(zOut); 
    spOut = y2s(yOut-yCalOp,z0);
else
%% CASE 2: if the throughs, shorts, and opens are given
    if ischar(args.shorts) && ischar(args.opens) && ischar(args.thrus)
        disp('De-embedding shorts, opens, and throughs')
        spOpenData = read(rfdata.data, args.opens); spOpens = spOpenData.S_Parameters;% read the opens
        yOpens = s2y(spOpens,z0);
        spShortData = read(rfdata.data, args.shorts); spShorts = spShortData.S_Parameters;% read the opens
        yShorts = s2y(spShorts,z0);
        spThruData = read(rfdata.data, args.thrus); spThrus = spThruData.S_Parameters;% read the opens    
        yThrus = s2y(spThrus,z0);
        G1 = yOpens(1,1,:)+yOpens(1,2,:); G2 = yOpens(2,2,:)+yOpens(1,2);
        G3 = (-1./yOpens(1,2,:)+1./yThrus(1,2,:)).^-1;
        Z1 = 0.5*(-1/yThrus(1,2,:)+1./(yShorts(1,1,:)-G1)-1/(yShorts(2,2,:)-G2));
        Z2 = 0.5*(-1/yThrus(1,2,:)-1./(yShorts(1,1,:)-G1)+1/(yShorts(2,2,:)-G2));
        Z3 = 0.5*(-1/yThrus(1,2,:)+1./(yShorts(1,1,:)-G1)+1/(yShorts(2,2,:)-G2));
        yData = s2y(spIn,z0); 
        yOutA = yData - [G1,zeros(1,1,size(G1,3));zeros(1,1,size(G1,3)),G2];
        zOutB = y2z(yOutA)-[Z1+Z3,Z3;Z3,Z2+Z3];
        yOut = z2y(zOutB)-[G3,-G3;-G3,G3];
        spOut = y2s(yOut,z0);
        outFileName = [outFileName 'OpShTh'];
    else
%% CASE 3: if only throughs    
        if ischar(args.thrus)
            disp('De-embedding throughs')
            spThruData = read(rfdata.data, args.thrus); spThrus = spThruData.S_Parameters; % read the thrus           
            tThrus = s2t(spThrus); 
            tThrusEff = arrayfun(@(freq) tThrus(:,:,freq)^0.5,1:size(tThrus,3),'UniformOutput',0); tThrusEff = cat(3,tThrusEff{:});
            spThrusEff = t2s(tThrusEff); 
            spOut = deembedsparams(spIn,spThrusEff,spThrusEff);
            outFileName = [outFileName 'Th'];
%% CASE 4: if throughs and opens
            if ischar(args.opens)
                disp('De-embedding opens')
                spOpenFile = read(rfdata.data,args.opens); %read the opens
                spOpenEff = deembedsparams(spOpenFile.S_Parameters,spThrusEff,spThrusEff);
                yOut = s2y(spOut) - s2y(spOpenEff,z0);
                spOut = y2s(yOut,z0);
                outFileName = [outFileName 'Op'];	
            end	
        else
%% CASE 4: if either opens or shorts or both
            if ischar(args.opens)
                disp('De-embedding opens')
                spOpenFile = args.opens;
                spOpenData = read(rfdata.data, spOpenFile); % read the opens
                %% convert to y
                yData = s2y(spIn,z0);
                yOpen = s2y(spOpenData.S_Parameters,z0);
                yOut = yData - yOpen;
                spOut = y2s(yOut,z0);
                spIn = spOut;
                outFileName = [outFileName 'Op'];
            end
            %% if only the shorts or with opens
            if ischar(args.shorts)
                disp('De-embedding shorts')
                spShortFile = args.shorts;
                spShortData = read(rfdata.data, spShortFile); % read the shorts
                %% convert to z
                zData = s2z(spIn,z0);
                if ischar(args.opens)
                    yShortRaw = s2y(spShortData.S_Parameters,z0);
                    zShort = y2z(yShortRaw - yOpen);
                else
                    zShort = s2z(spShortData.S_Parameters,z0);
                end
                zOut = zData - zShort;
                spOut = z2s(zOut,z0);
                spIn = spOut;
                outFileName = [outFileName 'Sh'];
            end 
        end
    end
end
%% create the new sparameter object
spOutData = rfdata.data;
spOutData.S_Parameters = spOut;
spOutData.Freq = freq;
spOutData.Z0 = z0;
outFileName = [outFileName extName];
if ischar(args.outFileName) % if specific outputFileName is given
    outFileName = args.outFileName;
%% create the file
if exist(outFileName,'file') == 2
    delete(outFileName); warning('Output file existed and was overwritten')
end
write(spOutData,outFileName); disp(['Wrote the file ' outFileName])

end
