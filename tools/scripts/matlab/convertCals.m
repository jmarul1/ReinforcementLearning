%##############################################################################
%# Intel Top Secret                                                           #
%##############################################################################
%# Copyright (C) 2015, Intel Corporation.  All rights reserved.               #
%#                                                                            #
%# This is the property of Intel Corporation and may only be utilized         #
%# pursuant to a written Restricted Use Nondisclosure Agreement               #
%# with Intel Corporation.  It may not be used, reproduced, or                #
%# disclosed to others except in accordance with the terms and                #
%# conditions of such agreement.                                              #
%#                                                                            #
%# All products, processes, computer systems, dates, and figures              #
%# specified are preliminary based on current expectations, and are           #
%# subject to change without notice.                                          #
%##############################################################################
%# Author:
%#   Mauricio Marulanda
%##############################################################################
function convertCals(spFileName,remove)
% this funciton converts the cals, it removes the S12,S21 components
% if the second argument is given the real parts are also removed
spInData = read(rfdata.data, spFileName); % read the file
[pathFile, fileName, extName] = fileparts(spFileName); %get the file information for 2 or 3 ports
spIn = spInData.S_Parameters; z0 = spInData.Z0;
spIn(1,2,:) = 0;
spIn(2,1,:) = 0;

if exist('remove','var')
    zIn = s2z(spIn,z0);
    for ii=1:length(zIn)
        zIn(1,1,ii) = 1i*imag(zIn(1,1,ii));
        zIn(2,2,ii) = 1i*imag(zIn(2,2,ii));
    end
    spIn = z2s(zIn,z0);
end

spInData.S_Parameters = spIn;
write(spInData,[fileName '_mm' extName]); disp(['Wrote the file ' fileName '_mm' extName])
