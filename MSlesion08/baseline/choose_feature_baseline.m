function [X, labels] = choose_feature_baseline(V, mask, annotations, params)
% Take features and labels from each voxel on every slice in imageidx
% Parameters:
%           mask: the mask for the brain tissues
%           annotations: annotations
% Returns:
%           X:  features
%           labels: labels
size_L = size(V); % 512 x 512 x # slices
imageidx = 1:size_L(3); %  indexes of the slices that contain annotations
if isfield(params, 'ratio')
    % We're undersampling the training data
    ratio = params.ratio;
    % Find some positive labels
    % Find index of positive labels on the imageidx
    lesion_pos = cell(length(imageidx), 1);
    nonlesion_pos = cell(length(imageidx), 1);
    total_lesions = 0; % # of pixels that are lesions
    for i = 1:length(imageidx)
        [row, col] = find(annotations(:, :, i));
        lesion_pos{i} = sub2ind(size_L(1:2), row, col); % index
        total_lesions = total_lesions + length(row);
        % Find negative labels
        % Random Search
        neg_labels_ind = zeros((ratio-1)*length(row), 1);
        for j = 1 : (ratio-1) * length(row)
            not_done = true;
            while not_done
                r = random('unid', size_L(1));
                c = random('unid', size_L(2));
                % pick a pixel that is brain tissue and has negative label
                if mask(r, c, i) && ~annotations(r, c, i)
                    not_done = false;
                end
            end
            neg_labels_ind(j) = sub2ind(size_L(1:2), r, c);
        end
        nonlesion_pos{i} = neg_labels_ind;
    end
    
    m = ratio * total_lesions; % # of training samples
    X = zeros(m, 1); 
    labels = zeros( m, 1);

    last_ind = 0;
    for i = 1:length(imageidx)
        % Get the label
        pos_row = length(lesion_pos{i});
        tmp = annotations(:, :, i);
        labels(last_ind + 1: last_ind + pos_row) = tmp(lesion_pos{i});
        labels(last_ind + pos_row + 1: last_ind + ratio*pos_row) = tmp(nonlesion_pos{i});
        % Get the features
        q = V(:, :, i); % 512*512
        X(last_ind + 1: last_ind + pos_row) = q(lesion_pos{i});
        X(last_ind + pos_row + 1: last_ind + ratio*pos_row) = q(nonlesion_pos{i});
        % update the index
        last_ind = last_ind + ratio * pos_row;
    end

else
    % Only pick the brain tissues ? 
    k = find(mask); % idx of brain pixels
    m = length(k); % # of training samples
    X = zeros(m, 1);
    % Loop through annotations, assigning features and labels
    % index of the labels in the last iteration
    last_ind = 0;
    % directly pick from 3D matrix mask and annotations
    labels = annotations(k);
    for i = 1:length(imageidx)
        % Loop through all slices       
        % Save the features corresponding to brain pixels
        q = V(:,:,i); % 512*512
        [r_brain, c_brain] = find(mask(:,:,i)); % row and column idx of brain pixels on each slice
        voxels = length(r_brain); % # of brain pixels on the current slice
        for j = 1:voxels
            X( last_ind+j ) = q(r_brain(j),c_brain(j));
        end
        last_ind = last_ind + voxels;
    end
end
    labels = labels + 1; % change to positive labels (0,1) to (1,2) so it works with softmax regression
end

