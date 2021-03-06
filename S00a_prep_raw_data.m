% This is the first 'pre'-step (S00..). It's purpose is to extract SSH data
% from either pop or aviso files named like eg 
% SSH_GLB_t.t0.1_42l_CORE.yyyymmdd.nc 
% or
% dt_global_twosat_msla_h_yyyymmdd_20140106.nc.
%
% the function
% -first creates the geometric information needed to transform
% input SSH to desired output geometry (see constructGeoFile.m)
% -and then saves one output .mat SSH file per time-step to
% ../dataXXX/CUTS/
%
% geo information is stored in ../dataXXX/window.mat.
%
% remember to run addpath(genpath('./')) when starting matlab

%% init dependencies
addpath(genpath('./'));
%% set up meta-data/info file "DD.mat" and get user input
DD = initialise('raw');
%% build info file for lat/lon etc
window = constructGeoFile(DD);
%% main
S00a_main(DD,window);
