classdef Ray < mb.base.Base & mb.base.Visible 
    
    properties
        light_id; % the unique id of the mb.Light object this ray ultimately originated at
        type='src'; % src, reflex, refrax
        length=Inf
        intensity=1
        medium="air" % The name of the material the ray is travelling in (will be matched to the media names in the optical boundary it encounters).
        lineage=struct % tracks the history of a ray
        zlayer=-1 % Objects with higher zlayer will be drawn on top in plots, -1 is the bottom, 1 is the top
    end
    
    properties (GetAccess=public, SetAccess=protected)
    end
    
    properties (Hidden)
        current_boundary_id % The boundary the ray is currently at, so that it can be skipped when searching the next hit
    end
    
    methods (Access=public)
        function O=Ray(varargin)
            O.apply_name_value_pairs(O,varargin);
            O.current_boundary_id = [];
            s = struct('id',[],'idx',[]); % id is the unique id of the ray, idx is the index into the mb.Scene.rays array
            O.lineage=struct('parent',s,'child_reflex',s,'child_refrax',s,'birthplace',[],'deathplace',[],'generation_nr',1);
        end
        
        %% Plot
        function show(O)
            if ~isvalid(O)
                return
            end
            if O.intensity==0
                return % Don't plot if the intensity is zero
            end
            ax=gca;
            if isinf(O.lineage.deathplace)
                % The ray did not hit anytning and is off into infinity
                len=mb.settings('infinite_ray_display_length');
                cap='o';
                cap_face_col=ax.Color;
            elseif isempty(O.lineage.child_reflex) && isempty(O.lineage.child_refrax)
                % The ray hit something but it's the last of his generation, capped by (arbitrary) mb.Scene.max_generations_per_ray counter
                len=O.length;
                cap='s';
                cap_face_col=O.color(1:3);
            else
                % Regular ray that doesn't need a cap
                len=O.length;
                cap=[];
            end
            endx=O.xpos+cosd(O.orientation)*len;
            endy=O.ypos+sind(O.orientation)*len;
            h=plot(ax,[O.xpos endx],[O.ypos endy],'Color',O.color,'LineWidth',O.linewidth,'LineStyle',O.linestyle,'ZData',ones(size([O.xpos endx])*O.zlayer));
            h.UserData=O.id; % Store this objects ID into the plot-object so it can be found using findobj(gca,'UserData',O.id)
            if ~isempty(cap)
                h=plot(ax,endx,endy,cap,'MarkerFaceColor',cap_face_col,'MarkerSize',O.markersize/2,'MarkerEdgeColor',O.color(1:3),'LineWidth',O.linewidth,'ZData',1); % ZData=1: always draw markers on top
                h.UserData=O.id; % Store this objects ID into the plot-object so it can be found using findobj(gca,'UserData',O.id)
            end
        end

        function vec=get_norm_vec(O)
            vec=[cosd(O.orientation); sind(O.orientation)];
        end
        
        function [slope, offset]=get_slope_offset(O)
            slope=tand(O.orientation); % will be infinite for 90 and 270
            offset=O.ypos-slope*O.xpos;
        end

        function [xy,x,y]=start_xy(O)
            xy=[O.xpos;O.ypos];
            x=xy(1);
            y=xy(2);
        end
        function [xy,x,y]=end_xy(O)
            xy=[O.xpos;O.ypos]+[cosd(O.orientation);sind(O.orientation)]*O.length;
            x=xy(1);
            y=xy(2);
        end
    end
end