classdef Navarro < mb.body.Body
    
    % Navarro et al 1985 model,  p. 255-6 Atchison & Smith 2002. I double
    % checked these values with those in Tables 4 & 5 of the original 1985
    % paper. All correct. With optional iris (ommited if pupil_diam<0)
    
    properties
        pupil_x=-3.5
        pupil_diam=4
        pupil_offset=0
        accommodation=0
    end
    
    properties (Constant)
    %    note="This model uses a refractive index of 1.3771 instead of the 1.367 given in the 1985 paper";
    end
    
    properties (SetAccess=private,GetAccess=public)
    end
    
    properties (Dependent)
    end
    
    methods (Access=public)
        function O=Navarro(varargin)
            O.apply_name_value_pairs(O,varargin);
            O.set_boundaries;         
        end
    end
    
    methods (Access=private)       
        function set_boundaries(O)
            % Navarro et al 1985 model,  p. 255-6 Atchison & Smith 2002. I double
            % checked these values with those in Tables 4 & 5 of the original 1985
            % paper. All correct.
            
            R3 = 10.2 - 1.7500 * log(O.accommodation+1);
            R4 = -6.0 + 0.2294 * log(O.accommodation+1);
            d2 = 3.05 - 0.0500 * log(O.accommodation+1);
            d3 = 4.00 + 0.1000 * log(O.accommodation+1);
            n3 = 1.42 + 9e-5 * (10*O.accommodation + O.accommodation^2);
            Q3 = -3.1316 - 0.34 * log(O.accommodation+1);
            Q4 = -1.0 - 0.125 * log(O.accommodation+1);
            O.boundaries={};
            O.add_boundary('Conic',"anterior_cornea",'media',["air" "cornea"],'n1n2',[1.0000 1.3771],'r1r2',[1 0],'x',0,'Q',-0.26,'R',7.72,'depth',3.75); % 1.367 1.3771
            O.add_boundary('Conic',"posterior_cornea",'media',["cornea" "aqueous"],'n1n2',[1.3771 1.3374],'r1r2',[1 0],'x',-0.55,'Q',0,'R',6.5,'depth',3);
            O.add_boundary('Conic',"anterior_lens",'media',["aqueous" "lens"],'n1n2',[1.3374 n3],'r1r2',[1 0],'x',-0.55-d2,'Q',Q3,'R',R3,'depth',1.8);
            O.add_boundary('Conic',"posterior_lens",'media',["lens" "vitreous"],'n1n2',[n3 1.3360],'r1r2',[1 0],'x',-0.55-d2-d3,'Q',Q4,'R',R4,'depth',3);
            O.add_boundary('Arc',"retina",'media',["vitreous" "sclera"],'n1n2',[1.3360 0.0000],'r1r2',[0 0],'x',-0.55-d2-d3-16.40398+12,'radius',12,'arc_delta',180,'span',270);
            O.add_boundary('Arc',"sclera",'media',["sclera" "air"],'n1n2',[0.0000 1.0000],'r1r2',[0 0],'x',-0.55-d2-d3-16.40398+12,'radius',12.5,'arc_delta',180,'span',270);
            
            % Add an iris, or not if O.pupil_diam<0
            if O.pupil_diam>=0
                iris_diam = 18;
                ccw_len = iris_diam/2 - O.pupil_diam/2 - O.pupil_offset;
                ccw_mid = iris_diam/2 - ccw_len/2;
                cw_len = iris_diam/2 - O.pupil_diam/2 + O.pupil_offset;
                cw_mid = -iris_diam/2 + cw_len/2;
                O.add_boundary('Line',"iris_ccw",'media',["*" "*"],'n1n2',[0 eps],'r1r2',[0 0],'length',ccw_len,'x',O.pupil_x,'y',ccw_mid,'ori',0);
                O.add_boundary('Line',"iris_cw",'media',["*" "*"],'n1n2',[0 eps],'r1r2',[0 0],'length',cw_len,'x',O.pupil_x,'y',cw_mid,'ori',0);
            end
            
            % Apply the body's orientation to the boundaries
            cellfun(@(x)x.rotate(O.orientation,[O.xpos O.ypos]),struct2cell(O.boundaries));
        end
    end
    
    methods
        function set.accommodation(O,val)
             if ~isnumeric(val) || ~isscalar(val) || val<0
                 error('accommodation must be a scalar equal to or larger than 0');
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
