classdef Rect < mb.body.Body
    
    properties
        height=10;
        width=10;
        media=["crownglass" "air"]
        n1n2=[1.517 1.000]
        r1r2=[1 1]
    end
    
    methods (Access=public)
        function O=Rect(varargin)
            O.apply_name_value_pairs(O,varargin);   
            O.set_boundaries;
        end
    end
    methods (Hidden)
        function set_boundaries(O)
            O.boundaries={};
            old_orientation=O.orientation;
            O.orientation=0;
            common={'media',O.media,'n1n2',O.n1n2,'r1r2',O.r1r2}; % properties shared by all boundaries
            O.add_boundary('Line','fore','x',O.xpos+O.width/2,'y',O.ypos,'ori',0,'length',O.height,common{:});
            O.add_boundary('Line','aft','x',O.xpos-O.width/2,'y',O.ypos,'ori',180,'length',O.height,common{:});
            O.add_boundary('Line','port','x',O.xpos,'y',O.ypos+O.height/2,'ori',90,'length',O.width,common{:});
            O.add_boundary('Line','starboard','x',O.xpos,'y',O.ypos-O.height/2,'ori',-90,'length',O.width,common{:});
            O.orientation=old_orientation;
        end
    end
    methods
        % TODO 666: add checks of val
        function set.height(O,val)
            O.height=val;
            O.set_boundaries;
        end
        function set.width(O,val)
            O.width=val;
            O.set_boundaries;
        end
         function set.media(O,val)
            O.media=val;
            O.set_boundaries;
        end
        function set.n1n2(O,val)
            O.n1n2=val;
            O.set_boundaries;
        end
        function set.r1r2(O,val)
            O.r1r2=val;
            O.set_boundaries;
        end
    end
end
