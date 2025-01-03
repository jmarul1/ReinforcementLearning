function spOut = convertPorts(varargin)
 %% check input functions
 isFile = @(fileName) any(exist(fileName,'file'));
 isValid = @(x) isnumeric(x) && isscalar(x) && (x > 0);
 %% Read the inputs
 inputs = inputParser;
 inputs.addRequired('spFileName',isFile);
 inputs.addRequired('newPorts',isValid);
 inputs.parse(varargin{:}); args = inputs.Results;
 %% Read the  sparam data
 spInData = read(rfdata.data, inputs.Results.spFileName); % read the file
 [pathFile, fileName, extName] = fileparts(inputs.Results.spFileName); %get the file information for 2 or 3 ports
 spIn = spInData.S_Parameters; z0 = spInData.Z0; freq = spInData.Freq;
 %% Convert
 spOut = snp2smp(spIn,z0,[1:inputs.Results.newPorts],0);
 %% create the new sparameter object
 spOutData = rfdata.data;
 spOutData.S_Parameters = spOut;
 spOutData.Freq = freq;
 spOutData.Z0 = z0;
 outFileName = [fileName '.s' num2str(inputs.Results.newPorts) 'p'];  
 write(spOutData,outFileName); disp(['Wrote the file ' outFileName])
end
