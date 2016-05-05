clear all

wdir = '/Volumes/HDD/data/BCI/dat_raw';
exclusions = {'BCI15-14',4};
bstime = 8;

for subno = [14 15 19 21 24 25]; %[1 2 3 4 5 6 7 8 11 12 14 15 19 21 24 25]
    
    sub = int2str(subno);
    if length(sub) == 1, sub = ['0' sub]; end
    sub = ['BCI15-' sub];    
    
    for sesno = 1:10
        
        skip = 0;
        for i = 1:size(exclusions,1)
            if strcmp(exclusions{i,1},sub) && exclusions{i,2} == sesno
                skip = 1;
            end 
        end

        if ~skip

            startsamp = 1; endsamp = 0;

            % Some files require splitting

            if strcmp(sub,'BCI15-05') && sesno == 1, startsamp = 1.15e6; end
            if strcmp(sub,'BCI15-05') && sesno == 2, startsamp = 1.16e6; end
            if strcmp(sub,'BCI15-07') && sesno == 4, startsamp = 11e5; end
            if strcmp(sub,'BCI15-19') && sesno == 4, startsamp = 13e5; end
            if strcmp(sub,'BCI15-12') && sesno == 4, endsamp = 4e5; end
            if strcmp(sub,'BCI15-15') && sesno == 9, endsamp = 3.6e5; end

            BCI_ParseData_pertrial(wdir,sub,sesno,startsamp,endsamp,bstime);

            fprintf(1,'%s %s\n',sub,int2str(sesno));
            
        end
        
    end
    
end