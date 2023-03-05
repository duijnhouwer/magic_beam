classdef GullstrandVar < mb.body.Body
    
    % Gulstrand eye ball model as described in Atchison & Smith (2000, page 252).
    %
    % This is a combinaton of the two original Gullstrand models that were created in a relaxed
    % (focusing at 0-dpt) and an accommodated (focusing at 10.878-dpt) variety. In this adaption by
    % Atchison & Smith (2000, page 46), accommodation is variable. It basically interpolates between
    % the two extremes. The two original models are a subset of this one.
    %
    % I have added an optional iris with variable pupil diameter and offet. Setting pupil_diam to a
    % negative value disables the iris.
    %
    % I had to made up a radius for the retinal arc because none was provided in the model
    % specification. Only the breadth of the vitreous body from the posterior boundary of the lens
    % to the retina was defined.
    %
    % Jacob Duijnhouwer 2021-06-09
    
    properties
        pupil_x=9.3 % Pupil location relative to center of retinal arc [9.3]
        pupil_diam=4 % Pupil diameter in mm [4]
        pupil_offset=0 % Pupil shift relative to optical axis in mm [0]
        accommodation=0 % % Accommodation of eye in diopters [0]
    end
    
    properties (SetAccess=private,GetAccess=public)
    end
    
    properties (Dependent)
    end
    
    methods (Access=public)
        function O=GullstrandVar(varargin)
            O.apply_name_value_pairs(O,varargin);
            O.set_boundaries;
        end
    end
    
    methods (Access=private)
        function set_boundaries(O)
            % Below values are from Atchison & Smith (2000) page 252
            % Except the radius of the retina. That was not provided. I made up a 11.5 mm because
            % that looks reasonable. The tables in Athchison & Smith only provide distances from one
            % boundary to the next.
            
            x = 1.052 * O.accommodation - 0.00531 * O.accommodation^2 + 0.000048564 * O.accommodation^3;
            Ao = 10.87013; % level of Gullstrand accommodated eye in dioptres
            
            cornea_thickness = 0.5;
            ant_chamber_depth = 3.1-(3.1-2.7)*x/Ao; % 2.7;
            cort_ant_thickness = 0.546 - (0.546-0.6725)*x/Ao; % 0.6725;
            core_thick = 2.419-(2.419-2.655)*x/Ao; % 2.655;
            cort_post_thickness = 0.635-(0.635-0.6725)*x/Ao; % 0.6725;
            vitreous_thickness = 17.18540;
            
            % Curv(ature) == 1/radius;
            lens_cortex_ant_curv = 0.1-(0.1-1/5.333)*x/Ao; % 1/5.333 at accomm 10.87013
            lens_core_ant_curv = 1/7.911 - (1/7.911 - 1/2.655)*x/Ao; % 1/2.655 at accomm 10.87013
            lens_core_post_curv = -1/5.760 - (-1/5.760 - 1/-2.655)*x/Ao; % 1/2.655 at accomm 10.87013. Note Atchison and Smith use negative radius to flip the arc, here we used arc_delta=180
            lens_cortex_post_curv = -1/6 - (-1/6 - 1/-5.333)*x/Ao; % 1/5.333 at accomm 10.87013
            
            
            O.boundaries={};
            
            h=O.add_boundary('Arc',"anterior_cornea",'media',["air" "cornea"],'n1n2',[1.000 1.376],'r1r2',[1 0],'radius',7.7);
            h.xpos = h.xpos - h.radius * cosd(h.arc_delta); % puts arc vertex at x=0
            
            h=O.add_boundary('Arc',"posterior_cornea",'media',["cornea" "aqueous"],'n1n2',[1.376 1.336],'r1r2',[1 0],'radius',6.8);
            h.xpos = h.xpos - h.radius * cosd(h.arc_delta); % puts arc vertex at x=0
            h.xpos = h.xpos - cornea_thickness;
            
            h=O.add_boundary('Arc',"anterior_lens",'media',["aqueous" "lens_cortex"],'n1n2',[1.336 1.386],'r1r2',[1 0],'radius',1/lens_cortex_ant_curv,'span',60+O.accommodation*4.25);
            h.xpos = h.xpos - h.radius * cosd(h.arc_delta); % puts arc vertex at x=0
            h.xpos = h.xpos - cornea_thickness - ant_chamber_depth;
            
            h=O.add_boundary('Arc',"anterior_lens_core",'media',["lens_cortex" "lens_core"],'n1n2',[1.386 1.406],'r1r2',[1 0],'radius',1/lens_core_ant_curv,'span',60+O.accommodation*6);
            h.xpos = h.xpos - h.radius * cosd(h.arc_delta); % puts arc vertex at x=0
            h.xpos = h.xpos - cornea_thickness - ant_chamber_depth - cort_ant_thickness;
            
            h=O.add_boundary('Arc',"posterior_lens_core",'media',["lens_core" "lens_cortex"],'n1n2',[1.406 1.386],'r1r2',[1 0],'radius',-1/lens_core_post_curv,'arc_delta',180,'span',85+O.accommodation*3.5);%
            h.xpos = h.xpos - h.radius * cosd(h.arc_delta); % puts arc vertex at x=0
            h.xpos = h.xpos - cornea_thickness - ant_chamber_depth - cort_ant_thickness - core_thick;
            
            h=O.add_boundary('Arc',"posterior_lens",'media',["lens_cortex" "vitreous"],'n1n2',[1.386 1.336],'r1r2',[1 0],'radius',-1/lens_cortex_post_curv,'arc_delta',180,'span',105+O.accommodation*0.1);
            h.xpos = h.xpos - h.radius * cosd(h.arc_delta); % puts arc vertex at x=0
            h.xpos = h.xpos - cornea_thickness - ant_chamber_depth - cort_ant_thickness - core_thick - cort_post_thickness;
            
            h=O.add_boundary('Arc',"retina",'media',["vitreous" "sclera"],'n1n2',[1.336 0.000],'r1r2',[0 0],'radius',11.5,'arc_delta',180,'span',285);
            h.xpos = h.xpos - h.radius * cosd(h.arc_delta); % puts arc vertex at x=0
            h.xpos = h.xpos - cornea_thickness - ant_chamber_depth - cort_ant_thickness - core_thick - cort_post_thickness - vitreous_thickness;
            
            h=O.add_boundary('Arc',"sclera",'media',["sclera" "air"],'n1n2',[0.000 1.000],'r1r2',[0 0],'radius',12,'arc_delta',180,'span',286);
            h.xpos = O.boundaries.retina.xpos; % same as retina   
            
            % Shift all boundaries to the right such that the center of the retinal arc is at (0,0)
            eyeball_center_x = O.boundaries.retina.xpos;
            cellfun(@(x)set(x,'xpos',x.xpos-eyeball_center_x),struct2cell(O.boundaries));
            
            % Add an iris, if requested with non-negative pupil_diam
            if O.pupil_diam>=0
                iris_diam = 15;
                ccw_len = iris_diam/2 - O.pupil_diam/2 - O.pupil_offset;
                ccw_mid = iris_diam/2 - ccw_len/2;
                cw_len = iris_diam/2 - O.pupil_diam/2 + O.pupil_offset;
                cw_mid = -iris_diam/2 + cw_len/2;
                O.add_boundary('Line',"iris_ccw",'media',["*" "*"],'n1n2',[0 eps],'r1r2',[0 0],'length',ccw_len,'x',O.pupil_x,'y',ccw_mid,'ori',0);
                O.add_boundary('Line',"iris_cw",'media',["*" "*"],'n1n2',[0 eps],'r1r2',[0 0],'length',cw_len,'x',O.pupil_x,'y',cw_mid,'ori',0);
            end

            % Apply the body's orientation to the boundaries
            O.pivot_x=O.boundaries.retina.xpos;
            O.pivot_y=O.boundaries.retina.ypos;
            cellfun(@(x)x.rotate(O.orientation,[O.xpos+O.pivot_x O.ypos+O.pivot_y]),struct2cell(O.boundaries));
        end
    end
    
    methods (Access=public)
            
       function xy = pupil_center_xy(eye)
           %% Find the center of the pupil
           iris_cw = eye.get_boundary_named("iris_cw");
           iris_ccw = eye.get_boundary_named("iris_ccw");
           if isempty(iris_cw) || isempty(iris_ccw)
               warning('eye does not comprise boundaries called ''iris_cw'' and ''iris_ccw''');
               xy=[];
               return
            end
            iris_cw_xy=iris_cw.get_vertices;
            iris_ccw_xy=iris_ccw.get_vertices;
            % Find the vertices that are closest together
            min_dist=Inf;
            for i=1:2
                for j=1:2
                    dist = norm(iris_cw_xy(:,i)-iris_ccw_xy(:,j));
                    if dist<min_dist
                        min_dist=dist;
                        xy = (iris_cw_xy(:,i)+iris_ccw_xy(:,j))/2;
                    end
                end
            end
       end
       
       function xy = back_of_retina_xy(eye)
           %% back_of_lens_xy
           bnd = eye.get_boundary_named("retina");
           if isempty(bnd)
               warning('eye does not comprise a boundary called ''retina''');
               xy=[];
               return
           end
           xy(1,1)=bnd.xpos+cosd(bnd.orientation+bnd.arc_delta)*bnd.radius;
           xy(2,1)=bnd.ypos+sind(bnd.orientation+bnd.arc_delta)*bnd.radius;
       end
        
        
        function xy = back_of_lens_xy(eye)
            %% back_of_lens_xy
             bnd = eye.get_boundary_named("posterior_lens");
            if isempty(bnd)
                warning('eye does not comprise a boundary called ''posterior_lens''');
                xy=[];
                return
            end
            xy(1,1)=bnd.xpos+cosd(bnd.orientation+bnd.arc_delta)*bnd.radius;
            xy(2,1)=bnd.ypos+sind(bnd.orientation+bnd.arc_delta)*bnd.radius;
        end
        
        function xy = front_of_lens_xy(eye)
            %% front_of_lens_xy
             bnd = eye.get_boundary_named("anterior_lens");
            if isempty(bnd)
                warning('eye does not comprise a boundary called ''anterior_lens''');
                xy=[];
                return
            end
            xy(1,1)=bnd.xpos+cosd(bnd.orientation+bnd.arc_delta)*bnd.radius;
            xy(2,1)=bnd.ypos+sind(bnd.orientation+bnd.arc_delta)*bnd.radius;
        end
        
        function xy = eyeball_center_xy(eye)
            %% eyeball_center_xy
            bnd = eye.get_boundary_named("retina");
            if isempty(bnd)
                warning('eye does not comprise a boundary called ''retina''');
                xy=[];
                return
            end
            xy=[bnd.xpos;bnd.ypos];
        end
        
        function xy = cornea_pole_xy(eye)
            %% cornea_pole_xy
            bnd = eye.get_boundary_named("anterior_cornea");
            if isempty(bnd)
                warning('eye does not comprise a boundary called ''anterior_cornea''');
                xy=[];
                return
            end
            xy(1,1)=bnd.xpos+cosd(bnd.orientation+bnd.arc_delta)*bnd.radius;
            xy(2,1)=bnd.ypos+sind(bnd.orientation+bnd.arc_delta)*bnd.radius;
        end
        
           
    end
    
    methods
        function set.accommodation(O,val)
            if ~isnumeric(val) || ~isscalar(val) || val<0
                error('accommodation must be a scalar equal or larger than 0');
            end
            if O.accommodation~=val
                O.accommodation=val;
                O.set_boundaries;
            end
        end
        function set.pupil_x(O,val)
            if ~isnumeric(val) || ~isscalar(val)
                error('pupil_x must be a numeric scalar');
            end
            if O.pupil_x~=val
                O.pupil_x=val;
                O.set_boundaries;
            end
        end
        function set.pupil_offset(O,val)
            if ~isnumeric(val) || ~isscalar(val)
                error('pupil_offset must be a numeric scalar');
            end
            if O.pupil_offset~=val
                O.pupil_offset=val;
                O.set_boundaries;
            end
        end
        function set.pupil_diam(O,val)
            if ~isnumeric(val) || ~isscalar(val) || val<0
                error('pupil_diam must be a positive numeric scalar');
            end
            if O.pupil_diam~=val
                O.pupil_diam=val;
                O.set_boundaries;
            end
        end
    end
end
