
function results=accommodation(results)
    if nargin==0
        results = run_sim;
    end
    analyze(results);
end


function results = run_sim
    %% Parameters
    mb.settings('refract',true,'reflex',false,'n_workers',0);
    parms.light_dpt = 1;
    parms.accom_values = [0.8 1.0];  %[0 1.3/2 1.3 2.6 5.2];
    parms.n_rays_per_light = 101; % Set the precission, more rays better but takes longer
    parms.fovea_alpha = 0;
    
    %% set up the output structure
    hit_retinal_arc=cell(size(parms.accom_values));
    accommodation=cell(size(parms.accom_values));
    scenes=mb.Scene.empty(0,numel(parms.accom_values));
    
    %% Run the conditions and store the results
    for i=1:numel(parms.accom_values) % change for into parfor to use multiple parallel workers
        ttt_rep = tic;
        fprintf('Working on accommodation %f dpt...\n',parms.accom_values(i));
        accommodation{i} = parms.accom_values(i); % put in cell because when done in parfor can be do in semi-random order
         
        %% Create a light source
        light=mb.Light('color','r','linewidth',1);
        light.xpos=cosd(parms.fovea_alpha)*1000/parms.light_dpt;
        light.ypos=sind(parms.fovea_alpha)*1000/parms.light_dpt;    
        light.aim_rays_at_line_segment(parms.n_rays_per_light,[0;-4],[0;4]);
        
        %% Create an eyeball
        %eye=mb.body.eye.Navarro;
        %eye=mb.body.eye.Arizona;
        eye=mb.body.eye.GullstrandVar;
        eye.accommodation = accommodation{i};
        eye.pupil_diam = 3;
        eye.pupil_offset = 0;
        
        %% Combine into a scene
        scene=mb.Scene;
        scene.add_light(light);
        scene.add_body(eye);
        
        %% Trace the light rays
        scene.shine;
        
        %% Get the distrubution of rays on the retina
        hit_retinal_arc{i} = mb.library.analysis.hit_distribution(scene.rays,"retina");
        scenes(i)=deep_copy(scene);
        toc(ttt_rep); % won't be printed in parfor loop
    end
    % Pack results in a structure, sort by increasing accommodation level
    [results.accom,idx]=sort(cell2mat(accommodation),'ascend');
    results.hit_retinal_arc=hit_retinal_arc(idx);
    results.scenes=scenes(idx);
    results.n_rays=parms.n_rays_per_light;
    results.N=numel(results.accom);
end

function analyze(results)
    
    fig=mb.library.Plot.find_fig(string(mfilename)+"_results");
    clf(fig);
    %% Plot the eyeballs and the rays. Only do this when there are less than X rays
    max_rays_to_plot = 200;
    if results.n_rays<=max_rays_to_plot
        if mb.library.Misc.start_parallel_worker_pool([])~=0
            error('Valid scenes can obly be stored when processing was serial, not parallel. Weird stuff happens in parallel, figure out and solve one day');
        end
      
        tiledlayout(fig,'flow');
        for i=1:numel(results.scenes)
            ax=nexttile;
            results.scenes(i).show;
            ax.XLim=[-27 3];
            ax.YLim=[-15 15];
            title(sprintf('Accommodation %0.2f dpt',results.accom(i)));
        end
    else
        title(sprintf('Not showing scene because parms.n_rays_per_light>%d',max_rays_to_plot),'interpreter','none');
    end

    %% Plot the retinal ray distribution
    fig=mb.library.Plot.find_fig(string(mfilename)+"_distribution");
    clf(fig);
    tiledlayout(fig,'flow');
    ax=nexttile;
    % Use a common binning base
    [min_mm, max_mm] = bounds([results.hit_retinal_arc{:}]);
    edges = linspace(min_mm,max_mm,ceil(sqrt(results.n_rays)));
    h_lines = [];
    labels = {};
    colmap = colormap('jet');
    for i=1:results.N
        [counts,edges]=histcounts(results.hit_retinal_arc{i},edges);
        centers=edges(1:end-1)+diff(edges)/2;
        if numel(results.accom)==1
            level=0;
        else
            level = (results.accom(i)-min(results.accom))/range(results.accom); % between 0 and 1
        end
        level256 = floor(1+(size(colmap,1)-1)*level); % between 0 and 255
        color = colmap(level256,:);
        h_lines(end+1) = plot(ax,centers,counts,'-','Color',color,'LineWidth',1+level*5); %#ok<AGROW>
        labels{end+1} = sprintf('%0.2f D',results.accom(i)); %#ok<AGROW>
        hold on
    end
    set(ax,'FontSize',mb.settings('fontsize')*0.8);
    xlabel(ax,'Arc length from center (mm)','FontSize',mb.settings('fontsize'))
    ylabel(ax,'Number of rays','FontSize',mb.settings('fontsize'))
    if min(xlim)<0 && max(xlim)>0
        plot(ax,[0 0],ylim(ax),'k--')
    end
    set(ax,'TickDir','out','box','off')
    h_leg = legend(h_lines,labels);
    h_leg.Title.String='Accommodation';
end

