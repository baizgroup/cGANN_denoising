function convertToRgb(directory)
    % Converts all the images in the directory to RGB.
    ims = imageDatastore(directory);
    for iIm = 1:numel(ims.Files)
        filename = ims.Files{iIm};
        [im, map] = imread(filename);
        %rgbIm = ind2rgb(im, map);
        rgbIm = repmat(im,[1 1 3]);
        imwrite(rgbIm, filename);
    end
end