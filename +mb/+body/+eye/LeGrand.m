classdef LeGrand < mb.body.Body
    
    
    % THIS EYEBALL MODEL PROBABLY NEEDS UPDATING TO BE CONSISTENT WITH FOR EXAMPEL GULLSTRANDVAR,
    % OUTDATED DESIGN    
    
    properties
        % note pupil_* properties must be a number (not empty) from the start because otherwise we
        % get endless recurssion in the O.update_iris method which their  set-methods call
        pupil_offset_deg=0;
        pupil_diam_deg=20;
    end
    
    methods (Access=public)
        function O=LeGrand(varargin)
            % Based on Le Grand full theoretical, model p. 251 Atchison & Smith 2002
            O.apply_name_value_pairs(O,varargin);
            O.boundaries={};
            O.add_boundary('Arc',"anterior_cornea",'media',["air" "cornea"],'n1n2',[1.0000 1.3771],'r1r2',[1 0],'x',5.3965,'radius',7.8,'span',117.868779);
            O.add_boundary('Arc',"posterior_cornea",'media',["cornea" "aqueous"],'n1n2',[1.3771 1.3374],'r1r2',[1 0],'x',6.1465,'radius',6.5,'span',118.307983);
            O.add_boundary('Arc',"anterior_lens",'media',["aqueous" "lens"],'n1n2',[1.3374 1.4200],'r1r2',[1 0],'x',3.9965,'radius',6,'span',98.644586);
            O.add_boundary('Arc',"posterior_lens",'media',["lens" "vitreous"],'n1n2',[1.4200 1.3360],'r1r2',[1 0],'x',10.9965,'radius',5.5,'arc_delta',180,'span',111.6479);
            O.add_boundary('Arc',"retina",'media',["vitreous" "sclera"],'n1n2',[1.3360 0.0000],'r1r2',[0 0],'x',0,'radius',11,'arc_delta',180,'span',299);
            O.add_boundary('Arc',"sclera",'media',["sclera" "air"],'n1n2',[0.0000 1.0000],'r1r2',[0 0],'x',0,'radius',11.55,'arc_delta',180,'span',289.34);
            O.update_iris;
            % Apply the body's orientation to the boundaries
            O.pivot_x=O.boundaries.retina.xpos;
            O.pivot_y=O.boundaries.retina.ypos;
            cellfun(@(x)x.rotate(O.orientation,[O.xpos+O.pivot_x O.ypos+O.pivot_y]),struct2cell(O.boundaries));
        end

    end
    
    methods (Access=private)
        function update_iris(O,varargin)
            % Delete existing boundaries whose name contains "iris". This automatically
            % deletes them from the plot, too.
            names=string(fieldnames(O.boundaries));
            O.boundaries=rmfield(O.boundaries,names(contains(names,'iris')));
            % Add the half of the iris that lies counter-clockwise from the eye's orientation axis
            h=O.add_boundary('Arc',"iris_ccw",'media',["*" "*"],'n1n2',[0 -1],'r1r2',[0 0],'radius',11,'x',O.xpos,'y',O.ypos,'ori',O.orientation);
            h.arc_delta = (45+O.pupil_diam_deg+O.pupil_offset_deg)/2;
            h.span = max(0,45-O.pupil_diam_deg/2-O.pupil_offset_deg/2);
            % Add the other half of the iris
            h=O.add_boundary('Arc',"iris_cw",'media',["*" "*"],'n1n2',[0 -1],'r1r2',[0 0],'radius',11,'x',O.xpos,'y',O.ypos,'ori',O.orientation);
            h.arc_delta = (-45-O.pupil_diam_deg+O.pupil_offset_deg)/2;
            h.span = max(0,45-O.pupil_diam_deg/2+O.pupil_offset_deg/2);
        end
    end
    
    methods
        function set.pupil_offset_deg(O,val)
            if ~isnumeric(val) || ~isscalar(val)
                error('pupil_offset_deg must be a positive scalar');
            end
            if O.pupil_offset_deg~=val
                O.pupil_offset_deg=val;
                O.update_iris;
            end
        end
        function set.pupil_diam_deg(O,val)
            if ~isnumeric(val) || ~isscalar(val) || val<0
                error('pupil_diam_deg must be a positive scalar');
            end
            if O.pupil_diam_deg~=val
                O.pupil_diam_deg=val;
                O.update_iris;
            end
        end
    end
end
