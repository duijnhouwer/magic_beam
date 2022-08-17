classdef (Abstract) Math < handle
    
    % Library of mathematical support functions for Magic Beam
    %
    % This is similar to having a subfolder with help functions, but i think
    % it's neater to have all these functions bundled into one file as static
    % methods (method is object-oriented equivalent of a function)
    %
    % methods(mb.lib) prints a list of all methods
    %
    % help mb.library.Math.NAMEOFMETHOD displays the help of method
    %
    % Examples:
    %   [x,y] = mb.library.Math.ellipse_line_intersect(2,1,0.1,0.1,180/4,1,0)
    %   help mb.library.Math.ellipse_line_intersect
    %
    % See also: mb.library.Misc, mb.library.Analysis
    
    % Jacob Duijnhouwer 2021-01-22
    
    methods (Static)
        
        function R=rotmat(angle_deg)
            %% Create a 2D rotation matrix
            narginchk(1,1)
            R = [cosd(angle_deg) -sind(angle_deg); sind(angle_deg) cosd(angle_deg)];
        end
        
        function [x,y] = ellipse_line_intersect(a,b,h,k,ccw_deg,mbar,cbar)
            %% ellipse_line_intersect - Find the 0, 1, or 2 intersections of a line and an ellipse
            %
            % [x,y] = ellipse_line_intersect(a,b,h,k,ccw_deg,mbar,cbar)
            %
            % Arguments:
            %   a: the length of the primary axis of the ellipse
            %   b: the length of its secondary axis of the ellipse
            %   h: the horizontal coordinate of its center
            %   k: the vertical coordinate of its center
            %   ccw_deg: the orientation of the ellipse in degrees
            %       (>0=counterclockwise)
            %   mbar: the slope of the line (*)
            %   cbar: the y-intercept of the line (*)
            %
            %   (*) If mbar is infinite, the line is vertical and cbar represents the
            %   x-intercept of the line. This is a special case
            %
            % Two points are returned. These points are identical when the line only
            % touches the ellipses.  When the line and ellipse do not intersect, NaNs
            % are returned.
            %
            %   Example:
            %       [x,y]=mb.library.Math.ellipse_line_intersect(2,1,0.1,0.1,180/4,1,0)
            %       x = 1.5142   -1.3142
            %       y = 1.5142   -1.3142
            %
            % See also: linecirc, mb.library.Math.conic_line_intersect

            % Jacob Duijnhouwer 2021-01-22
            
            narginchk(7,7)
            
            % An ellipse is symmetric in its b-axis so it has unique orientations only
            % between 0 and 180 degrees. Limit ccw_deg to this range. It will make
            % checking for special cases easier later on
            ccw_deg = mod(ccw_deg,180);
            
            
            %% Detect if this is a special case where the line is vertical.
            % cbar will represent the X-intercept of this vertical line
            vertical_line = isinf(mbar);
            if vertical_line
                % rotate everything by 90 degrees and solve as if line is horizontal
                Rv=[0 -1; 1 0]; % [cosd(90) -sind(90); sind(90) cosd(90)];
                mbar=0;
                tmp=a;
                a=b;
                b=tmp;
                hk=Rv*[h;k];
                h=hk(1);
                k=hk(2);
            end
            
            %% Get two arbitrary points on the line
            % We rotate these points with the slope of the ellipse so from now on we
            % can consider the ellipse a standard ellipse without rotation, that is,
            % with its a-axis parallel to the x-axis and its b-axis parallel to the
            % y-axis. This make the math for finding the intersection a lot easier! At
            % the end the intersections will be rotated back to give the solution for
            % ellipse with rotation.
            
            minx = h-1.5*max(a,b);
            maxx = h+1.5*max(a,b);
            miny = k-1.5*max(a,b);
            maxy = k+1.5*max(a,b);
            if mbar==0
                pt1 = [minx;cbar];
                pt2 = [maxx;cbar];
            else
                pt1 = [(miny-cbar)/mbar; miny];
                pt2 = [(maxy-cbar)/mbar; maxy];
            end
            
            %% Create the 2D-rotation matrix to rotate the points on the line with
            R=[cosd(ccw_deg) -sind(ccw_deg); sind(ccw_deg) cosd(ccw_deg)];
            
            %% Find the intersections. There are two distinct scenarios here:
            % 1: The line is vertical after rotation (can't be described with slope/offset)
            % 2: The line is not vertical after rotation, and slope/offset is fine
            
            if ccw_deg>0 && mod(atand(mbar)+ccw_deg, 180)==0 % The line is vertical after rotation
                % The line has a slope such that it will be perfectly vertical after being
                % rotated with by ccw_deg>0. This means that after rotating the ellipse to
                % become a standard ellipse (i.e., with its a-axis horizontal) that the
                % line would be vertical. This causes bizarro numerical problems for the
                % standard calculation. Treat cases as like these as special case here:
                dx = -mb.library.Math.point_line_distance([h;k],pt1,pt2);
                if mbar*h+cbar>0 % is the line above the ellipse-center?
                    dx=-dx;
                end
                xy(1,:)=[dx dx];
                xy(2,1)=sqrt(1-(dx^2/a^2))*b;
                xy(2,2)=-xy(2,1);
            else % The line is not vertical after rotation
                % Subtract the center coordinates of the ellipse from the line points, then
                % rotate them. The point being that we find the intersection of the line
                % with a standard ellipse that only has a and b parameters, not h,k, nor
                % rotation. We will apply rotation and h,k to the solution at the end
                pt1 = pt1-[h;k];
                pt2 = pt2-[h;k];
                pt1 = R\pt1;
                pt2 = R\pt2;
                
                % calculate m and c of the adjusted line
                m = (pt1(2)-pt2(2)) / (pt1(1)-pt2(1));
                c = pt1(2) - m * pt1(1);
                
                % Calculate the x-values of the intersections using math found here:
                % http://www.ambrsoft.com/TrigoCalc/Circles2/Ellipse/EllipseLine.htm
                xy(1,1) = (-a^2*m*c + a*b*sqrt(a^2*m^2+b^2-c^2)) / (b^2+a^2*m^2 );
                xy(1,2) = (-a^2*m*c - a*b*sqrt(a^2*m^2+b^2-c^2)) / (b^2+a^2*m^2 );
                
                % Find the corresponding y-values by pluging the x-values into the line equation
                xy(2,1) = m*xy(1,1)+c;
                xy(2,2) = m*xy(1,2)+c;
            end
            
            %% Re-apply the rotation and offset
            if vertical_line
                xy = R*inv(Rv)*xy + inv(Rv)*[h;k];
            else
                xy = R*xy + [h;k];
            end
            
            %% When the line has less than 2 intersections, the missing intersection
            % coordinates will have non-zero imaginary parts.
            % Detect those here and label them NaN
            xy(:,any(imag(xy)~=0,1))=nan;
            
            %% Make the output consistent with Matlab-native linecirc
            x=xy(1,:);
            y=xy(2,:);
        end
        
        function [ipts,normvecs,conic,line] = conic_line_intersect(Q,R,h,k,m,c)
            
            %conic_line_intersect(Q,R,h,k,m,c)
            %
            % Find the 0, 1, or 2 intersections of a line of the form:
            %
            %   y = m*x + c
            %
            % with a conic section of the form:
            %
            %   y^2 + (1+Q)*x^2 - 2*-R*x == 0
            %
            % Note: I have flipped the sign of R relative to the conic equation used in
            % Atchison & Smith 2002 (eq 2.4, p 13) so that an conic section with
            % orientation zero has it's convex apex pointing to the right (as was the
            % convention is earlier eye models that did not use conics).
            %
            % ipts = conic_line_intersect(Q,R,h,k,m,c) return the intersection(s) where
            % ipts is a 2xN matrix where the top row are x-coordinates and the bottom
            % row are y-coordinates for N intersections.
            %
            % [ipts,normvecs] = conic_line_intersect(_) in addition returns the
            % corresponding normal vectors
            %
            % [ipts,normvecs,conic,line] = conic_line_intersect(_) in addition returns
            % the symbolic represenations of the conic and line equations for easy
            % plotting using fimplicit([conic line]). This requires Matlab's Symbolic
            % Math toolbox.
            
            
            narginchk(6,6)
            
            % Line equation:
            %       y = m*x + c
            %
            % Conic equation:
            %       (y-k)^2 + (1+Q) * (x-h)^2 - (2*-R)*(x-h) == 0
            %
            % Notice here we use negative R, as opposed to Hutchison & Smith 2002. This
            % has a consequence that the rightmost tip of circular, elliptical,
            % parabolic conics is at (h,k) instead of left-most apex.
            %
            % For clarity define a=(1+Q) and b=(2*-R) and substitute:
            %       (y-k)^2 + a * (x-h)^2 - b*(x-h) == 0
            %
            % Rewrite to isolate y:
            %       y = sqrt( -a*(x-h)^2 + b*(x-h) ) + k
            %
            % Intersection is where line and conic are identical:
            %
            %   sqrt( -a*(x-h)^2 + b*(x-h) ) + k = m*x + c
            %
            % Solving for this for x will give us the x-coordinates of the
            % intersections. However, it turned out the math is better when we shift
            % the the line instead of the conic. So rewrite as if the conic is based on
            % the origin (0,0) instead of (h,k), and shift the line so as to keep the relation
            % between the line and the conic the same. At the end of this function, h
            % and k will be added to the x and y coordinates of the intersections.
            %
            %       sqrt( -a*x^2 + b*x) = m*(x+h) + c - k
            %
            % Solving this using wolframalpha.com like this:
            %       "solve sqrt( -a*x^2 + b*x) = m*(x+h) + c - k  for x"
            % https://www.wolframalpha.com/input/?i=solve+sqrt%28+-a*%28x-h%29%5E2+%2B+b*%28x-h%29+%29+%2B+k+%3D+m*x+%2B+c+for+x%3A
            % Gives the following solutions of x:
            
            a=(1+Q);
            b=(2*-R);
            
            if a==0 && m==0
                x1 = (c^2 - 2*c*k + k^2)/b; % (b*h + c^2 - 2*c*k + k^2)/b;
                x2 = 1i; % label as imaginary so it will be deleted
            else 
                x1 = ( -sqrt( -4*a*c^2 - 8*a*c*h*m + 8*a*c*k - 4*a*h^2*m^2 + 8*a*h*k*m - 4*a*k^2 + b^2 - 4*b*c*m - 4*b*h*m^2 + 4*b*k*m) + b - 2*c*m - 2*h*m^2 + 2*k*m)/(2*(a + m^2));
                x2 = (  sqrt( -4*a*c^2 - 8*a*c*h*m + 8*a*c*k - 4*a*h^2*m^2 + 8*a*h*k*m - 4*a*k^2 + b^2 - 4*b*c*m - 4*b*h*m^2 + 4*b*k*m) + b - 2*c*m - 2*h*m^2 + 2*k*m)/(2*(a + m^2));
            end
            % Put x1 and x2 in a single array. Note that assingning the solutions to
            % x(1) = ... and x(2) = ... right away somehow causes an error (*) when
            % this function is called within a parfor-loop. I have no idea why that
            % would be, running it in regular for-loop goes fine that way. No matter,
            % assigning them the x1 and x2 and the combining as  x=[x1 x2]; solved the
            % issue.
            % (*) Unable to perform assignment because the indices on the left side are not compatible with the size of the right side
            x=[x1 x2];
            
            % Remove solutions that are imaginary numbers
            x=x(imag(x)==0);
            
            % If the were all imaginary the line and the conic did not intersect.
            % Return empty solutions
            if isempty(x)
                ipts = [];
                normvecs=[];
                return
            end
            
            % Fill out the solutions of for x in the (shifted) line equation to get the
            % corresponding y-coordinates
            for i=1:numel(x)
                y(i) = m*(x(i)+h) + c - k; %#ok<AGROW>
            end
            
            % If the normals are requested ...
            if nargout>1
                % differentiate  y = sqrt( -a*x^2 + b*x )
                % https://www.wolframalpha.com/input/?i=differentiate++y+%3D+sqrt%28+-a*x%5E2+%2B+b*x+%29+%2B+k
                %       --> y'(x) = (b/2 - a x)/sqrt(-x (a x - b))
                %
                % Now calculate the slope at the 1 or 2 intersections
                normvecs=nan(2,length(x));
                for i=1:numel(x)
                    if y(i)==0
                        normvecs(:,i) = [1; 0];
                        continue;
                    end
                    slope = (b/2 - a*x(i))/sqrt(-x(i)*(a*x(i) - b));
                    if y(i)<0
                        slope = -slope;
                    end
                    if slope==0
                        normvecs(:,i) = [1; 0];
                    else
                        normvecs(:,i) = [1; -1/slope]./norm([1; -1/slope]);
                    end
                end
            end
            
            % Convert the intersection points to double matrix, first row Xs, second
            % row Ys. And add the offset h and k back into the solutions. (The normal
            % vectors are independent of h and k so they're fine already.)
            ipts=[x(:)'; y(:)'] + [h;k];           
            
            % Finally, if the output arguments conic is requested, create the symbolic
            % represenations of the conic and line equations for easy plotting using
            % fimplicit(conic) and fimplicit(line);
            if nargout>2
                syms x y
                conic = (y-k)^2 + (1+Q) * (x-h)^2 - 2*-R*(x-h) == 0;
                line = y == m*x + c;
                % S = solve([conic,line],[x y],'Real',true); % does the same thing as this function but is very slow
            end
        end
        
        function dist=point_line_distance(p, v1, v2)
            %% point_line_distance - Calculate distance of point(s) from line in 2D and 3D
            % dist=point_line_distance(p, v1, v2), where p, v1, and v2 are 2 or 3 element vectors
            % representing
            %   p: the point, or points
            %   v1: one point on the line
            %   v2: another point on line
            %
            % Jacob Duijnhouwer 2020-02-12, based on code from Rik Wisselink
            
            narginchk(3,3);
            if ~all(cellfun(@isnumeric,{p,v1,v2}))
                error('All three arguments must be numeric');
            end
            if all(v1==v2)
                error('v1 and v2 are identical, line undefined');
            end
            % force row vectors
            p=p(:)';
            v1=v1(:)';
            v2=v2(:)';
            if all(cellfun(@numel,{p,v1,v2})==2)
                p=[p 0];
                v1=[v1 0];
                v2=[v2 0];
            elseif ~all(cellfun(@numel,{p,v1,v2})==3)
                error('The input vectors must all be 2D or all be 3D');
            end
            
            dist=norm(cross(v1-v2,p-v2))/norm(v1-v2);
        end
        
        function [L,full_ellipse_L] = ellipse_arc_length(a,b,t1,t2,precission)
            %% ellipse_arc_length - Approximate the arc length of an ellipse
            %
            % Using the ellipse equation:
            %
            %     x(t) = a * cos(t)
            %     y(t) = b * sin(t)
            %
            % L = ellipse_arc_length(a,b,t1,t2) calculates the minimal, signed arc
            % length between angles t1 and t2 (in DEGREES). t1 is the reference,
            % meaning that if the t2 lies clockwise from t1, the arclength will be
            % negative.
            %
            % The ellipse arc length is computed numerically by dividing the arc in
            % small straight segments. The precission of this approximation is governed
            % by optional 5th argument (default 1e5). Larger numbers give more
            % precission but are costlier to calculate.
            %
            % The arlength L will be between plus-and-minus half the perimeter of the
            % full ellipse.
            %
            % Examples:
            %   >> ellipse_arc_length(1,1,0,90)/2/pi % quarter circle
            %       0.2500
            %   >> ellipse_arc_length(1,1,0,-90)/2/pi % the output is signed!
            %       -0.2500
            %   >> ellipse_arc_length(1,1,0,360)/2/pi
            %       0
            %   >> ellipse_arc_length(1,1,0,90)/2/pi*4 % full ellipse perimeter
            %       1
            %   >> ellipse_arc_length(1,1,-45,45)/2/pi
            %       0.2500
            %   >> ellipse_arc_length(1,1,45,-45)/2/pi
            %       -0.2500
            %   >> ellipse_arc_length(1,1,135,-135)/2/pi
            %       0.2500
            %   >> ellipse_arc_length(1,1,-135,135)/2/pi
            %       -0.2500
            
            %   Based on code by Luc Masset: https://www.mathworks.com/matlabcentral/fileexchange/26819-ellipse-arc-length
            
            %arguments
            narginchk(4,5);
            
            % Express t1 and t2 between -180 and 180
            t1 = mod(t1+180,360)-180;
            t2 = mod(t2+180,360)-180;
            
            % Check for trivial t1==t2 case
            if t1==t2
                L=0;
                return
            end
            
            % Check for trivial a==b case (circle)
            if a==b
                % Determine the absolute, minimal distance over the arc
                full_ellipse_L = 2*pi*abs(a);
                L=abs(full_ellipse_L/360*(t1-t2));
                if L>full_ellipse_L/2
                    L=full_ellipse_L-L;
                end
            else % (ellipse)
                % Use default precission if not provided
                if nargin==4
                    precission=1e5;
                end                
                % Determine the absolute, minimal distance over the arc
                L=abs(calc_L(a,b,t1,t2,precission));
                full_ellipse_L=abs(calc_L(a,b,0,90,precission)*4);
                if L>full_ellipse_L/2
                    L=full_ellipse_L-L;
                end
            end
            
            % Determine the sign of the angle (clockwise is negative)
            the_sign = sign(mb.library.Math.vec_signed_deg([cosd(t1);sind(t1)],[cosd(t2);sind(t2)]));
            % Combine sign and absolute value
            L=the_sign*L;
            
            function L=calc_L(a,b,t1,t2,precission)
                tt=t1:(t2-t1)/precission:t2;
                xx=a*cosd(tt);
                yy=b*sind(tt);
                dx=diff(xx);
                dy=diff(yy);
                L=sum(hypot(dx,dy));
            end
        end
        
        function theta  = vec_signed_deg(a,b)
            %% vec_signed_deg - return signed angle between 2D-vectors in degrees
            % theta  = vec_signed_deg(a,b), where
            %
            % a is a 2x1 or a 2xN matrix (columns represent 2D-vectors)
            % b is a 2x1 or a 2xN matrix (columns represent 2D-vectors)
            
            narginchk(2,2);
            if size(a,1)~=2 || size(b,1)~=2
                error('a and b must have 2 rows (for x and y)');
            end
            
            if size(a,2)~=size(b,2)
                if size(a,2)==1
                    a = repmat(a,1,size(b,2));
                elseif size(b,2)==1
                    b = repmat(b,1,size(a,2));
                else
                    error('Number of vectors in a and b must both be N, or one can be N and the other 1');
                end
            end
            d1 = dot(a,b);
            d2 = dot([0 -1; 1 0]*a,b);
            theta = atan2d(d2,d1);
        end
        
        function [midori,delta1,delta2] = angular_extent(eye_xy,pt1_xy,pt2_xy)
            %[midori,delta1,delta2] = angular_extent(eye_xy,pt1_xy,pt2_xy)
            % Input:
            %   eye_xy: coordinates of viewpoint
            %   pt1_xy: coordinates of point 1
            %   pt2_xy: coordinates of point 2
            % Output:
            %   midori: the angle of the line connecting eye to the point midway pt1 and pt2
            %   delta1: the angle between the mid line and point 1
            %   delta2: the angle between the mid line and point 2
            arguments
                eye_xy (2,1) double
                pt1_xy (2,1) double
                pt2_xy (2,1) double
            end
            % Convert to vectors (don't need to be normalized)
            vec1 = pt1_xy-eye_xy;
            vec2 = pt2_xy-eye_xy;
            vec_mid = (pt1_xy+pt2_xy)/2-eye_xy;
            % Calculate the angle of the line connecting eye to the midpoint
            midori = atan2d(vec_mid(2),vec_mid(1));
            % Calculate the angle between the mid line and the two points
            delta1 = mb.library.Math.vec_signed_deg(vec_mid,vec1);
            delta2 = mb.library.Math.vec_signed_deg(vec_mid,vec2);
        end
        
    end
end
