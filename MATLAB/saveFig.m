function saveFig(fig, name)
%SAVEFIG  Save a figure as PNG (300 dpi) into ./figures for the report.
d = fullfile(fileparts(mfilename('fullpath')), 'figures');
if ~exist(d, 'dir'), mkdir(d); end
f = fullfile(d, [name '.png']);
if exist('exportgraphics', 'file')
    exportgraphics(fig, f, 'Resolution', 300);
else
    print(fig, f, '-dpng', '-r300');
end
fprintf('saved %s\n', f);
end
