classdef Leaper < mb.body.Body
    
    methods (Access=public)
        %% Constructor
        function O=Leaper(varargin)
            O.apply_name_value_pairs(O,varargin);
            O.set_boundaries;
        end
    end
    
    methods (Access=private)
       
            % Measured by aligning cirles and ellipses to a Leaper image using Adobe
            % Illustrator, reporting the pixel values of their radii, (x,y)-pos, etc
            % below, and normalizing so that the leaper is 1-inch across
            %
            % Body top
            m.body_top_x = 960.8548 - 960.8548;
            m.body_top_y = 540.3952 - 540.3952;
            m.body_r = 517.7096 / 517.7096 * 25.4/2;
            % Left wing top
            m.leftwing_top_x =(923.1548 - 960.8548) / 517.7096 * 25.4;
            m.leftwing_top_y = - (787.7894 - 540.3952) / 517.7096 * 25.4;
            m.leftwing_top_r = 853.4037 / 517.7096 * 25.4/2;
            % Left wing bottom
            m.leftwing_bot_x = (1007.082 - 960.8548) / 517.7096 * 25.4;
            m.leftwing_bot_y = - (1660.6734 - 540.3952) / 517.7096 * 25.4;
            m.leftwing_bot_r = 2092.077 / 517.7096 * 25.4/2;
            % Left eye
            m.lefteye_x = (1094.1748 - 960.8548) / 517.7096 * 25.4;
            m.lefteye_y = - (453.1146 - 540.3952) / 517.7096 * 25.4;
            m.lefteye_r1 = 115.8405  / 517.7096 * 25.4/2;
            m.lefteye_r2 = 136.1843  / 517.7096 * 25.4/2;
            m.lefteye_tilt = 12.105;
            %
            O.boundaries={};
            O.boundaries{end+1}=mb.boundary.Arc('name',"bodytop",'media',["air" "leaper"],'n1n2',[1.000 2.667],'r1r2',[1 1],'x',0,'y',0,'radius',m.body_r,'arc_delta',90,'span',149.55);
            O.boundaries{end+1}=mb.boundary.Arc('name',"bodybottom",'media',["air" "leaper"],'n1n2',[1.000 2.667],'r1r2',[1 1],'x',0,'y',0,'radius',m.body_r,'arc_delta',-90,'span',138);
            O.boundaries{end+1}=mb.boundary.Arc('name',"leftwingtop",'media',["air" "leaper"],'n1n2',[1.000 2.667],'r1r2',[1 1],'x',m.leftwing_top_x,'y',m.leftwing_top_y,'radius',m.leftwing_top_r,'arc_delta',32.2,'span',31.3);
            O.boundaries{end+1}=mb.boundary.Arc('name',"leftwingbottom",'media',["air" "leaper"],'n1n2',[1.000 2.667],'r1r2',[1 1],'x',m.leftwing_bot_x,'y',m.leftwing_bot_y,'radius',m.leftwing_bot_r,'arc_delta',75.55,'span',7.35);
            O.boundaries{end+1}=mb.boundary.Arc('name',"rightwingtop",'media',["air" "leaper"],'n1n2',[1.000 2.667],'r1r2',[1 1],'x',-m.leftwing_top_x,'y',m.leftwing_top_y,'radius',m.leftwing_top_r,'arc_delta',180-32.2,'span',31.3);
            O.boundaries{end+1}=mb.boundary.Arc('name',"leftwingbottom",'media',["air" "leaper"],'n1n2',[1.000 2.667],'r1r2',[1 1],'x',-m.leftwing_bot_x,'y',m.leftwing_bot_y,'radius',m.leftwing_bot_r,'arc_delta',180-75.55,'span',7.35);
            O.boundaries{end+1}=mb.boundary.Arc('name',"lefteye",'media',["leaper" "air"],'n1n2',[2.667 1.000],'r1r2',[1 1],'x',m.lefteye_x,'y',m.lefteye_y,'radius',m.lefteye_r1,'radius2',m.lefteye_r2,'orientation',m.lefteye_tilt,'span',360);
            O.boundaries{end+1}=mb.boundary.Arc('name',"righteye",'media',["leaper" "air"],'n1n2',[2.667 1.000],'r1r2',[1 1],'x',-m.lefteye_x,'y',m.lefteye_y,'radius',m.lefteye_r1,'radius2',m.lefteye_r2,'orientation',-m.lefteye_tilt,'span',360);
            
        end
    end
end
