classdef Scene < mb.base.Base

    properties (Access=public)
        bodies=struct
        lights=struct
        max_rays_total=1e6
        max_generations_per_ray=100
        rays=mb.Ray.empty
    end

    methods (Access=public)
        function O=Scene(varargin)
            O.apply_name_value_pairs(O,varargin);
        end
        
        function add_body(O,body,name)
            % Add a Body with name ''name'' to this Scene. 
            % If ''name'' is missing or empty, the variable name of the body to be added will be used
            if ~any(superclasses(body)=="mb.body.Body")
                error('Object is not a subclass of mb.body.Body');
            end
            if ~isvalid(body)
                error('Body-object is invalid. Has it been deleted?');
            end
            O.delete_rays();
            if ~exist('name','var') || isempty(name)
                name=inputname(2);
            end
            try
                O.bodies.(name)=body;
            catch me
                if me.identifier=="MATLAB:AddField:InvalidFieldName"
                    error('Invalid body name: ''%s''. Valid body names begin with a letter, and can contain letters, digits, and underscores. The maximum length of a field name is the value that the namelengthmax function returns.',name);
                else
                    rethrow(me);
                end
            end
        end
        
        function add_light(O,light,name)
             if class(light)~="mb.Light"
                error('Object is not of class mb.Light');
            end
            if ~isvalid(light)
                error('Light-object is invalid. Has it been deleted?');
            end
            O.delete_rays();
            if ~exist('name','var') || isempty(name)
                name = inputname(2); %O.auto_fieldname(O.lights,'light',3);
            end
            try
                O.lights.(name)=light;
            catch me
                if me.identifier=="MATLAB:AddField:InvalidFieldName"
                    error('Invalid light name: ''%s''. Valid body names begin with a letter, and can contain letters, digits, and underscores. The maximum length of a field name is the value that the namelengthmax function returns.',name);
                else
                    rethrow(me);
                end
            end
        end
        
        function shine(O)
            % Play the scene, start ray-tracing
            start_tic=tic;
            
            rays_todo=mb.Ray.empty(0,O.max_rays_total); % alloc with max amount. Used to be a growing list but this is faster
            n_rays_todo = 0; % track the utilization of the rays_todo array
            lits=struct2cell(O.lights);
            if numel(lits)==0
                warning('The scene contains no lights to shine');
                return
            end
            for i=1:numel(lits)
                n = numel(lits{i}.rays);
                rays_todo(n_rays_todo+1:n_rays_todo+n) = lits{i}.rays;
                n_rays_todo=n_rays_todo+n;
            end          
            rays_done=mb.Ray.empty(0,O.max_rays_total); % rays that have finished processing are stored here
            this_ray_doing_idx=0;
            while this_ray_doing_idx<n_rays_todo
                if this_ray_doing_idx>=O.max_rays_total
                    O.fprintf(' --- Maximum total generations reached (max_rays_total = %d)\n',O.max_rays_total);
                    break;
                end
                O.fprintf('todo: %5d, done: %5d\n',numel(rays_todo),this_ray_doing_idx);
                min_length=Inf;
                reflex=mb.Ray.empty;
                refrax=mb.Ray.empty;
                this_ray_doing_idx = this_ray_doing_idx+1;
                ray_doing=rays_todo(this_ray_doing_idx);
                
                % For each body see this ray would hit any of its boundaries, and store the distance
                % the ray travelled to get there. The nearest boundary is the one that actually got
                % hit, as it occluded the others. The reflex and refrax will spawn at that point. If
                % two boundaries are equidistance from the light, then the first one takes the cake.
                % Should be rare, but there's room for improvement there. Both boundaries could spawn
                % a reflex and a refrax for example.
                bods=struct2cell(O.bodies);
                for i=1:numel(bods)
                    [hit,candidate_reflex,candidate_refrax] = bods{i}.reflect_and_refract(ray_doing);
                    if hit && ray_doing.length<min_length
                        reflex=candidate_reflex;
                        refrax=candidate_refrax;
                        reflex.lineage.parent.idx = this_ray_doing_idx;
                        refrax.lineage.parent.idx = this_ray_doing_idx;
                        min_length = ray_doing.length;
                    end
                end
                ray_doing.length=min_length;
                ray_doing.lineage.generation_nr = ray_doing.lineage.generation_nr+1;
                if min_length==Inf
                    % The ray is off into infinity
                    ray_doing.lineage.deathplace=Inf;
                else
                    ray_doing.lineage.deathplace=reflex.lineage.birthplace; % doesn't matter reflex or refrax
                    if ray_doing.lineage.generation_nr<O.max_generations_per_ray
                        if reflex.intensity>0
                            reflex.lineage.generation_nr=ray_doing.lineage.generation_nr;
                            n_rays_todo=n_rays_todo+1;
                            rays_todo(n_rays_todo)=reflex;
                        end
                        ray_doing.lineage.child_reflex.id=reflex.id;
                        if refrax.intensity>0
                            refrax.lineage.generation_nr=ray_doing.lineage.generation_nr;
                            n_rays_todo=n_rays_todo+1;
                            rays_todo(n_rays_todo)=refrax;
                        end
                        ray_doing.lineage.child_refrax.id=refrax.id;
                    else
                        % This lineage has reached its maximum number of generations, mark it as
                        % truncated
                        % THIS NEEDS A LOOK, WHY IS IT GRAYED OUT ?? 666
                        %  ray_doing.lineage.deathplace='truncated';
                        O.fprintf(' --- Lineage truncated (max_generations_per_ray = %d)\n',O.max_generations_per_ray);
                    end
                end
                % Add this ray to the done list
                rays_done(this_ray_doing_idx) = ray_doing;
                % Find the parent-ray idx, and update that ray at that index with who his children are
                if strcmp(ray_doing.type,'reflex')
                    rays_done(ray_doing.lineage.parent.idx).lineage.child_reflex.idx=this_ray_doing_idx;
                elseif strcmp(ray_doing.type,'refrax')
                    rays_done(ray_doing.lineage.parent.idx).lineage.child_refrax.idx=this_ray_doing_idx;
                end
            end
            rays_done(this_ray_doing_idx+1:end)=[]; % Trim the excess of the rays_done array
            O.rays=rays_done;
            O.fprintf('todo: %5d, done: %5d (Elapsed time: %s)\n',numel(rays_todo),this_ray_doing_idx,O.seconds_to_readable(toc(start_tic)));
        end
        
        function show(O,varargin)
            p=inputParser;
            p.addParameter('xylabel',[("x ("+mb.settings('length_unit')+")") ("y ("+mb.settings('length_unit')+")")],@(x)isstring(x) && numel(x)==2);
            p.addParameter('equal',true,@(x)islogical(x)||isempty(x));
            p.addParameter('title',[],@(x)ischar(x)||isstring(x)||iscell(x));
            p.addParameter('ray_visibility',1,@(x)isnumeric(x)&&x>=0&&x<=1); % show random selection of rays, 1 means show all rays, 0 none, 0.5 means a random half of them 
            p.parse(varargin{:});
            was_hold=ishold();
            if ~was_hold
                hold('on')
            end
            % plot the lights, rays, and bodies. note that 'zlayer', not plot order, determines the
            % occlussion
            if p.Results.ray_visibility==1
                ray_order=1:numel(O.rays);
            elseif p.Results.ray_visibility==0
                ray_order=[];
            else
                ray_order=randperm(numel(O.rays));
                ray_order=ray_order(1:ceil(numel(O.rays)*p.Results.ray_visibility));
            end
            for i=ray_order(:)'
                O.rays(i).show;
            end
            % Show the lights
            cellfun(@(x)x.show('xylabel',"",'equal',[]),struct2cell(O.lights));
            % Show the bodies
            cellfun(@(x)x.show('xylabel',"",'equal',[]),struct2cell(O.bodies));
            % Apply the axes styles
            fontsize=mb.settings('fontsize');
            if fontsize>0
                set(gca,'FontSize',fontsize*0.80);
                xlabel(p.Results.xylabel(1),'FontSize',fontsize);
                ylabel(p.Results.xylabel(2),'FontSize',fontsize);
            end
            if p.Results.equal
                axis('equal');
            end
            if ~isempty(p.Results.title)
                if iscell(p.Results.title)
                    title(p.Results.title{:});
                else
                    title(p.Results.title);
                end
            end
            if ~was_hold
                hold('off')
            end
        end
        
        function delete_rays(O)
            for i=1:numel(O.rays)
                O.rays(i).delete;
            end
            O.rays=mb.Ray.empty;
        end
        
        function dcopy = deep_copy(O)
            dcopy = copy(O);
            bod_names=fieldnames(O.bodies);
            for i=1:numel(bod_names)
                dcopy.(bod_names{i})=deep_copy(O.bodies.(bod_names{i}));
            end
            lit_names=fieldnames(O.lights);
            for i=1:numel(lit_names)
                dcopy.(lit_names{i})=copy(O.(lit_names{i}));
            end
            for i=1:numel(O.rays)
                dcopy.rays(i)=copy(O.rays(i));
            end
        end
    end
    
    methods (Access=private)
        
        function autoname(O,body)
            stem=class(body);
            nr=1;
            newname=stem+" "+string(nr);
            for i=1:numel(O.lights)
                if O.lights{i}.name==newname
                    nr=nr+1;
                    newname=stem+" "+string(nr);
                end
            end
            for i=1:numel(O.bodies)
                if O.bodies{i}.name==newname
                    nr=nr+1;
                    newname=stem+" "+string(nr);
                end
            end
            body.name=newname;
        end
        
        function rays_done = shine_private(O,start_rays)
            % I made this shine_private function to be called from shine (public shine)
            % to make it possible for parallel workers to work on subsets of the
            % start_rays. It worked. However, somehow it took the parallel workers
            % longer than doing it in series. TODO 666, figure out why and remedy.
            start_tic=tic;
            rays_todo=start_rays; % rays_todo grows whenever the ray splits in a reflex and refrax ray
            rays_done=mb.Ray.empty(0,O.max_rays_total); % rays that have finished processing are stored here
            this_ray_doing_idx=0;
        
            while ~isempty(rays_todo)
                if this_ray_doing_idx>=O.max_rays_total
                    O.fprintf(' --- Maximum total generations reached (max_rays_total = %d)\n',O.max_rays_total);
                    break;
                end
                O.fprintf('todo: %5d, done: %5d\n',numel(rays_todo),this_ray_doing_idx);
                min_length=Inf;
                reflex=mb.Ray.empty;
                refrax=mb.Ray.empty;
                ray_doing=rays_todo(1); % get fresh copy with length-property reset to Inf
                rays_todo(1) = []; % Doing this ray now, so delete it from the todo list
                this_ray_doing_idx = this_ray_doing_idx+1;
                
                % For each body see this ray would hit it, and store the distance the ray travelled
                % to get there. The nearest body is the body that actually got hit, as it occluded
                % the others. The reflex and refrax will spawn at that point. If two bodies are
                % equidistance from the light, then the first one takes the cake. Should be rare,
                % but there's room for improvement there. Both bodies could spawn a reflex and a
                % refrax for example.
                for i=1:numel(O.bodies)
                    [hit,candidate_reflex,candidate_refrax] = O.bodies{i}.reflect_and_refract(ray_doing);
                    if hit && ray_doing.length<min_length
                        reflex=candidate_reflex;
                        refrax=candidate_refrax;
                        reflex.lineage.parent.idx = this_ray_doing_idx;
                        refrax.lineage.parent.idx = this_ray_doing_idx;
                        min_length = ray_doing.length;
                    end
                end
                ray_doing.lineage.generation_nr = ray_doing.lineage.generation_nr+1;
                if min_length==Inf
                    % The ray is off into infinity
                    ray_doing.lineage.deathplace=Inf;
                else
                    ray_doing.lineage.deathplace=reflex.lineage.birthplace; % doesn't matter reflex or refrax
                    if ray_doing.lineage.generation_nr<O.max_generations_per_ray
                        if reflex.intensity>0
                            reflex.lineage.generation_nr=ray_doing.lineage.generation_nr;
                            rays_todo(end+1)=reflex; %#ok<AGROW>
                        end
                        ray_doing.lineage.child_reflex.id=reflex.id;
                        if refrax.intensity>0
                            refrax.lineage.generation_nr=ray_doing.lineage.generation_nr;
                            rays_todo(end+1)=refrax; %#ok<AGROW>
                        end
                        ray_doing.lineage.child_refrax.id=refrax.id;
                    else
                        % This lineage has reached its maximum number of generations, mark it as
                        % truncated
                        %  ray_doing.lineage.deathplace='truncated';
                        O.fprintf(' --- Lineage truncated (max_generations_per_ray = %d)\n',O.max_generations_per_ray);
                    end
                end
                % Add this ray to the done list
                rays_done(this_ray_doing_idx) = ray_doing;
                % Find the parent-ray idx, and update that ray at that index with who his children are
                if strcmp(ray_doing.type,'reflex')
                    rays_done(ray_doing.lineage.parent.idx).lineage.child_reflex.idx=this_ray_doing_idx;
                elseif strcmp(ray_doing.type,'refrax')
                    rays_done(ray_doing.lineage.parent.idx).lineage.child_refrax.idx=this_ray_doing_idx;
                end
            end
            rays_done(this_ray_doing_idx+1:end)=[]; % Trim the excess of the rays_done array
            O.fprintf('todo: %5d, done: %5d (Elapsed time: %s)\n',numel(rays_todo),this_ray_doing_idx,O.seconds_to_readable(toc(start_tic)));
        end
    end
    
end
