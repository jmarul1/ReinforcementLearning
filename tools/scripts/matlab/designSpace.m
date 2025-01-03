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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Program property of Intel Corporation
% (C) Copyright Intel Corporation, 2004
% All Rights Reserved
%
% This script is the property of Intel and is furnished pursuant to a written
% license agreement.  It may not be used, reproduced, or disclosed to others
% except in accordance with the terms and conditions of that agreement.
%
% Function: designSpace
% Overview: Plots the design space output from RIDE. If no range is specified,
%           L and Q are plotted with respect to frequency.
% Input:    A file with the dat extension output by RIDE
% Usage:    designSpace filename [number of contours]
% Date:     Q4, 2004
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function designSpace(filename, N)

if (nargin < 1)
    error('Usage: designSpace filename [number of contours]');
elseif (nargin == 1)
    N = 15;
end

fid = fopen(filename, 'r');

inductor = fgetl(fid);
pngName = inductor;
pngName((length(pngName) - 3):length(pngName)) = '.png';
inductor = escapeUnderScore(inductor);

turnsCnt = fread(fid, 1, 'int');

disp(sprintf(sprintf('Inductor = %s', inductor)));

if (turnsCnt == 0)

  nf = fread(fid, 1, 'int');

  turns = fread(fid, 1, 'double');
  spacings = fread(fid, 1, 'double');
  widths = fread(fid, 1, 'double');
  dims = fread(fid, 1, 'double');

  raw = fread(fid, nf * 3, 'double');
  raw = reshape(raw, 3, nf);

  [fullwave, count] = fread(fid, nf * 2, 'double');
  if (count > 0)
    fullwave = reshape(fullwave, 2, nf);
  end

  if (nargin == 2)
    raw = raw(:, 1:N);
    fullwave = fullwave(:, 1:N);
  end

  figure(1); clf;

  subplot(2,1,1);
  if (count == 0)
    plot(raw(1,:), raw(2,:), '--');
    legend('Analytic', 0);
  else
    plot(raw(1,:), raw(2,:), '--', raw(1,:), fullwave(1,:), '-.');
    legend('Analytic', 'Full-wave', 0);
  end
  title(sprintf('%s (NT=%g, S=%g, W=%g, OD=%g \\mu{m})', ...
        inductor, turns, spacings, widths, dims));
  grid;
  xlabel(sprintf( ...
    '\\Delta{Q_{peak}} = %g%%, \\Delta{L_{DC}} = %g%%', ...
    relPeakErr(fullwave(2,:), raw(3,:)), ...
    relPeakErr(fullwave(1,1), raw(2,1))));
  ylabel('L (nH)');

  subplot(2,1,2);
  if (count == 0)
    plot(raw(1,:), raw(3,:), '--');
    legend('Analytic', 0);
  else
    plot(raw(1,:), raw(3,:), '--', raw(1,:), fullwave(2,:), '-.');
    legend('Analytic', 'Full-wave', 0);
  end
  grid;
  xlabel('frequency (GHz)'); ylabel('Q');

  print('-dpng', pngName);
  disp(sprintf('Frequencies = %d', nf));

else

  spacingsCnt = fread(fid, 1, 'int');
  widthsCnt = fread(fid, 1, 'int');
  dimsCnt = fread(fid, 1, 'int');

  turns = fread(fid, turnsCnt, 'double');
  spacings = fread(fid, spacingsCnt, 'double');
  widths = fread(fid, widthsCnt, 'double');
  dims = fread(fid, dimsCnt, 'double');

  disp(sprintf('turns space: %d element(s)', turnsCnt));
  disp(sprintf('spacings space: %d element(s)', spacingsCnt));
  disp(sprintf('widths space: %d element(s)', widthsCnt));
  disp(sprintf('outer diameter space: %d element(s)', dimsCnt));

  if (dimsCnt == 1 || widthsCnt == 1)
    error('Only one point for widths or diameters!');
  end

  raw = fread(fid, turnsCnt * spacingsCnt * widthsCnt * dimsCnt * 2, 'double');
  raw = reshape(raw, 2, turnsCnt * spacingsCnt * widthsCnt * dimsCnt);
  rawMin = raw(1,:);
  minL = min(rawMin(rawMin > 0));
  maxL = max(raw(1,:));
  rawMin = raw(2,:);
  minQ = min(rawMin(rawMin > 0));
  maxQ = max(raw(2,:));
  disp(sprintf('Minimum L in the data set = %g um', minL));
  disp(sprintf('Maximum L in the data set = %g um', maxL));
  disp(sprintf('Minimum Q in the data set = %g', minQ));
  disp(sprintf('Maximum Q in the data set = %g', maxQ));

  [a, count] = fread(fid, 1, 'double');
  if (count > 0)
      error('Bug!');
  end

  disp('Press enter for the next plot.');

  for t = 1:turnsCnt
    for s = 1:spacingsCnt
      start = widthsCnt * dimsCnt * (s - 1 + spacingsCnt * (t - 1)) + 1;
      stop = start + widthsCnt * dimsCnt - 1;
      L = raw(1, start:stop);
      Q = raw(2, start:stop);
      locMinL = min(L(L > 0));
      locMaxL = max(L(L > 0));
      locMinQ = min(Q(Q > 0));
      locMaxQ = max(Q(Q > 0));
      L = reshape(L, dimsCnt, widthsCnt);
      Q = reshape(Q, dimsCnt, widthsCnt);
      clf;

      v = locMinL : ((locMaxL - locMinL) / N) : locMaxL;
      figure(1); clf;
      [cs,h] = contour(widths, dims, L, v);
      axis([min(widths) max(widths) min(dims) max(dims)]); grid;
      clabel(cs, h, v);

      title(sprintf('%s L (nH) [%-5.3f,%-5.3f] (%g turns, %g \\mu{m} spacing)', ...
            inductor, locMinL, locMaxL, turns(t), spacings(s)));
      xlabel('width (\mu{m})'); ylabel('outer diameter (\mu{m})');

      v = locMinQ : ((locMaxQ - locMinQ) / N) : locMaxQ;
      figure(2); clf;
      [cs, h] = contour(widths, dims, Q, v);
      axis([min(widths) max(widths) min(dims) max(dims)]); grid;
      clabel(cs, h, v);

      title(sprintf('%s Q [%-5.3f,%-5.3f] (%g turns, %g \\mu{m} spacing)', ...
            inductor, locMinQ, locMaxQ, turns(t), spacings(s)));
      xlabel('width (\mu{m})'); ylabel('outer diameter (\mu{m})');

      pause
    end
  end
end

function out = escapeUnderScore(str)
s = find(str == '_');
if (length(s) == 0)
  out = str;
  return;
end
if (s(1) > 1)
  out = str(1 : (s(1) - 1));
  lastChar = s(1) + 1;
else
  out = '';
  lastChar = 2;
end
for l = 2:length(s),
  out = strcat(out, '\_');
  out = strcat(out, str(lastChar : (s(l) - 1)));
  lastChar = s(l) + 1;
end
out = strcat(out, '\_');
out = strcat(out, str(lastChar : length(str)));
return

function out = relPeakErr(refA, newA)
ref = max(refA);
new = max(newA);
out = (new - ref) / ref * 100.0;
return

function out = relMaxErr(ref, new)
out = max(abs((new - ref) ./ ref) * 100.0);
return
