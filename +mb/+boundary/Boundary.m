classdef (Abstract) Boundary < mb.base.Base & mb.base.Visible 
    
    properties
        media=["air" "water"] % Media on either side of the boundary. ["air" "water"]
        n1n2=[1 1.333] % Refraction indices corresponding to the media. [1 1.333]
        r1r2=[1 0] % Reflection coeffients corresponding to media transition. [1 0]
        nvpmm=10 % Number of vertices to plot per millimeter of interace surface. Only affects plotting, not the ray-tracing itself. [10]
        zlayer=0; % Objects with higher zlayer will be drawn on top in plots, -1 is the bottom, 1 is the top
    end
    
    properties (Access=protected)
        body_xpos; % Keep track of the ...
        body_ypos; % position parameters 
        body_orientation;
    end
           
    methods (Access=public)
        %% Rotate the boundary around an arbitrary pivot point
        function rotate(O,angle,pivot_xy)
            arguments
                O, angle (1,1) double, pivot_xy (1,2) double
            end
            % Rotate the boundary around an arbitrary pivot point.
            O.orientation=O.orientation+angle;
            R = [cosd(angle) -sind(angle); sind(angle) cosd(angle)];
            rotated_xy =  R*transpose([O.xpos O.ypos]-pivot_xy);
            O.xpos = rotated_xy(1)+pivot_xy(1);
            O.ypos = rotated_xy(2)+pivot_xy(2);
        end
    end
    
    methods
        %% Destructor
        function delete(O)
            O.delete();
        end
    end
    
    methods (Abstract)
        [hitbool, reflex_ray, refrax_ray]=reflect_and_refract(O,inray)
        [xy]=get_vertices(O)
    end
    
    methods (Access=protected) % protected - Access from methods in class or subclasses
        
        function add_body_listeners(O,body)
            % Add listeners to the body's property change event. The corresponding values of the
            % boundary should change upon their change.
            % First, the position parameters
            addlistener(body,'xpos','PostSet',@O.body_prop_change);
            addlistener(body,'ypos','PostSet',@O.body_prop_change);
            addlistener(body,'orientation','PostSet',@O.body_prop_change);
            O.body_xpos=body.xpos;
            O.body_ypos=body.ypos;
            O.body_orientation=body.orientation;
            % Secondly add listeners to all other observable properties of the body
            mc=metaclass(body);
            propnames={mc.PropertyList.Name}; % all observable properties of body ...
            propnames=setdiff(propnames([mc.PropertyList.SetObservable]),{'xpos','ypos','orientation'}); % ... minus the position properties
            for propname=string(propnames)
                addlistener(body,propname,'PostSet',@O.body_prop_change);
            end
        end
        
        function body_prop_change(O,src,evt)
            % Propagate property changes of the body that contains this boundary to this boundary
            switch src.Name
                case 'xpos'
                    delta=evt.AffectedObject.xpos - O.body_xpos;
                    O.xpos=O.xpos+delta;
                    O.body_xpos=evt.AffectedObject.xpos;
                case 'ypos'
                    delta=evt.AffectedObject.ypos - O.body_ypos;
                    O.ypos=O.ypos+delta;
                    O.body_ypos=evt.AffectedObject.ypos;
                case 'orientation'
                    delta=evt.AffectedObject.orientation - O.body_orientation;
                    O.rotate(delta,[evt.AffectedObject.xpos evt.AffectedObject.ypos]+[evt.AffectedObject.pivot_x evt.AffectedObject.pivot_y]);
                    O.body_orientation=evt.AffectedObject.orientation;
                otherwise % e.g. linestyle, color
                    O.(src.Name)=evt.AffectedObject.(src.Name);  % simply copy
            end
        end
        
        %% Differentiate the stemray into a reflex_ray
        function reflex_ray = stem_to_reflex_ray(O,reflex_ray,norm_deg,in_deg)
            arguments
                O, reflex_ray (1,1) mb.Ray, norm_deg (1,1) double, in_deg (1,1) double
            end
            
            % Note: the reflex_ray will be changed, so pass a copy of stemray in case you need it
            % later (for example, to call stem_to_refrax_ray on it). I used to simply call input
            % Arg2 "stem_ray" and always make a copy here, but this way we can save the copy call
            % in the stem_to_refrax_ray call.

            %% The side of the boundary ray will hit corresponds to the medium the ray
            % is currently in. Use this to grab the appropriate reflectivity from r1r2
            if mb.settings('reflex')
                reflex_ray.type='reflex';
                reflex_ray.id=mb.library.Misc.unique_id; % give new object a unique ID
                reflex_ray.orientation=norm_deg-in_deg; % because angle in and out are symmetric on norm_vec
                reflex_ray.intensity=reflex_ray.intensity*O.r1r2(O.media==reflex_ray.medium);
            else
                reflex_ray.type='stub';
                reflex_ray.id=mb.library.Misc.unique_id; % give new object a unique ID
                reflex_ray.intensity=0;
            end
        end
        
        %% Differentiate the stemray into a refrax_ray
        function refrax_ray = stem_to_refrax_ray(O,refrax_ray,norm_deg,in_deg)
            arguments
                O, refrax_ray (1,1) mb.Ray, norm_deg (1,1) double, in_deg (1,1) double
            end
  
            % See note in stem_to_reflex_ray about when or why to make sure to pass copy(stemray) as the input arg2 (refrax_ray)
            
            refrax_ray.type='refrax';
            refrax_ray.id=mb.library.Misc.unique_id; % give new object a unique ID
            
            %% A refraction coefficient of zero is code for no-refraction. Check now if this is the case
            if any(O.n1n2==0) || ~mb.settings('refract')
                refrax_ray.intensity=0;
                return
            end
            
            %% Apply Snell's law
            % Decide which medium we are exiting and which we are entering. Use this to
            % dicide which is n1 and which is n2 in applying Snell's law,  n1*sind(theta1) = n2*sind(theta2)
            if ~any(O.media==refrax_ray.medium)
                error('<CODING_MISTAKE> The ray is not in any of the two media of the boundary. This should have been checked before getting to this function');
            end
            n1=O.n1n2(O.media==refrax_ray.medium);
            n2=O.n1n2(O.media~=refrax_ray.medium);
            theta2=asind(n1*sind(in_deg)/n2);  
            if ~isreal(theta2)
                % When n1>n2 there exists a critical angle at which snell's law breaks down, or at
                % least produces imaginary numbers. In nature what happens beyond this critical
                % angle is that all lights gets refracted. Therefore, now that we detected that
                % theta2 is imaginary, set the intensity of the refraction ray to 0.
                % See: https://www.livephysics.com/tools/optics-tools/find-critical-angle/
                refrax_ray.intensity=0;
            else
                refrax_ray.orientation = theta2+norm_deg+180;
                refrax_ray.length = Inf;
                refrax_ray.medium = O.media(O.media~=refrax_ray.medium); % Update ray's medium
            end
        end
    end
    
    
    %% set/get methods
    methods
        function set.nvpmm(O,val)
            arguments, O, val (1,1) double {mustBeNonnegative}, end
            O.nvpmm=val;
        end
        function set.media(O,val)
            arguments, O, val (1,2) string, end
            O.media=val;
        end
        function set.n1n2(O,val)
            arguments, O, val (1,2) double, end
            if val(1)==val(2)
                error('Refraction indices can''t be the same on either side of the boundary. There can only be a boundary iff they are different.');
            end
            O.n1n2=val;
        end
        function set.r1r2(O,val)
            arguments, O, val (1,2) double, end
            O.r1r2=max(0,min(1,val));
        end
    end
end