classdef Light < mb.base.Base & mb.base.Visible 
    
    properties
        ray_angles = 0:10:350 % direction of rays relative to light orientation. Number of ray_angles determines the number of rays
        symbol = "hexagram" % Marker shape, same options as in standard "plot". For example "hexagram" or "*".
        zlayer = 1 % Objects with higher zlayer will be drawn on top in plots
    end
    
    properties (SetAccess=private,GetAccess=public,Dependent)
        rays
    end
    
    methods (Access=public)
        
        %% Constructor
        function O=Light(varargin)
            O.color=[1 0 0 0.75]; % override default color defined in mb.Base
            O.apply_name_value_pairs(O,varargin); % note may override color again, but not necessarily
        end
        
        %% Plot
        function show(O,varargin)
            p=inputParser;
            p.addParameter('xylabel',[("x ("+mb.settings('length_unit') +")") ("y ("+mb.settings('length_unit') +")")],@(x)isstring(x) && numel(x)==2 || x=="");
            p.addParameter('equal',true,@(x)islogical(x)||isempty(x)); % empty to explicitely leave as is (equal,false does that too actually)
            p.parse(varargin{:});
            washolding=ishold();
            hold('on');
            h=plot(O.xpos,O.ypos,O.symbol,'MarkerFaceColor',O.color(1:3),'MarkerEdgeColor',get(gca,'Color'),'MarkerSize',O.markersize,'LineWidth',1,'ZData',O.zlayer);
            h.UserData=O.id; % Store this objects ID into the plot-object so it can be found using findobj(gca,'UserData',O.id)
            %% Apply the axes styles
            if numel(p.Results.xylabel)==2
                fontsize=mb.settings('fontsize');
                if fontsize>0
                    set('FontSize',fontsize*0.80);
                    xlabel(p.Results.xylabel(1),'FontSize',fontsize);
                    ylabel(p.Results.xylabel(2),'FontSize',fontsize);
                end
            end
            if p.Results.equal
                axis('equal');
            end
            %% Turn hold back to what it was
            if ~washolding
                hold('off');
            end
        end
        
        %% Destructor
        function delete(O)
            O.delete();
        end
        
        %% Deep copy function
        % currently a placeholder, nothing deeper to light than what copy
        % already gets
        function dcopy = deep_copy(O)
            dcopy = copy(O);
        end
        
        %% Convenience function that aims light bundle at specific line-segment
        function aim_rays_at_line_segment(O,n_rays,pt1,pt2)
            [midori,delta1,delta2] = mb.library.Math.angular_extent([O.xpos;O.ypos],pt1,pt2);
            O.orientation=midori; % aim at origin
            if n_rays>1
                O.ray_angles=linspace(delta1,delta2,n_rays);
            else
                O.ray_angles=0;
            end
        end
    end
    
    %% set/get methods
    methods
        function set.ray_angles(O,val)
            arguments 
                O (1,1);
                val (1,:) {mustBeNumeric}
            end
            O.ray_angles=val;
        end
        function val = get.rays(O)
            if numel(O.ray_angles)==0
                val = [];
                return
            end
            theta = O.ray_angles+O.orientation;
            R = mb.Ray('light_id',O.id,'xpos',O.xpos,'ypos',O.ypos);
            R.color=O.color;
            R.linewidth=O.linewidth;
            R.linestyle=O.linestyle;
            R.lineage.parent.id=O.id;
            R.lineage.parent.idx=0;
            R.lineage.birthplace=O.id;
            val=repmat(R,1,numel(O.ray_angles));
            val=copy(val);
            for i=1:numel(O.ray_angles)
                val(i).orientation=theta(i);
            end
        end
    end
end