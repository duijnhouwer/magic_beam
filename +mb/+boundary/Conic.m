classdef Conic < mb.boundary.Boundary
    
    %mb.boundary.Conic - Conic section boundary
    % Produces boundaries according to the following equation
    % y = +/- sqrt( -(1+Q)*x^2 + 2*R*x )
    %
    % Over the range [x-depth ... x]
    %
    % I adapted this equation is from Atchison and Smith 2002 p.13 except I
    % reduced it to 2D and flipped the sign of R such that the right apex of
    % the curve is at (xpos,ypos) instead of the left apex.
    % 
    % R is the vertex radius of curvature and Q governs the surface
    % asphericity:
    %   Q < -1: hyperbola
    %   Q = -1: parabola
    %   -1 < Q < 0: ellipse stretched in the Y direction
    %   Q = 0: circle
    %   Q > 0: ellipse stretched in the X direction
    %
    % Limitation: orientation has not yet been implemented for this type of
    % boundary! (TODO 666, Issue #13,14)
    
    properties
        Q = 0 % The asphericity parameter 
        R = 1 % Curvature parameter
        depth = 1 % Define the domain [x-depth ... x]
    end
    
    %% Public methods
    methods (Access=public)
        
        %% Constructor
        function O=Conic(body,varargin)
           O.apply_name_value_pairs(O,varargin);
           O.add_body_listeners(body);
        end
        
        %% Calculate the coordinates of the vertices for plotting
        function [xy]=get_vertices(O)
            % xy will be in body coordinate, that is: relative to O.xpos,O.ypos and relative (in
            % angle) to O.orientation
            
            O.depth;
            if true
                r = abs(O.R);
                step = 0.01;
                xx = 0:step:O.depth;
                ytop = sqrt( -(1+O.Q)*xx.^2 + 2*r*xx );
                isreal = imag(ytop)==0;
                xx(~isreal)=[];
                ytop(~isreal)=[];
                ybot = -ytop;
                xy =[[xx(end:-1:1) xx]; [ybot(end:-1:1) ytop ]];
                if O.R>0
                    xy(1,:)=-xy(1,:);
                end
            else
                % TODO 666: fix problem with low vertices for steep parts of curve like
                % this:
                %
                % To get ~n vertices per mm of arc we first get nvpmm y-values per mm of x-axis.
                % This is the minimum number of vertices necessary to get nvpmm values per mm of
                % arc, and only correct when the arc is exactly horizontal (e.g. ellipse with no
                % vertical expanse). Get the mm length between vertices and insert more to get close
                % to nvpmm per mm or arc in the second pass.
                % First determine the max depth (limited for circles and ellipses, open ended for
                % parabolas and hyperbolas
                if false && O.Q>-1 % ellipses (including circle)
                    % limit the depth to the horizontal cross section of the conic
                    ipts=O.conic_line_intersect(O.Q,O.R,0,0,0,0);
                    dep = min(O.depth,abs(diff(ipts(1,:))));
                else
                    dep = O.depth;
                end
                r = abs(O.R);
                step = 0.01;
                xx = 0:step:O.depth;
                ytop = sqrt( -(1+O.Q)*xx.^2 + 2*r*xx );
                isreal = imag(ytop)==0;
                xx(~isreal)=[];
                ytop(~isreal)=[];
                ybot = -ytop;
                xy =[[xx(end:-1:1) xx]; [ybot(end:-1:1) ytop ]];
                if O.R>0
                    xy(1,:)=-xy(1,:);
                end
            end
        end
        
        %% Plot
        function show(O)
            xy = O.rotmat(O.orientation) * O.get_vertices;
            h=plot(O.xpos+xy(1,:),O.ypos+xy(2,:),'Color',O.color,'LineWidth',O.linewidth,'LineStyle',O.linestyle,'ZData',ones(1,size(xy,2))*O.zlayer);
            h.UserData=O.id; % Store this objects ID into the plot-object so it can be found using findobj(gca,'UserData',O.id)
        end
        
        %% Bounce a ray of the conic section, produces a reflection and an refraction ray
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
            if inray.intensity==0 || ~any(O.media==inray.medium) && ~all(contains(O.media,"*"))
                return
            end
  
            %% Make template for the two output rays by shallow-copying of the source ray.
            % It's called a stemray because it will itself serve as a template for both the
            % refraction and the reflection rays.
            stemray=copy(inray);
            stemray.length=Inf;
            
            %% Find the intersections of the ray with the ellipse of which the arc is a segment
            % First, define the line with y_intercept and x_intercept
            [slope, offset] = inray.get_slope_offset;
            if isinf(slope)
                offset = inray.xpos; % special case, offset now is x-intercept of vertical line!
            end
            % Then find the 0,1,or 2 intersections of this line with the conic
            [ixy,normvecs] = O.conic_line_intersect(O.Q,O.R,O.xpos,O.ypos,slope,offset);
            
            if isempty(ixy) || isnan(ixy(1))
                % The inray does not hit the conic boundary
                return
            end
                
           %% Exclude intersection that are behind the ray's origin
            % Can happen when the origin is inside the conic
            keep=true(1,size(ixy,2));
            for i=1:size(ixy,2)
                hitvec = [ixy(1,i)-inray.xpos; ixy(2,i)-inray.ypos];
                hitvec = hitvec./norm(hitvec);
                keep(i) = acosd(dot(hitvec,inray.get_norm_vec))<90;
            end
            if ~any(keep)
                return
            end
            ixy=ixy(:,keep);
            normvecs=normvecs(:,keep);
            
            %% Exlude intersections that are outside the subset-of the conic
            % This is currently goverend by O.depth only, as orientation is currenty
            % ignored. In future, when orientation is implemented, remove the orientation
            % first (by rotating the intersecting lines) and then add the rotation back
            % in when the intersection has been found
            fudge = 1e-13; % Somehow this is needed, maybe because of different rounding using symbolic math in conic_line_intersect. TODO 666 look into this. Issue #15
            if O.R>0
                keep=ixy(1,:)>=O.xpos-O.depth & ixy(1,:)<=O.xpos + fudge; % check if the x coordinate is with range from the tip of the conic
            else
                keep=ixy(1,:)>=O.xpos-fudge & ixy(1,:)<=O.xpos+O.depth; % works the other way if arc is flipped using negative R trick
            end
            if ~any(keep)
                return
            end
            ixy=ixy(:,keep);
            normvecs=normvecs(:,keep);
            
            %% if there are still 2 intersections, pick the one that's closest to the
              % ray's origin. Otherwise use the one remaining intersection
            if size(ixy,2)==2
                [~,idx]=min(hypot(ixy(1,:)-inray.xpos,ixy(2,:)-inray.ypos));
            elseif size(ixy,2)==1
                idx=1;
            else
                error('This should not be possible, check code');
            end
            stemray.xpos=ixy(1,idx);
            stemray.ypos=ixy(2,idx);
            norm_vec=normvecs(:,idx);
                
            %% If we made it this far, the inray has hit the arc!
            hitbool=true;
            % Set the id of the stemray to that of the current boundary (conic) so that
            % we can skip this boundary when looking for the next hit for the reflex
            % and refraction rays that we create from the stemray (otherwise, the same
            % boundary will be a guaranteed hit with a ray with length zero).
            stemray.current_boundary_id = O.id;
            
            %% Calculate the distance from the source to the hit-point. This will be the
            % length the incoming ray has traveled. Update the length property of the inray
            % object. (This is important to note as it's not directly obvious by reading
            % through the code that an input argument will change during a call to a function.)
            inray.length=hypot(inray.xpos-stemray.xpos,inray.ypos-stemray.ypos);
            
            %% Convert the angle of the inray to a vector
            in_vec=inray.get_norm_vec;
            
            %% Calculate theta_in, the angle of incidence of the inray (relative to local normal)
            theta_in(1)=acosd(dot(-in_vec,norm_vec));
            theta_in(2)=acosd(dot(in_vec,norm_vec));
            cp=cross([in_vec; 0],[norm_vec; 0]); % to get sign for theta
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
            if acosd(dot([1;0],in_vec))<90
                norm_vec = -norm_vec;
            end
            norm_deg = atan2d(norm_vec(2),norm_vec(1));
            
            %% Differentiate the stemray into a reflex_ray
            reflex_ray = O.stem_to_reflex_ray(copy(stemray),norm_deg,theta_in);
            
            %% Differentiate the stemray into a refrax_ray
            refrax_ray = O.stem_to_refrax_ray(stemray,norm_deg,theta_in);
 
        end
    end
        
    %% set/get methods
    methods
        function set.depth(O,val)
            arguments, O, val (1,1) double {mustBeNonnegative}, end
            O.depth=val;
        end
        function set.R(O,val)
            arguments, O, val (1,1) double, end
            O.R=val;
        end
    end
    
end