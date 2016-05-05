% Run ParseData_batch first

remove_outliers = 1;
chunksize = 2; % Must be divisible into 12s, maximum 2s
subs = [1 2 3 4 5 6 7 8 11 12 14 15 19 21 24 25];   % All

% Leave this alone

clear all
wdir = '/Volumes/HDD/data/BCI/dat_proc/';
exclusions = {'BCI15-14',4};
output = {'subject','gender','age','hand','group','session','block','hemisphere','trial','time','betaERD'};
sides = {'L','R'};

for subno = 1:length(subs)
    
    sub = int2str(subs(subno));
    if length(sub) == 1, sub = ['0' sub]; end
    sub = ['BCI15-' sub];
    fprintf(1,'%s\n',sub);
    
    cd(fullfile(wdir,sub));
    
    % Get subject stats
    
    fid = fopen('../../work/participant_stats.csv');
    stats = textscan(fid,'%s%s%s%s','Delimiter',',');
    fclose(fid);
    
    row = find(strcmp(stats{1},sub));
    gender = stats{2}(row);
    age = stats{3}(row);
    handedness = stats{4}(row);

    for sno = 1:10

        skip = 0;
        for i = 1:size(exclusions,1)
            if strcmp(exclusions{i,1},sub) && exclusions{i,2} == sno
                skip = 1;
            end 
        end

        if ~skip
            
            load(['parsed_ses' int2str(sno) '.mat']);
            
            % Convert data into ERD
            
            % Left blocks
            
            for blockno = 1:size(out.left_blocks,3)
            
                nchunks = (size(out.left_blocks,2) - (2*out.fs)) / (chunksize*out.fs);
                ERD_LBLH = [];
                ERD_LBRH = [];
                baseline.RH = out.left_blocks(1,1:2*out.fs,blockno);
                baseline.LH = out.left_blocks(2,1:2*out.fs,blockno);
                
                for chunkno = 1:nchunks
                    
                    openingsamp = 2 * out.fs;
                    firstsamp = openingsamp + ((chunkno - 1) * (chunksize * out.fs));
                    lastsamp = firstsamp + (chunksize * out.fs);
                    active.RH = out.left_blocks(1,firstsamp:lastsamp-1,blockno);
                    active.LH = out.left_blocks(2,firstsamp:lastsamp-1,blockno);
                    ERD_LBLH = [ERD_LBLH -log2(bandpower(active.LH,out.fs,[15 30]) / bandpower(baseline.LH,out.fs,[15 30]))];
                    ERD_LBRH = [ERD_LBRH -log2(bandpower(active.RH,out.fs,[15 30]) / bandpower(baseline.RH,out.fs,[15 30]))];
                    
                end
            
                % Right blocks
            
                nchunks = (size(out.right_blocks,2) - (2*out.fs)) / (chunksize*out.fs);
                ERD_RBLH = [];
                ERD_RBRH = [];
                baseline.RH = out.right_blocks(1,1:2*out.fs,blockno);
                baseline.LH = out.right_blocks(2,1:2*out.fs,blockno);
                
                for chunkno = 1:nchunks
                    
                    openingsamp = 2 * out.fs;
                    firstsamp = openingsamp + ((chunkno - 1) * (chunksize * out.fs));
                    lastsamp = firstsamp + (chunksize * out.fs);
                    active.RH = out.right_blocks(1,firstsamp:lastsamp-1,blockno);
                    active.LH = out.right_blocks(2,firstsamp:lastsamp-1,blockno);
                    ERD_RBLH = [ERD_RBLH -log2(bandpower(active.LH,out.fs,[15 30]) / bandpower(baseline.LH,out.fs,[15 30]))];
                    ERD_RBRH = [ERD_RBRH -log2(bandpower(active.RH,out.fs,[15 30]) / bandpower(baseline.RH,out.fs,[15 30]))];
                    
                end

                % Put it into long format

                for bhemino = 1:2

                    block = char(sides(bhemino));

                    for hemisphereno = 1:2
                        
                        for seg = 1:length(ERD_LBLH)

                            hemisphere = char(sides(hemisphereno));

                            output{end+1,1} = sub;
                            output{end,2} = gender;
                            output{end,3} = age;
                            output{end,4} = handedness;
                            if mod(subs(subno),2), output{end,5} = 'robot';
                            else output{end,5} = 'bars'; end
                            output{end,6} = sno;
                            output{end,7} = block;
                            output{end,8} = hemisphere;
                            output{end,9} = blockno;
                            output{end,10} = (seg-1)*chunksize;

                            if bhemino == 1     % Hear left
                                if hemisphereno == 1 % Left hemisphere, or right hand MI
                                    val = ERD_LBLH(seg);
                                else % Right hemisphere, or left hand MI
                                    val = ERD_LBRH(seg);
                                end
                            else % Hear right
                                if hemisphereno == 1 % Left hemisphere, or right hand MI
                                    val = ERD_RBLH(seg);
                                else % Right hemisphere, or left hand MI
                                    val = ERD_RBRH(seg);
                                end
                            end

                            output{end,11} = val;
                        
                        end

                    end

                end
                
            end

        end
        
    end
    
end

% Find bounds for outliers

beta = [];
for i = 1:size(output,1) - 1, beta = [beta output{i+1,end}]; end

upper = mean(beta) + (2.5 * std(beta));
lower = mean(beta) - (2.5 * std(beta));

% Remove outliers

mask = ones(size(output,1),1);

for rowno = 2:size(output,1)
    
    if output{rowno,end} > upper || output{rowno,end} < lower
        mask(rowno) = 0;
    end
    
end

rows = find(mask==1);
output2 = output(rows,:);

n_outlier = size(output,1) - size(output2,1);
p_outlier = n_outlier / size(output,1) * 100;
fprintf(1,'%s trials removed, %.2f percent of data\n',int2str(n_outlier),p_outlier);

% Save output

if remove_outliers
    final = output2;
else
    final = output;
end

fname = ['/Volumes/HDD/data/BCI/work/alldat-' int2str(chunksize*1000) '-trials-time.csv'];
fancy_csv(fname,final);