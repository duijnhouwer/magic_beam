classdef Arizona < mb.body.Body
    
    properties
        pupil_x=-3.5 % Pupil location relative to cornea apex in mm [-3.5]
        pupil_diam=4 % Pupil diameter in mm [4]
        pupil_offset=0 % Pupil shift relative to optical axis in mm [0]
        accommodation=0 % Accommodation of eye in diopters [0]
    end
    
    properties (SetAccess=private,GetAccess=public)
    end
    
    properties (Dependent)
    end
    
    methods (Access=public)
        function O=Arizona(varargin)
            O.apply_name_value_pairs(O,varargin);
            O.set_boundaries;
        end
    end
    
    methods (Access=private)
        function set_boundaries(O)
            % Below values are from page 16 of the following book (PDF in mb/resources):
            % Field Guide to Visual and Ophthalmic Optics (2004) Jim Schwiegerling
            
            A=O.accommodation;
            Rant = 12.0-0.4*A;
            Rpost = -5.224557 + 0.2*A;
            taq = 2.97-0.04*A;
            nlens = 1.42+0.00256*A-0.00022*A^2;
            Qant = -7.518749 + 1.285720*A;
            Qpost = -1.353971 - 0.431762*A;
            tlens = 3.767 + 0.04*A;
            
            
            O.boundaries={};
            O.add_boundary('Conic',"anterior_cornea",'media',["air" "cornea"],'n1n2',[1.000 1.377],'r1r2',[1 0],'x',0,'Q',-0.25,'R',7.8,'depth',3.75);
            O.add_boundary('Conic',"posterior_cornea",'media',["cornea" "aqueous"],'n1n2',[1.377 1.337],'r1r2',[1 0],'x',-0.55,'Q',-0.25,'R',6.5,'depth',3);
            O.add_boundary('Conic',"anterior_lens",'media',["aqueous" "lens"],'n1n2',[1.337 nlens],'r1r2',[1 0],'x',-0.55-taq,'Q',Qant,'R',Rant,'depth',1.5);
            O.add_boundary('Conic',"posterior_lens",'media',["lens" "vitreous"],'n1n2',[nlens 1.3360],'r1r2',[1 0],'x',-0.55-taq-tlens,'Q',Qpost,'R',Rpost,'depth',3);
            O.add_boundary('Arc',"retina",'media',["vitreous" "sclera"],'n1n2',[1.336 0.000],'r1r2',[0 0],'x',-0.55-taq-tlens-16.713+13.4,'radius',13.4,'arc_delta',180,'span',245);
            O.add_boundary('Arc',"sclera",'media',["sclera" "air"],'n1n2',[0.000 1.000],'r1r2',[0 0],'x',-0.55-taq-tlens-16.713+13.4,'radius',13.9,'arc_delta',180,'span',245);
            
            % Add an iris
            if O.pupil_diam>=0
                iris_diam = 24;
                ccw_len = iris_diam/2 - O.pupil_diam/2 - O.pupil_offset;
                ccw_mid = iris_diam/2 - ccw_len/2;
                cw_len = iris_diam/2 - O.pupil_diam/2 + O.pupil_offset;
                cw_mid = -iris_diam/2 + cw_len/2;
                O.add_boundary('Line',"iris_ccw",'media',["*" "*"],'n1n2',[0 eps],'r1r2',[0 0],'length',ccw_len,'x',O.pupil_x,'y',ccw_mid,'ori',0);
                O.add_boundary('Line',"iris_cw",'media',["*" "*"],'n1n2',[0 eps],'r1r2',[0 0],'length',cw_len,'x',O.pupil_x,'y',cw_mid,'ori',0);
            end
            
            % Apply the body's orientation to the boundaries
            O.pivot_x=O.boundaries.retina.xpos;
            O.pivot_y=O.boundaries.retina.ypos;
            cellfun(@(x)x.rotate(O.orientation,[O.xpos+O.pivot_x O.ypos+O.pivot_y]),struct2cell(O.boundaries));
            
        end
    end
    
    methods
        function set.accommodation(O,val)
            if ~isnumeric(val) || ~isscalar(val) || val<0
                error('accommodation must be a scalar equal or larger than 0');
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
