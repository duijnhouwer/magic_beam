classdef Line < mb.boundary.Boundary
    
    %Class to create straight boundaries
    %
    % Line is defined as centered on (xpos,ypos), and the orientation defines
    % the angle of the line's normal in world reference.
    %
    % Line is a bit of a misnomer but shorter than LineSegment
    
    properties
        length=10
    end
    
    %% Public methods
    methods (Access=public)
        
        %% Constructor
        function O=Line(body,varargin)
            O.apply_name_value_pairs(O,varargin);
            O.add_body_listeners(body);
        end  
        
        %% Plot
        function show(O)
            xy = O.get_vertices;
            h=plot(xy(1,:),xy(2,:),'Color',O.color,'LineWidth',O.linewidth,'LineStyle',O.linestyle,'ZData',ones(1,size(xy,2))*O.zlayer);
            h.UserData=O.id; % Store this objects ID into the plot-object so it can be found using findobj(gca,'UserData',O.id)
        end
        
        function xy = get_vertices(O)
            % Return the scene-coordinates of the vertices that O.show would plot
            xy = O.get_boundary_centric_vertices;
            xy = xy + [O.xpos; O.ypos];
        end
        
        %% Bounce a ray of the arc, produces a reflection and an refraction ray
        function [hitbool, reflex_ray, refrax_ray]=reflect_and_refract(O,inray)
            % Note: If hitbool is true, this function changes the lenght propery of inray. See comments below.
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
            % - The incoming ray's current medium is not on either side of the boundary, UNLESS the media
            %       on both boundaries contain asterisks
            if inray.intensity==0 || (~any(O.media==inray.medium) && ~all(contains(O.media,"*")))
                return
            end
            
            %% Make template for the two output rays by shallow-copying of the source ray.
            % It's called a stemray because it will itself serve as a template for both the
            % refraction and the reflection rays.
            stemray=copy(inray);
            stemray.length=Inf;
            
            %% Find the intersection of the ray with the line
            [ray_slope, ray_offset] = inray.get_slope_offset; % will be infinite for 90 and 270 (vertical rays, but that's not a problem)
            line_slope = tand(O.orientation+90);
            line_offset = O.ypos-line_slope*O.xpos;
            
            if ray_slope==line_slope
                return % two parallel lines don't intersect, no hit.
            elseif isinf(ray_slope) && isinf(line_slope) % can be Inf and -Inf!
                return % two vertical lines don't intersect, no hit
            elseif isinf(line_slope) % this line is vertical
                ix = O.xpos;
                iy = ray_slope*ix+ray_offset;
            elseif isinf(ray_slope) % the incident ray is vertical
                ix = inray.xpos;
                iy = line_slope*ix+line_offset;
            else
                ix = (line_offset-ray_offset)/(ray_slope-line_slope);
                iy = line_slope*ix+line_offset;
            end
            
            %% if ix and iy are empty, the lines must be parallel.
            if isempty(ix)
                return % no hit
            end
            
            %% Make sure the intersection is found in the direction of the ray
            if isinf(ray_slope) % vertical ray
                if sign(sind(inray.orientation))~=sign(iy-inray.ypos)
                    return % no hit
                end
            else
                if sign(cosd(inray.orientation))~=sign(ix-inray.xpos)
                    % Example:
                    %
                    %   |boundary
                    %   |
                    %   ix     *--ray-->
                    %   |
                    %
                    % The ray starts at * and travels to the right, therefore cosd(inray.orientation)>0
                    % intersection ix of _line_ representing the ray is left of *'s xpos, therefore ix - xpos < 0
                    % Since, they have different signs, the ray's actual half-line does not intersect the boundary
                    return % no hit
                end
            end
            
            %% See if the intersection point is within the length of this line segment
            [xy]=O.get_boundary_centric_vertices+[O.xpos; O.ypos]; % 2x2 matrix, columns are the two ends of the segment, rows are x and y
            if ix<min(xy(1,:)) || ix>max(xy(1,:)) || iy<min(xy(2,:))|| iy>max(xy(2,:))
                return % no hit
            end
            stemray.xpos=ix;
            stemray.ypos=iy;
            norm_vec=O.get_normal_vector;
            
            %% If we made it this far, the inray has hit this boundary!
            hitbool=true;
            % Set the current_boundary_id of the stemray to that of the current boundary (line) so
            % that we can skip this boundary when looking for the next hit for the reflex and
            % refraction rays that we create from the stemray (otherwise, the same boundary will be
            % a guaranteed hit with a ray with length zero).
            stemray.current_boundary_id = O.id;
            
            %% Calculate the distance from the source to the hit-point. This will be the
            % length the incoming ray has traveled. Update the length property of the inray
            % object. (This is important to note as it's not directly obvious by reading
            % through the code that an input argument will change during a call to a function.)
            inray.length=hypot(inray.xpos-stemray.xpos,inray.ypos-stemray.ypos);
            
            %% Convert the angle of the inray to a vectoy
            in_vec=[cosd(inray.orientation) sind(inray.orientation)];
            
            
            %% Calculate theta_in, the angle of incidence of the inray (relative to local normal)
            theta_in(1)=O.vec_signed_deg(norm_vec(:),in_vec(:));
            theta_in(2)=O.vec_signed_deg(norm_vec(:),-in_vec(:));
            % Select the smallest way of the two options
            [~,idx]=min(abs(theta_in));
            theta_in=theta_in(idx);
            
            %  theta_in(1)=acosd(dot(-in_vec,norm_vec));
            %  theta_in(2)=acosd(dot(in_vec,norm_vec));
            %  cp=cross([in_vec 0],[norm_vec 0]); % to get sign for theta
            %  % Select the smallest way, and calculate its sign accordingly
            %  if theta_in(1)<theta_in(2)
            %      theta_in=theta_in(1);
            %      theta_in=theta_in*sign(cp(3)); % apply sign
            %  else
            %      theta_in=theta_in(2);
            %      theta_in=theta_in*-sign(cp(3)); % apply sign
            %  end
            
            
            %% Convert the norm_vec to an angle.
            % But first make sure the normal vector is sticking out of the side where the ray hits the segment
            if acosd(dot(norm_vec,in_vec))<90
                norm_vec = -norm_vec;
            end
            norm_deg = atan2d(norm_vec(2),norm_vec(1));
            
            %% Differentiate the stemray into a reflex_ray
            reflex_ray = O.stem_to_reflex_ray(copy(stemray),norm_deg,theta_in);
            
            %% Differentiate the stemray into a refrax_ray
            refrax_ray = O.stem_to_refrax_ray(stemray,norm_deg,theta_in);
            
        end
    end
    
    %% Private methods
    methods (Access=private)
        
        %% Calculate the coordinates of the vertices for plotting
        function [xy]=get_boundary_centric_vertices(O)
            % Line_segment is defined as centered on O.xpos,O.ypos, and the orientation
            % defines the angle of the line's normal in world reference
            dxdy=[cosd(O.orientation+90); sind(O.orientation+90)]*O.length/2;
            xy(:,1)=-dxdy;
            xy(:,2)=dxdy;
        end
        
        %% Return the normal vector of the line segment
        function norm_vec = get_normal_vector(O)
            norm_vec=[cosd(O.orientation) sind(O.orientation)];
        end
    end
    
    %% set/get methods
    methods
        function set.length(O,val)
            arguments, O, val (1,1) double {mustBeNonnegative}, end
            O.length=val;
        end
    end
    
end