src_path = fullfile('utils', 'private');
src_files = {'warping_jump_mex_corrected.c'};
output_path = src_path;

mexcmd = ['mex -O ', '-outdir ', output_path];
for i_file = 1 : length(src_files)
    eval([mexcmd,  ' ', fullfile(src_path, src_files{i_file})]);
end
