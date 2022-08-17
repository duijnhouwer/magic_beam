classdef Arc  < mb.boundary.Boundary
    
    properties
        radius=10 % Main radius [10]
        radius2=nan; % Optional secondary radius 2 [NaN]. If NaN (default), radius2 is the same as radius and the ellipse is a circle
        span=120 % Arc span angle [120]
        arc_delta=0 % Orientation-angle of middle of arc segment *relative* to the nominal axis [0]
    end
    
    properties (Dependent,Hidden)
        arc_orientation % orientation-angle of the middle of the arc relative to world-horizontal, that is, orientation+arc_delta (dependent)
        arc_vec % arc orientation as a vector, i.e., [cosd(arc_orientation) sind(arc_orientation)] (dependent)
    end
    
    %% Public methods
    methods (Access=public)
       
        %% Constructor
        function O=Arc(body,varargin)
            O.apply_name_value_pairs(O,varargin);
            if isnan(O.radius2)
                O.radius2=O.radius;
            end
            O.add_body_listeners(body);
        end
        
        %% Plot
        function show(O)
            R = O.rotmat(O.orientation);
            xy = R * O.get_vertices;
            h=plot(O.xpos+xy(1,:),O.ypos+xy(2,:),'Color',O.color,'LineWidth',O.linewidth,'LineStyle',O.linestyle,'ZData',ones(1,size(xy,2))*O.zlayer);
            h.UserData=O.id; % Store this objects ID into the plot-object so it can be found using findobj(gca,'UserData',O.id)
        end
        
        %% Calculate the coordinates of the vertices for plotting
        function xy=get_vertices(O)
            % xy will be in body coordinate, that is: relative to O.xpos,O.ypos and relative (in angle) to O.orientation
            if O.radius==O.radius2 % circle, use faster method
                arc_mm = O.span/180*pi*O.radius; % length of the arc in mm
                n_vertices = round(arc_mm*O.nvpmm);
                if O.span==360
                    theta = linspace(0,360-360/n_vertices,n_vertices);
                else
                    theta = linspace(-O.span/2,O.span/2,n_vertices);
                end
                R = O.rotmat(O.arc_delta); % To point the arc segments center in the direction of arc_delta
                xy = R * [cosd(theta);sind(theta)]*O.radius;
            else % ellipse, use general method
                %% Step 1: get the full ellipse
                total_mm = O.ellipse_arc_length(O.radius,O.radius2,0,90)*4;
                n_vertices = round(total_mm*O.nvpmm);
                theta = linspace(0,360-360/n_vertices,n_vertices);
                xy = [cosd(theta)*O.radius; sind(theta)*O.radius2];
                %% Step 2: cut away the vertices that are outside of the span
                vertex_vecs = xy./norm(xy); % express all vertices as a (normalized) vector
                arc_center_vec = [cosd(O.arc_delta); sind(O.arc_delta)];
                signed_deg = O.vec_signed_deg(arc_center_vec,vertex_vecs);  % get signed angles between all vertex_vecs and the central vector
                in_range = abs(signed_deg)<O.span/2;
                xy(:,~in_range)=[]; % delete out-of-range vertices
                %% Step 3: Sort the remaining vertices by ascending signed_deg (for plotting without jumps)
                [~,idx] = sort(signed_deg(in_range));
                xy=xy(:,idx);
            end
        end
        
        %% Bounce a ray of the arc, produces a reflection and an refraction ray
        function [hitbool, reflex_ray, refrax_ray]=reflect_and_refract(O,inray)
            arguments
                O, inray (1,1) mb.Ray
            end
  
            %% Initialize return arguments assuming that the inray will hit nothing
            hitbool=false;
            reflex_ray=[];
            refrax_ray=[];
            inray.length=Inf;
            
            %% We know right away this won't be a hit if ...
            % - The incoming ray's intensity is zero.
            % - The incoming ray's current medium is not on either side of the
            %   boundary, unless the media on both boundaries contain asterisks
            if inray.intensity==0 || (~any(O.media==inray.medium) && ~all(contains(O.media,"*")))
                return
            end
            
            %% Make template for the two output rays by shallow-copying of the source ray.
            % It's called a stemray because it will itself serve as a template for both the
            % refraction and the reflection rays.
            stemray=copy(inray);
            stemray.length=Inf;
            
            
            %% Find the intersections of the ray with the ellipse of which the arc is a segment
            % First, define the line with y_intercept and x_intercept
            ray_slope = tand(inray.orientation); % will be infinite for 90 and 270 (vertical rays, but that's not a problem)
            ray_offset = inray.ypos-ray_slope*inray.xpos;
            if isinf(ray_slope)
                ray_offset = inray.xpos; % special case, offset now is x-intercept of vertical line!
            end
            % Then find the 0,1,or 2 intersections of this line with the ellipse            
            [ix,iy] = O.ellipse_line_intersect(O.radius,O.radius2,O.xpos,O.ypos,O.orientation,ray_slope,ray_offset);
            
            
              %% Make sure the intersection is found in the direction of the ray
            keep=true(1,2);
            for i=1:2
              if isinf(ray_slope) % vertical ray
                if sign(sind(inray.orientation))~=sign(iy(i)-inray.ypos)
                    keep(i)=false; % no hit
                end
            else
                if sign(cosd(inray.orientation))~=sign(ix(i)-inray.xpos)
                    % Example:
                    %
                    %   |boundary 
                    %   |
                    %   ix     *--ray-->
                    %   |
                    %
                    % The ray starts at * and travels to the right, therefore cosd(inray.orientation)>0
                    % intersection ix of _line_ representing they ray is left of *'s xpos, therefore ix - xpos < 0 
                    % Since, they have different signs, the ray's actual half-line does not intersect the boundary
                    keep(i)=false; % no hit
                end
              end
            end
            if ~any(keep)
                return % no hit;
            end
            ix=ix(keep);
            iy=iy(keep);
            
            %% Pick the intersection (if any) that represents the hit-point
            if isnan(ix(1))
                % The inray does not hit the ellipse, let alone the arc
                return
            elseif O.span==360
                % Special case where the arc spans the full circle, simply return
                % the intersection that is nearest to the source
                [~,idx]=min(hypot(ix-inray.xpos,iy-inray.ypos));
                stemray.xpos=ix(idx);
                stemray.ypos=iy(idx);
                norm_vec=O.get_normal_vector(stemray.xpos,stemray.ypos);
            else
                % arc segment, see if the ellipse hit-point(s) are within the arc span
                n_points = numel(ix);
                dohitarc=false(n_points,1);
                norm_vec=nan(2,n_points);
                for i=1:n_points
                    center_to_intersection_vec=[ix(i)-O.xpos iy(i)-O.ypos]./norm([ix(i)-O.xpos iy(i)-O.ypos]);
                    delta_deg=acosd(dot(center_to_intersection_vec,O.arc_vec));
                    dohitarc(i) = delta_deg<=O.span/2;
                end
                if sum(dohitarc)==2
                    % ray intersects the arc in two points, return the one nearest to source
                    [~,idx]=min(hypot(ix-inray.xpos,iy-inray.ypos));
                    stemray.xpos=ix(idx);
                    stemray.ypos=iy(idx);
                    norm_vec=O.get_normal_vector(stemray.xpos,stemray.ypos);
                elseif sum(dohitarc)==1
                    % return the one intersection of ray and arc
                    stemray.xpos=ix(dohitarc);
                    stemray.ypos=iy(dohitarc);
                    norm_vec=O.get_normal_vector(stemray.xpos,stemray.ypos);
                elseif ~any(dohitarc)
                    % The inray hit the circle of which the arc is a part, but not the arc
                    % segment itself
                    return
                end
            end
            %% If we made it this far, the inray has hit the arc!
            hitbool=true;
            % Set the id of the stemray to that of the current boundary (arc) so that we can skip
            % this boundary when looking for the next hit for the reflex and refraction
            % rays that we create from the stemray (otherwise, the same boundary will be a
            % guaranteed hit with a ray with length zero).
            stemray.current_boundary_id = O.id;
            
            %% Calculate the distance from the source to the hit-point. This will be the
            % length the incoming ray has traveled. Update the length property of the inray
            % object. (This is important to note as it's not directly obvious by reading
            % through the code that an input argument will change during a call to a function.)
            inray.length=hypot(inray.xpos-stemray.xpos,inray.ypos-stemray.ypos);
            
            %% Convert the angle of the inray to a vector
            in_vec=[cosd(inray.orientation) sind(inray.orientation)];
            
            %% Calculate theta_in, the angle of incidence of the inray (relative to local normal)
            theta_in(1)=acosd(dot(-in_vec,norm_vec));
            theta_in(2)=acosd(dot(in_vec,norm_vec));
            cp=cross([in_vec 0],[norm_vec 0]); % to get sign for theta
            % Select the smallest way, and calculate its sign accordingly
            if theta_in(1)<theta_in(2)
                theta_in=theta_in(1);
                theta_in=theta_in*sign(cp(3)); % apply sign
            else
                theta_in=theta_in(2);
                theta_in=theta_in*-sign(cp(3)); % apply sign
            end
            
            % Check if the ray and the ori_vec normal point in the same direction. If they do, then the
            % ray hits the arc on the concave side and the normal needs to be flipped 180 deg
            if acosd(dot(O.arc_vec,in_vec))<90
                norm_vec = -norm_vec;
            end
            norm_deg = atan2d(norm_vec(2),norm_vec(1));
            
            %% Differentiate the stemray into a reflex_ray
            % Arg1 will be changed inside this function so pass a copy because we want to use a
            % fresh stemray for the stem_to_refrax_ray call after this.
            reflex_ray = O.stem_to_reflex_ray(copy(stemray),norm_deg,theta_in);
            
            %% Differentiate the stemray into a refrax_ray
            refrax_ray = O.stem_to_refrax_ray(stemray,norm_deg,theta_in);
        end
    end
    
    %% Private methods
    methods (Access=private)
        
        %% Return the normal vector at point (x,y)
        function norm_vec = get_normal_vector(O,x,y)
            % Return the normal on the arc segment at the location (x,y). Note: no effort is made to
            % check that (x,y) is in fact on the arc segment.
            if O.radius==O.radius2
                % This ellipse is a circle, or the option to get the normal as if its a circle has
                % been provided -> Norm vector is simply parallel to the line through the center of
                % the circle and (x,y)
                norm_vec = [x-O.xpos y-O.ypos]./norm([x-O.xpos y-O.ypos]);
            else
                % For a standard ellipse with center at 0,0 and the primary axis parallel
                % to the x-axis, the normal is at point x,y is simply
                % (x/radius^2,y/radius2^2) Therefore, transform our ellipse to such a
                % standard one by subtracting its xpos from x and its ypos from y, and make
                % its primary axis horizontal by rotating by the negative orientation.
                % Afterward, rotate the normal back by the orientation (the shift needs not
                % be added back in again, the normal is a positionless unit vector)
                xy = O.rotmat(-O.arc_orientation)*[x-O.xpos;y-O.ypos];
                norm_vec = O.rotmat(O.arc_orientation)*[xy(1)/O.radius^2;xy(2)/O.radius2^2];
                norm_vec = norm_vec./norm(norm_vec);
                norm_vec = norm_vec(:)';
            end
        end
    end
    
    %% set/get methods
    methods
        function set.radius(O,val)
            arguments, O, val (1,1) double {mustBeNonnegative}, end
            O.radius=val;
        end
        function set.radius2(O,val)
            if ~isscalar(val) && ~isempty(val) && ~isnumeric(val)
                error('radius2 must be a numeric scalar or empty')
            end
            O.radius2=val;
        end
        function set.span(O,val)
            arguments, O, val (1,1) double {mustBeNonnegative}, end
            O.span=max(0,min(360,val));
        end
        function set.arc_delta(O,val)
            arguments, O, val (1,1) double, end
            O.arc_delta=mod(val+180,360)-180;
        end
        function val=get.arc_orientation(O)
            val=O.orientation+O.arc_delta;
            val=mod(val+180,360)-180;
        end
        function val=get.arc_vec(O)
            val=[cosd(O.arc_orientation); sind(O.arc_orientation)];
        end
    end
    
end