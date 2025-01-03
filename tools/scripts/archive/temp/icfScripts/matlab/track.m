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
function track(fname);
% TRACK filename
%       Track plots the progress of full-wave optimizations.    
%       "filename" is optimization data extracted by extractTrace, which
%       must have a "dat" extension. "filename" should be specified
%       without this extension.

fsmat = sprintf('%s.dat', fname);
outname = sprintf('%s.png', fname);
d = load (fsmat);

t = 1:length(d(:,1));

figure(1);
clf;
subplot(2,3,1);
plot(t, d(:,1), 'x-');
ylabel('NT');
grid;

subplot(2,3,2);
plot(t, d(:,2), 'o-');
ylabel('OD (\mu{m})');
grid;

subplot(2,3,3);
plot(t, d(:,6), '+-r');
ylabel('L (nH)');
grid;

subplot(2,3,4);
plot(t, d(:,3), '^-');
ylabel('W (\mu{m})');
grid;

subplot(2,3,5);
plot(t, d(:,4), '^-');
ylabel('S (\mu{m})');
xlabel('Optimization iterations');
grid;

subplot(2,3,6);
plot(t, d(:,5), '*-r');
ylabel('Q');
grid;

print('-dpng', outname);
