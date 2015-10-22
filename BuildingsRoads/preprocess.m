function [patches_preproc, images] = preprocess(params, range)
    %%Loading Images
    imagefiles = dir(strcat(params.scansdir,'*.tiff'));      
    nfiles = length(imagefiles);    % Number of files found
    if range==0
        range= nfiles;
    end
    Vs = [];
    for i=1:range
        currentfilename = imagefiles(i).name;
        currentimage = imread(strcat(params.scansdir, currentfilename));
        
        % Gaussian Pyramid of the image, saved in a vector
        % V{i} is a cell array each of which is a scaled image in the pyramid
        pyr = pyramid(currentimage, params);
        %save pyramidTest.mat pyr 
        Vs = [Vs; pyr];
        
        %imshow(pyr{1});
        %pause
        clear currentimage;
        clear pyr;
    end
    
    % Extract Patches from the Gaussian Pyramid
    patches = extract_patches(Vs, params);
    clear Vs;
    
    % Apply ZCA Whitening
    patches_preproc= zcawhitening(patches, params);
   
    images= [];
end