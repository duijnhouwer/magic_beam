classdef (Abstract) Body < mb.base.Base & mb.base.Visible
    
    % Base class for bodies (such as prisms, eyeballs) that consists of several optical boundaries (such as
    % arc segments)
    
    properties (Access=public)
        boundaries=struct % Struct with optical boundaries that constitute the body.
        zlayer=1 % Objects with higher zlayer will be drawn on top in plots
    end
    
    methods
        %% Plot all boundaries that make up this body
        function show(O,varargin)
            p=inputParser;
            p.addParameter('xylabel',[("x ("+mb.settings('length_unit') +")") ("y ("+mb.settings('length_unit') +")")],@(x)isstring(x) && numel(x)==2 || x=="");
            p.addParameter('equal',true,@(x)islogical(x)||isempty(x)); % empty to explicitely leave as is (equal,false does that too actually)
            p.parse(varargin{:});
            washolding=ishold;
            hold('on');
            bnds=struct2cell(O.boundaries);
            for i=1:numel(bnds)
                delete(findobj(gca,'UserData',bnds{i}.id));
                bnds{i}.show;
            end
            % Apply the axes styles
            if numel(p.Results.xylabel)==2
                fontsize=mb.settings('fontsize');
                if fontsize>0
                    set(gca,'FontSize',fontsize*0.80);
                    xlabel(p.Results.xylabel(1),'FontSize',fontsize);
                    ylabel(p.Results.xylabel(2),'FontSize',fontsize);
                end
            end
            if p.Results.equal
                try
                    axis('equal');
                catch me
                    warning(me.message)
                end
            end
            if ~washolding
                hold('off');
            end
        end
        
        %% Destructor
        function delete(O)
            % Call the destructor of all boundaries
            bnds=struct2cell(O.boundaries);
            for i=1:numel(bnds)
                bnds{i}.delete();
            end
            O.delete;
        end
        
        function h = add_boundary(O,type,name,varargin)
            % Add a boundary of type ''type'' and with name ''name'' to this body. varargin may contain
            % name-value pairs to set the properties of the boundary. Return value 'h', a handle to
            % the boundary-object, can be used to make subsequent changes to the boundary-object.
            % If ''name'' is empty, a name of format 'bnd00X' will be autogenerated.
            if ~exist('name','var') || isempty(name)
                name = O.auto_fieldname(O.boundaries,'bnd',3);
            end
            try
                O.boundaries.(name)=mb.boundary.(type)(O,varargin);
                h=O.boundaries.(name); % return so that boundary properties can be conviently changed after adding
            catch me
                if me.identifier=="MATLAB:AddField:InvalidFieldName"
                    error('Invalid boundary name: ''%s''. Valid boundary names begin with a letter, and can contain letters, digits, and underscores. The maximum length of a field name is the value that the namelengthmax function returns.',name);
                else
                    rethrow(me);
                end
            end
        end
        
        function [inray_hit,reflex,refrax] = reflect_and_refract(O,inray)
            % Loop over all the boundaries that constitute this body and see if the
            % inray hits them. Return the reflex and refrax form the element that was
            % closest to the source, the other elements were in the shadow of this one.
            inray_hit=false;
            min_len=Inf;
            bnds=struct2cell(O.boundaries);
            for i=1:numel(bnds)
                if bnds{i}.id==inray.current_boundary_id
                    % Don't test the boundary at which the ray currenty is, because it doesn't make sense. And it will always be a hit
                    continue
                end
                [hit,candidate_reflex,candidate_refrax] = bnds{i}.reflect_and_refract(inray);
                if hit && inray.length<min_len
                    min_len=inray.length; % reflect_and_refract updated inray's length with the distance from origin to hitpoint
                    % reflex
                    %reflex=copy(candidate_reflex);
                    reflex=candidate_reflex;
                    reflex.lineage.parent.id=inray.id;
                    reflex.lineage.birthplace=bnds{i}.id;
                    % refrax
                    % refrax=copy(candidate_refrax);
                    refrax=candidate_refrax;
                    refrax.lineage.parent.id=inray.id;
                    refrax.lineage.birthplace=bnds{i}.id;
                    % signal the inray did hit something
                    inray_hit=true;
                end
            end
            if ~inray_hit
                reflex=[];
                refrax=[];
            end
            % Set the in_ray length to min_len, the distance it traveled from source to
            % hit-point (Inf if it didn't hit anything)
            inray.length=min_len;
        end
        
        function dcopy = deep_copy(O)
            dcopy = copy(O);
            for i=1:numel(O.boundaries)
                dcopy.boundaries{i}=copy(O.boundaries{i});
            end
        end
    end
end
