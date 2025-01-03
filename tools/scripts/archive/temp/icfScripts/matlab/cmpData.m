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

function cmpData(labSpFile,simSpFile)
% this funciton stacks the rf measured data and the simulated 

if iscell(labSpFile)
    numFiles = length(labSpFile); labSpFiles = labSpFile;
else
    numFiles = 1; labSpFiles{1} = labSpFile;
end

for ii=1:numFiles
    labSpFile = labSpFiles{ii};
    [pathFile, fileName, extName] = fileparts(labSpFile);
    lab = calculateQLSp(labSpFile);
    sim = calculateQLSp(simSpFile);
    fig = figure('Name', fileName);
    %% plot inductance
    lPlot = subplot(1,2,2); hold on
    y = smooth(lab(:,5));
    plot(lPlot,lab(:,1),y,'LineWidth',2,'Color','blue');
    plot(lPlot,sim(:,1),sim(:,5),'LineWidth',2,'Color','black');
    axis([0 max(sim(:,1)) 0 1.1*max(max(y),max(sim(:,5)))]);
    [simLpeak indexPeak] = max(sim(:,5)); simFpeak = sim(indexPeak,1);
    %text(simFpeak,1.01*simLpeak,'Lsimulated','FontSize',15);
    legend('rfLab','simulated')
    %% plot quality factor
    qPlot = subplot(1,2,1); hold on 
    y = smooth(lab(:,4)); 
    plot(qPlot,lab(:,1),y,'LineWidth',2,'Color','blue');
    plot(qPlot,sim(:,1),sim(:,4),'LineWidth',2,'Color','black'); hold off
    axis([0 max(sim(:,1)) 0 1.1*max(max(y),max(sim(:,4)))]);
    [simQpeak indexPeak] = max(sim(:,4)); simFpeak = sim(indexPeak,1);
    %text(simFpeak,1.01*simQpeak,'Qsimulated','FontSize',15);
    legend('rfLab','simulated')
    %% configure the plot
    xlabel(qPlot,'Frequency (GHz)'); xlabel(lPlot,'Frequency (GHz)');
    ylabel(qPlot,'Quality Factor');  ylabel(lPlot,'Inductance (nH)');
    title(lPlot,'Inductance'); title(qPlot,'Quality Factor');
end
