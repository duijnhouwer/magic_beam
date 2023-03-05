
% Visible - Base class that can be loaded in addition to mb.base.Base to add properties needed for
% objects that can be displayed: boundaries, bodies, lights, and ray. But not scene.

classdef (Abstract) Visible < matlab.mixin.SetGet
 
    properties (Access=public,SetObservable=true)
        xpos=0 % Horizontal position of center. [0]
        ypos=0 % Vertical position of center. [0]
        orientation=0 % Orientation-angle of nominal front of element. [0]
        pivot_x=0; % Rotation point relative to [xpos ypos]
        pivot_y=0; % Rotation point relative to [xpos ypos]
        linestyle='-'
        linewidth=1
        markersize=12
        color=[0 0 0 1]
    end
    
    properties (Access=public)
        UserData=[]
    end
    
    methods (Abstract)
        show(O)
    end
    
    %% Set/Get methods
    methods
        function set.xpos(O,val)
            if ~isnumeric(val) || ~isscalar(val) || isempty(val)
                error('val must be a non-empty numeric scalar');
            end
            O.xpos=val;
        end
        function set.ypos(O,val)
            if ~isnumeric(val) || ~isscalar(val) || isempty(val)
                error('val must be a non-empty numeric scalar');
            end
            O.ypos=val;
        end
        function set.pivot_x(O,val)
             if ~isnumeric(val) || ~isscalar(val) || isempty(val)
                error('val must be a non-empty numeric scalar');
            end
            O.pivot_x=val;
        end
        function set.pivot_y(O,val)
             if ~isnumeric(val) || ~isscalar(val) || isempty(val)
                error('val must be a non-empty numeric scalar');
            end
            O.pivot_y=val;
        end
        function set.orientation(O,val)
            O.orientation=val;
        end
        function set.color(O,val)
            O.color=[];
            illegal=false;
            if ischar(val) || isstring(val)
                O.color = [O.wrgbcmyk_to_rgb(val) 1];
            elseif isnumeric(val) && numel(val)==3
                O.color = [val(:)' 1];
            elseif isnumeric(val) && numel(val)==4
                O.color = val(:)';
            else
                illegal=true;
            end
            illegal = illegal || any([O.color<0 O.color>1]);
            if illegal
                error('Illegal color format, should be one letter from ''wrgbcmyk'' or a 3 or 4 number vector with values between 0 and 1');
            end
        end
    end
end