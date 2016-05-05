clear all

% Note: Exclusions will look like zeros
% Run ParseData_batch first

band = [15 30];
code = 'beta';
subs = [1 2 3 4 5 6 7 8 11 12 14 15 19 21 24 25];   % All
dsrate = 5;

wdir = '/Volumes/HDD/data/BCI/dat_proc/';
exclusions = {'BCI15-14',4};

% Don't touch this

sides = {'L','R'};
str = {'lbrh','lblh';'rbrh','rblh'};
f1 = band(1); f2 = band(2);
bins = 32;

% Main loop

for subno = 8:length(subs)
    
    sub = int2str(subs(subno));
    if length(sub) == 1, sub = ['0' sub]; end
    sub = ['BCI15-' sub];
    
    cd(fullfile(wdir,sub));

    for sno = 1:10

        skip = 0;
        for i = 1:size(exclusions,1)
            if strcmp(exclusions{i,1},sub) && exclusions{i,2} == sno
                skip = 1;
            end 
        end

        if ~skip
            
            load(['parsed_ses' int2str(sno) '.mat']);
            dods = 0;
            if out.fs == 1000, dods = 1; newfs = out.fs/dsrate; else newfs = out.fs; end
            blocks = {'left_blocks','right_blocks'};
            
            fprintf(1,'%s session %s, %s Hz\n',sub,int2str(sno),int2str(newfs));
            
            for blockno = 1:2
                
                blockstr = char(blocks(blockno));
                
                for hand = 1:2

                    sample = reshape(out.(blockstr)(hand,:,:),size(out.(blockstr),2),size(out.(blockstr),3));
                    if dods, sample = sample(1:dsrate:end,:); end
                    wvlt = wvlt_avg_scalo(sample,1,40,newfs,bins,bins);
                    wvlt = wvlt(:,newfs+1:end-newfs);
                    wvlt_norm = wvlt_log2_norm(wvlt,1,5*newfs);
                    freq = linspace(1,newfs,bins);
                    pos = find(freq>f1 & freq<f2);
                    wvlt_norm = mean(wvlt_norm(pos,:),1);

                    output.(str{blockno,hand})(subno,1:16*newfs,sno) = wvlt_norm;

                end
                
            end
            
        end
        
    end
    
end

% Patch exclusions

% Left blocks
samplelh = reshape(mean(output.lblh,1),size(output.lblh,2),size(output.lblh,3));
samplerh = reshape(mean(output.lbrh,1),size(output.lbrh,2),size(output.lbrh,3));

for sno = 1:10
    subplot(4,5,sno)
    plot(samplelh(:,sno)), hold on, plot(samplerh(:,sno))
    xlim([0 3200]), ylim([-1 0.5])
    xlabel('Time (s)');
    if sno == 1 || sno == 6
        ylabel('Beta ERS (Left blocks)');
    end
    title(['Session ' int2str(sno)])
    hold on, line([1400 1400],[-1 1],'Marker','.','LineStyle','-','Color','red')
    hold on, line([0 3200],[0 0],'Marker','.','LineStyle','-','Color','red')
    set(gca,'Xtick',0:400:3200)
    set(gca,'Xticklabel',((0:400:3200)/200)-7);
end

% Right blocks
samplelh = reshape(mean(output.rblh,1),size(output.lblh,2),size(output.rblh,3));
samplerh = reshape(mean(output.rbrh,1),size(output.lbrh,2),size(output.rbrh,3));

for sno = 1:10
    subplot(4,5,sno+10)
    plot(samplelh(:,sno)), hold on, plot(samplerh(:,sno))
    xlim([0 3200]), ylim([-1 0.5])
    xlabel('Time (s)');
    if sno == 1 || sno == 6
        ylabel('Beta ERS (Right blocks)');
    end
    title(['Session ' int2str(sno)])
    hold on, line([1400 1400],[-1 1],'Marker','.','LineStyle','-','Color','red')
    hold on, line([0 3200],[0 0],'Marker','.','LineStyle','-','Color','red')
    set(gca,'Xtick',0:400:3200)
    set(gca,'Xticklabel',((0:400:3200)/200)-7);
end

legend({'CP3','CP4'})