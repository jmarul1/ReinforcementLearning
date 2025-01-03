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
function plotSpfile(spFileName)
% This function plots the capacitance and resistance of calibration sparameter file

spData = read(rfdata.data, spFileName); % read the file
[pathFile, fileName, extName] = fileparts(spFileName); %get the file information for 2 or 3 ports

freq = spData.Freq;
%% get the capacitance, resistance, and inductance
yData = s2y(spData.S_Parameters,spData.Z0);
zData = s2z(spData.S_Parameters,spData.Z0);
for ii=1:length(yData)
    twoPiF = (2*pi()*freq(ii));
    c11(ii) = imag(yData(1,1,ii))/twoPiF*1e15; % in fF
    r11(ii) = real(zData(1,1,ii)); % in Ohms
    l11(ii) = imag(zData(1,1,ii))/twoPiF*1e9; % in nH
    q11(ii) = imag(yData(1,1,ii))/real(yData(1,1,ii))
    c12(ii) = imag(yData(1,2,ii))/twoPiF*1e15; % in fF
    r12(ii) = real(zData(1,2,ii)); % in Ohms
    l12(ii) = imag(zData(1,2,ii))/twoPiF*1e9; % in nH
    q12(ii) = imag(zData(1,2,ii))/real(zData(1,2,ii))        
    c21(ii) = imag(yData(2,1,ii))/twoPiF*1e15; % in fF
    r21(ii) = real(zData(2,1,ii)); % in Ohms
    l21(ii) = imag(zData(2,1,ii))/twoPiF*1e9; % in nH
    q21(ii) = imag(zData(2,1,ii))/real(zData(2,1,ii))    
    c22(ii) = imag(yData(2,2,ii))/twoPiF*1e15; % in fF
    r22(ii) = real(zData(2,2,ii)); % in Ohms
    l22(ii) = imag(zData(2,2,ii))/twoPiF*1e9; % in nH
    q22(ii) = imag(yData(2,2,ii))/real(yData(2,2,ii))    
end

%% plot the capacitance
fig1 = figure('Name', 'Capacitance');
plot11 = subplot(2,2,1); plot12 = subplot(2,2,2); plot21 = subplot(2,2,3); plot22 = subplot(2,2,4);
plot(plot11,freq/1e9,c11); plot(plot12,freq/1e9,c12); plot(plot21,freq/1e9,c21); plot(plot22,freq/1e9,c22);
axesList = findobj(fig1,'Type','Axes'); temp = get(axesList,'XLabel'); temp = [temp{:}]; set(temp,'String','Frequency (GHz)'); temp = get(axesList,'YLabel'); temp = [temp{:}]; set(temp,'String','Capacitance (fF)');
title(plot11,'C11'); title(plot21,'C21'); title(plot12,'C12'); title(plot22,'C22')

%% plot the resistance
fig2 = figure('Name', 'Resistance');
plot11 = subplot(2,2,1); plot12 = subplot(2,2,2); plot21 = subplot(2,2,3); plot22 = subplot(2,2,4);
semilogy(plot11,freq/1e9,r11); semilogy(plot12,freq/1e9,r12); semilogy(plot21,freq/1e9,r21); semilogy(plot22,freq/1e9,r22);
axesList = findobj(fig2,'Type','Axes'); temp = get(axesList,'XLabel'); temp = [temp{:}]; set(temp,'String','Frequency (GHz)'); temp = get(axesList,'YLabel'); temp = [temp{:}]; set(temp,'String','Resistance (Ohms)');
title(plot11,'R11'); title(plot21,'R21'); title(plot12,'R12'); title(plot22,'R22')
    
%% plot the inductance
fig3 = figure('Name', 'Inductance');
plot11 = subplot(2,2,1); plot12 = subplot(2,2,2); plot21 = subplot(2,2,3); plot22 = subplot(2,2,4);
plot(plot11,freq/1e9,l11); plot(plot12,freq/1e9,l12); plot(plot21,freq/1e9,l21); plot(plot22,freq/1e9,l22);
axesList = findobj(fig3,'Type','Axes'); temp = get(axesList,'XLabel'); temp = [temp{:}]; set(temp,'String','Frequency (GHz)'); temp = get(axesList,'YLabel'); temp = [temp{:}]; set(temp,'String','Inductance (nH)');
title(plot11,'L11'); title(plot21,'L21'); title(plot12,'L12'); title(plot22,'L22')

%% plot the QualityFactor
fig4 = figure('Name', 'Quality Factor');
plot11 = subplot(1,1,1); %plot12 = subplot(2,2,2); plot21 = subplot(2,2,3); plot22 = subplot(2,2,4);
hold on
plot(plot11,freq/1e9,q11); %plot(plot12,freq/1e9,q12); plot(plot21,freq/1e9,q21);
plot(plot11,freq/1e9,q22);
axesList = findobj(fig3,'Type','Axes'); temp = get(axesList,'XLabel'); temp = [temp{:}]; set(temp,'String','Frequency (GHz)'); temp = get(axesList,'YLabel'); temp = [temp{:}]; set(temp,'String','Inductance (nH)');
title(plot11,'Q11');% title(plot21,'Q21'); title(plot12,'Q12'); title(plot22,'Q22')
hold off
%% plot the smith chart
fig5 = figure('Name', 'SmithChart');
subplot(2,2,1); plot11 = smith(spData,'S11'); set(plot11,'LineWidth',2);
subplot(2,2,2); plot12 = smith(spData,'S12'); set(plot12,'LineWidth',2);
subplot(2,2,3); plot21 = smith(spData,'S21'); set(plot21,'LineWidth',2);
subplot(2,2,4); plot22 = smith(spData,'S22'); set(plot22,'LineWidth',2);
