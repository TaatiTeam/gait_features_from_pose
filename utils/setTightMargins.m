%  Remove superfluous margins from current figure. This means that the figure
% borders will be directly adjacent to the outermost figure parts, e.g. axis
% labels, or title.
%
% The optional argument 'mrg' allows to specify a custom margin in centimeters.
% It must be either a single value, or a vector "[left bottom top right]".
%
% Call this function after creating the plot, before calling 'setCrop',
% and before calling 'print'.
%
% Daniel Weibel <danielmweibel@gmail.com> November 2015
%------------------------------------------------------------------------------%
function setTightMargins(mrg)

% If the optional arg 'mrg' is specified
if nargin == 1
  if     length(mrg) == 4 my_mrg      = mrg;
  elseif length(mrg) == 1 my_mrg(1:4) = mrg;
  else                    error('Argument 1 must have length 1 or 4.'); end
else
  my_mrg(1:4) = 0;
end

% Get handles of current figure and axes
fig = gcf;  % Current figure handle
ax  = gca;  % Current axes handle

% Synchronise units of figure an axes object
fig.Units = 'centimeters';
ax.Units  = 'centimeters';

% Get minimum margins around plot (as calculated by Matlab)
min_margin_l = ax.TightInset(1);
min_margin_b = ax.TightInset(2);
min_margin_r = ax.TightInset(3);
min_margin_t = ax.TightInset(4);

% Add custom margins from optional argument 'mrg' to the minimum margins
margin_l = min_margin_l + my_mrg(1);
margin_b = min_margin_b + my_mrg(2);
margin_r = min_margin_r + my_mrg(3);
margin_t = min_margin_t + my_mrg(4);

% Get width and height of entire figure (in centimeters)
fig_width  = fig.Position(3);
fig_height = fig.Position(4);

% Set dimensions of axes regions to match custom margins
left   = margin_l;
bottom = margin_b;
width  = fig_width  - margin_l - margin_r;
height = fig_height - margin_b - margin_t;
ax.Position = [left, bottom, width, height];