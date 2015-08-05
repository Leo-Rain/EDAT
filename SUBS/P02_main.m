function P02_main(DD,window)
    [FN,tracks,txtFileName] = initTxtFileWrite(DD);
    %%
    writeToTxtFiles(txtFileName,FN,tracks,DD.threads.num);
    %%
    meanMap =  initMeanMaps(window);
    %%
    meanMap = buildMeanMaps(meanMap,txtFileName,DD.threads.num); %#ok<NASGU>
    %%
    save([DD.path.root,'meanMaps.mat'],'meanMap');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% init output map dim
function map = initMeanMaps(window) % TODO make better
    geo = window.geo;
    %     bs  = DD.map.out.binSize;
    %%
    if round(geo.east - geo.west)==360
        xvec    = wrapTo360(1:1:360);
    else
        xvec    = wrapTo360(round(geo.west):1:round(geo.east));
    end
    yvec    = round(geo.south):1:round(geo.north);
    %%
    [map.lon,map.lat] = meshgrid(xvec,yvec);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function meanMaps = buildMeanMaps(meanMaps,txtFileName,threads)
    %% init
    [Y,X] = size(meanMaps.lat);

    %% read lat lon vectors
    lat = fscanf(fopen(txtFileName.lat, 'r'), '%f ');
    lon = wrapTo360(fscanf(fopen(txtFileName.lon, 'r'), '%f '));
    %% find index in output geometry
    idxlin = binDownGlobalMap(lat,lon,meanMaps.lat,meanMaps.lon,threads);

    %% read parameters
    u     = fscanf(fopen(txtFileName.u, 'r'),     '%e ');
    v     = fscanf(fopen(txtFileName.v, 'r'),     '%e ');
    scale = fscanf(fopen(txtFileName.scale, 'r'), '%e ');

    %% sum over parameters for each grid cell
    meanMaps.u = meanMapOverIndexedBins(u,idxlin,Y,X,threads);
    meanMaps.v = meanMapOverIndexedBins(v,idxlin,Y,X,threads);
    meanMaps.scale = meanMapOverIndexedBins(scale,idxlin,Y,X,threads);

    %% calc angle
    uv               = meanMaps.u + 1i * meanMaps.v;
    meanMaps.absUV   = abs(uv) ;
    meanMaps.angleUV = reshape(wrapTo360(rad2deg(phase(uv(:)))),Y,X);

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [FN,tracks,txtFileName] = initTxtFileWrite(DD)
    tracks = DD.path.analyzed.files;
    txtdir = [ DD.path.root 'TXT/' ];
    mkdirp(txtdir);
    FN = {'lat','lon','u','v','scale','amp'};
    for ii=1:numel(FN); fn = FN{ii};
        txtFileName.(fn) = [ txtdir fn '.txt' ];
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function writeToTxtFiles(txtFileName,FN,tracks,threads)
    %% open files
    lims = thread_distro(threads,numel(tracks));
    T = disp_progress('init','creating TXT/*.txt files');
    spmd(threads)
        for ii=1:numel(FN); fn = FN{ii};
            myFname = strrep(txtFileName.(fn),'.txt',sprintf('%02d.txt',labindex));
            system(sprintf('rm -f %s',myFname));
            fid.(fn) = fopen(myFname, 'w');
        end
        %% write parameters to respective files
        for tt=lims(labindex,1):lims(labindex,2)
            T = disp_progress('show',T,diff(lims(labindex,:))+1,100);
            track = load(tracks(tt).fullname);
            fprintf(fid.lat,'%3.3f ',track.daily.geo.lat );
            fprintf(fid.lon,'%3.3f ',track.daily.geo.lon );
            fprintf(fid.u,  '%1.3e ',track.daily.vel.u);
            fprintf(fid.v,  '%1.3e ',track.daily.vel.v);
            fprintf(fid.scale, '%d ',track.daily.scale);
            fprintf(fid.amp,'%3.3f ',track.amp*100);
        end
        %% close files
        for ii=1:numel(FN); fn = FN{ii};
            fclose(fid.(fn));
        end
    end
    %% cat workers' files
      for ii=1:numel(FN); fn = FN{ii};
            allFname = strrep(txtFileName.(fn),'.txt','??.txt');
            outFname = txtFileName.(fn);
            system(sprintf('cat %s > %s',allFname,outFname));
            system(sprintf('rm %s',allFname));
      end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%